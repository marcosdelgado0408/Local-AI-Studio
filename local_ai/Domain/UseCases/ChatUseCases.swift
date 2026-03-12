import Foundation

struct SendMessageUseCase {
    private let inferenceRepository: InferenceRepository

    init(inferenceRepository: InferenceRepository) {
        self.inferenceRepository = inferenceRepository
    }

    func execute(prompt: String, config: GenerationConfig) async throws -> String {
        try await inferenceRepository.generate(prompt: prompt, config: config)
    }
}

struct StreamResponseUseCase {
    private let inferenceRepository: InferenceRepository

    init(inferenceRepository: InferenceRepository) {
        self.inferenceRepository = inferenceRepository
    }

    func execute(prompt: String, config: GenerationConfig) -> AsyncThrowingStream<String, Error> {
        inferenceRepository.stream(prompt: prompt, config: config)
    }
}

struct LoadChatHistoryUseCase {
    private let chatRepository: ChatRepository

    init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
    }

    func execute(sessionID: UUID) async throws -> [Message] {
        try await chatRepository.loadChatHistory(sessionID: sessionID)
    }
}

struct SaveMessageUseCase {
    private let chatRepository: ChatRepository

    init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
    }

    func execute(_ message: Message) async throws {
        try await chatRepository.saveMessage(message)
    }
}
