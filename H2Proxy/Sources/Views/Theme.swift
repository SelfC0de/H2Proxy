import UIKit

enum Theme {
    // MARK: - Colors
    static let backgroundPrimary = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 1)
            : UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
    }

    static let backgroundCard = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 1)
            : UIColor.white
    }

    static let backgroundCardElevated = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.13, blue: 0.22, alpha: 1)
            : UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1)
    }

    static let accentBlue = UIColor(red: 0.0, green: 0.6, blue: 0.95, alpha: 1)
    static let accentCyan = UIColor(red: 0.0, green: 0.78, blue: 0.85, alpha: 1)
    static let accentGreen = UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1)
    static let accentRed = UIColor(red: 0.92, green: 0.26, blue: 0.28, alpha: 1)
    static let accentOrange = UIColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1)

    static let textPrimary = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.95, alpha: 1)
            : UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1)
    }

    static let textSecondary = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.55, alpha: 1)
            : UIColor(white: 0.45, alpha: 1)
    }

    static let textMuted = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.35, alpha: 1)
            : UIColor(white: 0.62, alpha: 1)
    }

    static let separator = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.06)
            : UIColor(white: 0.0, alpha: 0.06)
    }

    // MARK: - Fonts
    static func title(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .bold)
    }

    static func heading(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .semibold)
    }

    static func body(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .regular)
    }

    static func mono(_ size: CGFloat) -> UIFont {
        .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    static func caption(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .medium)
    }

    // MARK: - Card styling
    static func styleCard(_ view: UIView, elevated: Bool = false) {
        view.backgroundColor = elevated ? backgroundCardElevated : backgroundCard
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        if #available(iOS 13.0, *) {
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: 4)
            view.layer.shadowRadius = 12
            view.layer.shadowOpacity = UITraitCollection.current.userInterfaceStyle == .dark ? 0.4 : 0.08
        }
    }

    // MARK: - Gradient
    static func makeGradientLayer(colors: [UIColor], start: CGPoint = CGPoint(x: 0, y: 0), end: CGPoint = CGPoint(x: 1, y: 1)) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = colors.map { $0.cgColor }
        layer.startPoint = start
        layer.endPoint = end
        return layer
    }

    // MARK: - Animations
    static func springAnimate(_ duration: TimeInterval = 0.6, delay: TimeInterval = 0, damping: CGFloat = 0.75, velocity: CGFloat = 0.5, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: animations,
            completion: completion
        )
    }

    static func fadeIn(_ view: UIView, duration: TimeInterval = 0.35, delay: TimeInterval = 0) {
        view.alpha = 0
        view.transform = CGAffineTransform(translationX: 0, y: 12)
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: [.curveEaseOut],
            animations: {
                view.alpha = 1
                view.transform = .identity
            }
        )
    }
}
