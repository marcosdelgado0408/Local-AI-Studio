import Foundation

@MainActor
final class SettingsViewModel {
    private let modelRepository: ModelRepository
    private let settingsRepository: SettingsRepository
    private let chatRepository: ChatRepository
    private let updateGenerationSettingsUseCase: UpdateGenerationSettingsUseCase
    private let storageInfoProvider: StorageInfoProviding
    private var activeModelID: String?

    private(set) var generationConfig: GenerationConfig = .default {
        didSet { onConfigUpdated?(generationConfig) }
    }
    private(set) var activeModelText: String = "No active model selected" {
        didSet { onActiveModelUpdated?(activeModelText) }
    }

    private(set) var storageText: String = "" {
        didSet { onStorageUpdated?(storageText) }
    }

    private(set) var storageUsedBytes: Int64 = 0 {
        didSet { onStorageBytesUpdated?(storageUsedBytes) }
    }

    var onConfigUpdated: ((GenerationConfig) -> Void)?
    var onActiveModelUpdated: ((String) -> Void)?
    var onStorageUpdated: ((String) -> Void)?
    var onStorageBytesUpdated: ((Int64) -> Void)?
    var onError: ((String) -> Void)?

    init(
        modelRepository: ModelRepository,
        settingsRepository: SettingsRepository,
        chatRepository: ChatRepository,
        updateGenerationSettingsUseCase: UpdateGenerationSettingsUseCase,
        storageInfoProvider: StorageInfoProviding
    ) {
        self.modelRepository = modelRepository
        self.settingsRepository = settingsRepository
        self.chatRepository = chatRepository
        self.updateGenerationSettingsUseCase = updateGenerationSettingsUseCase
        self.storageInfoProvider = storageInfoProvider
    }

    func load() {
        Task {
            let resolvedModel: LocalModel?
            do {
                resolvedModel = try await modelRepository.activeModel()
            } catch {
                resolvedModel = nil
            }
            activeModelID = resolvedModel?.id
            if let modelName = resolvedModel?.displayName {
                activeModelText = "Active model: \(modelName)"
            } else {
                activeModelText = "No active model selected"
            }
            generationConfig = await settingsRepository.loadGenerationConfig(modelID: activeModelID)
            let used = storageInfoProvider.currentDiskUsageInBytes()
            storageUsedBytes = used
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            storageText = formatter.string(fromByteCount: used)
        }
    }

    func save(config: GenerationConfig) {
        Task {
            do {
                try await updateGenerationSettingsUseCase.execute(config, modelID: activeModelID)
                generationConfig = config
            } catch {
                onError?("Failed to save settings.")
            }
        }
    }

    func resetToDefaults() {
        save(config: .default)
    }

    func clearChatHistory() {
        Task {
            do {
                try await chatRepository.clearChatHistory()
            } catch {
                onError?("Failed to clear chat history.")
            }
        }
    }
}
