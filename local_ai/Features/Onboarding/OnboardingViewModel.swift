import Foundation

@MainActor
final class OnboardingViewModel {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func completeOnboarding() async {
        await settingsRepository.setCompletedOnboarding(true)
    }
}
