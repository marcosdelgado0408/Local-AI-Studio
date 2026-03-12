import Foundation
import MLX
import MLXLMCommon

final class MLXInferenceEngine: InferenceEngineProtocol {
    private(set) var loadedModelID: String?
    private var loadedResolvedModelID: String?
    private var loadedContainer: ModelContainer?
    private var generationTask: Task<Void, Never>?

    func loadModel(descriptor: MLXModelDescriptor) async throws {
#if targetEnvironment(simulator)
        throw AppError.inferenceNotSupportedOnSimulator
#else
        let resolvedModelID = resolvedModelID(for: descriptor.id)
        if loadedModelID == descriptor.id,
           loadedResolvedModelID == resolvedModelID,
           loadedContainer != nil {
            return
        }

        let configuration = modelConfiguration(for: descriptor.id)
        // Keeps cache pressure predictable for mobile inference.
        Memory.cacheLimit = 20 * 1024 * 1024
        let container = try await loadModelContainer(configuration: configuration)

        loadedContainer = container
        loadedModelID = descriptor.id
        loadedResolvedModelID = resolvedModelID
#endif
    }

    func unloadModel() async {
        generationTask?.cancel()
        generationTask = nil
        loadedContainer = nil
        loadedModelID = nil
        loadedResolvedModelID = nil
    }

    func generate(prompt: String, attachments: [MessageAttachment], config: MLXGenerationConfig) async throws -> String {
        var result = ""
        for try await chunk in stream(prompt: prompt, attachments: attachments, config: config) {
            result += chunk
        }
        return result
    }

    func stream(prompt: String, attachments: [MessageAttachment], config: MLXGenerationConfig) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard let container = loadedContainer else {
                continuation.finish(throwing: AppError.inferenceEngineUnavailable)
                return
            }

            generationTask = Task {
                do {
                    let mediaImages = attachments.compactMap { attachment -> UserInput.Image? in
                        guard attachment.kind == .image else { return nil }
                        return .url(URL(fileURLWithPath: attachment.localFilePath))
                    }
                    let documentContext = attachments
                        .filter { $0.kind == .document }
                        .compactMap { attachment -> String? in
                            guard let text = attachment.extractedText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                                return nil
                            }
                            return "[Document: \(attachment.fileName)]\n\(text)"
                        }
                        .joined(separator: "\n\n")
                    let promptWithDocuments: String = {
                        guard !documentContext.isEmpty else { return prompt }
                        return """
                        \(prompt)

                        --- Attached Documents ---
                        \(documentContext)
                        """
                    }()
                    let userInput = UserInput(prompt: promptWithDocuments, images: mediaImages)

                    let stream = try await container.perform(nonSendable: userInput) { context, input in
                        let input = try await context.processor.prepare(input: input)
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
                Task { @MainActor [weak self] in
                    self?.generationTask?.cancel()
                    self?.generationTask = nil
                }
            }
        }
    }

    func stopGeneration() async {
        generationTask?.cancel()
        generationTask = nil
    }

    private func modelConfiguration(for modelID: String) -> ModelConfiguration {
        ModelConfiguration(id: resolvedModelID(for: modelID))
    }

    private func resolvedModelID(for modelID: String) -> String {
        switch modelID {
        case "qwen3_5-0_8b-8bit":
            return "mlx-community/Qwen3.5-0.8B-8bit"
        case "qwen3_5-2b-6bit":
            return "mlx-community/Qwen3.5-2B-6bit"
        default:
            return "mlx-community/Qwen3.5-0.8B-8bit"
        }
    }
}
