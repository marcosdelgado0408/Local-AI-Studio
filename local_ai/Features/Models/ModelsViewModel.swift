import Foundation

@MainActor
final class ModelsViewModel {
    private let downloadRepository: DownloadRepository
    private let listAvailableModelsUseCase: ListAvailableModelsUseCase
    private let listInstalledModelsUseCase: ListInstalledModelsUseCase
    private let downloadModelUseCase: DownloadModelUseCase
    private let deleteModelUseCase: DeleteModelUseCase
    private let selectActiveModelUseCase: SelectActiveModelUseCase
    private var downloadObservationTask: Task<Void, Never>?

    private(set) var models: [LocalModel] = [] {
        didSet { onModelsUpdated?(models) }
    }

    var onModelsUpdated: (([LocalModel]) -> Void)?
    var onError: ((String) -> Void)?

    init(
        downloadRepository: DownloadRepository,
        listAvailableModelsUseCase: ListAvailableModelsUseCase,
        listInstalledModelsUseCase: ListInstalledModelsUseCase,
        downloadModelUseCase: DownloadModelUseCase,
        deleteModelUseCase: DeleteModelUseCase,
        selectActiveModelUseCase: SelectActiveModelUseCase
    ) {
        self.downloadRepository = downloadRepository
        self.listAvailableModelsUseCase = listAvailableModelsUseCase
        self.listInstalledModelsUseCase = listInstalledModelsUseCase
        self.downloadModelUseCase = downloadModelUseCase
        self.deleteModelUseCase = deleteModelUseCase
        self.selectActiveModelUseCase = selectActiveModelUseCase
    }

    func load() {
        Task {
            do {
                try await refreshModels()
                _ = try await listInstalledModelsUseCase.execute()
                startObservingDownloadsIfNeeded()
            } catch {
                onError?("Failed to load models.")
            }
        }
    }

    func primaryAction(for model: LocalModel) {
        Task {
            do {
                switch model.status {
                case .notDownloaded:
                    try await downloadModelUseCase.execute(modelID: model.id)
                case .installed:
                    try await selectActiveModelUseCase.execute(modelID: model.id)
                case .downloading, .active:
                    break
                }
                try await refreshModels()
            } catch {
                let reason = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                onError?("Action failed for \(model.displayName).\n\(reason)")
            }
        }
    }

    func delete(model: LocalModel) {
        Task {
            do {
                try await deleteModelUseCase.execute(modelID: model.id)
                try await refreshModels()
            } catch {
                let reason = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                onError?("Failed to delete model.\n\(reason)")
            }
        }
    }

    private func refreshModels() async throws {
        models = try await listAvailableModelsUseCase.execute()
    }

    private func startObservingDownloadsIfNeeded() {
        guard downloadObservationTask == nil else { return }
        downloadObservationTask = Task {
            for await _ in downloadRepository.observeDownloadTasks() {
                do {
                    try await refreshModels()
                } catch {
                    onError?("Failed to refresh download progress.")
                }
            }
        }
    }
}
