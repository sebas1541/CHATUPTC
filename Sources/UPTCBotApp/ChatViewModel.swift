import Foundation
import MLXLMCommon
import Observation
import UPTCBotKit

struct ChatMessage: Identifiable, Codable, Equatable, Hashable {
    enum Role: String, Codable { case user, assistant }
    var id: UUID = UUID()
    let role: Role
    var text: String
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

    private var container: ModelContainer?
    private var session: ChatSession?
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
                let s = try ModelService.makeChatSession(container: c)
                self.container = c
                self.session = s
                self.modelState = .ready
            } catch {
                self.modelState = .failed(String(describing: error))
            }
        }
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let session, !isGenerating else { return }

        store.appendUserMessage(trimmed)
        store.startAssistantMessage()
        isGenerating = true

        generationTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.isGenerating = false
                self.store.save()
            }
            do {
                for try await chunk in session.streamResponse(to: trimmed) {
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

    /// Crea una nueva conversación vacía y reinicia la sesión MLX (sin KV cache previa).
    func newChat() {
        stopGeneration()
        store.newConversation()
        if let container {
            session = try? ModelService.makeChatSession(container: container)
        }
    }

    /// Cambia la conversación activa. La sesión MLX se recrea — el modelo no recuerda
    /// turnos previos al cambio, pero el usuario sí ve el historial visualmente.
    func selectConversation(_ id: UUID) {
        stopGeneration()
        store.selectedID = id
        if let container {
            session = try? ModelService.makeChatSession(container: container)
        }
    }
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
