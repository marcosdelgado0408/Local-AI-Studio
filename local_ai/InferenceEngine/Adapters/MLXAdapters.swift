import Foundation

struct MLXModelDescriptor {
    let id: String
    let displayName: String
    let localPath: String
}

struct MLXGenerationConfig {
    let temperature: Float
    let topP: Float
    let maxTokens: Int
    let contextLength: Int
}

enum MLXAdapter {
    static func mapModel(_ model: LocalModel, localPath: String) -> MLXModelDescriptor {
        MLXModelDescriptor(id: model.id, displayName: model.displayName, localPath: localPath)
    }

    static func mapGenerationConfig(_ config: GenerationConfig) -> MLXGenerationConfig {
        MLXGenerationConfig(
            temperature: Float(config.temperature),
            topP: Float(config.topP),
            maxTokens: config.maxTokens,
            contextLength: config.contextLength
        )
    }
}
