import Foundation

final class ModelMetadataStore {
    private enum Keys {
        static let activeModelID = "models.activeModelID"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadActiveModelID() -> String? {
        userDefaults.string(forKey: Keys.activeModelID)
    }

    func setActiveModelID(_ id: String?) {
        userDefaults.set(id, forKey: Keys.activeModelID)
    }
}
