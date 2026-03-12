import Foundation

final class SettingsStore {
    private enum Keys {
        static let generationConfig = "settings.generationConfig"
        static let onboardingCompleted = "settings.onboardingCompleted"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadGenerationConfig() -> GenerationConfig {
        guard
            let data = userDefaults.data(forKey: Keys.generationConfig),
            let config = try? JSONDecoder().decode(GenerationConfig.self, from: data)
        else {
            return .default
        }
        return config
    }

    func saveGenerationConfig(_ config: GenerationConfig) throws {
        let data = try JSONEncoder().encode(config)
        userDefaults.set(data, forKey: Keys.generationConfig)
    }

    func hasCompletedOnboarding() -> Bool {
        userDefaults.bool(forKey: Keys.onboardingCompleted)
    }

    func setCompletedOnboarding(_ completed: Bool) {
        userDefaults.set(completed, forKey: Keys.onboardingCompleted)
    }
}
