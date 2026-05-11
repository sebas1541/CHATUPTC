import CoreGraphics
import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLMCommon
import MLXVLM
import Tokenizers

public enum ModelService {
    public static func resolveModelDirectory() -> URL {
        if let env = ProcessInfo.processInfo.environment["UPTC_MODEL_PATH"], !env.isEmpty {
            return URL(fileURLWithPath: env)
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Model")
    }

    /// Carga el modelo Gemma 4 multimodal vía VLMModelFactory.
    /// La arquitectura `gemma4` (any-to-any) requiere el factory de VLM para
    /// soportar imágenes/audio además de texto.
    public static func loadContainer(modelDirectory: URL) async throws -> ModelContainer {
        // Limitar el cache de buffers Metal a ~2 GB para evitar OOM con
        // contextos largos. Sin esto MLX retiene buffers grandes y un solo
        // allocation puede superar el límite de 9.5 GB de un Metal buffer.
        MLX.GPU.set(cacheLimit: 2 * 1024 * 1024 * 1024)
        return try await VLMModelFactory.shared.loadContainer(
            from: modelDirectory,
            using: #huggingFaceTokenizerLoader()
        )
    }

    public static func makeChatSession(
        container: ModelContainer,
        temperature: Float = 0.3
    ) throws -> ChatSession {
        let instructions = try Knowledge.systemPrompt()
        return ChatSession(
            container,
            instructions: instructions,
            generateParameters: GenerateParameters(temperature: temperature),
            processing: UserInput.Processing(resize: CGSize(width: 768, height: 768))
        )
    }
}
