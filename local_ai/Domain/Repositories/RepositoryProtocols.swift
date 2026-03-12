import Foundation

protocol ModelRepository {
    func listAvailableModels() async throws -> [LocalModel]
    func listInstalledModels() async throws -> [LocalModel]
    func downloadModel(modelID: String) async throws
    func deleteModel(modelID: String) async throws
    func selectActiveModel(modelID: String) async throws
    func activeModel() async throws -> LocalModel?
    func model(by id: String) async throws -> LocalModel?
}

protocol ChatRepository {
    func loadChatHistory(sessionID: UUID) async throws -> [Message]
    func saveMessage(_ message: Message) async throws
    func loadChatSessions() async throws -> [ChatSession]
    func saveChatSession(_ session: ChatSession) async throws
    func deleteChatSession(sessionID: UUID) async throws
    func clearChatHistory() async throws
}

protocol DownloadRepository {
    func listDownloadTasks() async -> [DownloadTaskInfo]
    func observeDownloadTasks() -> AsyncStream<[DownloadTaskInfo]>
    func pauseDownload(taskID: UUID) async
    func resumeDownload(taskID: UUID) async
    func cancelDownload(taskID: UUID) async
}

protocol InferenceRepository {
    func loadModel(_ model: LocalModel) async throws
    func unloadModel() async
    func generate(prompt: String, config: GenerationConfig) async throws -> String
    func stream(prompt: String, config: GenerationConfig) -> AsyncThrowingStream<String, Error>
    func stopGeneration() async
}

protocol SettingsRepository {
    func loadGenerationConfig() async -> GenerationConfig
    func updateGenerationConfig(_ config: GenerationConfig) async throws
    func hasCompletedOnboarding() async -> Bool
    func setCompletedOnboarding(_ completed: Bool) async
}
