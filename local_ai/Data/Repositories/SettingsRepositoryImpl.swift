import Foundation

final class SettingsRepositoryImpl: SettingsRepository {
    private let store: SettingsStore

    init(store: SettingsStore) {
        self.store = store
    }

    func loadGenerationConfig() async -> GenerationConfig {
        store.loadGenerationConfig()
    }

    func updateGenerationConfig(_ config: GenerationConfig) async throws {
        do {
            try store.saveGenerationConfig(config)
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
