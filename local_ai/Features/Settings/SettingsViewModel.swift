import Foundation

@MainActor
final class SettingsViewModel {
    private let settingsRepository: SettingsRepository
    private let chatRepository: ChatRepository
    private let updateGenerationSettingsUseCase: UpdateGenerationSettingsUseCase
    private let storageInfoProvider: StorageInfoProviding

    private(set) var generationConfig: GenerationConfig = .default {
        didSet { onConfigUpdated?(generationConfig) }
    }

    private(set) var storageText: String = "" {
        didSet { onStorageUpdated?(storageText) }
    }

    private(set) var storageUsedBytes: Int64 = 0 {
        didSet { onStorageBytesUpdated?(storageUsedBytes) }
    }

    var onConfigUpdated: ((GenerationConfig) -> Void)?
    var onStorageUpdated: ((String) -> Void)?
    var onStorageBytesUpdated: ((Int64) -> Void)?
    var onError: ((String) -> Void)?

    init(
        settingsRepository: SettingsRepository,
        chatRepository: ChatRepository,
        updateGenerationSettingsUseCase: UpdateGenerationSettingsUseCase,
        storageInfoProvider: StorageInfoProviding
    ) {
        self.settingsRepository = settingsRepository
        self.chatRepository = chatRepository
        self.updateGenerationSettingsUseCase = updateGenerationSettingsUseCase
        self.storageInfoProvider = storageInfoProvider
    }

    func load() {
        Task {
            generationConfig = await settingsRepository.loadGenerationConfig()
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
                try await updateGenerationSettingsUseCase.execute(config)
                generationConfig = config
            } catch {
                onError?("Failed to save settings.")
            }
        }
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
