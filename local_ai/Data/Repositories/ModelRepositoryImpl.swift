import Foundation

final class ModelRepositoryImpl: ModelRepository {
    private let metadataStore: ModelMetadataStore
    private let storage: ModelFileStorage
    private let downloadClient: ModelDownloadClient
    private let downloadRepository: LocalDownloadRepository

    private let seededModels: [LocalModel] = [
        LocalModel(
            id: "qwen3_5-0_8b-8bit",
            displayName: "Qwen3.5 0.8B 8-bit (MLX, multimodal)",
            parameterSize: "0.8B",
            estimatedSizeInBytes: 2_100_000_000,
            summary: "Qwen 3.5 multimodal (image + text), 8-bit quantization for lower memory footprint.",
            supportsStreaming: true,
            minimumRAMInGB: 4,
            isCompatibleWithCurrentDevice: true,
            status: .notDownloaded
        ),
        LocalModel(
            id: "qwen3_5-2b-6bit",
            displayName: "Qwen3.5 2B 6-bit (MLX, multimodal)",
            parameterSize: "2B",
            estimatedSizeInBytes: 5_700_000_000,
            summary: "Qwen 3.5 multimodal (image + text), 6-bit quantization for stronger quality.",
            supportsStreaming: true,
            minimumRAMInGB: 8,
            isCompatibleWithCurrentDevice: true,
            status: .notDownloaded
        )
    ]

    init(
        metadataStore: ModelMetadataStore,
        storage: ModelFileStorage,
        downloadClient: ModelDownloadClient,
        downloadRepository: LocalDownloadRepository
    ) {
        self.metadataStore = metadataStore
        self.storage = storage
        self.downloadClient = downloadClient
        self.downloadRepository = downloadRepository
    }

    func listAvailableModels() async throws -> [LocalModel] {
        let installedIDs = Set(storage.listInstalledModelIDs())
        let activeID = metadataStore.loadActiveModelID()
        let downloadTasks = await downloadRepository.listDownloadTasks()
        let progressByModelID = Dictionary(
            uniqueKeysWithValues: downloadTasks.map { ($0.modelID, $0.progress) }
        )
        let downloadingIDs = Set(downloadTasks
            .filter { $0.state == .queued || $0.state == .downloading || $0.state == .paused }
            .map(\.modelID)
        )

        return seededModels.map { model in
            var resolved = model
            if downloadingIDs.contains(model.id) {
                resolved.status = .downloading
                resolved.downloadProgress = progressByModelID[model.id] ?? 0
            } else if activeID == model.id {
                resolved.status = .active
                resolved.downloadProgress = nil
            } else if installedIDs.contains(model.id) {
                resolved.status = .installed
                resolved.downloadProgress = nil
            } else {
                resolved.status = .notDownloaded
                resolved.downloadProgress = nil
            }
            return resolved
        }
    }

    func listInstalledModels() async throws -> [LocalModel] {
        try await listAvailableModels().filter { $0.status == .installed || $0.status == .active }
    }

    func downloadModel(modelID: String) async throws {
        guard let model = try await model(by: modelID) else {
            throw AppError.modelNotFound
        }

        let taskID = await downloadRepository.createTask(for: model)
        await downloadRepository.markDownloading(taskID: taskID)

        do {
            try await downloadClient.downloadModelBinary(
                for: model,
                destinationURL: storage.modelFileURL(modelID: model.id),
                onProgress: { progress in
                    Task { await self.downloadRepository.updateProgress(taskID: taskID, progress: progress) }
                }
            )
            await downloadRepository.markCompleted(taskID: taskID)
        } catch {
            await downloadRepository.markFailed(taskID: taskID)
            throw error
        }
    }

    func deleteModel(modelID: String) async throws {
        try storage.removeModelFile(modelID: modelID)
        if metadataStore.loadActiveModelID() == modelID {
            metadataStore.setActiveModelID(nil)
        }
    }

    func selectActiveModel(modelID: String) async throws {
        let installedIDs = Set(storage.listInstalledModelIDs())
        guard installedIDs.contains(modelID) else {
            throw AppError.invalidModelSelection
        }
        metadataStore.setActiveModelID(modelID)
    }

    func activeModel() async throws -> LocalModel? {
        guard let id = metadataStore.loadActiveModelID() else {
            return nil
        }
        return try await model(by: id)
    }

    func model(by id: String) async throws -> LocalModel? {
        try await listAvailableModels().first(where: { $0.id == id })
    }
}
