import CoreGraphics
import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

public enum ModelService {
    public static func resolveModelDirectory() -> URL {
        // 1. Env var (override para desarrollo)
        if let env = ProcessInfo.processInfo.environment["UPTC_MODEL_PATH"], !env.isEmpty {
            return URL(fileURLWithPath: env)
        }
        // 2. Si corremos dentro de un .app bundle, Model/ está en Contents/Resources/
        if let bundleModel = Bundle.main.resourceURL?.appendingPathComponent("Model"),
           FileManager.default.fileExists(atPath: bundleModel.path) {
            return bundleModel
        }
        // 3. Fallback: ./Model relativo al cwd (modo dev con scripts)
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Model")
    }

    /// Carga el modelo Gemma 4 vía LLMModelFactory (text-only).
    /// Aunque el modelo es multimodal en disco, usar MLXLLM en lugar de MLXVLM
    /// salta la carga del vision encoder en RAM y arranca más rápido.
    public static func loadContainer(modelDirectory: URL) async throws -> ModelContainer {
        // Limitar el cache de buffers Metal a ~2 GB para evitar OOM con contextos
        // largos. Sin esto MLX retiene buffers grandes y una sola allocation
        // puede superar el límite de 9.5 GB de un Metal buffer en M2.
        MLX.GPU.set(cacheLimit: 2 * 1024 * 1024 * 1024)
        return try await LLMModelFactory.shared.loadContainer(
            from: modelDirectory,
            using: #huggingFaceTokenizerLoader()
        )
    }

    /// Crea una ChatSession con instrucciones dinámicas (incluyendo los docs
    /// recuperados por RAG). La session se recrea por cada turno para no
    /// acumular KV cache de turnos anteriores.
    public static func makeChatSession(
        container: ModelContainer,
        instructions: String,
        temperature: Float = 0.3
    ) -> ChatSession {
        ChatSession(
            container,
            instructions: instructions,
            generateParameters: GenerateParameters(temperature: temperature)
        )
    }
}
