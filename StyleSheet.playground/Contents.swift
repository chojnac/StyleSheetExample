import UIKit
import PlaygroundSupport

typealias Style<T: UIView> = (T) -> Void

// MARK: - Foundation
enum StyleSheet {
    enum Mixins {}
}

func concat<T: UIView>(_ styles: [Style<T>]) -> Style<T> {
    return { view in
        styles.forEach {
            $0(view)
        }
    }
}

// MARK: - Mixins

extension StyleSheet.Mixins {
    static func border<T: UIView>(
        width: CGFloat? = nil,
        color: UIColor? = nil
    ) -> Style<T> {
        return { view in
            width.map { view.layer.borderWidth = $0 }
            color.map { view.layer.borderColor = $0.cgColor }
        }
    }

    static func cornerRadius<T: UIView>(value: CGFloat) -> Style<T> {
        return { view in
            view.layer.cornerRadius = value
        }
    }

    static func base<T: UIView>(
        backgroundColor: UIColor? = nil,
        clipsToBounds: Bool? = nil
    ) -> Style<T> {
        return { view in
            backgroundColor.map { view.backgroundColor = $0 }
            clipsToBounds.map { view.clipsToBounds = $0}
        }
    }

    static func button<T: UIButton>(
        titleColor: UIColor,
        for state: UIControl.State
    ) -> Style<T> {
        return { button in
            button.setTitleColor(titleColor, for: state)
        }
    }
}

// MARK: - Helper

protocol Styleable {
    associatedtype StyledElement: UIView
    func withStyle(_ f: Style<StyledElement>) -> StyledElement
}

extension Styleable where Self: UIView {
    func withStyle(_ f: Style<Self>) -> Self {
        f(self)
        return self
    }
}
extension UIView: Styleable {}

// MARK: - Button styles

extension StyleSheet {
    static let baseButtonStyle: Style<UIButton> = concat([
        Mixins.base(backgroundColor: .white, clipsToBounds: true),
        Mixins.border(width: 2, color: .black),
        Mixins.cornerRadius(value: 8),
        Mixins.button(titleColor: .black, for: .normal),
        Mixins.button(titleColor: .gray, for: .highlighted)
    ])

    static let primaryButtonStyle: Style<UIButton> = concat([
            baseButtonStyle,
            StyleSheet.Mixins.border(color: .black)
    ])

    static let secondaryButtonStyle: Style<UIButton> = concat([
        baseButtonStyle,
        StyleSheet.Mixins.base(backgroundColor: .clear),
        StyleSheet.Mixins.border(width: 0),
        StyleSheet.Mixins.button(titleColor: .blue, for: .normal)
    ])

}

class CustomOldSwitch: UISwitch {
    enum Style {
        case `default`
        case custom1
    }
    private let style: Style

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        addTarget(self, action: #selector(changeStyle(_:)), for: .valueChanged)
        updateStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func changeStyle(_ sender: CustomSwitch) {
        updateStyle()
    }

    private func updateStyle() {
        switch style {
            case .default:
                applyDefaultStyle()
            case .custom1:
                applyCustomStyle()
        }
    }

    private func applyDefaultStyle() {
        if isOn {
            self.layer.borderWidth = 1
        } else {
            self.layer.borderWidth = 0
        }
    }

    private func applyCustomStyle() {
        if isOn {
            self.layer.borderWidth = 1
            self.backgroundColor = .white
        } else {
            self.layer.borderWidth = 0
            self.backgroundColor = .gray
        }
    }
}

class CustomSwitch: UISwitch {
    var onStyle: Style<CustomSwitch> = StyleSheet.Mixins.border(width: 1) {
        didSet {
            changeStyle(self)
        }
    }
    var offStyle: Style<CustomSwitch> = StyleSheet.Mixins.border(width: 0) {
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
        static let switchButtonStyle: Style<CustomSwitch> = {
            $0.offStyle = concat([
                StyleSheet.Mixins.border(width: 0),
                StyleSheet.Mixins.base(backgroundColor: .gray)
            ])
            $0.onStyle = concat([
                StyleSheet.Mixins.border(width: 1),
                StyleSheet.Mixins.base(backgroundColor: .white)
            ])
        }
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        let primaryButton = UIButton()
            .withStyle(StyleSheet.primaryButtonStyle)
        primaryButton.setTitle("Primary button", for: .normal)

        let secondaryButton = UIButton()
            .withStyle(StyleSheet.secondaryButtonStyle)
        secondaryButton.setTitle("Secondary button", for: .normal)

        let custom1Switch = CustomSwitch()
            .withStyle(LocalStyles.switchButtonStyle)
        let custom2Switch = CustomOldSwitch(style: .custom1)

        let container = UIStackView(arrangedSubviews: [
            primaryButton,
            secondaryButton,
            custom1Switch,
            custom2Switch
        ])
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
