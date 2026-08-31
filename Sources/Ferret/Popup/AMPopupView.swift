import UIKit

// MARK: - 枚举定义

/// 弹窗展示样式
public enum AMPopupPresentationStyle {
    /// 从底部弹出
    case fromBottom
    /// Alert 弹出（默认垂直居中，可通过 `alertVerticalAlignment` 改为顶部固定）
    case alert
}

/// Alert 垂直对齐方式（仅 `presentationStyle == .alert` 时生效）
public enum AMPopupAlertVerticalAlignment {
    /// 垂直居中
    case center
    /// 顶部固定；内容高度变化时向下伸展，避免多页切换时弹窗上下跳动
    case top
}

/// 导航栏按钮样式
public enum AMPopupNavigationBarStyle {
    /// 右侧关闭
    case x
    /// 左侧返回
    case back
    /// 左侧取消 + 右侧确定
    case cancelAndSure
    /// 隐藏导航栏
    case hidden
}

/// 标题对齐方式（仅 `navigationBarStyle == .x` 时生效）
public enum AMPopupTitleAlignment {
    /// 靠左对齐
    case left
    /// 居中对齐
    case center
}

/// 弹窗 Modal 类型（仅 `fromBottom` 时生效）
public enum AMPopupModalType {
    case none
    case threeOverFourScreen
    case fullScreen
    case fullScreenWithoutSafeAreaTop
    case fullScreenWithoutNavigationBar
}

// MARK: - AMPopupView

/// Swift 版弹窗组件，对齐 `CHPopupView` 能力。
///
/// Alert 支持垂直居中与顶部固定；多页内容高度不同时请使用 `.top`，避免切换时上下跳动。
open class AMPopupView: UIView {

    private static let contentTopConstant: CGFloat = 54
    private static let animationDuration: TimeInterval = 0.4
    private static let navigationBarHeight: CGFloat = 44

    // MARK: Public Properties

    /// 背景图（在 `show` 前设置，展示时插入最底层）
    public var bgView: UIView?

    /// 内容视图
    public private(set) var contentView: UIView!

    /// 标题 Label（仅 `fromBottom` 样式，Alert 时为 `nil`）
    public private(set) var titleLabel: UILabel?

    /// 标题对齐方式，默认居中；仅 `navigationBarStyle == .x` 时生效
    public var titleAlignment: AMPopupTitleAlignment = .center {
        didSet { applyTitleAlignment() }
    }

    /// Modal 类型，决定弹窗高度；`none` 时由 `contentView` 约束决定高度
    public var modalType: AMPopupModalType = .none

    /// 弹出样式（初始化后只读）
    public private(set) var presentationStyle: AMPopupPresentationStyle

    /// 导航栏样式，默认 `.x`
    public var navigationBarStyle: AMPopupNavigationBarStyle = .x {
        didSet { applyNavigationBarStyle() }
    }

    /// 导航栏左侧自定义视图（设置后隐藏默认左侧按钮）
    public var navigationLeftItemView: UIView? {
        didSet { updateNavigationLeftItemView(oldValue: oldValue) }
    }

    /// 右侧按钮点击回调；设置后需自行处理关闭逻辑
    public var rightButtonPressed: ((AMPopupView) -> Void)?

    /// 点击遮罩是否关闭，默认 `true`（仅 `fromBottom` 生效）
    public var hiddenWhenTappedMask: Bool = true

    /// 是否隐藏导航栏，默认 `false`
    public var hiddenNavigationBar: Bool = false {
        didSet {
            contentTopConstraint?.constant = hiddenNavigationBar ? 0 : Self.contentTopConstant
        }
    }

    /// 弹窗关闭后的回调（X/返回/遮罩/代码 `hide()` 等）
    public var onDismiss: ((AMPopupView) -> Void)?

    /// 是否启用键盘避让
    public var enableKeyboardAdjustment: Bool = true

    /// 键盘与输入框的最小间距，默认 80
    public var minGapBetweenKeyboardAndTextField: CGFloat = 80

    /// 左侧按钮点击拦截，返回 `false` 时不执行默认关闭
    public var shouldExecLeftButtonTaped: ((AMPopupView) -> Bool)?

    /// 右侧按钮点击拦截，返回 `false` 时不执行默认关闭；与 `rightButtonPressed` 同时设置时仅执行 `rightButtonPressed`
    public var shouldExecRightButtonTaped: ((AMPopupView) -> Bool)?

    /// 弹窗圆角，默认 `20`；`modalType == .fullScreen` 时强制为 `0`
    public var cornerRadius: CGFloat = 20 {
        didSet { applyCornerRadius() }
    }

    /// 是否显示悬浮关闭按钮（遮罩层上、弹窗右上角外侧），默认 `false`。
    /// `.fromBottom` 与 `.alert` 均支持；可在 `show` 前设置，也可在展示后动态开关。
    public var showsFloatingCloseButton: Bool = false {
        didSet {
            guard oldValue != showsFloatingCloseButton, let mask = maskAlphaView else { return }
            installFloatingCloseButtonIfNeeded(on: mask)
            floatingCloseButton?.alpha = 1
            floatingCloseButton?.transform = .identity
        }
    }

    /// Alert 垂直对齐，默认居中；仅 `presentationStyle == .alert` 时生效
    public var alertVerticalAlignment: AMPopupAlertVerticalAlignment = .center

    /// Alert 顶部对齐时，相对容器安全区顶部的间距，默认 `24`
    public var alertTopInset: CGFloat = 24

    /// Alert 左右边距，默认 `16`；仅 `alertVerticalAlignment == .top` 时用于撑满宽度
    public var alertHorizontalInset: CGFloat = 16

    /// Alert 最大宽度，默认 `440`；仅 `alertVerticalAlignment == .top` 时生效（iPad 居中限宽）
    public var alertMaxWidth: CGFloat = 440

    // MARK: Private Properties

    private var navigationView: UIView!
    private var leftButton: UIButton!
    private var rightButton: UIButton!
    private var floatingCloseButton: UIButton?
    private var contentTopConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var centerYConstraint: NSLayoutConstraint?
    private var topConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var titleCenterXConstraint: NSLayoutConstraint?
    private var titleLeadingConstraint: NSLayoutConstraint?
    private var titleTrailingConstraint: NSLayoutConstraint?
    private weak var maskAlphaView: UIView?
    /// 避免 `hide()` 被连续调用时重复动画 / 重复触发 `onDismiss`
    private var isDismissing = false
    /// 是否已把 Alert 顶部锁定到接近居中的位置（只锁一次，避免换页跳动）
    private var hasLockedAlertTopNearCenter = false
    /// 锁定 top 时使用的弹窗高度；高度被 iOS 26 虚高撑大后再回落时需要重锁
    private var lockedAlertHeight: CGFloat = 0

    // MARK: - Init

    /// 从底部弹出的初始化方法（带标题栏）
    public convenience init(title: String, customView: UIView) {
        self.init(title: title, customView: customView, presentationStyle: .fromBottom)
    }

    /// Alert 样式的初始化方法（无标题栏）
    public convenience init(alertCustomView customView: UIView) {
        self.init(title: nil, customView: customView, presentationStyle: .alert)
    }

    public init(title: String?, customView: UIView, presentationStyle: AMPopupPresentationStyle = .fromBottom) {
        self.presentationStyle = presentationStyle
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
        enableKeyboardAdjustment = true
        minGapBetweenKeyboardAndTextField = 80
        hiddenWhenTappedMask = true

        switch presentationStyle {
        case .fromBottom:
            setupFromBottom(title: title ?? "", customView: customView)
        case .alert:
            setupAlert(customView: customView)
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeKeyboardObservers()
    }

    // MARK: - Show / Hide

    public func show() {
        showWithCompletion(nil)
    }

    public func showWithCompletion(_ completion: (() -> Void)?) {
        showInView(nil, completion: completion)
    }

    public func showInView(_ container: UIView?) {
        showInView(container, completion: nil)
    }

    public func showInView(_ container: UIView?, completion: (() -> Void)?) {
        if let superview {
            superview.removeFromSuperview()
        }

        let container = container ?? UIApplication.am_keyWindow
        guard let container else { return }

        let mask = UIControl()
        mask.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        mask.addTarget(self, action: #selector(maskTapped), for: .touchUpInside)
        mask.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mask)
        NSLayoutConstraint.activate([
            mask.topAnchor.constraint(equalTo: container.topAnchor),
            mask.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mask.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mask.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        container.layoutIfNeeded()
        mask.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        maskAlphaView = mask
        installFloatingCloseButtonIfNeeded(on: mask)

        addKeyboardObservers()
        installBackgroundViewIfNeeded()

        let screenHeight = UIScreen.main.bounds.height

        if presentationStyle == .fromBottom {
            applyModalHeight(screenHeight: screenHeight, container: container)

            let leading = leadingAnchor.constraint(equalTo: mask.leadingAnchor)
            let trailing = trailingAnchor.constraint(equalTo: mask.trailingAnchor)
            let bottom = bottomAnchor.constraint(equalTo: mask.bottomAnchor)
            NSLayoutConstraint.activate([leading, trailing, bottom])
            bottomConstraint = bottom

            transform = CGAffineTransform(translationX: 0, y: screenHeight)
            floatingCloseButton?.transform = transform
            mask.backgroundColor = UIColor.black.withAlphaComponent(0)
            UIView.animate(withDuration: Self.animationDuration, animations: {
                self.transform = .identity
                self.floatingCloseButton?.transform = .identity
                mask.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            }, completion: { _ in completion?() })
        } else {
            navigationView?.isHidden = true
            titleLabel?.isHidden = true
            leftButton?.isHidden = true
            rightButton?.isHidden = true
            navigationLeftItemView?.isHidden = true

            applyAlertPositionConstraints(on: mask)

            transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            alpha = 0
            floatingCloseButton?.alpha = 0
            floatingCloseButton?.transform = transform
            mask.backgroundColor = UIColor.black.withAlphaComponent(0)
            UIView.animate(withDuration: Self.animationDuration, animations: {
                self.alpha = 1
                self.transform = .identity
                self.floatingCloseButton?.alpha = 1
                self.floatingCloseButton?.transform = .identity
                mask.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            }, completion: { _ in completion?() })
        }
    }

    /// 按当前高度将 Alert 顶部对齐到接近垂直居中，且只锁定一次。
    ///
    /// 之后换页只改变高度、不改 top，避免上下跳动。键盘避让仍可临时上移。
    /// - Returns: 是否已锁定到有效的近居中位置
    @discardableResult
    public func lockAlertTopNearCenterIfNeeded() -> Bool {
        guard presentationStyle == .alert,
              alertVerticalAlignment == .top,
              let mask = superview else { return false }
        mask.layoutIfNeeded()
        layoutIfNeeded()
        let popupHeight = bounds.height
        let window = mask.window ?? UIApplication.am_keyWindow
        let layoutHeight = max(
            mask.bounds.height,
            window?.bounds.height ?? 0,
            UIScreen.main.bounds.height
        )
        let topSafe = max(mask.safeAreaInsets.top, window?.safeAreaInsets.top ?? 0)

        guard popupHeight > 1 else { return false }
        guard layoutHeight > popupHeight + 32 else { return false }

        let centeredTopInMask = (layoutHeight - popupHeight) / 2
        let inset = max(16, centeredTopInMask - topSafe)
        let previousLockInvalid = hasLockedAlertTopNearCenter && alertTopInset < 40 && inset > alertTopInset + 40
        let collapsedFromInflated = hasLockedAlertTopNearCenter && lockedAlertHeight > popupHeight + 80
        if hasLockedAlertTopNearCenter && !previousLockInvalid && !collapsedFromInflated {
            adjustForCurrentKeyboard(animated: false)
            return true
        }

        alertTopInset = inset
        topConstraint?.constant = inset
        hasLockedAlertTopNearCenter = true
        lockedAlertHeight = popupHeight
        mask.layoutIfNeeded()
        adjustForCurrentKeyboard(animated: false)
        return true
    }

    /// 按当前高度重新锁定近居中（用于首次真实高度落地）
    public func relockAlertTopNearCenter() {
        hasLockedAlertTopNearCenter = false
        lockedAlertHeight = 0
        lockAlertTopNearCenterIfNeeded()
    }

    /// 按当前已升起的键盘立刻避让（键盘已显示时 `keyboardWillShow` 不会再回调）
    /// - Parameter animated: 是否动画
    public func adjustForCurrentKeyboard(animated: Bool = true) {
        AMKeyboardTracker.startIfNeeded()
        guard let frame = AMKeyboardTracker.visibleFrame else { return }
        applyKeyboardAvoidance(keyboardFrameInScreen: frame, duration: animated ? 0.25 : 0)
    }

    /// 关闭弹窗
    /// - Note: 幂等；动画进行中或已关闭时再次调用无效，避免重复 `onDismiss`
    @objc public func hide() {
        guard !isDismissing else { return }
        endEditing(true)
        removeKeyboardObservers()

        guard let maskAlphaView else { return }
        isDismissing = true
        let screenHeight = UIScreen.main.bounds.height

        if presentationStyle == .fromBottom {
            UIView.animate(withDuration: Self.animationDuration, animations: {
                let offset = CGAffineTransform(translationX: 0, y: screenHeight)
                self.transform = offset
                self.floatingCloseButton?.transform = offset
                maskAlphaView.backgroundColor = UIColor.black.withAlphaComponent(0)
            }, completion: { _ in
                self.onDismiss?(self)
                maskAlphaView.removeFromSuperview()
                self.removeFromSuperview()
                self.floatingCloseButton = nil
            })
        } else {
            UIView.animate(withDuration: Self.animationDuration, animations: {
                let scale = CGAffineTransform(scaleX: 0.94, y: 0.94)
                self.transform = scale
                self.alpha = 0
                self.floatingCloseButton?.transform = scale
                self.floatingCloseButton?.alpha = 0
                maskAlphaView.backgroundColor = UIColor.black.withAlphaComponent(0)
            }, completion: { _ in
                self.onDismiss?(self)
                maskAlphaView.removeFromSuperview()
                self.removeFromSuperview()
                self.floatingCloseButton = nil
            })
        }
    }
}

// MARK: - Setup

private extension AMPopupView {

    func setupFromBottom(title: String, customView: UIView) {
        if #available(iOS 11.0, *) {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }

        let navigationView = UIView()
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(navigationView)
        self.navigationView = navigationView

        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        navigationView.addSubview(titleLabel)
        self.titleLabel = titleLabel

        let leftButton = UIButton(type: .custom)
        leftButton.titleLabel?.font = .systemFont(ofSize: 15)
        leftButton.isHidden = true
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        navigationView.addSubview(leftButton)
        self.leftButton = leftButton

        let rightButton = UIButton(type: .custom)
        rightButton.titleLabel?.font = .systemFont(ofSize: 15)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        navigationView.addSubview(rightButton)
        self.rightButton = rightButton

        customView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(customView)
        contentView = customView

        let titleCenterX = titleLabel.centerXAnchor.constraint(equalTo: navigationView.centerXAnchor)
        let titleLeading = titleLabel.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor, constant: 16)
        let titleTrailing = titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightButton.leadingAnchor, constant: -8)
        titleCenterXConstraint = titleCenterX
        titleLeadingConstraint = titleLeading
        titleTrailingConstraint = titleTrailing

        NSLayoutConstraint.activate([
            navigationView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            navigationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            navigationView.heightAnchor.constraint(equalToConstant: Self.navigationBarHeight),

            leftButton.topAnchor.constraint(equalTo: navigationView.topAnchor),
            leftButton.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor, constant: 10),
            leftButton.widthAnchor.constraint(equalToConstant: 44),
            leftButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerYAnchor.constraint(equalTo: navigationView.centerYAnchor),
            titleCenterX,

            rightButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            rightButton.trailingAnchor.constraint(equalTo: navigationView.trailingAnchor, constant: -10),
            rightButton.widthAnchor.constraint(equalToConstant: 44),
            rightButton.heightAnchor.constraint(equalToConstant: 44),

            customView.leadingAnchor.constraint(equalTo: leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        let contentTop = customView.topAnchor.constraint(
            equalTo: safeAreaLayoutGuide.topAnchor,
            constant: Self.contentTopConstant
        )
        contentTop.isActive = true
        contentTopConstraint = contentTop

        if let window = UIApplication.am_keyWindow, window.safeAreaInsets.bottom > 0 {
            customView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -window.safeAreaInsets.bottom).isActive = true
        } else {
            customView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }

        applyNavigationBarStyle()
    }

    func setupAlert(customView: UIView) {
        if #available(iOS 11.0, *) {
            layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
            ]
        }

        customView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(customView)
        contentView = customView

        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: topAnchor),
            customView.leadingAnchor.constraint(equalTo: leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// 安装 Alert 位置约束：居中保持原行为；顶部固定时左右撑满并限宽
    func applyAlertPositionConstraints(on mask: UIView) {
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: mask.centerXAnchor),
        ])

        switch alertVerticalAlignment {
        case .center:
            let centerY = centerYAnchor.constraint(equalTo: mask.centerYAnchor)
            NSLayoutConstraint.activate([
                centerY,
                leadingAnchor.constraint(greaterThanOrEqualTo: mask.leadingAnchor, constant: 20),
                trailingAnchor.constraint(lessThanOrEqualTo: mask.trailingAnchor, constant: -20),
            ])
            centerYConstraint = centerY
            topConstraint = nil
        case .top:
            let inset = alertHorizontalInset
            let top = topAnchor.constraint(
                equalTo: mask.safeAreaLayoutGuide.topAnchor,
                constant: alertTopInset
            )
            let preferredWidth = widthAnchor.constraint(equalTo: mask.widthAnchor, constant: -inset * 2)
            preferredWidth.priority = .defaultHigh
            NSLayoutConstraint.activate([
                top,
                leadingAnchor.constraint(greaterThanOrEqualTo: mask.leadingAnchor, constant: inset),
                trailingAnchor.constraint(lessThanOrEqualTo: mask.trailingAnchor, constant: -inset),
                widthAnchor.constraint(lessThanOrEqualToConstant: alertMaxWidth),
                preferredWidth,
            ])
            topConstraint = top
            centerYConstraint = nil
        }
    }

    func applyModalHeight(screenHeight: CGFloat, container: UIView) {
        heightConstraint?.isActive = false
        switch modalType {
        case .none:
            heightConstraint = nil
            applyCornerRadius()
        case .threeOverFourScreen:
            applyCornerRadius()
            heightConstraint = heightAnchor.constraint(equalToConstant: screenHeight * 0.75)
        case .fullScreen:
            layer.cornerRadius = 0
            heightConstraint = heightAnchor.constraint(equalToConstant: screenHeight)
        case .fullScreenWithoutSafeAreaTop:
            applyCornerRadius()
            let topSafeArea = container.safeAreaInsets.top
            heightConstraint = heightAnchor.constraint(equalToConstant: screenHeight - topSafeArea)
        case .fullScreenWithoutNavigationBar:
            applyCornerRadius()
            let topSpace = container.safeAreaInsets.top + Self.navigationBarHeight
            heightConstraint = heightAnchor.constraint(equalToConstant: screenHeight - topSpace)
        }
        heightConstraint?.isActive = true
    }

    /// 按 `cornerRadius` 与 `modalType` 更新圆角
    func applyCornerRadius() {
        layer.cornerRadius = (modalType == .fullScreen) ? 0 : cornerRadius
    }

    func installBackgroundViewIfNeeded() {
        guard let bgView, bgView.superview == nil else { return }
        bgView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(bgView, at: 0)
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// 在遮罩上安装悬浮关闭按钮，锚定到弹窗右上角外侧（底部弹窗 / Alert 通用）
    func installFloatingCloseButtonIfNeeded(on mask: UIView) {
        floatingCloseButton?.removeFromSuperview()
        floatingCloseButton = nil
        guard showsFloatingCloseButton else { return }

        let button = UIButton(type: .custom)
        button.setImage(UIImage.ferret("close_circle_stroke"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(floatingCloseButtonTapped), for: .touchUpInside)
        mask.addSubview(button)
        floatingCloseButton = button

        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: self.topAnchor, constant: -10),
            button.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    @objc func floatingCloseButtonTapped() {
        hide()
    }

    func applyNavigationBarStyle() {
        guard leftButton != nil, rightButton != nil else { return }

        if case .hidden = navigationBarStyle {
            navigationView?.isHidden = true
            titleLabel?.isHidden = true
            leftButton.isHidden = true
            rightButton.isHidden = true
            navigationLeftItemView?.isHidden = true
            contentTopConstraint?.constant = 0
            return
        }

        navigationView?.isHidden = hiddenNavigationBar
        titleLabel?.isHidden = hiddenNavigationBar
        navigationLeftItemView?.isHidden = hiddenNavigationBar
        if !hiddenNavigationBar {
            contentTopConstraint?.constant = Self.contentTopConstant
        }

        switch navigationBarStyle {
        case .x:
            leftButton.isHidden = true
            rightButton.isHidden = false
            leftButton.setImage(nil, for: .normal)
            leftButton.setTitle(nil, for: .normal)
            rightButton.setImage(
                UIImage.ferret("close_stroke")?.withRenderingMode(.alwaysTemplate),
                for: .normal
            )
            rightButton.setTitle(nil, for: .normal)
            rightButton.setTitleColor(nil, for: .normal)
            rightButton.tintColor = UIColor.hex(string: "#9CA3AF")
        case .back:
            leftButton.isHidden = false
            rightButton.isHidden = true
            leftButton.setImage(UIImage.ferret("navi_back"), for: .normal)
            leftButton.setTitle(nil, for: .normal)
            rightButton.setImage(nil, for: .normal)
            rightButton.setTitle(nil, for: .normal)
            rightButton.tintColor = nil
        case .cancelAndSure:
            leftButton.isHidden = false
            rightButton.isHidden = false
            leftButton.setImage(nil, for: .normal)
            leftButton.setTitle("取消", for: .normal)
            leftButton.setTitleColor(UIColor.hex(string: "#F54900"), for: .normal)
            rightButton.setImage(nil, for: .normal)
            rightButton.setTitle("确定", for: .normal)
            rightButton.setTitleColor(UIColor.hex(string: "#F54900"), for: .normal)
            rightButton.tintColor = nil
        case .hidden:
            break
        }

        if navigationLeftItemView != nil {
            leftButton.isHidden = true
        }

        applyTitleAlignment()
    }

    /// 按 `titleAlignment` 更新标题水平约束；非 `.x` 样式时强制居中
    func applyTitleAlignment() {
        guard titleLabel != nil else { return }

        let useLeft = navigationBarStyle == .x && titleAlignment == .left
        titleCenterXConstraint?.isActive = false
        titleLeadingConstraint?.isActive = false
        titleTrailingConstraint?.isActive = false
        if useLeft {
            titleLeadingConstraint?.isActive = true
            titleTrailingConstraint?.isActive = true
            titleLabel?.textAlignment = .left
        } else {
            titleCenterXConstraint?.isActive = true
            titleLabel?.textAlignment = .center
        }
    }

    func updateNavigationLeftItemView(oldValue: UIView?) {
        oldValue?.removeFromSuperview()
        guard let navigationView else { return }

        if let itemView = navigationLeftItemView {
            itemView.translatesAutoresizingMaskIntoConstraints = false
            navigationView.addSubview(itemView)
            NSLayoutConstraint.activate([
                itemView.topAnchor.constraint(equalTo: navigationView.topAnchor),
                itemView.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor, constant: 10),
                itemView.heightAnchor.constraint(equalToConstant: Self.navigationBarHeight),
            ])
            leftButton.isHidden = true
        } else {
            applyNavigationBarStyle()
        }
    }
}

// MARK: - Actions

private extension AMPopupView {

    @objc func maskTapped() {
        guard presentationStyle == .fromBottom, hiddenWhenTappedMask else { return }
        hide()
    }

    @objc func leftButtonTapped() {
        var shouldExec = true
        if let shouldExecLeftButtonTaped {
            shouldExec = shouldExecLeftButtonTaped(self)
        }
        if shouldExec {
            hide()
        }
    }

    @objc func rightButtonTapped() {
        if let rightButtonPressed {
            rightButtonPressed(self)
            return
        }

        var shouldExec = true
        if let shouldExecRightButtonTaped {
            shouldExec = shouldExecRightButtonTaped(self)
        }
        if shouldExec {
            hide()
        }
    }
}

// MARK: - Keyboard

private extension AMPopupView {

    func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for sub in view.subviews {
            if let found = findFirstResponder(in: sub) { return found }
        }
        return nil
    }

    func addKeyboardObservers() {
        // SwiftUI 输入框在 show 时可能尚未物化，不能仅依赖当前层级扫描
        guard enableKeyboardAdjustment else { return }
        AMKeyboardTracker.startIfNeeded()
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        applyKeyboardAvoidance(from: notification)
    }

    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let window = UIApplication.am_keyWindow else { return }
        let resolved = AMKeyboardTracker.resolvedFrame(keyboardFrame, in: window)
        if resolved.minY >= window.bounds.height - 1 {
            restoreKeyboardAvoidance(from: notification)
        } else {
            applyKeyboardAvoidance(keyboardFrameInScreen: resolved, duration: (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25)
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        restoreKeyboardAvoidance(from: notification)
    }

    func applyKeyboardAvoidance(from notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        applyKeyboardAvoidance(keyboardFrameInScreen: keyboardFrame, duration: duration)
    }

    func restoreKeyboardAvoidance(from notification: Notification) {
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        restoreKeyboardAvoidance(duration: duration)
    }

    func applyKeyboardAvoidance(keyboardFrameInScreen: CGRect, duration: TimeInterval) {
        guard enableKeyboardAdjustment, let window = UIApplication.am_keyWindow else { return }

        let keyboardFrame = AMKeyboardTracker.resolvedFrame(keyboardFrameInScreen, in: window)
        // 用「未避让」时的底边计算，避免重复调用时把已上移的位置再减一次
        let alreadyShifted = currentKeyboardShift
        let unshiftedMaxY: CGFloat
        if presentationStyle == .alert, alertVerticalAlignment == .top {
            unshiftedMaxY = convert(bounds, to: window).maxY + alreadyShifted
        } else if let firstResponder = findFirstResponder(in: contentView) ?? findFirstResponder(in: self) {
            unshiftedMaxY = firstResponder.convert(firstResponder.bounds, to: window).maxY + alreadyShifted
        } else {
            unshiftedMaxY = convert(bounds, to: window).maxY + alreadyShifted
        }
        let keyboardMinY = keyboardFrame.minY
        let gap = keyboardMinY - unshiftedMaxY
        // >0 上移贴键盘；<0 说明近居中已有余量，收回上移（高度从虚高回落后要把弹窗拉下来）
        let desiredShift = minGapBetweenKeyboardAndTextField - gap

        if presentationStyle == .fromBottom, let bottomConstraint {
            bottomConstraint.constant = desiredShift > 0 ? -desiredShift : 0
        } else if presentationStyle == .alert {
            if alertVerticalAlignment == .top, let topConstraint {
                let minInset: CGFloat = 8
                if desiredShift > 0 {
                    topConstraint.constant = max(minInset, alertTopInset - desiredShift)
                } else {
                    topConstraint.constant = alertTopInset
                }
            } else if let centerYConstraint {
                centerYConstraint.constant = desiredShift > 0 ? -desiredShift : 0
            }
        }
        let layout: () -> Void = {
            guard let superview = self.superview else { return }
            superview.layoutIfNeeded()
        }
        if duration > 0 {
            UIView.animate(withDuration: duration, animations: layout)
        } else {
            layout()
        }
    }

    /// 当前因键盘已上移的距离
    var currentKeyboardShift: CGFloat {
        if presentationStyle == .fromBottom {
            return -(bottomConstraint?.constant ?? 0)
        }
        if presentationStyle == .alert, alertVerticalAlignment == .top {
            return alertTopInset - (topConstraint?.constant ?? alertTopInset)
        }
        return -(centerYConstraint?.constant ?? 0)
    }

    func restoreKeyboardAvoidance(duration: TimeInterval) {
        guard enableKeyboardAdjustment else { return }
        if presentationStyle == .fromBottom {
            guard bottomConstraint?.constant != 0 else { return }
            bottomConstraint?.constant = 0
        } else if presentationStyle == .alert {
            if alertVerticalAlignment == .top {
                guard topConstraint?.constant != alertTopInset else { return }
                topConstraint?.constant = alertTopInset
            } else {
                guard centerYConstraint?.constant != 0 else { return }
                centerYConstraint?.constant = 0
            }
        }
        let layout: () -> Void = {
            guard let superview = self.superview else { return }
            superview.layoutIfNeeded()
        }
        if duration > 0 {
            UIView.animate(withDuration: duration, animations: layout)
        } else {
            layout()
        }
    }
}
