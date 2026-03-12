import Foundation

struct UpdateGenerationSettingsUseCase {
    private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
    }

    func execute(_ config: GenerationConfig) async throws {
        try await repository.updateGenerationConfig(config)
    }
}
