import Foundation

@MainActor
final class ChatViewModel {
    private let modelRepository: ModelRepository
    private let chatRepository: ChatRepository
    private let settingsRepository: SettingsRepository
    private let inferenceRepository: InferenceRepository
    private let sendMessageUseCase: SendMessageUseCase
    private let streamResponseUseCase: StreamResponseUseCase
    private let loadChatHistoryUseCase: LoadChatHistoryUseCase
    private let saveMessageUseCase: SaveMessageUseCase

    private(set) var messages: [Message] = [] {
        didSet { onMessagesUpdated?(messages) }
    }

    private(set) var activeModelDisplayName: String = "No active model" {
        didSet { onModelUpdated?(activeModelDisplayName) }
    }
    private var activeModelID: String?

    private(set) var sessions: [ChatSession] = [] {
        didSet { onSessionsUpdated?(sessions) }
    }
    private(set) var activeSessionID: UUID? {
        didSet { onActiveSessionUpdated?(activeSessionID) }
    }
    private(set) var isGenerating: Bool = false {
        didSet { onGenerationStateUpdated?(isGenerating) }
    }

    var onMessagesUpdated: (([Message]) -> Void)?
    var onModelUpdated: ((String) -> Void)?
    var onSessionsUpdated: (([ChatSession]) -> Void)?
    var onActiveSessionUpdated: ((UUID?) -> Void)?
    var onGenerationStateUpdated: ((Bool) -> Void)?
    var onError: ((String) -> Void)?

    private let activeSessionUserDefaultsKey = "chat.active.session.id"
    private var generationConfig: GenerationConfig = .default

    init(
        modelRepository: ModelRepository,
        chatRepository: ChatRepository,
        settingsRepository: SettingsRepository,
        inferenceRepository: InferenceRepository,
        sendMessageUseCase: SendMessageUseCase,
        streamResponseUseCase: StreamResponseUseCase,
        loadChatHistoryUseCase: LoadChatHistoryUseCase,
        saveMessageUseCase: SaveMessageUseCase
    ) {
        self.modelRepository = modelRepository
        self.chatRepository = chatRepository
        self.settingsRepository = settingsRepository
        self.inferenceRepository = inferenceRepository
        self.sendMessageUseCase = sendMessageUseCase
        self.streamResponseUseCase = streamResponseUseCase
        self.loadChatHistoryUseCase = loadChatHistoryUseCase
        self.saveMessageUseCase = saveMessageUseCase
    }

    func load() {
        Task {
            generationConfig = await settingsRepository.loadGenerationConfig()
            await refreshActiveModel()

            do {
                sessions = try await chatRepository.loadChatSessions()
                sortSessions()

                if sessions.isEmpty {
                    let session = ChatSession(id: UUID(), createdAt: Date(), title: "New Chat", activeModelID: activeModelID)
                    try await chatRepository.saveChatSession(session)
                    sessions = [session]
                }

                if let persistedID = persistedActiveSessionID(),
                   sessions.contains(where: { $0.id == persistedID }) {
                    activeSessionID = persistedID
                } else {
                    activeSessionID = sessions.first?.id
                }
                persistActiveSessionID(activeSessionID)

                if let activeSessionID {
                    messages = try await loadChatHistoryUseCase.execute(sessionID: activeSessionID)
                } else {
                    messages = []
                }
            } catch {
                onError?("Failed to load chat history.")
            }
        }
    }

    func refreshActiveModel() async {
        guard let model = try? await modelRepository.activeModel() else {
            activeModelID = nil
            activeModelDisplayName = "No active model"
            return
        }

        activeModelDisplayName = model.displayName
        if activeModelID != model.id {
            try? await inferenceRepository.loadModel(model)
            activeModelID = model.id
        }
    }

    func sendMessage(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let activeSessionID else {
            onError?("Could not create chat session.")
            return
        }

        // Render user prompt immediately.
        let userMessage = Message(
            id: UUID(),
            sessionID: activeSessionID,
            role: .user,
            content: trimmed,
            createdAt: Date()
        )
        messages.append(userMessage)
        Task { try? await saveMessageUseCase.execute(userMessage) }

        // Render an explicit loading placeholder.
        var assistantMessage = Message(
            id: UUID(),
            sessionID: activeSessionID,
            role: .assistant,
            content: "Thinking locally...",
            createdAt: Date()
        )
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1
        isGenerating = true

        Task {
            defer { isGenerating = false }
            await refreshActiveModel()
            guard activeModelID != nil else {
                onError?("Select and activate a model from the Models tab first.")
                assistantMessage = Message(
                    id: assistantMessage.id,
                    sessionID: assistantMessage.sessionID,
                    role: assistantMessage.role,
                    content: "Select and activate a model from the Models tab first.",
                    createdAt: assistantMessage.createdAt
                )
                messages[assistantIndex] = assistantMessage
                return
            }

            do {
                var receivedAnyToken = false
                for try await token in streamResponseUseCase.execute(prompt: trimmed, config: generationConfig) {
                    let next = receivedAnyToken ? assistantMessage.content + token : token
                    assistantMessage = Message(
                        id: assistantMessage.id,
                        sessionID: assistantMessage.sessionID,
                        role: assistantMessage.role,
                        content: next,
                        createdAt: assistantMessage.createdAt
                    )
                    messages[assistantIndex] = assistantMessage
                    receivedAnyToken = true
                }

                if !receivedAnyToken {
                    let fallback = try await sendMessageUseCase.execute(prompt: trimmed, config: generationConfig)
                    assistantMessage = Message(
                        id: assistantMessage.id,
                        sessionID: assistantMessage.sessionID,
                        role: assistantMessage.role,
                        content: fallback,
                        createdAt: assistantMessage.createdAt
                    )
                    messages[assistantIndex] = assistantMessage
                }

                try? await saveMessageUseCase.execute(assistantMessage)
                await updateSessionMetadataAfterMessage(prompt: trimmed)
            } catch {
                let reason = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                onError?("Failed to generate response.\n\(reason)")
                assistantMessage = Message(
                    id: assistantMessage.id,
                    sessionID: assistantMessage.sessionID,
                    role: assistantMessage.role,
                    content: "Failed to generate response.",
                    createdAt: assistantMessage.createdAt
                )
                messages[assistantIndex] = assistantMessage
            }
        }
    }

    func startNewChat() {
        Task {
            let session = ChatSession(id: UUID(), createdAt: Date(), title: "New Chat", activeModelID: activeModelID)
            do {
                try await chatRepository.saveChatSession(session)
                sessions.insert(session, at: 0)
                sortSessions()
                activeSessionID = session.id
                persistActiveSessionID(session.id)
                messages = []
            } catch {
                onError?("Failed to start a new chat.")
            }
        }
    }

    func selectSession(_ sessionID: UUID) {
        Task {
            do {
                activeSessionID = sessionID
                persistActiveSessionID(sessionID)
                messages = try await loadChatHistoryUseCase.execute(sessionID: sessionID)
            } catch {
                onError?("Failed to load selected chat.")
            }
        }
    }

    func togglePinSession(_ sessionID: UUID) {
        Task {
            guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
            var session = sessions[index]
            session.isPinned.toggle()
            do {
                try await chatRepository.saveChatSession(session)
                sessions[index] = session
                sortSessions()
            } catch {
                onError?("Failed to update pinned state.")
            }
        }
    }

    func renameSession(_ sessionID: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
            var session = sessions[index]
            session.title = String(trimmed.prefix(60))
            do {
                try await chatRepository.saveChatSession(session)
                sessions[index] = session
            } catch {
                onError?("Failed to rename chat.")
            }
        }
    }

    func deleteSession(_ sessionID: UUID) {
        Task {
            do {
                try await chatRepository.deleteChatSession(sessionID: sessionID)
                sessions.removeAll(where: { $0.id == sessionID })

                if sessions.isEmpty {
                    let session = ChatSession(id: UUID(), createdAt: Date(), title: "New Chat", activeModelID: activeModelID)
                    try await chatRepository.saveChatSession(session)
                    sessions = [session]
                }

                if activeSessionID == sessionID {
                    activeSessionID = sessions.first?.id
                    persistActiveSessionID(activeSessionID)
                    if let activeSessionID {
                        messages = try await loadChatHistoryUseCase.execute(sessionID: activeSessionID)
                    } else {
                        messages = []
                    }
                }
            } catch {
                onError?("Failed to remove chat.")
            }
        }
    }

    private func updateSessionMetadataAfterMessage(prompt: String) async {
        guard let sessionID = activeSessionID,
              let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }

        var session = sessions[index]
        if session.title == "New Chat" || session.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            session.title = String(prompt.prefix(48))
        }
        session.activeModelID = activeModelID
        try? await chatRepository.saveChatSession(session)
        sessions[index] = session

        let updated = sessions.remove(at: index)
        if updated.isPinned {
            sessions.insert(updated, at: 0)
        } else {
            let pinCount = sessions.filter(\.isPinned).count
            sessions.insert(updated, at: pinCount)
        }
    }

    private func persistedActiveSessionID() -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: activeSessionUserDefaultsKey) else {
            return nil
        }
        return UUID(uuidString: raw)
    }

    private func persistActiveSessionID(_ id: UUID?) {
        if let id {
            UserDefaults.standard.set(id.uuidString, forKey: activeSessionUserDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeSessionUserDefaultsKey)
        }
    }

    private func sortSessions() {
        sessions.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
}
