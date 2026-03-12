    import Foundation
import MLX
import MLXLLM
import MLXLMCommon

final class ModelDownloadClient {
    func downloadModelBinary(
        for model: LocalModel,
        destinationURL: URL,
        onProgress: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws {
#if targetEnvironment(simulator)
        throw AppError.inferenceNotSupportedOnSimulator
#else
        // Trigger official MLX Swift LM download/cache and warm the model.
        let configuration = modelConfiguration(for: model.id)
        Memory.cacheLimit = 20 * 1024 * 1024
        onProgress(0.05)
        _ = try await LLMModelFactory.shared.loadContainer(configuration: configuration) { progress in
            onProgress(max(0.05, min(0.95, progress.fractionCompleted)))
        }

        // Keep a lightweight local marker file so the app can track "installed" status.
        let fileManager = FileManager.default
        let destinationDirectory = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationDirectory.path) {
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        }

        let marker = Data("mlx-swift-lm-installed".utf8)
        try marker.write(to: destinationURL, options: .atomic)
        onProgress(1.0)
#endif
    }

    private func modelConfiguration(for modelID: String) -> ModelConfiguration {
        switch modelID {
        case "qwen3_5-0_8b-8bit":
            return ModelConfiguration(id: "mlx-community/Qwen3.5-0.8B-8bit")
        case "qwen3_5-2b-6bit":
            return ModelConfiguration(id: "mlx-community/Qwen3.5-2B-6bit")
        default:
            return ModelConfiguration(id: "mlx-community/Qwen3.5-0.8B-8bit")
        }
    }
}
