import Foundation

@MainActor
final class DownloadsViewModel {
    private let downloadRepository: DownloadRepository

    private(set) var tasks: [DownloadTaskInfo] = [] {
        didSet { onTasksUpdated?(tasks) }
    }

    var onTasksUpdated: (([DownloadTaskInfo]) -> Void)?

    private var streamTask: Task<Void, Never>?

    init(downloadRepository: DownloadRepository) {
        self.downloadRepository = downloadRepository
    }

    func start() {
        streamTask?.cancel()
        streamTask = Task {
            tasks = await downloadRepository.listDownloadTasks()
            for await updates in downloadRepository.observeDownloadTasks() {
                tasks = updates
            }
        }
    }

    func pause(_ taskID: UUID) {
        Task { await downloadRepository.pauseDownload(taskID: taskID) }
    }

    func resume(_ taskID: UUID) {
        Task { await downloadRepository.resumeDownload(taskID: taskID) }
    }

    func cancel(_ taskID: UUID) {
        Task { await downloadRepository.cancelDownload(taskID: taskID) }
    }
}
