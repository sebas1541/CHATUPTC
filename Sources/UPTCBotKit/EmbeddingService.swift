import Foundation
import HuggingFace
import MLX
import MLXEmbedders
import MLXHuggingFace
import MLXLMCommon
import Tokenizers

/// Servicio de retrieval semántico para el RAG.
///
/// Carga el modelo `intfloat/multilingual-e5-small` (~80 MB) vía MLXEmbedders,
/// pre-computa embeddings para los 54 docs de la base de conocimiento, y
/// expone `retrieve(query:topK:)` que devuelve los docs más relevantes según
/// similitud coseno.
///
/// Convención e5: el texto del query se prefija con "query: " y los documentos
/// con "passage: " (requerido por el modelo según el paper original).
public actor EmbeddingService {

    public enum LoadError: Error, CustomStringConvertible {
        case notInitialized
        public var description: String { "EmbeddingService no inicializado" }
    }

    private var container: EmbedderModelContainer?
    private var indexed: [(doc: KnowledgeDoc, vector: [Float])] = []

    public init() {}

    public var isReady: Bool { container != nil && !indexed.isEmpty }
    public var documentCount: Int { indexed.count }

    /// Carga el modelo embedder e indexa todos los docs. Llamar una vez al
    /// arranque de la app. ~5-10s la primera vez (incluye descarga del modelo
    /// desde HuggingFace si no está en caché local).
    public func initialize(
        progressHandler: @Sendable @escaping (Progress) -> Void = { _ in }
    ) async throws {
        if container == nil {
            container = try await EmbedderModelFactory.shared.loadContainer(
                from: #hubDownloader(),
                using: #huggingFaceTokenizerLoader(),
                configuration: EmbedderRegistry.multilingual_e5_small,
                progressHandler: progressHandler
            )
        }

        let docs = try Knowledge.allDocs()
        // Convención e5: documentos se prefijan con "passage: ".
        let texts = docs.map { "passage: \($0.embeddingText)" }
        let vectors = try await embed(texts: texts)
        indexed = zip(docs, vectors).map { (doc: $0, vector: $1) }
    }

    /// Recupera los `topK` docs más relevantes para `query`.
    public func retrieve(query: String, topK: Int = 5) async throws -> [KnowledgeDoc] {
        guard !indexed.isEmpty else { throw LoadError.notInitialized }

        // Convención e5: queries se prefijan con "query: ".
        let queryVectors = try await embed(texts: ["query: \(query)"])
        let queryVec = queryVectors[0]

        // Los vectores ya están L2-normalizados (normalize: true en pooling),
        // así que la similitud coseno es solo el producto punto.
        let scored = indexed.map { entry -> (KnowledgeDoc, Float) in
            let score = dotProduct(queryVec, entry.vector)
            return (entry.doc, score)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(topK)
            .map { $0.0 }
    }

    // MARK: Internals

    private func embed(texts: [String]) async throws -> [[Float]] {
        guard let container else { throw LoadError.notInitialized }

        return await container.perform { context in
            let tokenizer = context.tokenizer
            let encoded = texts.map {
                tokenizer.encode(text: $0, addSpecialTokens: true)
            }
            let maxLength = encoded.reduce(into: 16) { acc, elem in
                acc = max(acc, elem.count)
            }
            let padToken = tokenizer.eosTokenId ?? 0
            let padded = stacked(
                encoded.map { elem in
                    MLXArray(
                        elem + Array(
                            repeating: padToken,
                            count: maxLength - elem.count
                        )
                    )
                }
            )
            let mask = (padded .!= padToken)
            let tokenTypes = MLXArray.zeros(like: padded)

            let modelOutput = context.model(
                padded,
                positionIds: nil,
                tokenTypeIds: tokenTypes,
                attentionMask: mask
            )

            // e5 usa mean pooling con L2 normalization, no layer norm extra.
            let pooled = context.pooling(
                modelOutput,
                normalize: true,
                applyLayerNorm: false
            )
            pooled.eval()
            return pooled.map { $0.asArray(Float.self) }
        }
    }

    private func dotProduct(_ a: [Float], _ b: [Float]) -> Float {
        zip(a, b).map(*).reduce(0, +)
    }
}
