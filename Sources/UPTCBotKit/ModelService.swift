import CoreGraphics
import Foundation
import HuggingFace
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
        try await VLMModelFactory.shared.loadContainer(
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
