import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var appCoordinator: AppCoordinator?
    private var dependencyContainer: AppDependencyContainer?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let dependencies = AppDependencyContainer()
        let coordinator = AppCoordinator(window: window, dependencies: dependencies)

        self.window = window
        self.dependencyContainer = dependencies
        self.appCoordinator = coordinator

        coordinator.start()
    }
}
