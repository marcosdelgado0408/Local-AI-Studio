import UIKit

final class OnboardingViewController: UIViewController {
    private let viewModel: OnboardingViewModel
    private let gradientLayer = CAGradientLayer()

    var onContinue: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Run AI Locally"
        label.font = AppTypography.title
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Download and run supported models fully on-device. Your chats stay offline by default."
        label.font = AppTypography.body
        label.textColor = UIColor.white.withAlphaComponent(0.75)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let continueButton: PrimaryButton = {
        let button = PrimaryButton(type: .system)
        button.setTitle("Continue", for: .normal)
        return button
    }()

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        setupLayout()
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
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupLayout() {
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, continueButton])
        stack.axis = .vertical
        stack.spacing = AppSpacing.lg
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppSpacing.lg),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppSpacing.lg),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            continueButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc
    private func didTapContinue() {
        Task { @MainActor in
            await viewModel.completeOnboarding()
            onContinue?()
        }
    }
}
