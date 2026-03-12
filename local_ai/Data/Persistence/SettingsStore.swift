import Foundation

final class SettingsStore {
    private enum Keys {
        static let generationConfig = "settings.generationConfig"
        static let generationConfigByModel = "settings.generationConfigByModel"
        static let onboardingCompleted = "settings.onboardingCompleted"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadGenerationConfig(modelID: String?) -> GenerationConfig {
        if let modelID,
           let config = loadConfigByModel()[modelID] {
            return config
        }

        guard
            let data = userDefaults.data(forKey: Keys.generationConfig),
            let config = try? JSONDecoder().decode(GenerationConfig.self, from: data)
        else {
            return .default
        }
        return config
    }

    func saveGenerationConfig(_ config: GenerationConfig, modelID: String?) throws {
        if let modelID {
            var byModel = loadConfigByModel()
            byModel[modelID] = config
            let data = try JSONEncoder().encode(byModel)
            userDefaults.set(data, forKey: Keys.generationConfigByModel)
            return
        }

        let fallbackData = try JSONEncoder().encode(config)
        userDefaults.set(fallbackData, forKey: Keys.generationConfig)
    }

    func hasCompletedOnboarding() -> Bool {
        userDefaults.bool(forKey: Keys.onboardingCompleted)
    }

    func setCompletedOnboarding(_ completed: Bool) {
        userDefaults.set(completed, forKey: Keys.onboardingCompleted)
    }

    private func loadConfigByModel() -> [String: GenerationConfig] {
        guard
            let data = userDefaults.data(forKey: Keys.generationConfigByModel),
            let map = try? JSONDecoder().decode([String: GenerationConfig].self, from: data)
        else {
            return [:]
        }
        return map
    }
}
