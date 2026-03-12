import UIKit

enum AppColor {
    static let background = UIColor.systemBackground
    static let secondaryBackground = UIColor.secondarySystemBackground
    static let tertiaryBackground = UIColor.tertiarySystemBackground
    static let textPrimary = UIColor.label
    static let textSecondary = UIColor.secondaryLabel
    static let separator = UIColor.separator
    static let accent = UIColor.systemBlue
    static let success = UIColor.systemGreen
    static let warning = UIColor.systemOrange
    static let destructive = UIColor.systemRed
}

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum AppCornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

enum AppTypography {
    static let title = UIFont.systemFont(ofSize: 24, weight: .bold)
    static let sectionTitle = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let body = UIFont.systemFont(ofSize: 16, weight: .regular)
    static let bodyMedium = UIFont.systemFont(ofSize: 16, weight: .medium)
    static let caption = UIFont.systemFont(ofSize: 13, weight: .regular)
    static let button = UIFont.systemFont(ofSize: 16, weight: .semibold)
}
