import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private let dependencies: AppDependencyContainer

    init(window: UIWindow, dependencies: AppDependencyContainer) {
        self.window = window
        self.dependencies = dependencies
    }

    func start() {
        Task { @MainActor in
            if await dependencies.hasCompletedOnboarding() {
                showMainInterface()
            } else {
                showOnboarding()
            }
        }
    }

    @MainActor
    private func showOnboarding() {
        let onboardingController = dependencies.makeOnboardingViewController { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.dependencies.setCompletedOnboarding(true)
                self.showMainInterface()
            }
        }

        let navigationController = UINavigationController(rootViewController: onboardingController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    @MainActor
    private func showMainInterface() {
        window.rootViewController = dependencies.makeMainTabBarController()
        window.makeKeyAndVisible()
    }
}
