//
//  AMTagListView.swift
//  Flamingo
//
//  Created by xiaofei shen on 2015-05-09.
//  Copyright (c) 2015 xiaofei shen. All rights reserved.
//

import UIKit

@objc public protocol AMTagListViewDelegate {
    @objc optional func tagPressed(_ title: String, tagView: AMTagView, sender: AMTagListView, index: Int) -> Void
    @objc optional func tagRemoveButtonPressed(_ title: String, tagView: AMTagView, sender: AMTagListView, index: Int) -> Void
    @objc optional func tagListView(_ tagListView: AMTagListView, isExpanded:Bool) -> Void
}

@IBDesignable
open class AMTagListView: UIView {
    
    // MARK: - 新增计算属性：获取所有选中的tag文本数组
    open var selectedTagTexts: [String] {
        return tagViews
            .filter { $0.isSelected }
            .compactMap { $0.currentTitle }
    }
    
    @IBInspectable open dynamic var textColor: UIColor = .white {
        didSet {
            tagViews.forEach {
                $0.textColor = textColor
            }
        }
    }
    
    @IBInspectable open dynamic var selectedTextColor: UIColor = .white {
        didSet {
            tagViews.forEach {
                $0.selectedTextColor = selectedTextColor
            }
        }
    }

    @IBInspectable open dynamic var tagLineBreakMode: NSLineBreakMode = .byTruncatingMiddle {
        didSet {
            tagViews.forEach {
                $0.titleLineBreakMode = tagLineBreakMode
            }
        }
    }
    
    @IBInspectable open dynamic var tagBackgroundColor: UIColor = UIColor.gray {
        didSet {
            tagViews.forEach {
                $0.tagBackgroundColor = tagBackgroundColor
            }
        }
    }
    
    @IBInspectable open dynamic var tagHighlightedBackgroundColor: UIColor? {
        didSet {
            tagViews.forEach {
                $0.highlightedBackgroundColor = tagHighlightedBackgroundColor
            }
        }
    }
    
    @IBInspectable open dynamic var tagSelectedBackgroundColor: UIColor? {
        didSet {
            tagViews.forEach {
                $0.selectedBackgroundColor = tagSelectedBackgroundColor
            }
        }
    }
    
    @IBInspectable open dynamic var cornerRadius: CGFloat = 0 {
        didSet {
            tagViews.forEach {
                $0.cornerRadius = cornerRadius
            }
        }
    }
    @IBInspectable open dynamic var borderWidth: CGFloat = 0 {
        didSet {
            tagViews.forEach {
                $0.borderWidth = borderWidth
            }
        }
    }
    
    @IBInspectable open dynamic var borderColor: UIColor? {
        didSet {
            tagViews.forEach {
                $0.borderColor = borderColor
            }
        }
    }
    
    @IBInspectable open dynamic var selectedBorderColor: UIColor? {
        didSet {
            tagViews.forEach {
                $0.selectedBorderColor = selectedBorderColor
            }
        }
    }
    
    @IBInspectable open dynamic var paddingY: CGFloat = 2 {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.paddingY = paddingY
            }
        }
    }
    @IBInspectable open dynamic var paddingX: CGFloat = 5 {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.paddingX = paddingX
            }
        }
    }
    @IBInspectable open dynamic var marginY: CGFloat = 2 {
        didSet {
            rearrangeViews()
        }
    }
    @IBInspectable open dynamic var marginX: CGFloat = 5 {
        didSet {
            rearrangeViews()
        }
    }

    @IBInspectable open dynamic var minWidth: CGFloat = 0 {
        didSet {
            rearrangeViews()
        }
    }
    
    @objc public enum Alignment: Int {
        case left
        case center
        case right
        case leading
        case trailing
    }
    @IBInspectable open var alignment: Alignment = .leading {
        didSet {
            rearrangeViews()
        }
    }
    @IBInspectable open dynamic var shadowColor: UIColor = .white {
        didSet {
            rearrangeViews()
        }
    }
    @IBInspectable open dynamic var shadowRadius: CGFloat = 0 {
        didSet {
            rearrangeViews()
        }
    }
    @IBInspectable open dynamic var shadowOffset: CGSize = .zero {
        didSet {
            rearrangeViews()
        }
    }
    @IBInspectable open dynamic var shadowOpacity: Float = 0 {
        didSet {
            rearrangeViews()
        }
    }
    
    @IBInspectable open dynamic var enableRemoveButton: Bool = false {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.enableRemoveButton = enableRemoveButton
            }
        }
    }

    open var removeButtonStyle: AMTagView.RemoveButtonStyle = .normal {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.removeButtonStyle = removeButtonStyle
            }
        }
    }
    
    @IBInspectable open var removeButtonBackgroundColor: UIColor? = nil {
        didSet {
            tagViews.forEach {
                $0.removeButtonBackgroundColor = removeButtonBackgroundColor
            }
        }
    }
    
    @IBInspectable open dynamic var removeButtonIconSize: CGFloat = 12 {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.removeButtonIconSize = removeButtonIconSize
            }
        }
    }
    @IBInspectable open dynamic var removeIconLineWidth: CGFloat = 1 {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.removeIconLineWidth = removeIconLineWidth
            }
        }
    }
    
    @IBInspectable open dynamic var removeIconLineColor: UIColor = UIColor.white.withAlphaComponent(0.54) {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.removeIconLineColor = removeIconLineColor
            }
        }
    }
    
    @objc open dynamic var textFont: UIFont = .systemFont(ofSize: 12) {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.textFont = textFont
            }
        }
    }
    
    @IBOutlet open weak var delegate: AMTagListViewDelegate?

    //默认 折叠的行数， 默认 0, 0 表示不折叠,  大于 0 表示 大于 x 行后会折叠
    @IBInspectable open dynamic var numberOfCollapseRows: Int = 0 {
        didSet {
            isExpanded = numberOfCollapseRows <= 0
            rearrangeViews()
        }
    }
    
    /*
     预设AMTagListView 的宽度
     用于优化在 tableviewcell 中的时候，没那么快拿到高度，导致高度计算有问题。 可以通过预设这个属性来解决， 并且在对于的 tableviewcell 中重写systemLayoutSizeFitting方法，在里面调用rearrangeViews方法
     
     //Example:
     override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                           withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
                                           verticalFittingPriority: UILayoutPriority) -> CGSize {
         tagListView.rearrangeViews()
         return super.systemLayoutSizeFitting(targetSize,
                                              withHorizontalFittingPriority: horizontalFittingPriority,
                                              verticalFittingPriority: verticalFittingPriority)
     }
     */
    open var presetWidth: CGFloat?
    
    // State variables, true 表示展开， false表示需要折叠
    open var isExpanded: Bool = true
    private var expandButton: UIButton?
    public private(set) var hiddenTagCount: Int = 0
    public private(set) var totalTags: Int = 0
    //默认显示展开收起按钮，设置成 false 后，expendButton不在作为展开收起的功能， 在numberOfCollapseRows>0 的时候, 显示+{number}
    public var showExpandButton: Bool = true
    
    // Custom button text properties
    @IBInspectable open var expandButtonTitle: String = "展开"
    
    @IBInspectable open var collapseButtonTitle: String = "收起"
    
    // Whether to show hidden tag count in expand button
    @IBInspectable open var showHiddenTagCount: Bool = true
    
    // Expand button style properties
    @IBInspectable open var expandButtonTextColor: UIColor = UIColor.white {
        didSet {
            updateExpandButtonStyle()
        }
    }
    
    @IBInspectable open var expandButtonBackgroundColor: UIColor = UIColor.gray {
        didSet {
            updateExpandButtonStyle()
        }
    }
    
    @IBInspectable open var expandButtonCornerRadius: CGFloat = 0 {
        didSet {
            updateExpandButtonStyle()
        }
    }
    
    @IBInspectable open var expandButtonBorderWidth: CGFloat = 0 {
        didSet {
            updateExpandButtonStyle()
        }
    }
    
    @IBInspectable open var expandButtonBorderColor: UIColor? {
        didSet {
            updateExpandButtonStyle()
        }
    }
    
    //缓存的 AMTagView
    private var cachesTagViews: [AMTagView] = []
    open private(set) var tagViews: [AMTagView] = []
    private(set) var tagBackgroundViews: [UIView] = []
    private(set) var rowViews: [UIView] = []
    open private(set) var tagViewHeight: CGFloat = 0
    open private(set) var rows = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: - Interface Builder
    
    open override func prepareForInterfaceBuilder() {
        addTag("Welcome")
        addTag("to")
        addTag("TagListView").isSelected = true
    }
    
    // MARK: - Layout
    
    open override func layoutSubviews() {
        defer { rearrangeViews() }
        super.layoutSubviews()
    }
    
    open func rearrangeViews() {
        // Remove existing views
        let views = tagViews as [UIView] + tagBackgroundViews + rowViews
        views.forEach {
            $0.removeFromSuperview()
        }
        rowViews.removeAll(keepingCapacity: true)
        
        // Remove expand button if exists
        expandButton?.removeFromSuperview()
        expandButton = nil

        let frameWidth = self.presetWidth ?? bounds.width
        var finnallyRowCount = 0
        
        // First pass to calculate total rows and hidden tags
        //=============  计算是否需要展示 展开按钮 ===========================
        var tempRowWidth: CGFloat = 0
        var visibleTagCount = 0
        var tempRowTagCount = 0
        totalTags = tagViews.count


        // Add expand/collapse button if needed
        var expandButtonWidth: CGFloat = 0
        addExpandButton()
        if !showHiddenTagCount || isExpanded {
            //展开状态或者不需要显示剩余的数量，按钮的文本是固定的可以提前计算
            updateExpandButtonTitle(hiddenTagCount: 0)
            let intrinsicContentSize = expandButton?.intrinsicContentSize ?? .zero
            if showExpandButton {
                expandButtonWidth = intrinsicContentSize.width + paddingX * 2
            } else {
                expandButtonWidth = intrinsicContentSize.width
            }
        }
        
        for tagView in tagViews {
            let tagSize = tagView.intrinsicContentSize
            tagViewHeight = tagView.frame.height

            var currentMaxWidth: CGFloat = frameWidth
            if !isExpanded {
                if finnallyRowCount == numberOfCollapseRows {
                    
                    if showHiddenTagCount {
                        //收起并且需要展示剩余数量的情况下, 每次都要重新计算当前的剩余数量，因为文本宽度不固定
                        updateExpandButtonTitle(hiddenTagCount: totalTags - visibleTagCount)
                        let intrinsicContentSize = expandButton?.intrinsicContentSize ?? .zero
                        if showExpandButton {
                            expandButtonWidth = intrinsicContentSize.width + paddingX * 2
                        } else {
                            expandButtonWidth = intrinsicContentSize.width
                        }
                    }
                    
                    currentMaxWidth = frameWidth - expandButtonWidth - marginX
                }
                
                if tempRowTagCount == 0 || tempRowWidth + tagView.frame.width > currentMaxWidth {
                    if finnallyRowCount == numberOfCollapseRows && numberOfCollapseRows > 0 {
                        //未展开情况下，结束
                        break
                    }
                    
                    finnallyRowCount += 1
                    tempRowWidth = 0
                    tempRowTagCount = 0
                }
            } else {
                if tempRowTagCount == 0 || tempRowWidth + tagView.frame.width > currentMaxWidth {
                    finnallyRowCount += 1
                    tempRowWidth = 0
                    tempRowTagCount = 0
                }
            }
            
            tempRowWidth += max(minWidth, min(tagSize.width, frameWidth)) + marginX
            visibleTagCount += 1
            tempRowTagCount += 1
        }
        if isExpanded && numberOfCollapseRows > 0 && tempRowWidth + expandButtonWidth > frameWidth {
            finnallyRowCount += 1
        }
        
        // Check if we need to show expand/collapse button
        let needsShowExpandButton = numberOfCollapseRows > 0 && ((isExpanded && finnallyRowCount > numberOfCollapseRows) || (!isExpanded && visibleTagCount < totalTags))
        hiddenTagCount = needsShowExpandButton && !isExpanded ? totalTags - visibleTagCount : 0
        
        //===================================================================

        
        //================  开始布局 tagviews， 计算 tagview 位置 ==============================
        var isRtl: Bool = false
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            isRtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
        }
        else if #available(iOS 9.0, *) {
            isRtl = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        }
        else if let shared = UIApplication.value(forKey: "sharedApplication") as? UIApplication {
            isRtl = shared.userInterfaceLayoutDirection == .leftToRight
        }
        
        var alignment = self.alignment
        if alignment == .leading {
            alignment = isRtl ? .right : .left
        }
        else if alignment == .trailing {
            alignment = isRtl ? .left : .right
        }
        
        let directionTransform = isRtl
            ? CGAffineTransform(scaleX: -1.0, y: 1.0)
            : CGAffineTransform.identity
        
        var currentRow = 0
        var currentRowView: UIView!
        var currentRowTagCount = 0
        var currentRowWidth: CGFloat = 0
        
        
        for (index, tagView) in tagViews.enumerated() {
            tagView.frame.size = tagView.intrinsicContentSize
            tagView.tag = index
            tagView.removeButton.tag = index
            tagViewHeight = tagView.frame.height
            if numberOfCollapseRows > 0 && index > visibleTagCount - 1 {
                //剩余的不显示
                break;
            }
            
            if currentRowTagCount == 0 || currentRowWidth + tagView.frame.width > frameWidth {
                currentRow += 1
                currentRowWidth = 0
                currentRowTagCount = 0
                
                currentRowView = UIView()
                currentRowView.transform = directionTransform
                currentRowView.frame.origin.y = CGFloat(currentRow - 1) * (tagViewHeight + marginY)
                
                rowViews.append(currentRowView)
                addSubview(currentRowView)

                tagView.frame.size.width = min(tagView.frame.size.width, frameWidth)
            }
            
            let tagBackgroundView = tagBackgroundViews[index]
            tagBackgroundView.transform = directionTransform
            tagBackgroundView.frame.origin = CGPoint(
                x: currentRowWidth,
                y: 0)
            tagBackgroundView.frame.size = tagView.bounds.size
            tagView.frame.size.width = max(minWidth, tagView.frame.size.width)
            tagBackgroundView.layer.shadowColor = shadowColor.cgColor
            tagBackgroundView.layer.shadowPath = UIBezierPath(roundedRect: tagBackgroundView.bounds, cornerRadius: cornerRadius).cgPath
            tagBackgroundView.layer.shadowOffset = shadowOffset
            tagBackgroundView.layer.shadowOpacity = shadowOpacity
            tagBackgroundView.layer.shadowRadius = shadowRadius
            tagBackgroundView.addSubview(tagView)
            currentRowView.addSubview(tagBackgroundView)
            
            currentRowTagCount += 1
            currentRowWidth += tagView.frame.width + marginX
            
            switch alignment {
            case .leading: fallthrough // switch must be exahutive
            case .left:
                currentRowView.frame.origin.x = 0
            case .center:
                currentRowView.frame.origin.x = (frameWidth - (currentRowWidth - marginX)) / 2
            case .trailing: fallthrough // switch must be exahutive
            case .right:
                currentRowView.frame.origin.x = frameWidth - (currentRowWidth - marginX)
            }
            currentRowView.frame.size.width = currentRowWidth
            currentRowView.frame.size.height = max(tagViewHeight, currentRowView.frame.height)
        }
        
        rows = finnallyRowCount

        if needsShowExpandButton {
            if showExpandButton {
                self.expandButton?.frame = CGRect(x: frameWidth - expandButtonWidth, y: CGFloat(finnallyRowCount - 1) * (tagViewHeight + marginY), width: expandButtonWidth, height: tagViewHeight)
            } else {
                self.expandButton?.frame = CGRect(x: currentRowWidth, y: CGFloat(finnallyRowCount - 1) * (tagViewHeight + marginY), width: expandButtonWidth, height: tagViewHeight)
            }
        } else {
            self.expandButton?.removeFromSuperview()
            self.expandButton = nil
        }
        
        invalidateIntrinsicContentSize()
    }
    
    private func addExpandButton() {
        // Calculate button position
        
        // Create button
        if expandButton == nil {
            expandButton = UIButton(type: .system)
        }
        expandButton?.titleLabel?.font = self.textFont
        
        // Apply custom styles
        updateExpandButtonStyle()
        
        if showExpandButton {
            expandButton?.addTarget(self, action: #selector(toggleExpandCollapse), for: .touchUpInside)
        }
        expandButton?.isUserInteractionEnabled = showExpandButton
        
        if let button = expandButton {
            addSubview(button)
            // Adjust intrinsic content size to accommodate the button
            rows += 1
        }
    }
    
    private func updateExpandButtonStyle() {
        guard let button = expandButton else { return }
        
        button.backgroundColor = expandButtonBackgroundColor
        button.setTitleColor(expandButtonTextColor, for: .normal)
        button.layer.cornerRadius = expandButtonCornerRadius
        button.layer.borderWidth = expandButtonBorderWidth
        button.layer.borderColor = expandButtonBorderColor?.cgColor
        
        // Ensure the button clips to bounds for corner radius
        button.clipsToBounds = expandButtonCornerRadius > 0
    }
    
    private func updateExpandButtonTitle(hiddenTagCount: Int) {
        guard let button = expandButton else { return }
        
        if showExpandButton {
            if isExpanded {
                button.setTitle(collapseButtonTitle, for: .normal)
            } else {
                // Show hidden tag count in collapsed state if enabled
                if showHiddenTagCount {
                    button.setTitle("\(expandButtonTitle)+\(hiddenTagCount)", for: .normal)
                } else {
                    button.setTitle(expandButtonTitle, for: .normal)
                }
            }
        } else {
            button.setTitle("+\(hiddenTagCount)", for: .normal)
        }
    }
    
    @objc private func toggleExpandCollapse() {
        isExpanded = !isExpanded
        rearrangeViews()
        self.delegate?.tagListView?(self, isExpanded: isExpanded)
    }
    
    // MARK: - Manage tags
    
    override open var intrinsicContentSize: CGSize {
        var height = CGFloat(rows) * (tagViewHeight + marginY)
        if rows > 0 {
            height -= marginY
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
    
    private func createNewTagView(_ title: String, isSelected: Bool = false) -> AMTagView {
        let tagView: AMTagView
        if cachesTagViews.count > 0, let cache = cachesTagViews.popLast() {
            tagView = cache
        } else {
            tagView = AMTagView(title: title)
        }
        
        tagView.setTitle(title, for: .normal)
        tagView.textColor = textColor
        tagView.selectedTextColor = selectedTextColor
        tagView.tagBackgroundColor = tagBackgroundColor
        tagView.highlightedBackgroundColor = tagHighlightedBackgroundColor
        tagView.selectedBackgroundColor = tagSelectedBackgroundColor
        tagView.titleLineBreakMode = tagLineBreakMode
        tagView.cornerRadius = cornerRadius
        tagView.borderWidth = borderWidth
        tagView.borderColor = borderColor
        tagView.selectedBorderColor = selectedBorderColor
        tagView.paddingX = paddingX
        tagView.paddingY = paddingY
        tagView.textFont = textFont
        tagView.removeIconLineWidth = removeIconLineWidth
        tagView.removeButtonIconSize = removeButtonIconSize
        tagView.enableRemoveButton = enableRemoveButton
        tagView.removeButtonStyle = removeButtonStyle
        tagView.removeIconLineColor = removeIconLineColor
        tagView.removeButtonBackgroundColor = removeButtonBackgroundColor
        tagView.addTarget(self, action: #selector(tagPressed(_:)), for: .touchUpInside)
        tagView.removeButton.addTarget(self, action: #selector(removeButtonPressed(_:)), for: .touchUpInside)
        tagView.isSelected = isSelected
        
        // On long press, deselect all tags except this one
        tagView.onLongPress = { [unowned self] this in
            self.tagViews.forEach {
                $0.isSelected = $0 == this
            }
        }
        
        return tagView
    }

    @discardableResult
    open func addTag(_ title: String) -> AMTagView {
        defer { rearrangeViews() }
        return addTagView(createNewTagView(title))
    }
    
    @discardableResult
    open func addTags(_ titles: [String]) -> [AMTagView] {
        return addTagViews(titles.map({ createNewTagView($0) }))
    }
    
    @discardableResult
    open func addTags(tags: [(title:String, isSelected: Bool)]) -> [AMTagView] {
        return addTagViews(tags.map({ createNewTagView($0.title, isSelected: $0.isSelected) }))
    }
    
    @discardableResult
    open func addTagView(_ tagView: AMTagView) -> AMTagView {
        defer { rearrangeViews() }
        tagViews.append(tagView)
        tagBackgroundViews.append(UIView(frame: tagView.bounds))
        
        return tagView
    }
    
    @discardableResult
    open func addTagViews(_ tagViewList: [AMTagView]) -> [AMTagView] {
        defer { rearrangeViews() }
        tagViewList.forEach {
            tagViews.append($0)
            tagBackgroundViews.append(UIView(frame: $0.bounds))
        }
        return tagViews
    }

    @discardableResult
    open func insertTag(_ title: String, at index: Int) -> AMTagView {
        return insertTagView(createNewTagView(title), at: index)
    }
    

    @discardableResult
    open func insertTagView(_ tagView: AMTagView, at index: Int) -> AMTagView {
        defer { rearrangeViews() }
        tagViews.insert(tagView, at: index)
        tagBackgroundViews.insert(UIView(frame: tagView.bounds), at: index)
        
        return tagView
    }
    
    open func setTitle(_ title: String, at index: Int) {
        tagViews[index].titleLabel?.text = title
    }
    
    open func removeTag(_ title: String) {
        tagViews.reversed().filter({ $0.currentTitle == title }).forEach(removeTagView)
    }
    
    open func removeTagView(_ tagView: AMTagView) {
        defer { rearrangeViews() }
        
        tagView.removeFromSuperview()
        if let index = tagViews.firstIndex(of: tagView) {
            tagViews.remove(at: index)
            tagBackgroundViews.remove(at: index)
        }
    }
    
    open func removeAllTags() {
        defer {
            cachesTagViews.append(contentsOf:tagViews)
            tagViews = []
            tagBackgroundViews = []
            rearrangeViews()
        }
        
        let views: [UIView] = tagViews + tagBackgroundViews
        views.forEach { $0.removeFromSuperview() }
    }

    open func selectedTags() -> [AMTagView] {
        return tagViews.filter { $0.isSelected }
    }
    
    // MARK: - Events
    
    @objc func tagPressed(_ sender: AMTagView!) {
        sender.onTap?(sender)
        delegate?.tagPressed?(sender.currentTitle ?? "", tagView: sender, sender: self, index: sender.tag)
    }
    
    @objc func removeButtonPressed(_ closeButton: AMCloseButton!) {
        if let tagView = closeButton.tagView {
            delegate?.tagRemoveButtonPressed?(tagView.currentTitle ?? "", tagView: tagView, sender: self, index: closeButton.tag)
        }
    }
}
