//
//  AMFormTextField.swift
//  aitrade
//

import UIKit

/// 表单输入框：浮动占位、聚焦/禁用/错误态，支持结束编辑时校验
public final class AMFormTextField: UIView, AMFormValidatable {
    /// 可圆角的角集合
    public struct RoundedCorners: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let topLeft = RoundedCorners(rawValue: 1 << 0)
        public static let topRight = RoundedCorners(rawValue: 1 << 1)
        public static let bottomLeft = RoundedCorners(rawValue: 1 << 2)
        public static let bottomRight = RoundedCorners(rawValue: 1 << 3)
        public static let left: RoundedCorners = [.topLeft, .bottomLeft]
        public static let right: RoundedCorners = [.topRight, .bottomRight]
        public static let top: RoundedCorners = [.topLeft, .topRight]
        public static let bottom: RoundedCorners = [.bottomLeft, .bottomRight]
        public static let all: RoundedCorners = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    }

    /// 输入框全局默认文案配置
    public struct Config: Sendable {
        /// 必填为空时的错误文案
        public var requiredErrorMessage: String

        /// 创建配置
        /// - Parameter requiredErrorMessage: 必填为空时的错误文案
        public init(requiredErrorMessage: String = "") {
            self.requiredErrorMessage = requiredErrorMessage
        }

        /// 全局默认配置；主工程在启动与切语言时赋值
        public static var `default` = Config()
    }

    /// 输入文本
    public var text: String {
        get { textField.text ?? "" }
        set {
            let oldValue = textField.text ?? ""
            textField.text = newValue
            if oldValue != newValue {
                invalidateValidationCacheIfTextChanged()
            }
            updatePlaceholderState(animated: false)
        }
    }

    /// 占位文案
    public var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            updatePlaceholderState(animated: false)
        }
    }

    /// 是否允许输入
    public var isInputEnabled: Bool = true {
        didSet {
            textField.isEnabled = isInputEnabled
            isUserInteractionEnabled = isInputEnabled
            updateAppearance()
        }
    }

    /// 左侧图标；`nil` 时不展示
    public var icon: UIImage? {
        didSet { updateIcon() }
    }

    /// 错误文案；非空时展示错误态与提示行
    public var errorText: String? {
        didSet { updateErrorState() }
    }

    /// 错误边框与图标颜色，默认系统红
    public var errorColor: UIColor = .systemRed {
        didSet { updateErrorState() }
    }

    /// 禁用态背景色，默认 `#F1F3F5`
    public var disabledBackgroundColor: UIColor = UIColor.hex(string: "#F1F3F5") {
        didSet { updateAppearance() }
    }

    /// 禁用态边框色，默认 `#D1D5DB`
    public var disabledBorderColor: UIColor = UIColor.hex(string: "#D1D5DB") {
        didSet { updateAppearance() }
    }

    /// 输入框圆角半径，默认 12
    public var cornerRadius: CGFloat = 12 {
        didSet {
            updateCornerMask()
            updateFloatedPlaceholderLeading()
        }
    }

    /// 输入框圆角位置，默认全部圆角
    public var roundedCorners: RoundedCorners = .all {
        didSet { updateCornerMask() }
    }

    /// 文本变化回调（输入过程中触发）
    public var onTextChanged: ((String) -> Void)?

    /// 固有高度变化回调（如错误文案显隐导致）
    public var onIntrinsicHeightChange: (() -> Void)?

    /// 是否必填；默认 `false`
    public var required: Bool = false

    /// 必填为空时的错误文案；未单独赋值时使用 `Config.default.requiredErrorMessage`
    public var requiredErrorMessage: String {
        get { requiredErrorMessageOverride ?? Config.default.requiredErrorMessage }
        set { requiredErrorMessageOverride = newValue }
    }

    /// 校验逻辑；结束编辑时触发，支持异步回传结果
    /// - Note: 命名为 `validateHandler`，避免与 `UIResponder.validate(_:)` 冲突
    public var validateHandler: AMFormValidateHandler? {
        didSet { clearValidationCache() }
    }

    /// 底层文本输入框（只读暴露，便于 caller 设置键盘类型等）
    public let textField = UITextField(frame: .zero)

    private let fieldContainer = UIView(frame: .zero)
    /// 边框层（独立于内容，便于浮动占位盖在边框之上）
    private let borderView = UIView(frame: .zero)
    private let iconView = UIImageView(frame: .zero)
    /// 浮动占位下方的边框遮罩（label 保持透明，由该视图盖住顶部边框缺口）
    private let placeholderBorderCover = UIView(frame: .zero)
    private let placeholderLabel = UILabel(frame: .zero)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorContainer = UIView(frame: .zero)
    private let errorIconView = UIImageView(frame: .zero)
    private let errorLabel = UILabel(frame: .zero)

    private var placeholderCenterYConstraint: NSLayoutConstraint?
    private var placeholderTopConstraint: NSLayoutConstraint?
    /// 浮动态占位 leading：距父视图左侧 `cornerRadius + 4`
    private var placeholderFloatedLeadingConstraint: NSLayoutConstraint?
    /// 默认态占位 trailing：不超过右侧 loading 区域
    private var placeholderToActivityTrailingConstraint: NSLayoutConstraint?
    /// 浮动态占位 trailing：贴 fieldContainer 右侧
    private var placeholderFloatedTrailingConstraint: NSLayoutConstraint?
    private var iconWidthConstraint: NSLayoutConstraint?
    /// 图标与文案间距；无图标时为 0
    private var iconToContentSpacingConstraint: NSLayoutConstraint?
    /// 输入框与图标间距；无图标时为 0
    private var textFieldLeadingToIconConstraint: NSLayoutConstraint?
    private var activityWidthConstraint: NSLayoutConstraint?
    private var textFieldTrailingToContainerConstraint: NSLayoutConstraint?
    private var textFieldTrailingToActivityConstraint: NSLayoutConstraint?
    private var fieldBottomConstraint: NSLayoutConstraint?
    private var errorTopConstraint: NSLayoutConstraint?
    private var validationToken = UUID()
    private var isValidating = false
    /// 未单独设置时回落 `Config.default.requiredErrorMessage`
    private var requiredErrorMessageOverride: String?
    /// 最近一次走完 `validateHandler` 的原文（与当前 `text` 一致时可复用结果）
    private var cachedValidatedText: String?
    /// 最近一次 `validateHandler` 的校验结果
    private var cachedValidationResult: Result<Bool, AMFormValidationError>?
    /// 是否展示边框遮罩（上浮前即布局到位，通过 alpha 淡入）
    private var shouldShowPlaceholderBorderCover = false

    private let fieldHeight: CGFloat = 48
    private let horizontalInset: CGFloat = 10
    private let iconSize: CGFloat = 20
    private let iconSpacing: CGFloat = 8
    private let placeholderFontSize: CGFloat = 16
    private let floatedPlaceholderFontSize: CGFloat = 12
    private let placeholderBorderCoverHorizontalPad: CGFloat = 4
    /// 浮动占位相对圆角的额外左间距
    private let floatedPlaceholderLeadingExtra: CGFloat = 4
    /// 占位上浮 / 遮罩淡入共用时长
    private let placeholderAnimationDuration: TimeInterval = 0.2
    private let normalBorderColor = UIColor.hex(string: "#EEEEEE")
    private let normalBackgroundColor = UIColor.hex(string: "#FAFAFA")

    private var isFieldFocused = false

    /// 创建表单输入框
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
        let errorHeight = errorContainer.isHidden ? 0 : measuredErrorHeight()
        let spacing: CGFloat = errorContainer.isHidden ? 0 : 6
        return CGSize(width: UIView.noIntrinsicMetric, height: fieldHeight + spacing + errorHeight)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutPlaceholderBorderCover()
        updateCornerMask()
    }

    private func setupViews() {
        fieldContainer.backgroundColor = normalBackgroundColor
        fieldContainer.layer.cornerRadius = cornerRadius
        fieldContainer.layer.cornerCurve = .continuous
        fieldContainer.clipsToBounds = false
        addSubview(fieldContainer)

        borderView.isUserInteractionEnabled = false
        borderView.backgroundColor = .clear
        borderView.layer.borderWidth = 1
        borderView.layer.cornerCurve = .continuous
        fieldContainer.addSubview(borderView)

        iconView.contentMode = .scaleAspectFit
        iconView.isHidden = true
        fieldContainer.addSubview(iconView)

        textField.font = .systemFont(ofSize: placeholderFontSize)
        textField.textColor = .label
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.autocorrectionType = .no
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(handleEditingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEnd)
        fieldContainer.addSubview(textField)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        fieldContainer.addSubview(activityIndicator)

        // 占位最后加入，保证浮动时盖在边框之上；遮罩在 label 下方
        placeholderBorderCover.isUserInteractionEnabled = false
        placeholderBorderCover.isHidden = true
        placeholderBorderCover.alpha = 0
        fieldContainer.addSubview(placeholderBorderCover)

        placeholderLabel.font = .systemFont(ofSize: placeholderFontSize)
        placeholderLabel.textColor = UIColor.hex(string: "#9CA3AF")
        placeholderLabel.backgroundColor = .clear
        placeholderLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        placeholderLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        fieldContainer.addSubview(placeholderLabel)

        errorIconView.image = UIImage.ferret("warn_stroke")?.withRenderingMode(.alwaysTemplate)
        errorIconView.contentMode = .scaleAspectFit
        errorContainer.addSubview(errorIconView)

        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textColor = errorColor
        errorLabel.numberOfLines = 0
        errorLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        errorContainer.addSubview(errorLabel)
        errorContainer.isHidden = true
        addSubview(errorContainer)

        translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        borderView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        errorContainer.translatesAutoresizingMaskIntoConstraints = false
        errorIconView.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        iconWidthConstraint = yielding(iconView.widthAnchor.constraint(equalToConstant: 0))
        iconToContentSpacingConstraint = yielding(placeholderLabel.leadingAnchor.constraint(
            equalTo: iconView.trailingAnchor,
            constant: 0
        ))
        placeholderFloatedLeadingConstraint = placeholderLabel.leadingAnchor.constraint(
            equalTo: fieldContainer.leadingAnchor,
            constant: floatedPlaceholderLeadingInset
        )
        placeholderFloatedLeadingConstraint?.isActive = false
        placeholderToActivityTrailingConstraint = placeholderLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: activityIndicator.leadingAnchor,
            constant: -8
        )
        placeholderFloatedTrailingConstraint = placeholderLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: fieldContainer.trailingAnchor,
            constant: -horizontalInset
        )
        placeholderFloatedTrailingConstraint?.isActive = false
        textFieldLeadingToIconConstraint = yielding(textField.leadingAnchor.constraint(
            equalTo: iconView.trailingAnchor,
            constant: 0
        ))
        activityWidthConstraint = yielding(activityIndicator.widthAnchor.constraint(equalToConstant: 0))

        placeholderCenterYConstraint = placeholderLabel.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor)
        placeholderTopConstraint = placeholderLabel.centerYAnchor.constraint(equalTo: fieldContainer.topAnchor)
        placeholderTopConstraint?.isActive = false

        fieldBottomConstraint = yielding(fieldContainer.bottomAnchor.constraint(equalTo: bottomAnchor))
        errorTopConstraint = errorContainer.topAnchor.constraint(equalTo: fieldContainer.bottomAnchor, constant: 6)

        textFieldTrailingToContainerConstraint = yielding(textField.trailingAnchor.constraint(
            equalTo: fieldContainer.trailingAnchor,
            constant: -horizontalInset
        ))
        textFieldTrailingToActivityConstraint = textField.trailingAnchor.constraint(
            equalTo: activityIndicator.leadingAnchor,
            constant: -8
        )
        textFieldTrailingToActivityConstraint?.isActive = false

        NSLayoutConstraint.activate([
            fieldContainer.topAnchor.constraint(equalTo: topAnchor),
            fieldContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            // 999：让位于系统 `_UITemporaryLayoutWidth/Height == 0`，避免未布局完成时 required 冲突
            yielding(fieldContainer.trailingAnchor.constraint(equalTo: trailingAnchor)),
            yielding(fieldContainer.heightAnchor.constraint(equalToConstant: fieldHeight)),
            fieldBottomConstraint!,

            borderView.topAnchor.constraint(equalTo: fieldContainer.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),

            yielding(iconView.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: horizontalInset)),
            iconView.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
            iconWidthConstraint!,

            iconToContentSpacingConstraint!,
            placeholderToActivityTrailingConstraint!,
            placeholderCenterYConstraint!,

            yielding(activityIndicator.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -horizontalInset)),
            activityIndicator.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            activityIndicator.heightAnchor.constraint(equalToConstant: iconSize),
            activityWidthConstraint!,

            textFieldLeadingToIconConstraint!,
            textFieldTrailingToContainerConstraint!,
            textField.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor, constant: 0),

            errorTopConstraint!,
            errorContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            yielding(errorContainer.trailingAnchor.constraint(equalTo: trailingAnchor)),
            errorContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            errorIconView.leadingAnchor.constraint(equalTo: errorContainer.leadingAnchor),
            errorIconView.topAnchor.constraint(equalTo: errorContainer.topAnchor),
            yielding(errorIconView.widthAnchor.constraint(equalToConstant: 16)),
            errorIconView.heightAnchor.constraint(equalToConstant: 16),

            yielding(errorLabel.leadingAnchor.constraint(equalTo: errorIconView.trailingAnchor, constant: 4)),
            errorLabel.trailingAnchor.constraint(equalTo: errorContainer.trailingAnchor),
            errorLabel.topAnchor.constraint(equalTo: errorContainer.topAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: errorContainer.bottomAnchor)
        ])

        updateAppearance()
        updateIcon()
        updateErrorState()
        updateCornerMask()
        updateValidatingUI()
    }

    /// 主动触发一次校验（与结束编辑时相同逻辑）
    public func validateIfNeeded() {
        runFormValidation(completion: { _ in })
    }

    /// 执行校验并将结果回传
    /// - Parameter completion: 是否通过
    public func runFormValidation(completion: @escaping (Bool) -> Void) {
        let currentText = text
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if required && trimmed.isEmpty {
            applyValidationResult(.failure(AMFormValidationError(requiredErrorMessage)))
            completion(false)
            return
        }

        guard let validateHandler else {
            applyValidationResult(.success(true))
            completion(true)
            return
        }

        // 文本未变：直接复用上次 `validateHandler` 结果，避免重复请求
        if let cachedValidatedText,
           cachedValidatedText == currentText,
           let cachedValidationResult {
            finishValidation(with: cachedValidationResult, completion: completion)
            return
        }

        let token = UUID()
        validationToken = token
        var didCompleteSynchronously = false

        validateHandler(currentText) { [weak self] result in
            let apply = {
                guard let self else {
                    completion(false)
                    return
                }
                guard self.validationToken == token else {
                    completion(false)
                    return
                }
                // 回调期间文本已变：丢弃本次结果，不写入缓存
                guard self.text == currentText else {
                    self.setValidating(false)
                    completion(false)
                    return
                }
                didCompleteSynchronously = true
                self.setValidating(false)
                self.cachedValidatedText = currentText
                self.cachedValidationResult = result
                self.finishValidation(with: result, completion: completion)
            }
            if Thread.isMainThread {
                apply()
            } else {
                DispatchQueue.main.async(execute: apply)
            }
        }

        // 闭包返回后仍未同步完成 → 视为异步，展示 loading
        if !didCompleteSynchronously, validationToken == token {
            setValidating(true)
        }
    }

    @objc private func handleEditingDidBegin() {
        isFieldFocused = true
        // 重新编辑时取消进行中的校验 loading
        validationToken = UUID()
        setValidating(false)
        updatePlaceholderState(animated: true)
        updateAppearance()
    }

    @objc private func handleEditingDidEnd() {
        isFieldFocused = false
        updatePlaceholderState(animated: true)
        updateAppearance()
        runFormValidation(completion: { _ in })
    }

    @objc private func handleEditingChanged() {
        invalidateValidationCacheIfTextChanged()
        updatePlaceholderState(animated: true)
        onTextChanged?(text)
    }

    private func finishValidation(
        with result: Result<Bool, AMFormValidationError>,
        completion: @escaping (Bool) -> Void
    ) {
        applyValidationResult(result)
        switch result {
        case .success(true):
            completion(true)
        case .success(false), .failure:
            completion(false)
        }
    }

    private func applyValidationResult(_ result: Result<Bool, AMFormValidationError>) {
        switch result {
        case .success(true):
            errorText = nil
        case .success(false):
            // 失败但无错误文案：保留现有 errorText（若无则不展示错误行）
            break
        case .failure(let error):
            errorText = error.message
        }
    }

    /// 文本相对上次校验结果发生变化时清空缓存
    private func invalidateValidationCacheIfTextChanged() {
        guard let cachedValidatedText else { return }
        if text != cachedValidatedText {
            clearValidationCache()
        }
    }

    private func clearValidationCache() {
        cachedValidatedText = nil
        cachedValidationResult = nil
    }

    private func setValidating(_ validating: Bool) {
        guard isValidating != validating else { return }
        isValidating = validating
        updateValidatingUI()
    }

    private func updateValidatingUI() {
        activityWidthConstraint?.constant = isValidating ? iconSize : 0
        activityIndicator.isHidden = !isValidating
        if isValidating {
            activityIndicator.startAnimating()
            textFieldTrailingToContainerConstraint?.isActive = false
            textFieldTrailingToActivityConstraint?.isActive = true
        } else {
            activityIndicator.stopAnimating()
            textFieldTrailingToActivityConstraint?.isActive = false
            textFieldTrailingToContainerConstraint?.isActive = true
        }
        setNeedsLayout()
    }

    private var isPlaceholderFloated: Bool {
        isFieldFocused || !text.isEmpty
    }

    private func updatePlaceholderState(animated: Bool) {
        let floated = isPlaceholderFloated
        let wasShowingCover = shouldShowPlaceholderBorderCover
        placeholderLabel.text = placeholder
        placeholderLabel.isHidden = placeholder?.isEmpty ?? true

        // 上浮前先把遮罩摆到最终位置；从非浮动态进入时先透明，再与占位同步淡入
        if floated {
            preparePlaceholderBorderCover(startTransparent: animated && !wasShowingCover)
        }

        let apply = {
            self.placeholderCenterYConstraint?.isActive = !floated
            self.placeholderTopConstraint?.isActive = floated
            // 浮动时 leading 改为贴父视图左侧；先撤销旧约束再启用新约束，避免冲突
            if floated {
                self.updateFloatedPlaceholderLeading()
                self.iconToContentSpacingConstraint?.isActive = false
                self.placeholderFloatedLeadingConstraint?.isActive = true
                self.placeholderToActivityTrailingConstraint?.isActive = false
                self.placeholderFloatedTrailingConstraint?.isActive = true
            } else {
                self.placeholderFloatedLeadingConstraint?.isActive = false
                self.placeholderFloatedTrailingConstraint?.isActive = false
                self.iconToContentSpacingConstraint?.isActive = true
                self.placeholderToActivityTrailingConstraint?.isActive = true
            }
            self.placeholderLabel.font = .systemFont(
                ofSize: floated ? self.floatedPlaceholderFontSize : self.placeholderFontSize
            )
            self.fieldContainer.bringSubviewToFront(self.placeholderLabel)
            self.layoutIfNeededIfSized()
            self.placeholderBorderCover.alpha = floated ? 1 : 0
        }

        if animated {
            UIView.animate(
                withDuration: placeholderAnimationDuration,
                delay: 0,
                options: .curveEaseOut,
                animations: apply,
                completion: { _ in
                    if !floated {
                        self.hidePlaceholderBorderCover()
                    }
                }
            )
        } else {
            apply()
            if !floated {
                hidePlaceholderBorderCover()
            }
        }
    }

    /// 按浮动态最终位置布局遮罩；`startTransparent` 为 true 时 alpha 置 0，供随后淡入
    private func preparePlaceholderBorderCover(startTransparent: Bool) {
        guard let frame = floatedPlaceholderBorderCoverFrame() else {
            hidePlaceholderBorderCover()
            return
        }
        shouldShowPlaceholderBorderCover = true
        placeholderBorderCover.backgroundColor = resolvedBackgroundColor()
        placeholderBorderCover.frame = frame
        fieldContainer.insertSubview(placeholderBorderCover, belowSubview: placeholderLabel)
        placeholderBorderCover.isHidden = false
        if startTransparent {
            placeholderBorderCover.alpha = 0
        }
    }

    private func hidePlaceholderBorderCover() {
        shouldShowPlaceholderBorderCover = false
        placeholderBorderCover.isHidden = true
        placeholderBorderCover.alpha = 0
    }

    /// 浮动态遮罩目标 frame（不依赖当前 placeholderLabel.frame，便于上浮前预布局）
    private func floatedPlaceholderBorderCoverFrame() -> CGRect? {
        guard let text = placeholder, !text.isEmpty else { return nil }
        let font = UIFont.systemFont(ofSize: floatedPlaceholderFontSize)
        let labelWidth = (text as NSString).size(withAttributes: [.font: font]).width
        guard labelWidth > 0 else { return nil }

        let borderWidth = max(borderView.layer.borderWidth, 1)
        let coverWidth = placeholderBorderCoverHorizontalPad + labelWidth + placeholderBorderCoverHorizontalPad
        return CGRect(
            x: floatedPlaceholderLeadingInset - placeholderBorderCoverHorizontalPad,
            y: 0,
            width: coverWidth,
            height: borderWidth + 1
        )
    }

    private func updateIcon() {
        let hasIcon = icon != nil
        iconView.image = icon
        iconView.isHidden = !hasIcon
        iconWidthConstraint?.constant = hasIcon ? iconSize : 0
        iconToContentSpacingConstraint?.constant = hasIcon ? iconSpacing : 0
        textFieldLeadingToIconConstraint?.constant = hasIcon ? iconSpacing : 0
        setNeedsLayout()
    }

    private func updateErrorState() {
        let hasError = !(errorText?.isEmpty ?? true)
        errorContainer.isHidden = !hasError
        errorLabel.text = errorText
        errorLabel.textColor = errorColor
        errorIconView.tintColor = errorColor

        fieldBottomConstraint?.isActive = !hasError
        errorTopConstraint?.isActive = hasError

        updateAppearance()
        invalidateIntrinsicContentSize()
        onIntrinsicHeightChange?()
    }

    private func updateAppearance() {
        fieldContainer.backgroundColor = resolvedBackgroundColor()
        placeholderBorderCover.backgroundColor = resolvedBackgroundColor()

        let borderColor: UIColor
        if hasError {
            borderColor = errorColor
        } else if !isInputEnabled {
            borderColor = disabledBorderColor
        } else if isFieldFocused {
            borderColor = tintColor
        } else {
            borderColor = normalBorderColor
        }
        borderView.layer.borderColor = borderColor.cgColor
    }

    private var hasError: Bool {
        !(errorText?.isEmpty ?? true)
    }

    private func resolvedBackgroundColor() -> UIColor {
        isInputEnabled ? normalBackgroundColor : disabledBackgroundColor
    }

    private var floatedPlaceholderLeadingInset: CGFloat {
        cornerRadius + floatedPlaceholderLeadingExtra
    }

    /// 更新浮动占位左侧间距：`cornerRadius + 4`
    private func updateFloatedPlaceholderLeading() {
        placeholderFloatedLeadingConstraint?.constant = floatedPlaceholderLeadingInset
    }

    /// 布局浮动占位遮罩：高度为边框线宽 + 1，仅盖住顶部边框缺口
    private func layoutPlaceholderBorderCover() {
        guard shouldShowPlaceholderBorderCover else { return }
        guard let frame = floatedPlaceholderBorderCoverFrame() else {
            hidePlaceholderBorderCover()
            return
        }
        placeholderBorderCover.backgroundColor = resolvedBackgroundColor()
        placeholderBorderCover.frame = frame
    }

    private func updateCornerMask() {
        let mask = roundedCorners.caCornerMask
        fieldContainer.layer.cornerRadius = cornerRadius
        fieldContainer.layer.maskedCorners = mask
        borderView.layer.cornerRadius = cornerRadius
        borderView.layer.maskedCorners = mask
    }

    private func measuredErrorHeight() -> CGFloat {
        let width = bounds.width > 0 ? bounds.width - 20 : UIScreen.main.bounds.width - 40
        let labelHeight = errorLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return max(labelHeight, 16)
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

private extension AMFormTextField.RoundedCorners {
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
