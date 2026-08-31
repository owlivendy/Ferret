//
//  AMTextView.swift
//  ChinaHomelife247
//
//  Created by Codex on 2026/4/22.
//

import UIKit
import SnapKit

/// 带 placeholder 和字数限制的输入框
/// - 支持右下角展示当前字数/最大字数
/// - 限制字数时兼容中文输入法联想态
open class AMTextView: UIView, AMFormValidatable {
    public typealias TextChangedBlock = (_ text: String) -> Void

    public weak var amDelegate: UITextViewDelegate?

    public let textView = UITextView()

    public var textChangedBlock: TextChangedBlock?

    /// 是否必填；默认 `false`
    public var required: Bool = false

    /// 校验逻辑；支持异步回传结果
    /// - Note: 命名为 `validateHandler`，避免与 `UIResponder.validate(_:)` 冲突
    public var validateHandler: AMFormValidateHandler?

    public var isEditable: Bool {
        get { textView.isEditable }
        set { textView.isEditable = newValue }
    }

    public var isSelectable: Bool {
        get { textView.isSelectable }
        set { textView.isSelectable = newValue }
    }

    public var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
            updatePlaceholderVisibility()
        }
    }

    public var placeholderColor: UIColor = UIColor.hex(string: "C2C7D0") {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    public var placeholderFont: UIFont = .systemFont(ofSize: 14) {
        didSet {
            placeholderLabel.font = placeholderFont
        }
    }

    public var text: String {
        get { textView.text ?? "" }
        set { setText(newValue, triggerCallback: false) }
    }

    public var font: UIFont? {
        get { textView.font }
        set {
            textView.font = newValue
            if let newValue {
                placeholderLabel.font = newValue
            }
        }
    }

    public var textColor: UIColor? {
        get { textView.textColor }
        set { textView.textColor = newValue }
    }

    /// 最大可输入字数，<= 0 时不限制
    public var maxCharacterCount: Int = 0 {
        didSet {
            if maxCharacterCount < 0 {
                maxCharacterCount = 0
                return
            }
            enforceTextLimitIfNeeded()
            updateCountLabel()
            updateCountLabelVisibility()
            updateTextLayout()
        }
    }

    /// 是否展示右下角字数统计，仅在设置了最大字数时生效
    public var showsCountLabel: Bool = false {
        didSet {
            updateCountLabelVisibility()
            updateTextLayout()
        }
    }

    public var textContainerInset: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) {
        didSet {
            updateTextContainerInset()
            updatePlaceholderConstraints()
        }
    }

    public var countLabelFont: UIFont = .systemFont(ofSize: 12) {
        didSet {
            countLabel.font = countLabelFont
        }
    }

    public var countLabelTextColor: UIColor = UIColor.hex(string: "98A2B3") {
        didSet {
            countLabel.textColor = countLabelTextColor
        }
    }

    private let placeholderLabel = UILabel(frame: .zero)
    private let countContainer = UIView(frame: .zero)
    private let countLabel = UILabel(frame: .zero)
    private let countContainerHeight: CGFloat = 20

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setupViews()
        setupNotifications()
        updateTextContainerInset()
        updatePlaceholderConstraints()
        updatePlaceholderVisibility()
        updateCountLabel()
        updateCountLabelVisibility()
        updateTextLayout()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        addSubview(textView)
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = UIColor.hex(string: "333333")
        textView.textContainer.lineFragmentPadding = 0
        textView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        addSubview(placeholderLabel)
        placeholderLabel.numberOfLines = 0
        placeholderLabel.font = placeholderFont
        placeholderLabel.textColor = placeholderColor

        addSubview(countContainer)
        // 只钉在底部；与 textView 的衔接由 `updateTextLayout` 负责。
        // 若再约束 top == textView.bottom，隐藏字数条时 textView.bottom == superview.bottom 会与 height == 20 冲突。
        countContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(countContainerHeight)
        }

        countContainer.addSubview(countLabel)
        countLabel.font = countLabelFont
        countLabel.textColor = countLabelTextColor
        countLabel.textAlignment = .right
        countLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textDidChangeNotification(_:)),
                                               name: UITextView.textDidChangeNotification,
                                               object: textView)
    }

    private func updatePlaceholderConstraints() {
        placeholderLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(textContainerInset.top)
            make.leading.equalToSuperview().offset(textContainerInset.left)
            make.trailing.lessThanOrEqualToSuperview().offset(-textContainerInset.right)
        }
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    private func updateCountLabelVisibility() {
        let shouldShow = showsCountLabel && maxCharacterCount > 0
        countLabel.isHidden = !shouldShow
        countContainer.isHidden = !shouldShow
    }

    private func updateCountLabel() {
        guard maxCharacterCount > 0 else {
            countLabel.text = nil
            return
        }
        countLabel.text = "\(text.count)/\(maxCharacterCount)"
    }

    private func updateTextContainerInset() {
        textView.textContainerInset = textContainerInset
    }

    private func updateTextLayout() {
        let shouldShow = showsCountLabel && maxCharacterCount > 0
        updateTextContainerInset()

        textView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            if shouldShow {
                make.bottom.equalTo(countContainer.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
        }
    }

    private func enforceTextLimitIfNeeded(triggerCallback: Bool = false) {
        guard maxCharacterCount > 0 else { return }
        guard textView.markedTextRange == nil else { return }

        let currentText = textView.text ?? ""
        guard currentText.count > maxCharacterCount else { return }

        let limitedText = String(currentText.prefix(maxCharacterCount))
        textView.text = limitedText
        if triggerCallback {
            textChangedBlock?(limitedText)
        }
    }

    public func setText(_ text: String, triggerCallback: Bool = false) {
        if maxCharacterCount > 0 {
            textView.text = String(text.prefix(maxCharacterCount))
        } else {
            textView.text = text
        }
        updatePlaceholderVisibility()
        updateCountLabel()

        if triggerCallback {
            textChangedBlock?(textView.text ?? "")
        }
    }

    /// 执行校验并将结果回传
    /// - Parameter completion: 是否通过
    public func runFormValidation(completion: @escaping (Bool) -> Void) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if required && trimmed.isEmpty {
            completion(false)
            return
        }

        guard let validateHandler else {
            completion(true)
            return
        }

        validateHandler(text) { result in
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

    @objc private func textDidChangeNotification(_ notification: Notification) {
        guard notification.object as? UITextView === textView else { return }

        enforceTextLimitIfNeeded()
        updatePlaceholderVisibility()
        updateCountLabel()
        amDelegate?.textViewDidChange?(textView)
        textChangedBlock?(textView.text ?? "")
    }
}

extension AMTextView: UITextViewDelegate {
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        amDelegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        amDelegate?.textViewDidBeginEditing?(textView)
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        amDelegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        enforceTextLimitIfNeeded()
        updatePlaceholderVisibility()
        updateCountLabel()
        amDelegate?.textViewDidEndEditing?(textView)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        amDelegate?.textViewDidChangeSelection?(textView)
    }

    public func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        let shouldChange = amDelegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
        guard shouldChange else { return false }

        guard maxCharacterCount > 0 else { return true }
        guard textView.markedTextRange == nil else { return true }

        let currentText = textView.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: text)
        guard newText.count > maxCharacterCount else { return true }
        textView.text = String(newText.prefix(maxCharacterCount))
        updatePlaceholderVisibility()
        updateCountLabel()
        amDelegate?.textViewDidChange?(textView)
        textChangedBlock?(textView.text ?? "")
        return false
    }
}
