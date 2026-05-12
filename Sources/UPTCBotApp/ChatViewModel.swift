import Foundation
import MLXLMCommon
import Observation
import UPTCBotKit

struct ChatMessage: Identifiable, Codable, Equatable, Hashable {
    enum Role: String, Codable { case user, assistant }
    var id: UUID = UUID()
    let role: Role
    var text: String
    var imagePaths: [String] = []
}

@MainActor
@Observable
final class ChatViewModel {
    enum ModelState {
        case idle
        case loading
        case ready
        case failed(String)
    }

    let store: ConversationStore
    var modelState: ModelState = .idle
    var isGenerating = false
    /// Reservado para futura reintroducción de imágenes — hoy no se usa
    /// porque cargamos vía MLXLLM (text-only) para reducir RAM.
    var pendingAttachment: URL?

    private var container: ModelContainer?
    private let embedder = EmbeddingService()
    private var loadTask: Task<Void, Never>?
    private var generationTask: Task<Void, Never>?

    init(store: ConversationStore) {
        self.store = store
    }

    var messages: [ChatMessage] {
        store.selectedConversation?.messages ?? []
    }

    func loadModelIfNeeded() {
        guard case .idle = modelState else { return }
        modelState = .loading

        loadTask = Task {
            do {
                let dir = ModelService.resolveModelDirectory()
                let c = try await ModelService.loadContainer(modelDirectory: dir)
                self.container = c

                // Cargar embedder e indexar 54 docs. Si falla, seguimos
                // con un fallback de stuffing reducido (sin RAG).
                do {
                    try await self.embedder.initialize()
                } catch {
                    // No abortar la app si el embedder falla — el LLM
                    // puede operar con un prompt genérico.
                    print("⚠️ Embedder no disponible: \(error). Continuando sin RAG.")
                }

                self.modelState = .ready
            } catch {
                self.modelState = .failed(String(describing: error))
            }
        }
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let container, !isGenerating else { return }

        // Red de seguridad: garantizar conversación activa.
        if store.selectedConversation == nil {
            store.newConversation()
        }

        store.appendUserMessage(trimmed)
        store.startAssistantMessage()
        isGenerating = true

        generationTask = Task { [weak self, embedder] in
            guard let self else { return }
            defer {
                self.isGenerating = false
                self.store.save()
            }

            do {
                // 1. Retrieval: obtener top-5 docs relevantes para esta query.
                let docs: [KnowledgeDoc]
                if await embedder.isReady {
                    docs = (try? await embedder.retrieve(query: trimmed, topK: 5)) ?? []
                } else {
                    docs = []
                }

                // 2. Construir system prompt dinámico con solo esos docs.
                let instructions = Knowledge.systemPrompt(usingDocs: docs)

                // 3. Sesión nueva por turno: sin KV cache acumulada de turnos
                //    anteriores → memoria sostenida bajo control.
                let session = ModelService.makeChatSession(
                    container: container,
                    instructions: instructions
                )

                // 4. Stream de respuesta.
                let stream = session.streamResponse(to: trimmed)
                for try await chunk in stream {
                    if Task.isCancelled { break }
                    self.store.appendChunkToLastAssistantMessage(chunk)
                }
            } catch {
                self.store.appendChunkToLastAssistantMessage("\n\n[Error: \(error)]")
            }
        }
    }

    func stopGeneration() {
        generationTask?.cancel()
        isGenerating = false
        store.save()
    }

    func newChat() {
        stopGeneration()
        store.newConversation()
    }

    func selectConversation(_ id: UUID) {
        stopGeneration()
        store.selectedID = id
    }

    // Stubs para compatibilidad con UI viejo (drag&drop, attach). No-op
    // mientras estemos en MLXLLM text-only.
    func attachImage(_ url: URL) {}
    func clearAttachment() {}
}

extension ChatViewModel.ModelState: Equatable {
    static func == (lhs: ChatViewModel.ModelState, rhs: ChatViewModel.ModelState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.ready, .ready): true
        case (.failed(let a), .failed(let b)): a == b
        default: false
        }
    }
}
