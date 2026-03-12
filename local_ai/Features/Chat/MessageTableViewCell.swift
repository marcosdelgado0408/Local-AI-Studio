import UIKit

final class MessageTableViewCell: UITableViewCell {
    static let reuseID = "MessageTableViewCell"

    private let nameLabel = UILabel()
    private let avatarView = UIView()
    private let bubbleView = UIView()
    private let messageLabel = UILabel()

    private var assistantNameTop: NSLayoutConstraint?
    private var bubbleTopToName: NSLayoutConstraint?
    private var bubbleTopCompact: NSLayoutConstraint?
    private var assistantLeadingConstraint: NSLayoutConstraint?
    private var userTrailingConstraint: NSLayoutConstraint?
    private var userLeadingMinConstraint: NSLayoutConstraint?
    private var assistantTrailingMaxConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        configureUI()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func configureUI() {
        nameLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = UIColor(red: 0.72, green: 0.80, blue: 0.93, alpha: 0.95)

        avatarView.layer.cornerRadius = 16
        avatarView.layer.borderWidth = 1
        avatarView.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        avatarView.backgroundColor = UIColor(red: 0.40, green: 0.83, blue: 1.0, alpha: 1)

        bubbleView.layer.cornerRadius = 22
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor

        messageLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        messageLabel.numberOfLines = 0

        contentView.addSubviews(nameLabel, avatarView, bubbleView)
        bubbleView.addSubview(messageLabel)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        assistantNameTop = nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10)
        bubbleTopToName = bubbleView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6)
        bubbleTopCompact = bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6)

        assistantLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10)
        userTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14)
        userLeadingMinConstraint = bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 84)
        assistantTrailingMaxConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -64)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),
            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),

            nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 4),

            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.80),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 14),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -14),
        ])
    }

    func configure(message: Message, modelName: String) {
        assistantNameTop?.isActive = false
        bubbleTopToName?.isActive = false
        bubbleTopCompact?.isActive = false
        assistantLeadingConstraint?.isActive = false
        userTrailingConstraint?.isActive = false
        userLeadingMinConstraint?.isActive = false
        assistantTrailingMaxConstraint?.isActive = false

        if message.role == .user {
            nameLabel.isHidden = true
            avatarView.isHidden = true

            bubbleView.backgroundColor = UIColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 0.96)
            bubbleView.layer.borderColor = UIColor(red: 0.15, green: 0.45, blue: 0.95, alpha: 0.22).cgColor
            bubbleView.layer.shadowColor = UIColor(red: 0.10, green: 0.45, blue: 0.95, alpha: 1).cgColor
            bubbleView.layer.shadowOpacity = 0.18
            bubbleView.layer.shadowRadius = 16
            bubbleView.layer.shadowOffset = .zero

            messageLabel.attributedText = formattedMessage(
                message.content,
                color: UIColor.white.withAlphaComponent(0.95)
            )

            bubbleTopCompact?.isActive = true
            userTrailingConstraint?.isActive = true
            userLeadingMinConstraint?.isActive = true
        } else {
            nameLabel.isHidden = false
            avatarView.isHidden = false
            nameLabel.text = modelName == "No active model" ? "Liquid AI" : modelName

            bubbleView.backgroundColor = UIColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 0.92)
            bubbleView.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
            bubbleView.layer.shadowOpacity = 0

            messageLabel.attributedText = formattedMessage(
                message.content,
                color: UIColor.white.withAlphaComponent(0.90)
            )

            avatarView.backgroundColor = UIColor(red: 0.34, green: 0.83, blue: 1.0, alpha: 1)

            assistantNameTop?.isActive = true
            bubbleTopToName?.isActive = true
            assistantLeadingConstraint?.isActive = true
            assistantTrailingMaxConstraint?.isActive = true
        }
    }

    private func formattedMessage(_ rawText: String, color: UIColor) -> NSAttributedString {
        let baseFont = UIFont.systemFont(ofSize: 17, weight: .regular)
        let boldFont = UIFont.systemFont(ofSize: 17, weight: .semibold)

        let mutable = NSMutableAttributedString(
            string: rawText,
            attributes: [
                .font: baseFont,
                .foregroundColor: color,
            ]
        )

        // Lightweight markdown support for **bold** markers.
        let pattern = #"(?s)\*\*(.+?)\*\*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return mutable
        }

        let source = rawText as NSString
        let matches = regex.matches(in: rawText, range: NSRange(location: 0, length: source.length))
        for match in matches.reversed() {
            let innerRange = match.range(at: 1)
            guard innerRange.location != NSNotFound else { continue }
            let innerText = source.substring(with: innerRange)
            let replacement = NSAttributedString(
                string: innerText,
                attributes: [
                    .font: boldFont,
                    .foregroundColor: color,
                ]
            )
            mutable.replaceCharacters(in: match.range, with: replacement)
        }

        return mutable
    }
}
