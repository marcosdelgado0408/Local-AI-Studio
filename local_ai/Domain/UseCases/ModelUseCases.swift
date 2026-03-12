import Foundation

struct ListAvailableModelsUseCase {
    private let repository: ModelRepository

    init(repository: ModelRepository) {
        self.repository = repository
    }

    func execute() async throws -> [LocalModel] {
        try await repository.listAvailableModels()
    }
}

struct ListInstalledModelsUseCase {
    private let repository: ModelRepository

    init(repository: ModelRepository) {
        self.repository = repository
    }

    func execute() async throws -> [LocalModel] {
        try await repository.listInstalledModels()
    }
}

struct DownloadModelUseCase {
    private let repository: ModelRepository

    init(repository: ModelRepository) {
        self.repository = repository
    }

    func execute(modelID: String) async throws {
        try await repository.downloadModel(modelID: modelID)
    }
}

struct DeleteModelUseCase {
    private let repository: ModelRepository

    init(repository: ModelRepository) {
        self.repository = repository
    }

    func execute(modelID: String) async throws {
        try await repository.deleteModel(modelID: modelID)
    }
}

struct SelectActiveModelUseCase {
    private let repository: ModelRepository

    init(repository: ModelRepository) {
        self.repository = repository
    }

    func execute(modelID: String) async throws {
        try await repository.selectActiveModel(modelID: modelID)
    }
}
