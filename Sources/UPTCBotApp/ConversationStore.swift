import Foundation
import Observation

struct Conversation: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String = "New chat"
    var messages: [ChatMessage] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var subtitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(updatedAt) { return "Today" }
        if cal.isDateInYesterday(updatedAt) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: updatedAt)
    }
}

@MainActor
@Observable
final class ConversationStore {
    var conversations: [Conversation] = []
    var selectedID: UUID?

    private let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("UPTCBot")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("conversations.json")
    }()

    init() {
        load()
        if conversations.isEmpty {
            newConversation()
        } else {
            selectedID = conversations.first?.id
        }
    }

    var selectedConversation: Conversation? {
        guard let id = selectedID else { return nil }
        return conversations.first(where: { $0.id == id })
    }

    var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return conversations.firstIndex(where: { $0.id == id })
    }

    @discardableResult
    func newConversation() -> Conversation {
        let convo = Conversation()
        conversations.append(convo)
        selectedID = convo.id
        save()
        return convo
    }

    func deleteConversation(_ id: UUID) {
        conversations.removeAll(where: { $0.id == id })
        if selectedID == id {
            selectedID = conversations.first?.id
        }
        // Si te quedaste sin chats, crear uno vacío automáticamente —
        // si no, el composer se queda en el aire y los mensajes se pierden.
        if conversations.isEmpty {
            newConversation()
            return
        }
        save()
    }

    func appendUserMessage(_ text: String, imagePaths: [String] = []) {
        guard let idx = selectedIndex else { return }
        conversations[idx].messages.append(
            ChatMessage(role: .user, text: text, imagePaths: imagePaths)
        )
        conversations[idx].updatedAt = Date()
        if conversations[idx].title == "New chat" {
            let preview = text.prefix(40).trimmingCharacters(in: .whitespaces)
            conversations[idx].title = preview.isEmpty ? "New chat" : String(preview)
        }
        // No guardamos en cada caracter; un user message es atómico, sí guardamos.
        save()
    }

    /// Crea un mensaje de assistant vacío que se irá llenando con chunks.
    func startAssistantMessage() {
        guard let idx = selectedIndex else { return }
        conversations[idx].messages.append(ChatMessage(role: .assistant, text: ""))
    }

    func appendChunkToLastAssistantMessage(_ chunk: String) {
        guard let idx = selectedIndex else { return }
        guard let lastIdx = conversations[idx].messages.indices.last else { return }
        guard conversations[idx].messages[lastIdx].role == .assistant else { return }
        conversations[idx].messages[lastIdx].text += chunk
        conversations[idx].updatedAt = Date()
        // No guardamos durante el streaming — sería muy costoso. Save() al final.
    }

    func save() {
        let snapshot = conversations
        let url = saveURL
        Task.detached(priority: .utility) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(snapshot) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let list = try? decoder.decode([Conversation].self, from: data) {
            conversations = list.sorted(by: { $0.createdAt < $1.createdAt })
        }
    }
}
