//
//  AMFixedTagListView.swift
//  aitrade
//

import UIKit

/// 固定列数 Tag 列表选中模式
@objc public enum AMFixedTagListSelectionMode: Int {
    /// 单选（再次点击已选项可取消）
    case single
    /// 多选
    case multiple
}

/// `AMFixedTagListView` 代理
@objc public protocol AMFixedTagListViewDelegate: AnyObject {
  /// Tag 被点击
  /// - Parameters:
  ///   - tagListView: 列表视图
  ///   - title: 文案
  ///   - index: 索引
  ///   - isSelected: 点击后的选中状态
  @objc optional func fixedTagListView(
    _ tagListView: AMFixedTagListView,
    didSelectTag title: String,
    at index: Int,
    isSelected: Bool
  )

  /// 选中项变化
  /// - Parameters:
  ///   - tagListView: 列表视图
  ///   - selectedIndexes: 选中索引
  ///   - selectedTitles: 选中文案
  @objc optional func fixedTagListView(
    _ tagListView: AMFixedTagListView,
    selectionDidChange selectedIndexes: [Int],
    selectedTitles: [String]
  )
}

/// 每行固定个数、等宽排列的 Tag 列表，支持单选 / 多选
@IBDesignable
open class AMFixedTagListView: UIView {
    /// 每行 Tag 个数（至少 1）
    @IBInspectable open var tagsPerRow: Int = 3 {
        didSet {
            tagsPerRow = max(1, tagsPerRow)
            rearrangeViews()
        }
    }

    /// Tag 高度
    @IBInspectable open dynamic var tagHeight: CGFloat = 32 {
        didSet {
            tagHeight = max(1, tagHeight)
            rearrangeViews()
        }
    }

    /// 水平间距
    @IBInspectable open dynamic var marginX: CGFloat = 8 {
        didSet { rearrangeViews() }
    }

    /// 垂直间距
    @IBInspectable open dynamic var marginY: CGFloat = 8 {
        didSet { rearrangeViews() }
    }

    /// 圆角
    @IBInspectable open dynamic var cornerRadius: CGFloat = 8 {
        didSet { applyStyleToAllTags() }
    }

    /// 边框宽度
    @IBInspectable open dynamic var borderWidth: CGFloat = 1 {
        didSet { applyStyleToAllTags() }
    }

    /// 未选中背景色
    @IBInspectable open dynamic var tagBackgroundColor: UIColor = UIColor.hex(string: "#FFFFFF") {
        didSet { applyStyleToAllTags() }
    }

    /// 未选中边框色
    @IBInspectable open dynamic var tagBorderColor: UIColor = UIColor.hex(string: "#E5E7EB") {
        didSet { applyStyleToAllTags() }
    }

    /// 未选中文字色
    @IBInspectable open dynamic var tagTextColor: UIColor = UIColor.hex(string: "#242433") {
        didSet { applyStyleToAllTags() }
    }

    /// 选中背景色
    @IBInspectable open dynamic var selectedBackgroundColor: UIColor = UIColor.hex(string: "#FFF0E8") {
        didSet { applyStyleToAllTags() }
    }

    /// 选中边框色
    @IBInspectable open dynamic var selectedBorderColor: UIColor = UIColor.hex(string: "#FF4D1C") {
        didSet { applyStyleToAllTags() }
    }

    /// 选中文字色
    @IBInspectable open dynamic var selectedTextColor: UIColor = UIColor.hex(string: "#FF4D1C") {
        didSet { applyStyleToAllTags() }
    }

    /// 标题字体
    @IBInspectable open dynamic var textFont: UIFont = .systemFont(ofSize: 14, weight: .medium) {
        didSet { applyStyleToAllTags() }
    }

    /// 选中模式
    open var selectionMode: AMFixedTagListSelectionMode = .single {
        didSet {
            if selectionMode == .single, selectedIndexes.count > 1 {
                keepOnlyFirstSelection()
            }
        }
    }

    /// 预设宽度（TableView Cell 高度计算时可先赋值）
    open var presetWidth: CGFloat?

    /// 代理
    open weak var delegate: AMFixedTagListViewDelegate?

    /// 选中变化回调
    open var onSelectionChanged: (([Int], [String]) -> Void)?

    /// 当前选中的 Tag 文案
    open var selectedTagTexts: [String] {
        selectedIndexes.compactMap { index in
            guard tagViews.indices.contains(index) else { return nil }
            return tagViews[index].currentTitle
        }
    }

    /// 当前选中的索引（有序）
    open private(set) var selectedIndexes: [Int] = []

    open private(set) var tagViews: [AMTagView] = []
    open private(set) var rows: Int = 0 {
        didSet { invalidateIntrinsicContentSize() }
    }

    private var tagTitles: [String] = []

    /// 创建固定列 Tag 列表
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    /// 从归档创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open override func layoutSubviews() {
        defer { rearrangeViews() }
        super.layoutSubviews()
    }

    open override var intrinsicContentSize: CGSize {
        let rowCount = rows
        guard rowCount > 0 else {
            return CGSize(width: UIView.noIntrinsicMetric, height: 0)
        }
        let height = CGFloat(rowCount) * tagHeight + CGFloat(rowCount - 1) * marginY
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    // MARK: - Public API

    /// 设置全部 Tag（默认未选中）
    /// - Parameter titles: 文案数组
    open func setTags(_ titles: [String]) {
        setTags(titles.map { (title: $0, isSelected: false) })
    }

    /// 设置全部 Tag 及初始选中状态
    /// - Parameter items: `(文案, 是否选中)` 数组
    open func setTags(_ items: [(title: String, isSelected: Bool)]) {
        removeAllTagsWithoutReload()
        tagTitles = items.map(\.title)
        tagViews = items.map { createTagView(title: $0.title, isSelected: $0.isSelected) }
        syncSelectedIndexesFromViews()
        if selectionMode == .single {
            keepOnlyFirstSelection()
        }
        rearrangeViews()
    }

    /// 设置选中索引（越界项会被忽略）
    /// - Parameter indexes: 目标索引
    open func setSelectedIndexes(_ indexes: [Int]) {
        let valid = Set(indexes.filter { tagViews.indices.contains($0) })
        if selectionMode == .single {
            let single = valid.sorted().prefix(1)
            applySelection(Set(single))
        } else {
            applySelection(valid)
        }
        notifySelectionChanged()
    }

    /// 清空全部 Tag
    open func removeAllTags() {
        tagViews.forEach { $0.removeFromSuperview() }
        tagViews.removeAll()
        tagTitles.removeAll()
        selectedIndexes.removeAll()
        rows = 0
        invalidateIntrinsicContentSize()
    }

    // MARK: - Layout

    private func rearrangeViews() {
        guard tagsPerRow > 0 else { return }

        let frameWidth = presetWidth ?? bounds.width
        guard frameWidth > 0, !tagViews.isEmpty else {
            rows = tagViews.isEmpty ? 0 : Int(ceil(Double(tagViews.count) / Double(tagsPerRow)))
            invalidateIntrinsicContentSize()
            return
        }

        let columns = tagsPerRow
        let tagWidth = (frameWidth - CGFloat(columns - 1) * marginX) / CGFloat(columns)
        let totalRows = Int(ceil(Double(tagViews.count) / Double(columns)))
        rows = totalRows

        for (index, tagView) in tagViews.enumerated() {
            let row = index / columns
            let column = index % columns
            let x = CGFloat(column) * (tagWidth + marginX)
            let y = CGFloat(row) * (tagHeight + marginY)

            tagView.frame = CGRect(x: x, y: y, width: tagWidth, height: tagHeight)
            tagView.tag = index

            if tagView.superview !== self {
                addSubview(tagView)
            }
        }

        invalidateIntrinsicContentSize()
    }

    // MARK: - Tag Factory

    private func createTagView(title: String, isSelected: Bool) -> AMTagView {
        let tagView = AMTagView(title: title)
        tagView.isSelected = isSelected
        tagView.titleLabel?.lineBreakMode = .byTruncatingTail
        tagView.addTarget(self, action: #selector(tagPressed(_:)), for: .touchUpInside)
        applyStyle(to: tagView)
        return tagView
    }

    private func applyStyleToAllTags() {
        tagViews.forEach { applyStyle(to: $0) }
    }

    private func applyStyle(to tagView: AMTagView) {
        tagView.cornerRadius = cornerRadius
        tagView.borderWidth = borderWidth
        tagView.borderColor = tagBorderColor
        tagView.selectedBorderColor = selectedBorderColor
        tagView.tagBackgroundColor = tagBackgroundColor
        tagView.selectedBackgroundColor = selectedBackgroundColor
        tagView.textColor = tagTextColor
        tagView.selectedTextColor = selectedTextColor
        tagView.textFont = textFont
        tagView.paddingX = 8
        tagView.paddingY = 0
        tagView.enableRemoveButton = false
        tagView.titleLabel?.adjustsFontSizeToFitWidth = true
        tagView.titleLabel?.lineBreakMode = .byTruncatingTail
    }

    // MARK: - Selection

    @objc private func tagPressed(_ sender: AMTagView) {
        let index = sender.tag
        guard tagViews.indices.contains(index) else { return }

        switch selectionMode {
        case .single:
            if sender.isSelected {
                sender.isSelected = false
            } else {
                tagViews.forEach { $0.isSelected = false }
                sender.isSelected = true
            }
        case .multiple:
            sender.isSelected.toggle()
        }

        syncSelectedIndexesFromViews()
        notifySelectionChanged()

        let title = sender.currentTitle ?? ""
        delegate?.fixedTagListView?(self, didSelectTag: title, at: index, isSelected: sender.isSelected)
    }

    private func syncSelectedIndexesFromViews() {
        selectedIndexes = tagViews.enumerated().compactMap { index, view in
            view.isSelected ? index : nil
        }
    }

    private func applySelection(_ indexes: Set<Int>) {
        tagViews.enumerated().forEach { index, view in
            view.isSelected = indexes.contains(index)
        }
        syncSelectedIndexesFromViews()
    }

    private func keepOnlyFirstSelection() {
        guard let first = selectedIndexes.first else {
            tagViews.forEach { $0.isSelected = false }
            selectedIndexes.removeAll()
            return
        }
        applySelection([first])
    }

    private func notifySelectionChanged() {
        let titles = selectedTagTexts
        onSelectionChanged?(selectedIndexes, titles)
        delegate?.fixedTagListView?(self, selectionDidChange: selectedIndexes, selectedTitles: titles)
    }

    private func removeAllTagsWithoutReload() {
        tagViews.forEach { $0.removeFromSuperview() }
        tagViews.removeAll()
        tagTitles.removeAll()
        selectedIndexes.removeAll()
        rows = 0
    }
}
