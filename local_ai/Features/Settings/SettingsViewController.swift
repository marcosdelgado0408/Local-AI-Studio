import UIKit

final class SettingsViewController: UIViewController {
    private let viewModel: SettingsViewModel

    private let gradientLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let storageUsedLabel = UILabel()
    private let storageProgressView = UIProgressView(progressViewStyle: .default)
    private let storageCachedLabel = UILabel()
    private let storageModelsLabel = UILabel()

    private let temperatureSlider = UISlider()
    private let topPSlider = UISlider()
    private let maxTokensSlider = UISlider()
    private let contextSlider = UISlider()

    private let temperatureValue = UILabel()
    private let topPValue = UILabel()
    private let maxTokensValue = UILabel()
    private let contextValue = UILabel()
    private let modelScopeLabel = UILabel()

    private var currentConfig: GenerationConfig = .default
    private var currentStorageBytes: Int64 = 0

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureLayout()
        bindViewModel()
        viewModel.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel.load()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func configureBackground() {
        view.backgroundColor = UIColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1)
        gradientLayer.colors = [
            UIColor(red: 0.04, green: 0.08, blue: 0.20, alpha: 1).cgColor,
            UIColor(red: 0.02, green: 0.03, blue: 0.10, alpha: 1).cgColor,
            UIColor(red: 0.01, green: 0.02, blue: 0.06, alpha: 1).cgColor,
        ]
        gradientLayer.locations = [0, 0.45, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
        ])

        stackView.addArrangedSubview(makeHeader())
        stackView.addArrangedSubview(makeSectionTitle("Storage Status"))
        stackView.addArrangedSubview(makeStorageCard())
        stackView.addArrangedSubview(makeSectionTitle("Generation Parameters"))
        stackView.addArrangedSubview(makeGenerationCard())
        stackView.addArrangedSubview(makeSectionTitle("General"))
        stackView.addArrangedSubview(makeGeneralCard())
        stackView.addArrangedSubview(makeFooter())
    }

    private func makeHeader() -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = "Settings"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white

        let subtitleLabel = UILabel()
        subtitleLabel.text = "DataStore Configuration"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        subtitleLabel.numberOfLines = 0
        modelScopeLabel.font = subtitleLabel.font
        modelScopeLabel.textColor = subtitleLabel.textColor
        modelScopeLabel.numberOfLines = 2
        modelScopeLabel.text = "No active model selected"

        let statusDot = UIView()
        statusDot.backgroundColor = UIColor(red: 0.22, green: 0.83, blue: 0.59, alpha: 1)
        statusDot.layer.cornerRadius = 7
        statusDot.layer.shadowColor = statusDot.backgroundColor?.cgColor
        statusDot.layer.shadowOpacity = 0.6
        statusDot.layer.shadowRadius = 10
        statusDot.layer.shadowOffset = .zero
        statusDot.translatesAutoresizingMaskIntoConstraints = false

        let statusHalo = UIView()
        statusHalo.backgroundColor = UIColor(red: 0.15, green: 0.32, blue: 0.72, alpha: 0.5)
        statusHalo.layer.cornerRadius = 22
        statusHalo.translatesAutoresizingMaskIntoConstraints = false
        statusHalo.addSubview(statusDot)

        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, modelScopeLabel])
        labels.axis = .vertical
        labels.spacing = 3
        labels.translatesAutoresizingMaskIntoConstraints = false

        container.addSubviews(labels, statusHalo)
        NSLayoutConstraint.activate([
            labels.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labels.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            labels.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),

            statusHalo.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            statusHalo.centerYAnchor.constraint(equalTo: labels.centerYAnchor),
            statusHalo.widthAnchor.constraint(equalToConstant: 44),
            statusHalo.heightAnchor.constraint(equalToConstant: 44),

            statusDot.centerXAnchor.constraint(equalTo: statusHalo.centerXAnchor),
            statusDot.centerYAnchor.constraint(equalTo: statusHalo.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 14),
            statusDot.heightAnchor.constraint(equalToConstant: 14),
        ])
        return container
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        return label
    }

    private func makeStorageCard() -> UIView {
        let card = cardView()

        let title = UILabel()
        title.text = "Device Storage"
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.textColor = .white

        storageUsedLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        storageUsedLabel.textColor = .white
        storageUsedLabel.textAlignment = .right

        let topRow = UIStackView(arrangedSubviews: [title, storageUsedLabel])
        topRow.axis = .horizontal

        storageProgressView.trackTintColor = UIColor.white.withAlphaComponent(0.12)
        storageProgressView.progressTintColor = UIColor(red: 0.27, green: 0.53, blue: 1, alpha: 1)
        storageProgressView.layer.cornerRadius = 4
        storageProgressView.clipsToBounds = true

        let cachedCard = miniStatCard(title: "CACHED", valueLabel: storageCachedLabel)
        let modelsCard = miniStatCard(title: "MODELS", valueLabel: storageModelsLabel)
        let stats = UIStackView(arrangedSubviews: [cachedCard, modelsCard])
        stats.axis = .horizontal
        stats.spacing = 10
        stats.distribution = .fillEqually

        let content = UIStackView(arrangedSubviews: [topRow, storageProgressView, stats])
        content.axis = .vertical
        content.spacing = 14
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            storageProgressView.heightAnchor.constraint(equalToConstant: 8),
        ])
        return card
    }

    private func miniStatCard(title: String, valueLabel: UILabel) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.05, green: 0.09, blue: 0.23, alpha: 0.78)
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 0.33, green: 0.48, blue: 0.95, alpha: 0.16).cgColor

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.62)

        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = UIColor.white.withAlphaComponent(0.95)

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
        return card
    }

    private func makeGenerationCard() -> UIView {
        let card = cardView()

        let sliders = UIStackView(arrangedSubviews: [
            parameterRow(
                title: "Temperature",
                slider: temperatureSlider,
                value: temperatureValue,
                min: 0,
                max: 1.5,
                description: "Controls randomness: Lowering results in less random completions."
            ),
            parameterRow(
                title: "Top P",
                slider: topPSlider,
                value: topPValue,
                min: 0.1,
                max: 1,
                description: "Nucleus sampling: The model considers the tokens with top_p probability mass."
            ),
            parameterRow(
                title: "Max Tokens",
                slider: maxTokensSlider,
                value: maxTokensValue,
                min: 64,
                max: 4096,
                description: "Maximum number of tokens to generate per request."
            ),
            parameterRow(
                title: "Context Length",
                slider: contextSlider,
                value: contextValue,
                min: 512,
                max: 16384,
                description: "Maximum context window for each generation session."
            ),
        ])
        sliders.axis = .vertical
        sliders.spacing = 0
        sliders.translatesAutoresizingMaskIntoConstraints = false

        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset to Defaults", for: .normal)
        resetButton.setTitleColor(UIColor(red: 0.14, green: 0.67, blue: 1, alpha: 1), for: .normal)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        resetButton.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        resetButton.layer.cornerRadius = 12
        resetButton.layer.borderWidth = 1
        resetButton.layer.borderColor = UIColor(red: 0.34, green: 0.49, blue: 0.95, alpha: 0.35).cgColor
        resetButton.addTarget(self, action: #selector(didTapResetGeneration), for: .touchUpInside)
        resetButton.translatesAutoresizingMaskIntoConstraints = false

        card.addSubviews(sliders, resetButton)

        NSLayoutConstraint.activate([
            sliders.topAnchor.constraint(equalTo: card.topAnchor),
            sliders.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            sliders.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            sliders.bottomAnchor.constraint(equalTo: resetButton.topAnchor, constant: -10),

            resetButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            resetButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            resetButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            resetButton.heightAnchor.constraint(equalToConstant: 38),
        ])
        return card
    }

    private func parameterRow(
        title: String,
        slider: UISlider,
        value: UILabel,
        min: Float,
        max: Float,
        description: String
    ) -> UIView {
        let row = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .white

        value.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        value.textColor = UIColor(red: 0.14, green: 0.67, blue: 1, alpha: 1)
        value.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        value.layer.cornerRadius = 8
        value.layer.masksToBounds = true
        value.textAlignment = .center
        value.setContentHuggingPriority(.required, for: .horizontal)
        value.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true

        let top = UIStackView(arrangedSubviews: [titleLabel, value])
        top.axis = .horizontal
        top.alignment = .center

        slider.minimumValue = min
        slider.maximumValue = max
        slider.minimumTrackTintColor = UIColor(red: 0.35, green: 0.48, blue: 1, alpha: 1)
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.16)
        slider.thumbTintColor = .white
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderCommit), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        let body = UILabel()
        body.text = description
        body.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        body.textColor = UIColor.white.withAlphaComponent(0.5)
        body.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [top, slider, body])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(stack)

        let divider = UIView()
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        divider.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(divider)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: row.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -14),
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            divider.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        return row
    }

    private func makeGeneralCard() -> UIView {
        let card = cardView()

        let button = UIButton(type: .system)
        button.setTitle("Clear Chat History", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.60, green: 0.14, blue: 0.23, alpha: 0.48)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.94, green: 0.35, blue: 0.43, alpha: 0.44).cgColor
        button.addTarget(self, action: #selector(didTapClearHistory), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            button.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
        return card
    }

    private func makeFooter() -> UIView {
        let container = UIView()
        let title = UILabel()
        title.text = "DATASTORE SNAPSHOT"
        title.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        title.textColor = UIColor.white.withAlphaComponent(0.46)

        let subtitle = UILabel()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        subtitle.text = "Build v\(version) (Liquid Glass Edition)"
        subtitle.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.4)

        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])
        return container
    }

    private func cardView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.05, green: 0.09, blue: 0.24, alpha: 0.86)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 0.34, green: 0.49, blue: 0.95, alpha: 0.18).cgColor
        view.layer.shadowColor = UIColor(red: 0.10, green: 0.35, blue: 0.95, alpha: 1).cgColor
        view.layer.shadowOpacity = 0.10
        view.layer.shadowRadius = 12
        view.layer.shadowOffset = CGSize(width: 0, height: 7)
        return view
    }

    private func bindViewModel() {
        viewModel.onConfigUpdated = { [weak self] config in
            self?.currentConfig = config
            self?.applyConfigToUI(config)
        }

        viewModel.onActiveModelUpdated = { [weak self] modelText in
            self?.modelScopeLabel.text = modelText
        }

        viewModel.onStorageUpdated = { [weak self] text in
            self?.updateStorageUI(from: self?.currentStorageBytes ?? 0, fallbackText: text)
        }

        viewModel.onStorageBytesUpdated = { [weak self] usedBytes in
            self?.currentStorageBytes = usedBytes
            self?.updateStorageUI(from: usedBytes, fallbackText: nil)
        }

        viewModel.onError = { [weak self] message in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func applyConfigToUI(_ config: GenerationConfig) {
        temperatureSlider.setValue(Float(config.temperature), animated: false)
        topPSlider.setValue(Float(config.topP), animated: false)
        maxTokensSlider.setValue(Float(config.maxTokens), animated: false)
        contextSlider.setValue(Float(config.contextLength), animated: false)
        updateValueLabels()
    }

    private func updateStorageUI(from usedBytes: Int64, fallbackText: String?) {
        let total = totalDiskBytes()
        let usedText = fallbackText ?? ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file)
        let totalText = ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
        storageUsedLabel.text = "\(usedText) / \(totalText)"

        let ratio = total > 0 ? min(1, max(0, Double(usedBytes) / Double(total))) : 0
        storageProgressView.progress = Float(ratio)
        storageCachedLabel.text = usedText
        storageModelsLabel.text = "\(Int(ratio * 100))%"
    }

    private func totalDiskBytes() -> Int64 {
        let path = NSHomeDirectory()
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path),
              let size = attrs[.systemSize] as? NSNumber else {
            return 256_000_000_000
        }
        return size.int64Value
    }

    @objc
    private func sliderValueChanged() {
        updateValueLabels()
    }

    @objc
    private func sliderCommit() {
        let config = GenerationConfig(
            temperature: Double(temperatureSlider.value),
            topP: Double(topPSlider.value),
            maxTokens: Int(maxTokensSlider.value.rounded()),
            contextLength: Int(contextSlider.value.rounded())
        )
        currentConfig = config
        viewModel.save(config: config)
    }

    private func updateValueLabels() {
        temperatureValue.text = String(format: " %.2f ", temperatureSlider.value)
        topPValue.text = String(format: " %.2f ", topPSlider.value)
        maxTokensValue.text = " \(Int(maxTokensSlider.value.rounded())) "
        contextValue.text = " \(Int(contextSlider.value.rounded())) "
    }

    @objc
    private func didTapClearHistory() {
        let alert = UIAlertController(
            title: "Clear chat history?",
            message: "This will permanently delete all chats and messages from all sessions.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive, handler: { [weak self] _ in
            self?.viewModel.clearChatHistory()
        }))
        present(alert, animated: true)
    }

    @objc
    private func didTapResetGeneration() {
        let defaults = GenerationConfig.default
        currentConfig = defaults
        applyConfigToUI(defaults)
        viewModel.resetToDefaults()
    }
}
