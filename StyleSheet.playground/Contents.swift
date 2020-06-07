import UIKit
import PlaygroundSupport

// MARK: - Foundation
enum StyleSheet {
    enum Mixins {}
}

precedencegroup CompositionPrecedence {
    associativity: left
    higherThan: AssignmentPrecedence
}

infix operator >>>: CompositionPrecedence

func >>> <T: UIView>(
    lhs: @escaping (T) -> Void,
    rhs: @escaping (T) -> Void
) -> (T) -> Void {
    return {
        lhs($0)
        rhs($0)
    }
}

// MARK: - Mixins

extension StyleSheet.Mixins {
    static func border<T: UIView>(
        width: CGFloat? = nil,
        color: UIColor? = nil
    ) -> (T) -> Void {
        return { view in
            width.map { view.layer.borderWidth = $0 }
            color.map { view.layer.borderColor = $0.cgColor }
        }
    }

    static func cornerRadius<T: UIView>(value: CGFloat) -> (T) -> Void {
        return { view in
            view.layer.cornerRadius = value
        }
    }

    static func base<T: UIView>(
        backgroundColor: UIColor? = nil,
        clipsToBounds: Bool? = nil
    ) -> (T) -> Void {
        return { view in
            backgroundColor.map { view.backgroundColor = $0 }
            clipsToBounds.map { view.clipsToBounds = $0}
        }
    }

    static func button<T: UIButton>(
        titleColor: UIColor,
        for state: UIControl.State
    ) -> (T) -> Void {
        return { button in
            button.setTitleColor(titleColor, for: state)
        }
    }
}

// MARK: - Helper

protocol Styleable {
    associatedtype StyledElement
    func withStyle(_ f: (StyledElement) -> Void) -> StyledElement
}

extension Styleable {
    func withStyle(_ f: (Self) -> Void) -> Self {
        f(self)
        return self
    }
}
extension UIView: Styleable {}

// MARK: - Button styles

extension StyleSheet {
    static let baseButtonStyle: (UIButton) -> Void =
        Mixins.base(backgroundColor: .white, clipsToBounds: true)
            >>> Mixins.border(width: 2, color: .black)
            >>> Mixins.cornerRadius(value: 8)
            >>> Mixins.button(titleColor: .black, for: .normal)
            >>> Mixins.button(titleColor: .gray, for: .highlighted)

    static let primaryButtonStyle: (UIButton) -> Void =
        baseButtonStyle
            >>> StyleSheet.Mixins.border(color: .black)


    static let secondaryButtonStyle: (UIButton) -> Void =
        baseButtonStyle
            >>> StyleSheet.Mixins.base(backgroundColor: .clear)
            >>> StyleSheet.Mixins.border(width: 0)
            >>> StyleSheet.Mixins.button(titleColor: .blue, for: .normal)

}

class CustomSwitch: UISwitch {
    var onStyle: (CustomSwitch) -> Void = StyleSheet.Mixins.border(width: 1) {
        didSet {
            changeStyle(self)
        }
    }
    var offStyle: (CustomSwitch) -> Void = StyleSheet.Mixins.border(width: 0) {
        didSet {
            changeStyle(self)
        }
    }

    init() {
        super.init(frame: .zero)
        addTarget(self, action: #selector(changeStyle(_:)), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func changeStyle(_ sender: CustomSwitch) {
        sender.isOn ? onStyle(self) : offStyle(self)
    }

}

class TestViewController: UIViewController {
    enum LocalStyles {
        static let switchButtonStyle: (CustomSwitch) -> Void = {
            $0.offStyle =
                StyleSheet.Mixins.border(width: 0)
                >>> StyleSheet.Mixins.base(backgroundColor: .gray)
            $0.onStyle = StyleSheet.Mixins.border(width: 1)
            >>> StyleSheet.Mixins.base(backgroundColor: .white)
        }
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        let primaryButton = UIButton().withStyle(StyleSheet.primaryButtonStyle)
        primaryButton.setTitle("Primary button", for: .normal)

        let secondaryButton = UIButton().withStyle(StyleSheet.secondaryButtonStyle)
        secondaryButton.setTitle("Secondary button", for: .normal)

        let customSwitch = CustomSwitch().withStyle(LocalStyles.switchButtonStyle)

        let container = UIStackView(arrangedSubviews: [primaryButton, secondaryButton, customSwitch])
        container.axis = .vertical
        container.spacing = 10
        container.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(container)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }
}

PlaygroundPage.current.liveView = TestViewController()
