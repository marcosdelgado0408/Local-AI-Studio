import UIKit

final class CardContainerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.secondaryBackground
        layer.cornerRadius = AppCornerRadius.md
        layer.borderColor = AppColor.separator.cgColor
        layer.borderWidth = 1
    }

    required init?(coder: NSCoder) {
        return nil
    }
}
