//
//  AMTagView.swift
//  Flamingo
//
//  Created by xiaofei shen on 2015-05-09.
//  Copyright (c) 2015 xiaofei shen. All rights reserved.
//


import UIKit

@IBDesignable
open class AMTagView: UIButton {

    @IBInspectable open var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable open var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable open var borderColor: UIColor? {
        didSet {
            reloadStyles()
        }
    }
    
    @IBInspectable open var textColor: UIColor = UIColor.white {
        didSet {
            reloadStyles()
        }
    }
    @IBInspectable open var selectedTextColor: UIColor = UIColor.white {
        didSet {
            reloadStyles()
        }
    }
    @IBInspectable open var titleLineBreakMode: NSLineBreakMode = .byTruncatingMiddle {
        didSet {
            titleLabel?.lineBreakMode = titleLineBreakMode
        }
    }
    @IBInspectable open var paddingY: CGFloat = 2 {
        didSet {
            titleEdgeInsets.top = paddingY
            titleEdgeInsets.bottom = paddingY
        }
    }
    @IBInspectable open var paddingX: CGFloat = 5 {
        didSet {
            titleEdgeInsets.left = paddingX
            updateRightInsets()
        }
    }

    @IBInspectable open var tagBackgroundColor: UIColor = UIColor.gray {
        didSet {
            reloadStyles()
        }
    }
    
    @IBInspectable open var highlightedBackgroundColor: UIColor? {
        didSet {
            reloadStyles()
        }
    }
    
    @IBInspectable open var selectedBorderColor: UIColor? {
        didSet {
            reloadStyles()
        }
    }
    
    @IBInspectable open var selectedBackgroundColor: UIColor? {
        didSet {
            reloadStyles()
        }
    }
    
    @IBInspectable open var textFont: UIFont = .systemFont(ofSize: 12) {
        didSet {
            titleLabel?.font = textFont
        }
    }
    
    private func reloadStyles() {
        if isHighlighted {
            if let highlightedBackgroundColor = highlightedBackgroundColor {
                // For highlighted, if it's nil, we should not fallback to backgroundColor.
                // Instead, we keep the current color.
                backgroundColor = highlightedBackgroundColor
            }
        }
        else if isSelected {
            backgroundColor = selectedBackgroundColor ?? tagBackgroundColor
            layer.borderColor = selectedBorderColor?.cgColor ?? borderColor?.cgColor
            setTitleColor(selectedTextColor, for: UIControl.State())
        }
        else {
            backgroundColor = tagBackgroundColor
            layer.borderColor = borderColor?.cgColor
            setTitleColor(textColor, for: UIControl.State())
        }
    }
    
    override open var isHighlighted: Bool {
        didSet {
            reloadStyles()
        }
    }
    
    override open var isSelected: Bool {
        didSet {
            reloadStyles()
        }
    }
    
    // MARK: remove button
    
    let removeButton = AMCloseButton()
    
    @IBInspectable open var enableRemoveButton: Bool = false {
        didSet {
            removeButton.isHidden = !enableRemoveButton
            updateRightInsets()
            rearlayoutRemoveButton()
        }
    }
    
    public enum RemoveButtonStyle {
        case normal // 正常显示在右侧
        case float // 悬浮在右侧
    }
    open var removeButtonStyle: RemoveButtonStyle = .normal {
        didSet {
            updateRightInsets()
            rearlayoutRemoveButton()
        }
    }
    
    @IBInspectable open var removeButtonBackgroundColor: UIColor? = nil {
        didSet {
            removeButton.backgroundColor = removeButtonBackgroundColor
        }
    }
    
    @IBInspectable open var removeButtonIconSize: CGFloat = 12 {
        didSet {
            removeButton.iconSize = removeButtonIconSize
            updateRightInsets()
        }
    }
    
    @IBInspectable open var removeIconLineWidth: CGFloat = 3 {
        didSet {
            removeButton.lineWidth = removeIconLineWidth
        }
    }
    @IBInspectable open var removeIconLineColor: UIColor = UIColor.white.withAlphaComponent(0.54) {
        didSet {
            removeButton.lineColor = removeIconLineColor
        }
    }
    
    /// Handles Tap (TouchUpInside)
    open var onTap: ((AMTagView) -> Void)?
    open var onLongPress: ((AMTagView) -> Void)?
    
    // MARK: - init
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
    }
    
    public init(title: String) {
        super.init(frame: CGRect.zero)
        setTitle(title, for: .normal)
        
        setupView()
    }
    
    private func setupView() {
        titleLabel?.lineBreakMode = titleLineBreakMode

        frame.size = intrinsicContentSize
        addSubview(removeButton)
        removeButton.tagView = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        self.addGestureRecognizer(longPress)
    }
    
    @objc func longPress() {
        onLongPress?(self)
    }
    
    // MARK: - layout

    override open var intrinsicContentSize: CGSize {
        // 用 title(for:)，避免 setTitle 后 titleLabel.text 尚未同步导致宽度偏小
        let title = currentTitle ?? title(for: .normal) ?? ""
        var size = (title as NSString).size(withAttributes: [NSAttributedString.Key.font: textFont])
        size.height = textFont.pointSize + paddingY * 2
        size.width += paddingX * 2
        if size.width < size.height {
            size.width = size.height
        }
        if enableRemoveButton {
            if removeButtonStyle == .normal {
                size.width += removeButtonIconSize + paddingX
            }
        }
        return size
    }

    open override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        invalidateIntrinsicContentSize()
    }
    
    private func updateRightInsets() {
        if enableRemoveButton {
            switch removeButtonStyle {
            case .normal:
                titleEdgeInsets.right = paddingX  + removeButtonIconSize + paddingX
            case .float:
                titleEdgeInsets.right = paddingX
            }
        }
        else {
            titleEdgeInsets.right = paddingX
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        rearlayoutRemoveButton()
    }
    
    func rearlayoutRemoveButton() {
        removeButton.frame.size.width = paddingX + removeButtonIconSize + paddingX
        removeButton.frame.size.height = self.frame.height
        removeButton.frame.origin.x = self.frame.width - removeButton.frame.width
        removeButton.frame.origin.y = 0
    }
}

/// Swift < 4.2 support
#if !(swift(>=4.2))
private extension NSAttributedString {
    typealias Key = NSAttributedStringKey
}
private extension UIControl {
    typealias State = UIControlState
}
#endif
