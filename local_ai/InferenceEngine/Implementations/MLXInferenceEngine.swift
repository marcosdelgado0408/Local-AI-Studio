import Foundation
import MLX
import MLXLLM
import MLXLMCommon

final class MLXInferenceEngine: InferenceEngineProtocol {
    private(set) var loadedModelID: String?
    private var loadedContainer: ModelContainer?
    private var generationTask: Task<Void, Never>?

    func loadModel(descriptor: MLXModelDescriptor) async throws {
#if targetEnvironment(simulator)
        throw AppError.inferenceNotSupportedOnSimulator
#else
        if loadedModelID == descriptor.id, loadedContainer != nil {
            return
        }

        let configuration = modelConfiguration(for: descriptor.id)
        // Keeps cache pressure predictable for mobile inference.
        Memory.cacheLimit = 20 * 1024 * 1024
        let container = try await LLMModelFactory.shared.loadContainer(configuration: configuration)

        loadedContainer = container
        loadedModelID = descriptor.id
#endif
    }

    func unloadModel() async {
        generationTask?.cancel()
        generationTask = nil
        loadedContainer = nil
        loadedModelID = nil
    }

    func generate(prompt: String, config: MLXGenerationConfig) async throws -> String {
        var result = ""
        for try await chunk in stream(prompt: prompt, config: config) {
            result += chunk
        }
        return result
    }

    func stream(prompt: String, config: MLXGenerationConfig) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard let container = loadedContainer else {
                continuation.finish(throwing: AppError.inferenceEngineUnavailable)
                return
            }

            generationTask = Task {
                do {
                    let stream = try await container.perform { context in
                        let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
                        let parameters = GenerateParameters(
                            maxTokens: config.maxTokens,
                            temperature: config.temperature,
                            topP: config.topP
                        )
                        return try MLXLMCommon.generate(input: input, parameters: parameters, context: context)
                    }

                    for await generation in stream {
                        if Task.isCancelled {
                            continuation.finish(throwing: AppError.generationStopped)
                            return
                        }

                        if case .chunk(let chunk) = generation, !chunk.isEmpty {
                            continuation.yield(chunk)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { [weak self] _ in
                self?.generationTask?.cancel()
                self?.generationTask = nil
            }
        }
    }

    func stopGeneration() async {
        generationTask?.cancel()
        generationTask = nil
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
