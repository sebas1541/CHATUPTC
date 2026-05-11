import Foundation
import MLXLMCommon
import UPTCBotKit

func run() async throws {
    let modelDir = ModelService.resolveModelDirectory()
    guard FileManager.default.fileExists(atPath: modelDir.path) else {
        FileHandle.standardError.write(Data("""
            Error: no encontré el modelo en \(modelDir.path)
            Define UPTC_MODEL_PATH o ejecuta desde el directorio raíz del proyecto.

            """.utf8))
        exit(1)
    }

    FileHandle.standardError.write(Data("Cargando modelo desde \(modelDir.path)...\n".utf8))
    let container = try await ModelService.loadContainer(modelDirectory: modelDir)
    let session = try ModelService.makeChatSession(container: container)
    FileHandle.standardError.write(Data("Modelo listo. Escribe tu pregunta (Ctrl+D para salir).\n\n".utf8))

    while true {
        print("> ", terminator: "")
        guard let line = readLine(strippingNewline: true) else {
            print("")
            break
        }
        let question = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if question.isEmpty { continue }

        do {
            for try await chunk in session.streamResponse(to: question) {
                print(chunk, terminator: "")
                fflush(stdout)
            }
            print("\n")
        } catch {
            FileHandle.standardError.write(Data("Error: \(error)\n".utf8))
        }
    }
}

try await run()
