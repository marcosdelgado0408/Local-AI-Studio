import UIKit

final class AppDependencyContainer {
    private let settingsStore = SettingsStore()
    private let metadataStore = ModelMetadataStore()
    private let chatStore = ChatHistoryStore()
    private let modelStorage = ModelFileStorage()
    private let modelDownloadClient = ModelDownloadClient()
    private let downloadRepository = LocalDownloadRepository()

    private lazy var settingsRepository: SettingsRepository = SettingsRepositoryImpl(store: settingsStore)
    private lazy var modelRepository: ModelRepository = ModelRepositoryImpl(
        metadataStore: metadataStore,
        storage: modelStorage,
        downloadClient: modelDownloadClient,
        downloadRepository: downloadRepository
    )
    private lazy var chatRepository: ChatRepository = ChatRepositoryImpl(store: chatStore)
    private lazy var inferenceRepository: InferenceRepository = InferenceRepositoryImpl(
        engine: MLXInferenceEngine(),
        storage: modelStorage
    )

    func hasCompletedOnboarding() async -> Bool {
        await settingsRepository.hasCompletedOnboarding()
    }

    func setCompletedOnboarding(_ completed: Bool) async {
        await settingsRepository.setCompletedOnboarding(completed)
    }

    @MainActor
    func makeOnboardingViewController(onContinue: @escaping () -> Void) -> UIViewController {
        let viewModel = OnboardingViewModel(settingsRepository: settingsRepository)
        let viewController = OnboardingViewController(viewModel: viewModel)
        viewController.onContinue = onContinue
        return viewController
    }

    @MainActor
    func makeMainTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()

        let chatController = makeChatViewController()
        let modelsController = makeModelsViewController()
        let settingsController = makeSettingsViewController()

        let chatNav = UINavigationController(rootViewController: chatController)
        let modelsNav = UINavigationController(rootViewController: modelsController)
        let settingsNav = UINavigationController(rootViewController: settingsController)

        chatNav.tabBarItem = UITabBarItem(title: "Chat", image: UIImage(systemName: "message"), selectedImage: UIImage(systemName: "message.fill"))
        modelsNav.tabBarItem = UITabBarItem(title: "Models", image: UIImage(systemName: "cpu"), selectedImage: UIImage(systemName: "cpu.fill"))
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))

        tabBarController.viewControllers = [chatNav, modelsNav, settingsNav]
        return tabBarController
    }

    @MainActor
    private func makeChatViewController() -> UIViewController {
        let sendMessageUseCase = SendMessageUseCase(inferenceRepository: inferenceRepository)
        let streamResponseUseCase = StreamResponseUseCase(inferenceRepository: inferenceRepository)
        let loadChatHistoryUseCase = LoadChatHistoryUseCase(chatRepository: chatRepository)
        let saveMessageUseCase = SaveMessageUseCase(chatRepository: chatRepository)

        let viewModel = ChatViewModel(
            modelRepository: modelRepository,
            chatRepository: chatRepository,
            settingsRepository: settingsRepository,
            inferenceRepository: inferenceRepository,
            sendMessageUseCase: sendMessageUseCase,
            streamResponseUseCase: streamResponseUseCase,
            loadChatHistoryUseCase: loadChatHistoryUseCase,
            saveMessageUseCase: saveMessageUseCase
        )

        return ChatViewController(viewModel: viewModel)
    }

    @MainActor
    private func makeModelsViewController() -> UIViewController {
        let viewModel = ModelsViewModel(
            downloadRepository: downloadRepository,
            listAvailableModelsUseCase: ListAvailableModelsUseCase(repository: modelRepository),
            listInstalledModelsUseCase: ListInstalledModelsUseCase(repository: modelRepository),
            downloadModelUseCase: DownloadModelUseCase(repository: modelRepository),
            deleteModelUseCase: DeleteModelUseCase(repository: modelRepository),
            selectActiveModelUseCase: SelectActiveModelUseCase(repository: modelRepository)
        )

        return ModelsViewController(viewModel: viewModel)
    }

    @MainActor
    private func makeSettingsViewController() -> UIViewController {
        let viewModel = SettingsViewModel(
            modelRepository: modelRepository,
            settingsRepository: settingsRepository,
            chatRepository: chatRepository,
            updateGenerationSettingsUseCase: UpdateGenerationSettingsUseCase(repository: settingsRepository),
            storageInfoProvider: modelStorage
        )
        return SettingsViewController(viewModel: viewModel)
    }
}
