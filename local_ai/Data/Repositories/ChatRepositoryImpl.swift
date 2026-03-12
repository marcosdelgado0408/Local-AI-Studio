import Foundation

final class ChatRepositoryImpl: ChatRepository {
    private let store: ChatHistoryStore

    init(store: ChatHistoryStore) {
        self.store = store
    }

    func loadChatHistory(sessionID: UUID) async throws -> [Message] {
        try store.loadMessages(sessionID: sessionID)
    }

    func saveMessage(_ message: Message) async throws {
        try store.appendMessage(message)
    }

    func loadChatSessions() async throws -> [ChatSession] {
        try store.loadSessions()
    }

    func saveChatSession(_ session: ChatSession) async throws {
        try store.upsertSession(session)
    }

    func deleteChatSession(sessionID: UUID) async throws {
        try store.deleteSession(sessionID: sessionID)
    }

    func clearChatHistory() async throws {
        try store.clear()
    }
}
