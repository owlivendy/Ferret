//
//  AMSelector.swift
//  aitrade
//

import UIKit

/// `AMSelector.Config` 的共享存储，避免泛型特化导致 `default` 分裂
private enum AMSelectorConfigStorage {
    static var searchPlaceholder: String = ""
}

/// 字符串值选择器（常用别名）
public typealias AMStringSelector = AMSelector<String>

private enum AMSelectorMetrics {
    static let rowHeight: CGFloat = 44
    static let searchBarHeight: CGFloat = 48
    /// 选项列表文案字号（14pt 两行可放入 44 行高）
    static let optionFontSize: CGFloat = 14
    /// 选项文案最多行数
    static let optionMaxLines: Int = 2
    /// 选项 Cell 内容边距（上下收紧以容纳两行）
    static let optionContentInsets = NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
    /// 与页面导航栏预留高度一致，对应 `AMPopupView.navigationBarHeight`
    static let popupNavigationHeight: CGFloat = 44
    /// 弹窗顶部到内容区顶部的间距，对应 `AMPopupView.contentTopConstant`
    static let popupContentTopOffset: CGFloat = 54
}

/// 选择器内建选项模型
public struct AMSelectorOption<T: Equatable & Sendable>: Equatable, Sendable {
    /// 选项值
    public let value: T
    /// 展示文案
    public let label: String

    /// 创建选项
    /// - Parameters:
    ///   - value: 选项值
    ///   - label: 展示文案
    public init(value: T, label: String) {
        self.value = value
        self.label = label
    }
}

/// 选择器选项列表数据源（弹窗内容由 caller 配置）
public protocol AMSelectorOptionsDataSource: AnyObject {
    /// 选项值类型
    associatedtype OptionValue: Equatable & Sendable

    /// 选项数量
    /// - Parameter selector: 选择器
    /// - Returns: 选项个数
    func numberOfOptions(in selector: AMSelector<OptionValue>) -> Int

    /// 配置弹窗列表中的选项 Cell
    /// - Parameters:
    ///   - selector: 选择器
    ///   - cell: 列表 Cell
    ///   - index: 选项索引
    func selector(_ selector: AMSelector<OptionValue>, configureOptionCell cell: UITableViewCell, at index: Int)

    /// 搜索匹配文案；未实现时默认返回空字符串
    /// - Parameters:
    ///   - selector: 选择器
    ///   - index: 选项索引
    /// - Returns: 用于搜索过滤的文本
    func selector(_ selector: AMSelector<OptionValue>, searchableTextForOptionAt index: Int) -> String
}

public extension AMSelectorOptionsDataSource {
    /// 默认不参与搜索过滤
    func selector(_ selector: AMSelector<OptionValue>, searchableTextForOptionAt index: Int) -> String {
        ""
    }
}

/// 选择器选项点击代理
public protocol AMSelectorDelegate: AnyObject {
    /// 选项值类型
    associatedtype OptionValue: Equatable & Sendable

    /// 选中某个选项
    /// - Parameters:
    ///   - selector: 选择器
    ///   - index: 选项索引
    func selector(_ selector: AMSelector<OptionValue>, didSelectOptionAt index: Int)

    /// 取消选中某个选项（仅多选时可能触发）
    /// - Parameters:
    ///   - selector: 选择器
    ///   - index: 选项索引
    func selector(_ selector: AMSelector<OptionValue>, didDeselectOptionAt index: Int)
}

public extension AMSelectorDelegate {
    /// 默认空实现
    func selector(_ selector: AMSelector<OptionValue>, didDeselectOptionAt index: Int) {}
}

/// 表单选择器：点击后通过 `AMPopupView` 展示可滚动选项列表
public final class AMSelector<T: Equatable & Sendable>: UIControl, AMFormValidatable {
    /// 可圆角的角集合
    public struct RoundedCorners: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static var topLeft: RoundedCorners { RoundedCorners(rawValue: 1 << 0) }
        public static var topRight: RoundedCorners { RoundedCorners(rawValue: 1 << 1) }
        public static var bottomLeft: RoundedCorners { RoundedCorners(rawValue: 1 << 2) }
        public static var bottomRight: RoundedCorners { RoundedCorners(rawValue: 1 << 3) }
        public static var left: RoundedCorners { [.topLeft, .bottomLeft] }
        public static var right: RoundedCorners { [.topRight, .bottomRight] }
        public static var top: RoundedCorners { [.topLeft, .topRight] }
        public static var bottom: RoundedCorners { [.bottomLeft, .bottomRight] }
        public static var all: RoundedCorners { [.topLeft, .topRight, .bottomLeft, .bottomRight] }
    }

    /// 选择器全局默认文案配置
    ///
    /// 因 `AMSelector` 为泛型，请通过任意特化访问（如 `AMStringSelector.Config.default`）；
    /// 底层为模块级共享存储，所有特化读写的是同一份配置。
    public struct Config: Sendable {
        /// 搜索框占位文案
        public var searchPlaceholder: String

        /// 创建配置
        /// - Parameter searchPlaceholder: 搜索框占位文案
        public init(searchPlaceholder: String = "") {
            self.searchPlaceholder = searchPlaceholder
        }

        /// 全局默认配置（所有泛型特化共享）
        public static var `default`: Config {
            get { Config(searchPlaceholder: AMSelectorConfigStorage.searchPlaceholder) }
            set { AMSelectorConfigStorage.searchPlaceholder = newValue.searchPlaceholder }
        }
    }

    /// 占位文案
    public var placeholder: String? {
        didSet { updateDisplayedText(animated: false) }
    }

    /// 展示文案；设置 `value` 时会自动同步，也可由 caller 单独覆盖
    public var displayText: String? {
        didSet { updateDisplayedText(animated: true) }
    }

    /// 当前选中项；多选时可包含多个值
    public var value: [AMSelectorOption<T>]? {
        didSet {
            syncDisplayTextFromValue()
            if value != oldValue {
                sendActions(for: .valueChanged)
            }
        }
    }

    /// 左侧图标；`nil` 时不展示
    public var icon: UIImage? {
        didSet { updateIcon() }
    }

    /// 是否支持多选；单选时点击选项后自动关闭弹窗
    public var allowsMultipleSelection = false

    /// 弹窗标题；默认使用 `placeholder`
    public var popupTitle: String?

    /// 是否开启选项搜索，默认 `false`
    public var isSearchEnabled = false

    /// 搜索框占位文案；未单独赋值时使用 `Config.default.searchPlaceholder`
    public var searchPlaceholder: String {
        get { searchPlaceholderOverride ?? Config.default.searchPlaceholder }
        set { searchPlaceholderOverride = newValue }
    }

    /// 内建选项列表；未设置 `optionsDataSource` 时使用
    public var options: [AMSelectorOption<T>] = [] {
        didSet {
            guard optionsDataSourceBridge == nil, let value else { return }
            let valid = value.filter { options.contains($0) }
            if valid.count != value.count {
                self.value = valid.isEmpty ? nil : valid
            }
        }
    }

    /// 禁用态背景色，默认 `#F1F3F5`
    public var disabledBackgroundColor: UIColor = UIColor.hex(string: "#F1F3F5") {
        didSet { updateAppearance() }
    }

    /// 禁用态边框色，默认 `#D1D5DB`
    public var disabledBorderColor: UIColor = UIColor.hex(string: "#D1D5DB") {
        didSet { updateAppearance() }
    }

    /// 选择器圆角半径，默认 12
    public var cornerRadius: CGFloat = 12 {
        didSet {
            updateCornerMask()
            updateFloatedPlaceholderLeading()
        }
    }

    /// 选择器圆角位置，默认全部圆角
    public var roundedCorners: RoundedCorners = .all {
        didSet { updateCornerMask() }
    }

    /// 是否必填；默认 `false`
    public var required: Bool = false

    /// 选中项展示文案格式化；设置后最终显示文本由该闭包生成
    /// - Note: 多选时会对每一项调用，结果以 `", "` 拼接
    public var textFormator: ((AMSelectorOption<T>) -> String)? {
        didSet { syncDisplayTextFromValue() }
    }

    /// 校验逻辑；支持异步回传结果
    /// - Note: 命名为 `validateHandler`，避免与 `UIResponder.validate(_:)` 冲突
    public var validateHandler: AMFormValidateHandler?

    /// 选项数据源（弱引用，需通过 `setOptionsDataSource` 绑定同类型实现）
    public private(set) weak var optionsDataSource: (any AMSelectorOptionsDataSource)?

    /// 选项点击代理（弱引用，需通过 `setDelegate` 绑定同类型实现）
    public private(set) weak var delegate: (any AMSelectorDelegate)?

    private var optionsDataSourceBridge: OptionsDataSourceBridge<T>?
    private var delegateBridge: SelectorDelegateBridge<T>?

    fileprivate var usesCustomOptionsDataSource: Bool {
        optionsDataSourceBridge != nil
    }

    private let fieldContainer = UIView(frame: .zero)
    /// 边框层（独立于内容，便于浮动占位盖在边框之上）
    private let borderView = UIView(frame: .zero)
    private let iconView = UIImageView(frame: .zero)
    /// 浮动占位下方的边框遮罩（label 保持透明，由该视图盖住顶部边框缺口）
    private let placeholderBorderCover = UIView(frame: .zero)
    private let placeholderLabel = UILabel(frame: .zero)
    private let valueLabel = UILabel(frame: .zero)
    private let arrowView = UIImageView(frame: .zero)

    private var placeholderCenterYConstraint: NSLayoutConstraint?
    private var placeholderTopConstraint: NSLayoutConstraint?
    /// 浮动态占位 leading：距父视图左侧 `cornerRadius + 4`
    private var placeholderFloatedLeadingConstraint: NSLayoutConstraint?
    /// 默认态占位 trailing：不超过箭头左侧
    private var placeholderToArrowTrailingConstraint: NSLayoutConstraint?
    /// 浮动态占位 trailing：贴 fieldContainer 右侧
    private var placeholderFloatedTrailingConstraint: NSLayoutConstraint?
    /// 图标与占位间距；无图标时为 0
    private var iconToPlaceholderSpacingConstraint: NSLayoutConstraint?
    /// 图标与选中文案间距；无图标时为 0
    private var iconToValueSpacingConstraint: NSLayoutConstraint?
    private var iconWidthConstraint: NSLayoutConstraint?
    private weak var activePopup: AMPopupView?
    /// 未单独设置时回落 `Config.default.searchPlaceholder`
    private var searchPlaceholderOverride: String?
    /// 浮动到位后再显示边框遮罩（不参与占位动画）
    private var shouldShowPlaceholderBorderCover = false
    private var isPlaceholderFloated = false

    private let fieldHeight: CGFloat = 48
    private let horizontalInset: CGFloat = 10
    private let iconSize: CGFloat = 20
    private let iconSpacing: CGFloat = 8
    private let placeholderFontSize: CGFloat = 16
    private let floatedPlaceholderFontSize: CGFloat = 12
    private let placeholderBorderCoverHorizontalPad: CGFloat = 4
    /// 浮动占位相对圆角的额外左间距
    private let floatedPlaceholderLeadingExtra: CGFloat = 4
    private let normalBorderColor = UIColor.hex(string: "#EEEEEE")
    private let normalBackgroundColor = UIColor.hex(string: "#FAFAFA")

    /// 创建选择器
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: fieldHeight)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutPlaceholderBorderCover()
        updateCornerMask()
    }

    public override var isEnabled: Bool {
        didSet { updateAppearance() }
    }

    public override var isHighlighted: Bool {
        didSet { fieldContainer.alpha = isHighlighted ? 0.85 : 1 }
    }

    /// 关闭当前选项弹窗
    public func dismissOptionsPopup() {
        activePopup?.hide()
    }

    /// 绑定选项数据源
    /// - Parameter dataSource: 数据源；`OptionValue` 须与选择器泛型 `T` 一致
    public func setOptionsDataSource<DS: AMSelectorOptionsDataSource>(_ dataSource: DS?) where DS.OptionValue == T {
        optionsDataSource = dataSource
        optionsDataSourceBridge = dataSource.map { OptionsDataSourceBridge($0) }
    }

    /// 绑定选项点击代理
    /// - Parameter delegate: 代理；`OptionValue` 须与选择器泛型 `T` 一致
    public func setDelegate<Del: AMSelectorDelegate>(_ delegate: Del?) where Del.OptionValue == T {
        self.delegate = delegate
        delegateBridge = delegate.map { SelectorDelegateBridge($0) }
    }

    private func setupViews() {
        fieldContainer.isUserInteractionEnabled = false
        fieldContainer.backgroundColor = normalBackgroundColor
        fieldContainer.layer.cornerRadius = cornerRadius
        fieldContainer.layer.cornerCurve = .continuous
        fieldContainer.clipsToBounds = false
        addSubview(fieldContainer)

        borderView.isUserInteractionEnabled = false
        borderView.backgroundColor = .clear
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = normalBorderColor.cgColor
        borderView.layer.cornerCurve = .continuous
        fieldContainer.addSubview(borderView)

        iconView.contentMode = .scaleAspectFit
        iconView.isHidden = true
        fieldContainer.addSubview(iconView)

        valueLabel.font = .systemFont(ofSize: placeholderFontSize)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 1
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        fieldContainer.addSubview(valueLabel)

        arrowView.image = UIImage.ferret("down_arrow")
        arrowView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        arrowView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        fieldContainer.addSubview(arrowView)

        // 占位最后加入，保证浮动时盖在边框之上；遮罩在 label 下方
        placeholderBorderCover.isUserInteractionEnabled = false
        placeholderBorderCover.isHidden = true
        fieldContainer.addSubview(placeholderBorderCover)

        placeholderLabel.font = .systemFont(ofSize: placeholderFontSize)
        placeholderLabel.textColor = UIColor.hex(string: "#9CA3AF")
        placeholderLabel.backgroundColor = .clear
        placeholderLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        placeholderLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        fieldContainer.addSubview(placeholderLabel)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        borderView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowView.translatesAutoresizingMaskIntoConstraints = false

        iconWidthConstraint = yielding(iconView.widthAnchor.constraint(equalToConstant: 0))
        iconToPlaceholderSpacingConstraint = yielding(placeholderLabel.leadingAnchor.constraint(
            equalTo: iconView.trailingAnchor,
            constant: 0
        ))
        placeholderFloatedLeadingConstraint = placeholderLabel.leadingAnchor.constraint(
            equalTo: fieldContainer.leadingAnchor,
            constant: floatedPlaceholderLeadingInset
        )
        placeholderFloatedLeadingConstraint?.isActive = false
        placeholderToArrowTrailingConstraint = placeholderLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: arrowView.leadingAnchor,
            constant: -8
        )
        placeholderFloatedTrailingConstraint = placeholderLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: fieldContainer.trailingAnchor,
            constant: -horizontalInset
        )
        placeholderFloatedTrailingConstraint?.isActive = false
        iconToValueSpacingConstraint = yielding(valueLabel.leadingAnchor.constraint(
            equalTo: iconView.trailingAnchor,
            constant: 0
        ))

        placeholderCenterYConstraint = placeholderLabel.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor)
        placeholderTopConstraint = placeholderLabel.centerYAnchor.constraint(equalTo: fieldContainer.topAnchor)
        placeholderTopConstraint?.isActive = false

        NSLayoutConstraint.activate([
            fieldContainer.topAnchor.constraint(equalTo: topAnchor),
            fieldContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            // 999：让位于系统 `_UITemporaryLayoutWidth/Height == 0`，避免未布局完成时 required 冲突
            yielding(fieldContainer.trailingAnchor.constraint(equalTo: trailingAnchor)),
            yielding(fieldContainer.bottomAnchor.constraint(equalTo: bottomAnchor)),
            yielding(fieldContainer.heightAnchor.constraint(equalToConstant: fieldHeight)),

            borderView.topAnchor.constraint(equalTo: fieldContainer.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),

            yielding(iconView.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: horizontalInset)),
            iconView.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
            iconWidthConstraint!,

            yielding(arrowView.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -horizontalInset)),
            arrowView.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),

            iconToPlaceholderSpacingConstraint!,
            placeholderToArrowTrailingConstraint!,
            placeholderCenterYConstraint!,

            iconToValueSpacingConstraint!,
            yielding(valueLabel.trailingAnchor.constraint(equalTo: arrowView.leadingAnchor, constant: -8)),
            valueLabel.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor)
        ])

        updateIcon()
        updateDisplayedText(animated: false)
        updateCornerMask()
        updateAppearance()
    }

    @objc private func handleTap() {
        guard isEnabled else { return }
        // 打开选项弹窗前先收起键盘，避免遮挡弹窗
        window?.endEditing(true)
        presentOptionsPopup()
    }

    private func presentOptionsPopup() {
        let totalCount: Int
        if let optionsDataSourceBridge {
            totalCount = optionsDataSourceBridge.numberOfOptions(in: self)
        } else {
            totalCount = options.count
        }
        guard totalCount > 0 else { return }

        let popupContent = AMSelectorPopupContentView<T>(frame: .zero)
        popupContent.configure(
            selector: self,
            totalOptionCount: totalCount,
            isSearchEnabled: isSearchEnabled,
            searchPlaceholder: searchPlaceholder,
            maxContentHeight: Self.maxPopupContentHeight()
        )
        popupContent.onOptionTapped = { [weak self] index in
            self?.handleBuiltInOptionTap(at: index)
        }

        let popup = AMPopupView(title: resolvedPopupTitle, customView: popupContent)
        popup.modalType = .none
        popup.onDismiss = { [weak self] _ in
            self?.activePopup = nil
        }
        activePopup = popup
        popup.show()
        popupContent.reloadData()
    }

    private var resolvedPopupTitle: String {
        popupTitle ?? placeholder ?? ""
    }

    /// 弹窗内容区（搜索框 + 列表）最大高度。
    /// 弹窗总高度上限 = 屏幕高度 - safeAreaTop - 导航栏高度；
    /// 内容区需再减去弹窗内标题区与底部安全区。
    private static func maxPopupContentHeight() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let window = UIApplication.am_keyWindow
        let topInset = window?.safeAreaInsets.top ?? 0
        let bottomInset = window?.safeAreaInsets.bottom ?? 0
        let maxPopupHeight = screenHeight - topInset - AMSelectorMetrics.popupNavigationHeight
        let maxContentHeight = maxPopupHeight
            - AMSelectorMetrics.popupContentTopOffset
            - bottomInset
        return max(maxContentHeight, 0)
    }

    private func handleBuiltInOptionTap(at index: Int) {
        guard optionsDataSourceBridge == nil, options.indices.contains(index) else {
            if allowsMultipleSelection {
                delegateBridge?.selector(self, didSelectOptionAt: index)
            } else {
                delegateBridge?.selector(self, didSelectOptionAt: index)
                activePopup?.hide()
            }
            return
        }

        let tappedOption = options[index]
        if allowsMultipleSelection {
            var selected = value ?? []
            if let existingIndex = selected.firstIndex(of: tappedOption) {
                selected.remove(at: existingIndex)
                value = selected.isEmpty ? nil : selected
                delegateBridge?.selector(self, didDeselectOptionAt: index)
            } else {
                selected.append(tappedOption)
                value = selected
                delegateBridge?.selector(self, didSelectOptionAt: index)
            }
        } else {
            value = [tappedOption]
            delegateBridge?.selector(self, didSelectOptionAt: index)
            activePopup?.hide()
        }
    }

    /// 执行校验并将结果回传
    /// - Parameter completion: 是否通过
    public func runFormValidation(completion: @escaping (Bool) -> Void) {
        let isEmpty = value?.isEmpty ?? true
        if required && isEmpty {
            completion(false)
            return
        }

        guard let validateHandler else {
            completion(true)
            return
        }

        validateHandler(displayText ?? "") { result in
            let finish = {
                switch result {
                case .success(true):
                    completion(true)
                case .success(false), .failure:
                    completion(false)
                }
            }
            if Thread.isMainThread {
                finish()
            } else {
                DispatchQueue.main.async(execute: finish)
            }
        }
    }

    private func syncDisplayTextFromValue() {
        if let value, !value.isEmpty {
            if let textFormator {
                displayText = value.map(textFormator).joined(separator: ", ")
            } else {
                displayText = value.map(\.label).joined(separator: ", ")
            }
        } else {
            displayText = nil
        }
    }

    private func updateDisplayedText(animated: Bool) {
        let trimmed = displayText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasValue = !trimmed.isEmpty
        valueLabel.text = hasValue ? trimmed : nil
        valueLabel.isHidden = !hasValue
        updatePlaceholderState(floated: hasValue, animated: animated)
    }

    private func updatePlaceholderState(floated: Bool, animated: Bool) {
        isPlaceholderFloated = floated
        placeholderLabel.text = placeholder
        placeholderLabel.isHidden = placeholder?.isEmpty ?? true
        shouldShowPlaceholderBorderCover = false
        placeholderBorderCover.isHidden = true

        let apply = {
            self.placeholderCenterYConstraint?.isActive = !floated
            self.placeholderTopConstraint?.isActive = floated
            if floated {
                self.updateFloatedPlaceholderLeading()
                self.iconToPlaceholderSpacingConstraint?.isActive = false
                self.placeholderFloatedLeadingConstraint?.isActive = true
                self.placeholderToArrowTrailingConstraint?.isActive = false
                self.placeholderFloatedTrailingConstraint?.isActive = true
            } else {
                self.placeholderFloatedLeadingConstraint?.isActive = false
                self.placeholderFloatedTrailingConstraint?.isActive = false
                self.iconToPlaceholderSpacingConstraint?.isActive = true
                self.placeholderToArrowTrailingConstraint?.isActive = true
            }
            self.placeholderLabel.font = .systemFont(
                ofSize: floated ? self.floatedPlaceholderFontSize : self.placeholderFontSize
            )
            self.fieldContainer.bringSubviewToFront(self.placeholderLabel)
            self.layoutIfNeededIfSized()
        }

        let showBorderCoverIfNeeded = {
            guard floated else { return }
            self.shouldShowPlaceholderBorderCover = true
            self.layoutPlaceholderBorderCover()
            self.fieldContainer.insertSubview(self.placeholderBorderCover, belowSubview: self.placeholderLabel)
            self.placeholderBorderCover.isHidden = false
        }

        if animated {
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: .curveEaseOut,
                animations: apply,
                completion: { _ in showBorderCoverIfNeeded() }
            )
        } else {
            apply()
            showBorderCoverIfNeeded()
        }
    }

    private func updateIcon() {
        let hasIcon = icon != nil
        iconView.image = icon
        iconView.isHidden = !hasIcon
        iconWidthConstraint?.constant = hasIcon ? iconSize : 0
        iconToPlaceholderSpacingConstraint?.constant = hasIcon ? iconSpacing : 0
        iconToValueSpacingConstraint?.constant = hasIcon ? iconSpacing : 0
        setNeedsLayout()
    }

    private var floatedPlaceholderLeadingInset: CGFloat {
        cornerRadius + floatedPlaceholderLeadingExtra
    }

    /// 更新浮动占位左侧间距：`cornerRadius + 4`
    private func updateFloatedPlaceholderLeading() {
        placeholderFloatedLeadingConstraint?.constant = floatedPlaceholderLeadingInset
    }

    /// 布局浮动占位遮罩：高度等于边框线宽，仅盖住顶部边框缺口
    private func layoutPlaceholderBorderCover() {
        guard shouldShowPlaceholderBorderCover, isPlaceholderFloated else {
            placeholderBorderCover.isHidden = true
            return
        }

        let labelWidth = placeholderLabel.intrinsicContentSize.width
        guard labelWidth > 0 else {
            placeholderBorderCover.isHidden = true
            return
        }

        let borderWidth = max(borderView.layer.borderWidth, 1)
        let coverWidth = placeholderBorderCoverHorizontalPad + labelWidth + placeholderBorderCoverHorizontalPad
        placeholderBorderCover.backgroundColor = resolvedBackgroundColor()
        placeholderBorderCover.frame = CGRect(
            x: placeholderLabel.frame.minX - placeholderBorderCoverHorizontalPad,
            y: 0,
            width: coverWidth,
            height: borderWidth
        )
    }

    private func updateAppearance() {
        fieldContainer.backgroundColor = resolvedBackgroundColor()
        placeholderBorderCover.backgroundColor = resolvedBackgroundColor()
        borderView.layer.borderColor = (isEnabled ? normalBorderColor : disabledBorderColor).cgColor
    }

    private func resolvedBackgroundColor() -> UIColor {
        isEnabled ? normalBackgroundColor : disabledBackgroundColor
    }

    private func updateCornerMask() {
        let mask = roundedCorners.caCornerMask
        fieldContainer.layer.cornerRadius = cornerRadius
        fieldContainer.layer.maskedCorners = mask
        borderView.layer.cornerRadius = cornerRadius
        borderView.layer.maskedCorners = mask
    }

    fileprivate func searchableText(forOptionAt index: Int) -> String {
        if optionsDataSourceBridge == nil, options.indices.contains(index) {
            return options[index].label
        }
        return optionsDataSourceBridge?.searchableText(in: self, at: index) ?? ""
    }

    fileprivate func configureDefaultOptionCell(_ cell: UITableViewCell, at index: Int) {
        guard options.indices.contains(index) else { return }
        var config = cell.defaultContentConfiguration()
        config.text = options[index].label
        // 14pt、最多 2 行；收紧上下边距以适配固定 44 行高
        config.textProperties.font = .systemFont(ofSize: AMSelectorMetrics.optionFontSize)
        config.textProperties.numberOfLines = AMSelectorMetrics.optionMaxLines
        config.textProperties.lineBreakMode = .byTruncatingTail
        config.directionalLayoutMargins = AMSelectorMetrics.optionContentInsets
        cell.contentConfiguration = config
    }

    fileprivate func configureDataSourceOptionCell(_ cell: UITableViewCell, at index: Int) {
        optionsDataSourceBridge?.configure(cell, in: self, at: index)
    }

    /// 宽高尚未确定时跳过，避免系统 `_UITemporaryLayoutWidth/Height == 0` 与内部约束冲突
    private func layoutIfNeededIfSized() {
        guard bounds.width > 1, bounds.height > 1 else { return }
        layoutIfNeeded()
    }

    /// 优先级 999，让位于系统 0 尺寸测量约束
    private func yielding(_ constraint: NSLayoutConstraint) -> NSLayoutConstraint {
        constraint.priority = UILayoutPriority(999)
        return constraint
    }
}

// MARK: - 类型擦除

private struct OptionsDataSourceBridge<Value: Equatable & Sendable> {
    private let numberOfOptionsHandler: (AMSelector<Value>) -> Int
    private let configureHandler: (AMSelector<Value>, UITableViewCell, Int) -> Void
    private let searchableTextHandler: (AMSelector<Value>, Int) -> String

    init<DS: AMSelectorOptionsDataSource>(_ source: DS) where DS.OptionValue == Value {
        numberOfOptionsHandler = source.numberOfOptions(in:)
        configureHandler = source.selector(_:configureOptionCell:at:)
        searchableTextHandler = source.selector(_:searchableTextForOptionAt:)
    }

    func numberOfOptions(in selector: AMSelector<Value>) -> Int {
        numberOfOptionsHandler(selector)
    }

    func configure(_ cell: UITableViewCell, in selector: AMSelector<Value>, at index: Int) {
        configureHandler(selector, cell, index)
    }

    func searchableText(in selector: AMSelector<Value>, at index: Int) -> String {
        searchableTextHandler(selector, index)
    }
}

private struct SelectorDelegateBridge<Value: Equatable & Sendable> {
    private let selectHandler: (AMSelector<Value>, Int) -> Void
    private let deselectHandler: (AMSelector<Value>, Int) -> Void

    init<Del: AMSelectorDelegate>(_ delegate: Del) where Del.OptionValue == Value {
        selectHandler = delegate.selector(_:didSelectOptionAt:)
        deselectHandler = delegate.selector(_:didDeselectOptionAt:)
    }

    func selector(_ selector: AMSelector<Value>, didSelectOptionAt index: Int) {
        selectHandler(selector, index)
    }

    func selector(_ selector: AMSelector<Value>, didDeselectOptionAt index: Int) {
        deselectHandler(selector, index)
    }
}

// MARK: - 弹窗内容

/// 选择器弹窗内容：可选搜索框 + 选项列表
private final class AMSelectorPopupContentView<T: Equatable & Sendable>: UIView, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    var onOptionTapped: ((Int) -> Void)?

    private weak var selector: AMSelector<T>?
    private var totalOptionCount = 0
    private var filteredIndices: [Int] = []
    private var maxContentHeight: CGFloat = 0
    private var listHeightConstraint: NSLayoutConstraint?
    private var contentHeightConstraint: NSLayoutConstraint?
    private var searchHeightConstraint: NSLayoutConstraint?

    private let searchContainer = UIView(frame: .zero)
    private let searchField = UITextField(frame: .zero)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let cellReuseID = "AMSelectorOptionCell"
    private var keyboardObservers: [NSObjectProtocol] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        registerKeyboardObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func configure(
        selector: AMSelector<T>,
        totalOptionCount: Int,
        isSearchEnabled: Bool,
        searchPlaceholder: String,
        maxContentHeight: CGFloat
    ) {
        self.selector = selector
        self.totalOptionCount = totalOptionCount
        self.maxContentHeight = maxContentHeight
        searchContainer.isHidden = !isSearchEnabled
        searchField.placeholder = searchPlaceholder
        searchHeightConstraint?.constant = isSearchEnabled ? AMSelectorMetrics.searchBarHeight : 0
        resetFilteredIndices()
        updateHeights()
    }

    func reloadData() {
        resetFilteredIndices()
        tableView.reloadData()
        updateHeights()
    }

    private func setupViews() {
        searchContainer.backgroundColor = .clear
        addSubview(searchContainer)

        searchField.borderStyle = .roundedRect
        searchField.font = .systemFont(ofSize: 14)
        searchField.clearButtonMode = .whileEditing
        searchField.returnKeyType = .search
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(handleSearchChanged), for: .editingChanged)
        searchContainer.addSubview(searchField)

        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.rowHeight = AMSelectorMetrics.rowHeight
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseID)
        addSubview(tableView)

        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchField.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        listHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        contentHeightConstraint = heightAnchor.constraint(equalToConstant: 0)
        searchHeightConstraint = searchContainer.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            contentHeightConstraint!,

            searchContainer.topAnchor.constraint(equalTo: topAnchor),
            searchContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchHeightConstraint!,

            searchField.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -16),
            searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchField.heightAnchor.constraint(equalToConstant: 36),

            tableView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            listHeightConstraint!
        ])
    }

    private func resetFilteredIndices() {
        filteredIndices = Array(0..<totalOptionCount)
        applySearchFilter()
    }

    @objc private func handleSearchChanged() {
        // 搜索只过滤列表数据，弹窗高度保持初始值不变
        applySearchFilter()
        tableView.reloadData()
    }

    private func applySearchFilter() {
        let keyword = searchField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        guard !keyword.isEmpty, let selector else {
            filteredIndices = Array(0..<totalOptionCount)
            return
        }
        filteredIndices = (0..<totalOptionCount).filter { index in
            selector.searchableText(forOptionAt: index)
                .lowercased()
                .contains(keyword)
        }
    }

    /// 按初始选项总数与固定行高计算列表高度；搜索过滤不改变弹窗高度
    private func updateHeights() {
        let searchHeight = searchContainer.isHidden ? 0 : AMSelectorMetrics.searchBarHeight
        let availableListHeight = max(maxContentHeight - searchHeight, 0)
        let desiredListHeight = CGFloat(totalOptionCount) * AMSelectorMetrics.rowHeight
        let listHeight = min(desiredListHeight, availableListHeight)
        listHeightConstraint?.constant = listHeight
        contentHeightConstraint?.constant = searchHeight + listHeight
        tableView.isScrollEnabled = true
    }

    private func registerKeyboardObservers() {
        let center = NotificationCenter.default
        let willChange = center.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.adjustForKeyboard(notification)
        }
        keyboardObservers = [willChange]
    }

    /// 键盘升起时增加列表底部 inset，避免内容被遮挡
    private func adjustForKeyboard(_ notification: Notification) {
        guard
            window != nil,
            let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let frameInTable = tableView.convert(endFrame, from: nil)
        let overlap = max(0, tableView.bounds.maxY - frameInTable.minY)
        tableView.contentInset.bottom = overlap
        tableView.verticalScrollIndicatorInsets.bottom = overlap
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredIndices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseID, for: indexPath)
        cell.selectionStyle = .none
        guard let selector else { return cell }
        let optionIndex = filteredIndices[indexPath.row]
        if selector.usesCustomOptionsDataSource {
            selector.configureDataSourceOptionCell(cell, at: optionIndex)
        } else {
            selector.configureDefaultOptionCell(cell, at: optionIndex)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        AMSelectorMetrics.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard filteredIndices.indices.contains(indexPath.row) else { return }
        onOptionTapped?(filteredIndices[indexPath.row])
        if selector?.allowsMultipleSelection == true {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

private extension AMSelector.RoundedCorners {
    var caCornerMask: CACornerMask {
        var mask: CACornerMask = []
        if contains(.topLeft) {
            mask.insert(.layerMinXMinYCorner)
        }
        if contains(.topRight) {
            mask.insert(.layerMaxXMinYCorner)
        }
        if contains(.bottomLeft) {
            mask.insert(.layerMinXMaxYCorner)
        }
        if contains(.bottomRight) {
            mask.insert(.layerMaxXMaxYCorner)
        }
        return mask
    }
}
