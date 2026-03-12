import UIKit

final class DownloadTaskTableViewCell: UITableViewCell {
    static let reuseID = "DownloadTaskTableViewCell"

    var onPauseResume: (() -> Void)?
    var onCancel: (() -> Void)?

    private let titleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let stateLabel = UILabel()
    private let pauseResumeButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func configureUI() {
        selectionStyle = .none

        titleLabel.font = AppTypography.bodyMedium
        stateLabel.font = AppTypography.caption
        stateLabel.textColor = AppColor.textSecondary

        pauseResumeButton.addTarget(self, action: #selector(didTapPauseResume), for: .touchUpInside)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(AppColor.destructive, for: .normal)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [pauseResumeButton, cancelButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = AppSpacing.sm

        let stack = UIStackView(arrangedSubviews: [titleLabel, progressView, stateLabel, buttonRow])
        stack.axis = .vertical
        stack.spacing = AppSpacing.xs
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppSpacing.sm),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppSpacing.md),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppSpacing.md),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppSpacing.sm)
        ])
    }

    func configure(with task: DownloadTaskInfo) {
        titleLabel.text = task.modelName
        progressView.progress = Float(task.progress)
        stateLabel.text = "\(task.state.rawValue.capitalized) • \(Int(task.progress * 100))%"

        pauseResumeButton.setTitle(task.state == .paused ? "Resume" : "Pause", for: .normal)
        pauseResumeButton.isEnabled = task.state == .downloading || task.state == .paused
        cancelButton.isEnabled = task.state == .queued || task.state == .downloading || task.state == .paused
    }

    @objc
    private func didTapPauseResume() {
        onPauseResume?()
    }

    @objc
    private func didTapCancel() {
        onCancel?()
    }
}
