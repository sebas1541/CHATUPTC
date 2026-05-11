import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

public enum ModelService {
    public static func resolveModelDirectory() -> URL {
        if let env = ProcessInfo.processInfo.environment["UPTC_MODEL_PATH"], !env.isEmpty {
            return URL(fileURLWithPath: env)
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Model")
    }

    public static func loadContainer(modelDirectory: URL) async throws -> ModelContainer {
        try await loadModelContainer(
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
            generateParameters: GenerateParameters(temperature: temperature)
        )
    }
}
