import Foundation

protocol ModelRuntimeProtocol {
    var loadedModelID: String? { get }
    func loadModel(descriptor: MLXModelDescriptor) async throws
    func unloadModel() async
}

protocol InferenceEngineProtocol: ModelRuntimeProtocol {
    func generate(prompt: String, attachments: [MessageAttachment], config: MLXGenerationConfig) async throws -> String
    func stream(prompt: String, attachments: [MessageAttachment], config: MLXGenerationConfig) -> AsyncThrowingStream<String, Error>
    func stopGeneration() async
}
