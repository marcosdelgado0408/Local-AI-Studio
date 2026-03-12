import Foundation

final class SettingsRepositoryImpl: SettingsRepository {
    private let store: SettingsStore

    init(store: SettingsStore) {
        self.store = store
    }

    func loadGenerationConfig(modelID: String?) async -> GenerationConfig {
        store.loadGenerationConfig(modelID: modelID)
    }

    func updateGenerationConfig(_ config: GenerationConfig, modelID: String?) async throws {
        do {
            try store.saveGenerationConfig(config, modelID: modelID)
        } catch {
            throw AppError.persistenceFailure
        }
    }

    func hasCompletedOnboarding() async -> Bool {
        store.hasCompletedOnboarding()
    }

    func setCompletedOnboarding(_ completed: Bool) async {
        store.setCompletedOnboarding(completed)
    }
}
