import Foundation

actor LocalDownloadRepository: DownloadRepository {
    private var tasks: [UUID: DownloadTaskInfo] = [:]
    private var continuations: [UUID: AsyncStream<[DownloadTaskInfo]>.Continuation] = [:]

    func createTask(for model: LocalModel) -> UUID {
        let taskID = UUID()
        tasks[taskID] = DownloadTaskInfo(
            id: taskID,
            modelID: model.id,
            modelName: model.displayName,
            progress: 0,
            state: .queued
        )
        broadcast()
        return taskID
    }

    func markDownloading(taskID: UUID) {
        guard var task = tasks[taskID] else { return }
        task.state = .downloading
        tasks[taskID] = task
        broadcast()
    }

    func updateProgress(taskID: UUID, progress: Double) {
        guard var task = tasks[taskID], task.state == .downloading || task.state == .paused else { return }
        task.progress = max(0, min(1, progress))
        tasks[taskID] = task
        broadcast()
    }

    func markCompleted(taskID: UUID) {
        guard var task = tasks[taskID] else { return }
        task.state = .completed
        task.progress = 1.0
        tasks[taskID] = task
        broadcast()
    }

    func markFailed(taskID: UUID) {
        guard var task = tasks[taskID] else { return }
        task.state = .failed
        tasks[taskID] = task
        broadcast()
    }

    func listDownloadTasks() async -> [DownloadTaskInfo] {
        tasks.values.sorted { $0.modelName < $1.modelName }
    }

    nonisolated func observeDownloadTasks() -> AsyncStream<[DownloadTaskInfo]> {
        AsyncStream { continuation in
            Task {
                let streamID = UUID()
                await self.registerContinuation(continuation, streamID: streamID)
                continuation.onTermination = { _ in
                    Task { await self.removeContinuation(streamID: streamID) }
                }
            }
        }
    }

    func pauseDownload(taskID: UUID) async {
        guard var task = tasks[taskID], task.state == .downloading else {
            return
        }
        task.state = .paused
        tasks[taskID] = task
        broadcast()
    }

    func resumeDownload(taskID: UUID) async {
        guard var task = tasks[taskID], task.state == .paused else {
            return
        }
        task.state = .downloading
        tasks[taskID] = task
        broadcast()
    }

    func cancelDownload(taskID: UUID) async {
        guard var task = tasks[taskID], task.state == .downloading || task.state == .paused || task.state == .queued else {
            return
        }
        task.state = .canceled
        tasks[taskID] = task
        broadcast()
    }

    private func registerContinuation(_ continuation: AsyncStream<[DownloadTaskInfo]>.Continuation, streamID: UUID) {
        continuations[streamID] = continuation
        continuation.yield(tasks.values.sorted { $0.modelName < $1.modelName })
    }

    private func removeContinuation(streamID: UUID) {
        continuations[streamID] = nil
    }

    private func broadcast() {
        let sorted = tasks.values.sorted { $0.modelName < $1.modelName }
        continuations.values.forEach { $0.yield(sorted) }
    }
}
