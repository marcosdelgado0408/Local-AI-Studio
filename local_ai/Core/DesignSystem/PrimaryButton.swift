import UIKit

final class PrimaryButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureStyle()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func configureStyle() {
        backgroundColor = AppColor.accent
        setTitleColor(.white, for: .normal)
        titleLabel?.font = AppTypography.button
        layer.cornerRadius = AppCornerRadius.md
        contentEdgeInsets = UIEdgeInsets(top: AppSpacing.sm, left: AppSpacing.md, bottom: AppSpacing.sm, right: AppSpacing.md)
    }
}
