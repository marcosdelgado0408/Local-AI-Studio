import Foundation

final class ChatHistoryStore {
    private let messagesFileURL: URL
    private let sessionsFileURL: URL

    init(fileManager: FileManager = .default) {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        self.messagesFileURL = documentsDirectory.appendingPathComponent("chat_history.json")
        self.sessionsFileURL = documentsDirectory.appendingPathComponent("chat_sessions.json")
    }

    func loadMessages(sessionID: UUID) throws -> [Message] {
        let allMessages = try loadAllMessages()
        return allMessages.filter { $0.sessionID == sessionID }
    }

    func appendMessage(_ message: Message) throws {
        var allMessages = try loadAllMessages()
        allMessages.append(message)
        let data = try JSONEncoder().encode(allMessages)
        try data.write(to: messagesFileURL, options: .atomic)
    }

    func loadSessions() throws -> [ChatSession] {
        guard let data = try? Data(contentsOf: sessionsFileURL), !data.isEmpty else {
            return []
        }
        return try JSONDecoder().decode([ChatSession].self, from: data)
    }

    func upsertSession(_ session: ChatSession) throws {
        var sessions = try loadSessions()
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        try saveSessions(sessions)
    }

    func deleteSession(sessionID: UUID) throws {
        let filteredMessages = try loadAllMessages().filter { $0.sessionID != sessionID }
        let messagesData = try JSONEncoder().encode(filteredMessages)
        try messagesData.write(to: messagesFileURL, options: .atomic)

        let filteredSessions = try loadSessions().filter { $0.id != sessionID }
        try saveSessions(filteredSessions)
    }

    func clear() throws {
        try Data().write(to: messagesFileURL, options: .atomic)
        try Data().write(to: sessionsFileURL, options: .atomic)
    }

    private func loadAllMessages() throws -> [Message] {
        guard let data = try? Data(contentsOf: messagesFileURL), !data.isEmpty else {
            return []
        }
        return try JSONDecoder().decode([Message].self, from: data)
    }

    private func saveSessions(_ sessions: [ChatSession]) throws {
        let data = try JSONEncoder().encode(sessions)
        try data.write(to: sessionsFileURL, options: .atomic)
    }
}
