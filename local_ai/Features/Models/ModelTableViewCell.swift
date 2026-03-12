import UIKit

final class ModelTableViewCell: UITableViewCell {
    static let reuseID = "ModelTableViewCell"

    var onPrimaryAction: (() -> Void)?
    var onDeleteAction: (() -> Void)?
    var onInfoAction: (() -> Void)?

    private let cardView = UIView()
    private let modelIconView = UIImageView()
    private let nameLabel = UILabel()
    private let statusBadge = UILabel()
    private let metadataChip = UILabel()
    private let quantChip = UILabel()
    private let infoButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let progressPercentLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let primaryButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = UIColor(red: 0.11, green: 0.12, blue: 0.20, alpha: 0.84)
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor

        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 0

        modelIconView.contentMode = .scaleAspectFit
        modelIconView.translatesAutoresizingMaskIntoConstraints = false
        modelIconView.tintColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1)
        modelIconView.isHidden = true

        statusBadge.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        statusBadge.textAlignment = .center
        statusBadge.textColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1)
        statusBadge.backgroundColor = UIColor(red: 0.13, green: 0.28, blue: 0.47, alpha: 0.5)
        statusBadge.layer.cornerRadius = 11
        statusBadge.layer.masksToBounds = true

        configureChip(metadataChip)
        configureChip(quantChip)

        let infoImage = UIImage(systemName: "info.circle")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold))
        infoButton.setImage(infoImage, for: .normal)
        infoButton.tintColor = UIColor.white.withAlphaComponent(0.78)
        infoButton.contentHorizontalAlignment = .center
        infoButton.contentVerticalAlignment = .center
        infoButton.setContentHuggingPriority(.required, for: .horizontal)
        infoButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        infoButton.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)

        statusLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.7)

        progressPercentLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        progressPercentLabel.textColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1)
        progressPercentLabel.textAlignment = .right

        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.12)
        progressView.progressTintColor = UIColor(red: 0.13, green: 0.78, blue: 1, alpha: 1)
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true

        configurePrimaryButton()
        configureDeleteButton()

        let topRightStack = UIStackView(arrangedSubviews: [infoButton, statusBadge])
        topRightStack.axis = .horizontal
        topRightStack.spacing = 8
        topRightStack.alignment = .center

        let titleLeftStack = UIStackView(arrangedSubviews: [modelIconView, nameLabel])
        titleLeftStack.axis = .horizontal
        titleLeftStack.spacing = 8
        titleLeftStack.alignment = .center

        let titleRow = UIStackView(arrangedSubviews: [titleLeftStack, topRightStack])
        titleRow.axis = .horizontal
        titleRow.alignment = .top

        let chipsRow = UIStackView(arrangedSubviews: [metadataChip, quantChip])
        chipsRow.axis = .horizontal
        chipsRow.spacing = 8
        chipsRow.alignment = .leading

        let progressHeader = UIStackView(arrangedSubviews: [statusLabel, progressPercentLabel])
        progressHeader.axis = .horizontal

        let actionRow = UIStackView(arrangedSubviews: [primaryButton, deleteButton])
        actionRow.axis = .horizontal
        actionRow.spacing = 12
        actionRow.distribution = .fillEqually

        let contentStack = UIStackView(arrangedSubviews: [titleRow, chipsRow, progressHeader, progressView, actionRow])
        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18),

            metadataChip.heightAnchor.constraint(equalToConstant: 28),
            quantChip.heightAnchor.constraint(equalToConstant: 28),
            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 74),
            statusBadge.heightAnchor.constraint(equalToConstant: 22),
            modelIconView.widthAnchor.constraint(equalToConstant: 20),
            modelIconView.heightAnchor.constraint(equalToConstant: 20),
            infoButton.widthAnchor.constraint(equalToConstant: 26),
            infoButton.heightAnchor.constraint(equalToConstant: 26),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            primaryButton.heightAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func configureChip(_ label: UILabel) {
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.66)
        label.textAlignment = .center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        label.layer.cornerRadius = 15
        label.layer.masksToBounds = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 78).isActive = true
    }

    private func configurePrimaryButton() {
        primaryButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        primaryButton.layer.cornerRadius = 15
        primaryButton.layer.borderWidth = 1
        primaryButton.addTarget(self, action: #selector(didTapPrimary), for: .touchUpInside)
    }

    private func configureDeleteButton() {
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        deleteButton.setTitleColor(UIColor(red: 0.91, green: 0.40, blue: 0.42, alpha: 1), for: .normal)
        deleteButton.backgroundColor = UIColor(red: 0.37, green: 0.18, blue: 0.24, alpha: 0.66)
        deleteButton.layer.cornerRadius = 15
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor(red: 0.91, green: 0.40, blue: 0.42, alpha: 0.36).cgColor
        deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)
    }

    func configure(with model: LocalModel) {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let size = formatter.string(fromByteCount: model.estimatedSizeInBytes)

        primaryButton.isHidden = false
        deleteButton.isHidden = false

        nameLabel.text = model.displayName
        configureModelIcon(for: model)
        metadataChip.text = "  \(size)  "
        quantChip.text = "  \(quantizationTag(from: model.displayName))  "
        progressView.progress = Float(model.downloadProgress ?? 0)
        progressPercentLabel.text = "\(Int((model.downloadProgress ?? 0) * 100))%"

        let isActive = model.status == .active
        cardView.layer.shadowColor = UIColor(red: 0.10, green: 0.57, blue: 1.0, alpha: 1).cgColor
        cardView.layer.shadowOpacity = isActive ? 0.44 : 0
        cardView.layer.shadowRadius = isActive ? 16 : 0
        cardView.layer.shadowOffset = .zero
        cardView.layer.borderColor = (isActive
            ? UIColor(red: 0.10, green: 0.57, blue: 1.0, alpha: 0.8)
            : UIColor.white.withAlphaComponent(0.15)).cgColor

        switch model.status {
        case .notDownloaded:
            statusBadge.text = " AVAILABLE "
            statusLabel.text = "Available in cloud"
            progressView.isHidden = true
            progressPercentLabel.isHidden = true
            primaryButton.setTitle("Download", for: .normal)
            primaryButton.isEnabled = true
            primaryButton.setTitleColor(.white, for: .normal)
            primaryButton.backgroundColor = UIColor.white.withAlphaComponent(0.14)
            primaryButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            deleteButton.isHidden = true
        case .downloading:
            statusBadge.text = " DOWNLOADING "
            statusLabel.text = "Downloading..."
            progressView.isHidden = false
            progressPercentLabel.isHidden = false
            primaryButton.setTitle("Downloading", for: .normal)
            primaryButton.isEnabled = false
            primaryButton.setTitleColor(UIColor.white.withAlphaComponent(0.64), for: .normal)
            primaryButton.backgroundColor = UIColor.white.withAlphaComponent(0.14)
            primaryButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            deleteButton.isHidden = true
        case .installed:
            statusBadge.text = " INSTALLED "
            statusLabel.text = "Installed locally"
            progressView.isHidden = true
            progressPercentLabel.isHidden = true
            primaryButton.setTitle("Activate", for: .normal)
            primaryButton.isEnabled = true
            primaryButton.setTitleColor(UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1), for: .normal)
            primaryButton.backgroundColor = UIColor(red: 0.18, green: 0.28, blue: 0.46, alpha: 0.66)
            primaryButton.layer.borderColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 0.6).cgColor
            deleteButton.isHidden = false
        case .active:
            statusBadge.text = " ACTIVE "
            statusLabel.text = "Active engine"
            progressView.isHidden = true
            progressPercentLabel.isHidden = true
            primaryButton.isHidden = true
            deleteButton.isHidden = false
        }
    }

    private func quantizationTag(from name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("4-bit") || lower.contains("4bit") {
            return "Q4_K_M"
        }
        if lower.contains("6-bit") || lower.contains("6bit") {
            return "Q6_K"
        }
        if lower.contains("8-bit") || lower.contains("8bit") {
            return "Q8_0"
        }
        return "F16"
    }

    private func configureModelIcon(for model: LocalModel) {
        let isQwen = model.displayName.lowercased().contains("qwen")
            || model.id.lowercased().contains("qwen")

        if isQwen, let qwenIcon = UIImage(named: "qwen_icon") {
            modelIconView.image = qwenIcon.withRenderingMode(.alwaysOriginal)
            modelIconView.isHidden = false
        } else {
            modelIconView.image = nil
            modelIconView.isHidden = true
        }
    }

    @objc
    private func didTapPrimary() {
        onPrimaryAction?()
    }

    @objc
    private func didTapDelete() {
        onDeleteAction?()
    }

    @objc
    private func didTapInfo() {
        onInfoAction?()
    }
}
