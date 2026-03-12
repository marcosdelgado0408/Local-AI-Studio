import Foundation

enum AppError: Error, LocalizedError {
    case modelNotFound
    case invalidModelSelection
    case inferenceEngineUnavailable
    case generationStopped
    case persistenceFailure
    case storageFailure
    case invalidDownloadURL
    case unsupportedModelSource
    case downloadFailed
    case inferenceNotSupportedOnSimulator

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "The selected model could not be found."
        case .invalidModelSelection:
            return "The selected model is not installed on this device."
        case .inferenceEngineUnavailable:
            return "Inference engine is unavailable."
        case .generationStopped:
            return "Generation was stopped."
        case .persistenceFailure:
            return "Failed to persist local data."
        case .storageFailure:
            return "Failed to access local storage."
        case .invalidDownloadURL:
            return "The configured download URL is invalid."
        case .unsupportedModelSource:
            return "No official source configured for this model."
        case .downloadFailed:
            return "Model download failed due to network or server error."
        case .inferenceNotSupportedOnSimulator:
            return "MLX inference is not supported on iOS Simulator. Run on a real iPhone/iPad or on My Mac."
        }
    }
}
