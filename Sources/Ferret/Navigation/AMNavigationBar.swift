//
//  AMNavigationBar.swift
//  Ferret
//

import UIKit

/// 自定义导航栏：返回按钮、标题或自定义标题视图。
open class AMNavigationBar: UIView {

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel(frame: .zero)

    /// 导航栏标题；设置自定义标题视图后隐藏
    open var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title == nil || customTitleView != nil
            if customTitleView == nil {
                updateTitleConstraints()
            }
        }
    }

    /// 标题颜色；为 `nil` 时跟随 `tintColor`
    open var titleColor: UIColor? {
        didSet { applyTintColor() }
    }

    /// 自定义标题视图，设置后替换默认文本标题并居中
    open var customTitleView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            titleLabel.isHidden = customTitleView != nil
            if let customTitleView {
                addSubview(customTitleView)
                setupCustomTitleViewConstraints(customTitleView)
            } else {
                updateTitleConstraints()
            }
        }
    }

    /// 主题色，影响返回按钮与标题颜色
    open override var tintColor: UIColor! {
        didSet { applyTintColor() }
    }

    /// 返回按钮点击回调；未设置时走默认 pop / dismiss
    open var onBackButtonTapped: (() -> Void)?

    /// 创建导航栏
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .white

        addSubview(backButton)
        addSubview(titleLabel)

        backButton.setImage(
            UIImage.ferret("navi_back")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        backButton.setContentHuggingPriority(.required, for: .horizontal)
        backButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        applyTintColor()
        setupConstraints()
    }

    private func applyTintColor() {
        backButton.tintColor = tintColor ?? .black
        titleLabel.textColor = titleColor ?? tintColor
    }

    private func setupConstraints() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.topAnchor.constraint(equalTo: topAnchor),
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        updateTitleConstraints()
    }

    private func updateTitleConstraints() {
        guard customTitleView == nil else { return }

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    private func setupCustomTitleViewConstraints(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc private func backButtonTapped() {
        if let customHandler = onBackButtonTapped {
            customHandler()
        } else {
            handleDefaultBackAction()
        }
    }

    private func handleDefaultBackAction() {
        guard let viewController = findViewController() else { return }
        if let navigationController = viewController.navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                viewController.dismiss(animated: true)
            }
        } else {
            viewController.dismiss(animated: true)
        }
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}
