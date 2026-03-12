import Foundation

protocol StorageInfoProviding {
    func currentDiskUsageInBytes() -> Int64
}

final class ModelFileStorage: StorageInfoProviding {
    private let fileManager: FileManager
    private let baseDirectory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        self.baseDirectory = applicationSupport.appendingPathComponent("Models", isDirectory: true)
        ensureDirectoryExists()
    }

    func modelFileURL(modelID: String) -> URL {
        baseDirectory.appendingPathComponent("\(modelID).bin")
    }

    func listInstalledModelIDs() -> [String] {
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return fileURLs
            .filter { $0.pathExtension == "bin" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }

    func removeModelFile(modelID: String) throws {
        let url = modelFileURL(modelID: modelID)
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        try fileManager.removeItem(at: url)
    }

    func currentDiskUsageInBytes() -> Int64 {
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return fileURLs.reduce(0) { partialResult, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return partialResult + Int64(size)
        }
    }

    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }
}
