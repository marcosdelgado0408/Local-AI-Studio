import Foundation

final class InferenceRepositoryImpl: InferenceRepository {
    private let engine: InferenceEngineProtocol
    private let storage: ModelFileStorage

    init(engine: InferenceEngineProtocol, storage: ModelFileStorage) {
        self.engine = engine
        self.storage = storage
    }

    func loadModel(_ model: LocalModel) async throws {
        let descriptor = MLXAdapter.mapModel(model, localPath: storage.modelFileURL(modelID: model.id).path)
        try await engine.loadModel(descriptor: descriptor)
    }

    func unloadModel() async {
        await engine.unloadModel()
    }

    func generate(prompt: String, attachments: [MessageAttachment], config: GenerationConfig) async throws -> String {
        let mlxConfig = MLXAdapter.mapGenerationConfig(config)
        return try await engine.generate(prompt: prompt, attachments: attachments, config: mlxConfig)
    }

    func stream(prompt: String, attachments: [MessageAttachment], config: GenerationConfig) -> AsyncThrowingStream<String, Error> {
        let mlxConfig = MLXAdapter.mapGenerationConfig(config)
        return engine.stream(prompt: prompt, attachments: attachments, config: mlxConfig)
    }

    func stopGeneration() async {
        await engine.stopGeneration()
    }
}
