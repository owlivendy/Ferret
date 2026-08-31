//
//  AMMarkdownView.swift
//  Flamingo
//
//  Created by xiaofei shen on 2025/8/30.
//

import UIKit
import Markdown

/// Markdown 渲染样式配置
public nonisolated struct AMMarkdownViewStyle {
    // MARK: - Table style
    /// 表格斑马纹：偶数行背景色（不含表头）
    public var tableRowEvenBackgroundColor: UIColor = .white
    /// 表格斑马纹：奇数行背景色（不含表头）
    public var tableRowOddBackgroundColor: UIColor = UIColor.hex(string: "#FFF7F4")
    /// 表头背景色
    public var tableHeaderBackgroundColor: UIColor = .systemGray6
    /// 表头字体（会覆盖表头单元格内部 attributedText 的 font）
    public var tableHeaderFont: UIFont = .systemFont(ofSize: 16, weight: .semibold)
    
    //MARK: - paragrah style
    /// 通用段落样式：正文、标题、表格文本等未单独覆盖时都会继承该样式。
    public var paragrahStyle: NSParagraphStyle
    /// 列表段落样式
    public var listParagrahStyle: NSParagraphStyle
    /// 块级元素（段落、标题、列表、表格）之间的垂直间距；建议为行间距的 1.5~2 倍。
    public var blockSpacing: CGFloat = 18
    
    //MARK: font
    /// 正文基础字体：普通文本、列表文本、表格内容等默认使用该字体。
    public var baseFont: UIFont = .systemFont(ofSize: 16)
    /// 代码字体：代码块与内联代码优先使用等宽字体，便于对齐与阅读。
    public var codeFont: UIFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    /// 一级标题字号
    public var heading1Font: UIFont = .systemFont(ofSize: 26, weight: .bold)
    /// 二级标题字号
    public var heading2Font: UIFont = .systemFont(ofSize: 22, weight: .bold)
    /// 三级标题字号
    public var heading3Font: UIFont = .systemFont(ofSize: 20, weight: .bold)
    /// 四级及以下标题字号
    public var headingSmallFont: UIFont = .systemFont(ofSize: 18, weight: .semibold)

    // MARK: - Code block style
    /// 代码块背景色（需明显区别于聊天气泡底色；气泡为白色时用系统灰）
    public var codeBlockBackgroundColor: UIColor = UIColor.hex(string: "#F2F2F7")
    /// 代码块圆角
    public var codeBlockCornerRadius: CGFloat = 10
    /// 代码块内边距
    public var codeBlockContentInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    /// 代码块正文字色
    public var codeBlockTextColor: UIColor = .label
    /// 纯文本代码块（```text / 无语言）使用正文字体；其它语言使用等宽字体
    public var prefersProportionalFontForPlainCodeBlock: Bool = true

    // MARK: - BlockQuote style
    /// BlockQuote 背景色（默认透明，仅保留左侧竖线）
    public var blockQuoteBackgroundColor: UIColor = .clear
    /// BlockQuote 左侧竖线颜色
    public var blockQuoteBarColor: UIColor = UIColor.systemGray3
    /// BlockQuote 左侧竖线宽度
    public var blockQuoteBarWidth: CGFloat = 3
    /// BlockQuote 内边距；左侧为 0，竖线顶到内容前缘
    public var blockQuoteContentInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    /// BlockQuote 圆角（无背景时无视觉效果）
    public var blockQuoteCornerRadius: CGFloat = 0
    /// BlockQuote 竖线与正文间距
    public var blockQuoteBarSpacing: CGFloat = 10
    
    public var isDebug = false
    
    /// 默认样式
    public nonisolated static let `default`: AMMarkdownViewStyle = AMMarkdownViewStyle()
    
    /// 创建默认 Markdown 样式
    public init() {
        let _paragrahstyle = NSMutableParagraphStyle()
        _paragrahstyle.lineSpacing = 6
        _paragrahstyle.paragraphSpacing = 10
        paragrahStyle = _paragrahstyle
        
        let _listParagrahstyle = NSMutableParagraphStyle()
        _listParagrahstyle.lineSpacing = 4
        _listParagrahstyle.paragraphSpacing = 8
        _listParagrahstyle.firstLineHeadIndent = 0
        _listParagrahstyle.headIndent = 0
        listParagrahStyle = _listParagrahstyle
    }
}

/// 主视图：用于渲染 Markdown Document（不使用 UIStackView 版本）
open class AMMarkdownView: UIView {
    private let container = UIView() // 用于承载所有子元素的容器
    private var lastSubview: UIView? // 记录上一个添加的子视图，用于约束布局
    private var reuseTextView = [UITextView]()

    /// 当前渲染样式
    public let markdownStyle: AMMarkdownViewStyle
    
    /// 链接点击回调
    public var onLinkTapped:((URL) -> Void)?
    
    /// 创建 Markdown 渲染视图
    /// - Parameters:
    ///   - frame: 初始 frame
    ///   - markdownStyle: 渲染样式，默认 `.default`
    public init(frame: CGRect, markdownStyle: AMMarkdownViewStyle = .default) {
        self.markdownStyle = markdownStyle
        super.init(frame: frame)
        setupContainer()
    }
    
    /// 使用 Markdown Document 刷新内容
    /// - Parameter document: Markdown 文档；为 `nil` 时清空内容
    public func update(document: Markdown.Document?) {
        lastSubview = nil
        container.subviews.forEach { v in
            if let tv = v as? UITextView {
                reuseTextView.append(tv)
            }
            v.removeFromSuperview()
        }
        if let document = document {
            render(document)
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContainer() {
        addSubview(container)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        // 容器宽度跟随自身；高度由内容堆叠结果决定
        if container.bounds.width != bounds.width {
            container.frame.size.width = bounds.width
        }
        container.frame.origin = .zero
        if container.frame.height == 0 {
            container.frame.size.height = bounds.height
        }
    }
    
    @objc func onLinkLabelPress(sender: UITapGestureRecognizer) {
        guard let accessibilityIdentifier = sender.view?.accessibilityIdentifier else {return}
        guard let linkUrl = URL.init(string: accessibilityIdentifier) else {return}
        print("\(linkUrl)")
        onLinkTapped?(linkUrl)
    }
    
    // MARK: - 渲染入口
    private func render(_ document: Markdown.Document) {
        let width = max(bounds.width, 1)
        container.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        if markdownStyle.isDebug {
            print("[AMMarkdownView] document: \(document.debugDescription())")
        }

        let items = Self.buildRenderItems(from: document, markdownStyle: markdownStyle)
        for item in items {
            switch item {
            case .richText(let attr):
                addSubviewToContainer(makeTextView(attribute: attr, width: width))
            case .codeBlock(let attr):
                addSubviewToContainer(makeCodeBlockView(attribute: attr, width: width))
            case .blockQuote(let attr):
                let view = AMMarkdownBlockQuoteView(frame: CGRect(x: 0, y: 0, width: width, height: 0), style: markdownStyle)
                view.configure(text: attr, width: width, delegate: self)
                addSubviewToContainer(view)
            case .table(let table):
                addSubviewToContainer(makeTableView(table: table))
            case .thematicBreak:
                addSubviewToContainer(makeThematicBreakView(width: width))
            }
        }
        finalizeContainerLayout(width: width)
    }

    /// 根据最后一个子视图结算容器高度
    private func finalizeContainerLayout(width: CGFloat) {
        let height = lastSubview?.frame.maxY ?? 0
        container.frame = CGRect(x: 0, y: 0, width: width, height: height)
        if bounds.height != height || bounds.width != width {
            bounds.size = CGSize(width: width, height: height)
        }
    }

    // 向容器添加子视图并用 AMFrameLayout 做 frame 布局
    private func addSubviewToContainer(_ subview: UIView) {
        let width = max(container.bounds.width, bounds.width, 1)
        if subview.frame.width <= 0 {
            subview.frame.size.width = width
        }

        container.addSubview(subview)
        subview.am.make { make in
            make.size.equalToSize(size: CGSize(width: width, height: subview.frame.height))
            if let last = lastSubview {
                make.top.equalTo(sameLevelView: last.am.bottom).offset(markdownStyle.blockSpacing)
            } else {
                make.top.equalToSuper(view: container.am.top)
            }
            make.leading.equalToSuper(view: container.am.leading)
        }
        lastSubview = subview
    }
    
    private func makeTextView(attribute: NSAttributedString, width: CGFloat) -> UITextView {
        let textView: UITextView
        
        if let tv = self.reuseTextView.popLast() {
            textView = tv
        } else {
            textView = UITextView(frame: .zero)
            textView.backgroundColor = .clear
            textView.isEditable = false
            textView.isSelectable = true
            textView.isScrollEnabled = false
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.delegate = self
            textView.dataDetectorTypes = []
        }
        
        textView.attributedText = attribute
        let size = AMMarkdownView.heightWithAttiribute(
            attribute,
            width: width,
            markdownStyle: markdownStyle,
            addCommonPragraph: false
        )
        textView.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
        
        return textView
    }
    
    private func makeCodeBlockView(attribute: NSAttributedString, width: CGFloat) -> UIView {
        let inset = markdownStyle.codeBlockContentInset
        let contentWidth = max(width - inset.left - inset.right, 1)

        let wrapper = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        wrapper.backgroundColor = markdownStyle.codeBlockBackgroundColor
        wrapper.layer.cornerRadius = markdownStyle.codeBlockCornerRadius
        wrapper.layer.cornerCurve = .continuous
        wrapper.clipsToBounds = true

        // 代码块使用独立 TextView，避免复用正文 TextView 的样式残留
        let textView = UITextView(frame: .zero)
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.dataDetectorTypes = []
        textView.attributedText = attribute

        let size = AMMarkdownView.heightWithAttiribute(
            attribute,
            width: contentWidth,
            markdownStyle: markdownStyle,
            addCommonPragraph: false
        )
        textView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: size.height)

        wrapper.addSubview(textView)
        textView.am.make { make in
            make.size.equalToSize(size: textView.frame.size)
            make.top.equalToSuper(view: wrapper.am.top).offset(inset.top)
            make.leading.equalToSuper(view: wrapper.am.leading).offset(inset.left)
        }
        wrapper.frame.size.height = size.height + inset.top + inset.bottom
        return wrapper
    }

    private func makeThematicBreakView(width: CGFloat) -> UIView {
        let wrapper = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 12))
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.separator
        wrapper.addSubview(line)
        line.am.make { make in
            make.size.equalToSize(size: CGSize(width: width, height: 1.0 / UIScreen.main.scale))
            make.centerY.equalToSuper(view: wrapper.am.centerY)
            make.leading.equalToSuper(view: wrapper.am.leading)
        }
        return wrapper
    }

    private func makeBlockQuoteView(quote: BlockQuote, width: CGFloat) -> UIView {
        let attr = Self.attributedText(forBlockQuote: quote, baseFont: markdownStyle.baseFont, markdownStyle: markdownStyle)
        let view = AMMarkdownBlockQuoteView(frame: CGRect(x: 0, y: 0, width: width, height: 0), style: markdownStyle)
        view.configure(text: attr, width: width, delegate: self)
        return view
    }

    // MARK: - 表格渲染（frame 布局）
    private func makeTableView(table: Table) -> UIView {
        let availableWidth = max(bounds.width, 1)
        let headCells = Array(table.head.cells)
        let colCount = max(headCells.count, 1)
        
        let layout = Self.computeTableLayout(
            table: table,
            availableWidth: availableWidth,
            markdownStyle: markdownStyle
        )
        
        let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: availableWidth, height: 0))
        scroll.showsHorizontalScrollIndicator = true
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceHorizontal = layout.totalWidth > availableWidth
        scroll.bounces = true
        scroll.isDirectionalLockEnabled = true
        
        let tableContainer = UIView(frame: CGRect(x: 0, y: 0, width: layout.totalWidth, height: 0))
        scroll.addSubview(tableContainer)
        
        var lastRowView: UIView?
        var totalHeight: CGFloat = 0
        
        let headerRow = makeTableRow(
            headCells,
            colCount: colCount,
            colWidths: layout.colWidths,
            isHeader: true,
            rowIndex: 0
        )
        tableContainer.addSubview(headerRow)
        headerRow.frame.origin = .zero
        lastRowView = headerRow
        totalHeight = headerRow.frame.maxY
        
        var bodyIndex = 0
        for row in table.body.rows {
            bodyIndex += 1
            let cells = Array(row.cells)
            let rowView = makeTableRow(
                cells,
                colCount: colCount,
                colWidths: layout.colWidths,
                isHeader: false,
                rowIndex: bodyIndex
            )
            tableContainer.addSubview(rowView)
            rowView.am.make { make in
                make.size.equalToSize(size: rowView.frame.size)
                if let last = lastRowView {
                    make.top.equalTo(sameLevelView: last.am.bottom)
                } else {
                    make.top.equalToSuper(view: tableContainer.am.top)
                }
                make.leading.equalToSuper(view: tableContainer.am.leading)
            }
            lastRowView = rowView
            totalHeight = rowView.frame.maxY
        }
        
        tableContainer.frame.size.height = totalHeight
        scroll.contentSize = CGSize(width: layout.totalWidth, height: totalHeight)
        scroll.frame.size.height = totalHeight
        return scroll
    }
    
    // 辅助方法：渲染单行 TableRow（frame 布局）
    private func makeTableRow(
        _ cells: [Table.Cell],
        colCount: Int,
        colWidths: [CGFloat],
        isHeader: Bool,
        rowIndex: Int
    ) -> UIView {
        let rowView = UIView(frame: .zero)
        rowView.clipsToBounds = true
        
        if isHeader {
            rowView.backgroundColor = markdownStyle.tableHeaderBackgroundColor
        } else {
            let even = (rowIndex % 2 == 0)
            rowView.backgroundColor = even ? markdownStyle.tableRowEvenBackgroundColor : markdownStyle.tableRowOddBackgroundColor
        }
        
        var lastCellView: UIView?
        var maxHeight: CGFloat = 0
        let lineColor = UIColor.hex(string: "#E9E9E9")
        let lineWidth = 1.0 / UIScreen.main.scale
        
        let widths: [CGFloat] = (colWidths.count >= colCount)
        ? Array(colWidths.prefix(colCount))
        : (colWidths + Array(repeating: Self.tableMinColWidth, count: max(0, colCount - colWidths.count)))
        
        func buildCellView(content: NSAttributedString?, col: Int, width: CGFloat, height: CGFloat, isHeader: Bool) -> UIView {
            let cell = AMMarkdownTableCellView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            cell.backgroundColor = .clear
            
            let label = UILabel(frame: .zero)
            label.numberOfLines = 0
            if isHeader, let content {
                let attr = NSMutableAttributedString(attributedString: content)
                attr.addAttribute(.font, value: markdownStyle.tableHeaderFont, range: NSRange(location: 0, length: attr.length))
                label.attributedText = attr
            } else {
                label.attributedText = content
            }
            label.textAlignment = .center
            label.backgroundColor = .clear
            cell.addSubview(label)
            label.am.make { make in
                make.size.equalToSize(size: CGSize(width: max(width - 20, 1), height: max(height - 16, 1)))
                make.top.equalToSuper(view: cell.am.top).offset(8)
                make.leading.equalToSuper(view: cell.am.leading).offset(10)
            }
            
            cell.lineColor = lineColor
            cell.lineWidth = lineWidth
            cell.drawTop = (rowIndex == 0)
            cell.drawLeft = (col == 0)
            cell.drawRight = true
            cell.drawBottom = true
            return cell
        }
        
        var cellHeights: [CGFloat] = Array(repeating: 0, count: colCount)
        var cellContents: [NSAttributedString?] = Array(repeating: nil, count: colCount)
        for col in 0..<colCount {
            if col < cells.count {
                let attr = AMMarkdownView.attributedText(for: cells[col], baseFont: markdownStyle.baseFont)
                cellContents[col] = attr
                let textWidth = max(1, widths[col] - 20)
                let h = AMMarkdownView.heightWithAttiribute(attr, width: textWidth, markdownStyle: markdownStyle, addCommonPragraph: false).height
                cellHeights[col] = h + 16
                maxHeight = max(maxHeight, cellHeights[col])
            }
        }
        
        for col in 0..<colCount {
            let cellView = buildCellView(
                content: cellContents[col],
                col: col,
                width: widths[col],
                height: maxHeight,
                isHeader: isHeader
            )
            rowView.addSubview(cellView)
            cellView.am.make { make in
                make.size.equalToSize(size: CGSize(width: widths[col], height: maxHeight))
                make.top.equalToSuper(view: rowView.am.top)
                if let last = lastCellView {
                    make.leading.equalTo(sameLevelView: last.am.trailing)
                } else {
                    make.leading.equalToSuper(view: rowView.am.leading)
                }
            }
            lastCellView = cellView
        }
        
        let totalWidth = widths.reduce(0, +)
        rowView.frame = CGRect(x: 0, y: 0, width: totalWidth, height: maxHeight)
        return rowView
    }
    
}

// MARK: - Table layout helpers
private extension AMMarkdownView {
    struct TableLayout {
        let colWidths: [CGFloat]
        let totalWidth: CGFloat
    }
    
    nonisolated static let tableMinColWidth: CGFloat = 88
    nonisolated static let tableMaxColWidth: CGFloat = 260
    
    nonisolated static func computeTableLayout(
        table: Table,
        availableWidth: CGFloat,
        markdownStyle: AMMarkdownViewStyle
    ) -> TableLayout {
        let headCells = Array(table.head.cells)
        let colCount = max(headCells.count, 1)
        
        // 采样：表头 + 前若干行，避免大表全量测量
        let maxSampleRows = 8
        let bodyRows = Array(table.body.rows.prefix(maxSampleRows))
        
        var cols: [[NSAttributedString]] = Array(repeating: [], count: colCount)
        
        func addRowCells(_ cells: [Table.Cell]) {
            for i in 0..<colCount {
                guard i < cells.count else { continue }
                let attr = AMMarkdownView.attributedText(for: cells[i], baseFont: markdownStyle.baseFont)
                cols[i].append(attr)
            }
        }
        
        addRowCells(headCells)
        for r in bodyRows {
            addRowCells(Array(r.cells))
        }
        
        let lineInset: CGFloat = 20 // 与 label 左右 inset 对齐
        var widths: [CGFloat] = []
        widths.reserveCapacity(colCount)
        
        for i in 0..<colCount {
            var w: CGFloat = tableMinColWidth
            for attr in cols[i] {
                let size = AMMarkdownView.heightWithAttiribute(attr, width: tableMaxColWidth - lineInset, markdownStyle: markdownStyle, addCommonPragraph: false)
                // boundingRect 的 width 在短文本时可能偏小；加上 padding
                w = max(w, min(tableMaxColWidth, size.width + lineInset))
            }
            widths.append(w)
        }
        
        // 如果列总宽小于可用宽度：不强行拉伸（保持内容宽），横滑自然不会出现
        let total = widths.reduce(0, +)
        return TableLayout(colWidths: widths, totalWidth: total)
    }
}

//MARK: UITextViewDelegate
extension AMMarkdownView: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        onLinkTapped?(URL)
        return false
    }
    
}

// MARK: - 渲染项构建（render / height 共用）
private extension AMMarkdownView {
    enum RenderItem {
        case richText(NSAttributedString)
        case codeBlock(NSAttributedString)
        case blockQuote(NSAttributedString)
        case table(Table)
        case thematicBreak
    }

    /// 将 Document 转为统一渲染项，避免 render 与 height 两套逻辑漂移
    nonisolated static func buildRenderItems(
        from document: Markdown.Document,
        markdownStyle: AMMarkdownViewStyle
    ) -> [RenderItem] {
        var items: [RenderItem] = []
        let pendingText = NSMutableAttributedString()

        func appendBlockSpacingIfNeeded() {
            guard pendingText.length > 0 else { return }
            pendingText.append(NSAttributedString(string: "\n"))
        }

        func appendCommonParagraphStyle(_ attr: NSMutableAttributedString) {
            guard attr.length > 0 else { return }
            attr.addAttribute(
                .paragraphStyle,
                value: markdownStyle.paragrahStyle,
                range: NSRange(location: 0, length: attr.length)
            )
        }

        func flushPendingTextIfNeeded() {
            guard pendingText.length > 0 else { return }
            items.append(.richText(NSAttributedString(attributedString: pendingText)))
            pendingText.setAttributedString(NSAttributedString())
        }

        func appendParagraph(_ para: Paragraph) {
            appendBlockSpacingIfNeeded()
            let attr = NSMutableAttributedString(
                attributedString: attributedText(for: para, baseFont: markdownStyle.baseFont)
            )
            appendCommonParagraphStyle(attr)
            pendingText.append(attr)
        }

        func appendHeading(_ heading: Heading) {
            flushPendingTextIfNeeded()
            let font: UIFont
            switch heading.level {
            case 1: font = markdownStyle.heading1Font
            case 2: font = markdownStyle.heading2Font
            case 3: font = markdownStyle.heading3Font
            default: font = markdownStyle.headingSmallFont
            }
            let attr = NSMutableAttributedString(
                attributedString: attributedText(for: heading, baseFont: font)
            )
            let headingStyle = NSMutableParagraphStyle()
            headingStyle.lineSpacing = 4
            headingStyle.paragraphSpacing = 6
            if attr.length > 0 {
                attr.addAttribute(
                    .paragraphStyle,
                    value: headingStyle,
                    range: NSRange(location: 0, length: attr.length)
                )
            }
            items.append(.richText(attr))
        }

        func appendCodeBlock(_ code: CodeBlock) {
            flushPendingTextIfNeeded()
            // 保留原文换行与 `-` 字符，不要再走列表解析；去掉围栏闭合带来的尾部空行
            var codeText = code.code
            while codeText.last == "\n" || codeText.last == "\r" {
                codeText.removeLast()
            }
            let language = (code.language ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let isPlainTextBlock = language.isEmpty || language == "text" || language == "plaintext"
            let font: UIFont
            if markdownStyle.prefersProportionalFontForPlainCodeBlock && isPlainTextBlock {
                font = markdownStyle.baseFont.withSize(markdownStyle.baseFont.pointSize - 3)
            } else {
                font = markdownStyle.codeFont
            }
            let codeStyle = NSMutableParagraphStyle()
            codeStyle.lineSpacing = 2
            codeStyle.paragraphSpacing = 2
            let attr = NSMutableAttributedString(string: codeText, attributes: [
                .font: font,
                .foregroundColor: markdownStyle.codeBlockTextColor,
                .paragraphStyle: codeStyle
            ])
            items.append(.codeBlock(attr))
        }

        func appendList(_ list: ListItemContainer, ordered: Bool) {
            flushPendingTextIfNeeded()
            let listText = NSMutableAttributedString()
            let listItems = Array(list.listItems)
            for (idx, item) in listItems.enumerated() {
                let bullet = ordered ? "\(idx + 1). " : "• "
                let lines = attributedTextForListItem(for: item, baseFont: markdownStyle.baseFont)
                for (jdx, line) in lines.enumerated() {
                    let dealt: NSMutableAttributedString
                    if jdx == 0 {
                        dealt = manipulateListItemAttribute(
                            attribute: line,
                            bullet: bullet,
                            markdownStyle: markdownStyle,
                            bulletFont: ordered
                                ? .systemFont(ofSize: markdownStyle.baseFont.pointSize, weight: .semibold)
                                : markdownStyle.baseFont
                        )
                    } else {
                        dealt = manipulateListItemAttribute(
                            attribute: line,
                            markdownStyle: markdownStyle
                        )
                    }
                    listText.append(dealt)
                    if jdx != lines.count - 1 {
                        listText.append(NSAttributedString(string: "\n"))
                    }
                }
                if idx != listItems.count - 1 {
                    listText.append(NSAttributedString(string: "\n"))
                }
            }
            if listText.length > 0 {
                items.append(.richText(listText))
            }
        }

        for block in document.children {
            switch block {
            case let para as Paragraph:
                appendParagraph(para)
            case let heading as Heading:
                appendHeading(heading)
            case let code as CodeBlock:
                appendCodeBlock(code)
            case let list as UnorderedList:
                appendList(list, ordered: false)
            case let list as OrderedList:
                appendList(list, ordered: true)
            case let quote as BlockQuote:
                flushPendingTextIfNeeded()
                items.append(.blockQuote(
                    attributedText(
                        forBlockQuote: quote,
                        baseFont: markdownStyle.baseFont,
                        markdownStyle: markdownStyle
                    )
                ))
            case let table as Table:
                flushPendingTextIfNeeded()
                items.append(.table(table))
            case is ThematicBreak:
                flushPendingTextIfNeeded()
                items.append(.thematicBreak)
            default:
                break
            }
        }

        flushPendingTextIfNeeded()
        return items
    }
}

// MARK: - 内联文本处理
extension AMMarkdownView {
    static func extraSpacingAttributedString(_ height: CGFloat) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: 0, width: 1, height: max(0, height))
        return NSAttributedString(attachment: attachment)
    }

    /// BlockQuote 多段落保留换行
    nonisolated static func attributedText(
        forBlockQuote quote: BlockQuote,
        baseFont: UIFont,
        markdownStyle: AMMarkdownViewStyle
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let children = Array(quote.children)
        for (index, child) in children.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n"))
            }
            result.append(attributedText(for: child, baseFont: baseFont))
        }
        if result.length > 0 {
            result.addAttribute(
                .paragraphStyle,
                value: markdownStyle.paragrahStyle,
                range: NSRange(location: 0, length: result.length)
            )
        }
        return result
    }

    nonisolated static func attributedTextForListItem(for block: Markup, baseFont: UIFont) -> [NSMutableAttributedString] {
        var lines = [NSMutableAttributedString]()
        let children = Array(block.children)
        var tmpAttr = NSMutableAttributedString()

        func flushTmpIfNeeded() {
            guard tmpAttr.length > 0 else { return }
            lines.append(tmpAttr)
            tmpAttr = NSMutableAttributedString()
        }

        for child in children {
            switch child {
            case let text as Markdown.Text:
                tmpAttr.append(NSAttributedString(string: text.string, attributes: [.font: baseFont]))

            case let strong as Strong:
                let sub = attributedText(for: strong, baseFont: baseFont)
                let bold = NSMutableAttributedString(attributedString: sub)
                bold.addAttributes(
                    [.font: UIFont.boldSystemFont(ofSize: baseFont.pointSize)],
                    range: NSRange(location: 0, length: bold.length)
                )
                tmpAttr.append(bold)

            case let em as Emphasis:
                let sub = attributedText(for: em, baseFont: baseFont)
                let italic = NSMutableAttributedString(attributedString: sub)
                italic.addAttributes(
                    [.font: UIFont.italicSystemFont(ofSize: baseFont.pointSize)],
                    range: NSRange(location: 0, length: italic.length)
                )
                tmpAttr.append(italic)

            case let strike as Strikethrough:
                let sub = attributedText(for: strike, baseFont: baseFont)
                let struck = NSMutableAttributedString(attributedString: sub)
                struck.addAttributes(
                    [.strikethroughStyle: NSUnderlineStyle.single.rawValue],
                    range: NSRange(location: 0, length: struck.length)
                )
                tmpAttr.append(struck)

            case let code as InlineCode:
                tmpAttr.append(NSAttributedString(string: code.code, attributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular),
                    .backgroundColor: UIColor.systemGray5,
                    .foregroundColor: UIColor.systemRed
                ]))

            case let link as Link:
                let sub = attributedText(for: link, baseFont: baseFont)
                let linked = NSMutableAttributedString(attributedString: sub)
                linked.addAttributes([
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: link.destination ?? ""
                ], range: NSRange(location: 0, length: linked.length))
                tmpAttr.append(linked)

            case is SoftBreak:
                tmpAttr.append(NSAttributedString(string: " ", attributes: [.font: baseFont]))

            case is LineBreak:
                flushTmpIfNeeded()

            case is Paragraph:
                flushTmpIfNeeded()
                lines.append(contentsOf: attributedTextForListItem(for: child, baseFont: baseFont))

            case let nested as UnorderedList:
                flushTmpIfNeeded()
                lines.append(contentsOf: nestedListLines(nested, ordered: false, baseFont: baseFont))

            case let nested as OrderedList:
                flushTmpIfNeeded()
                lines.append(contentsOf: nestedListLines(nested, ordered: true, baseFont: baseFont))

            default:
                tmpAttr.append(attributedText(for: child, baseFont: baseFont))
            }
        }

        flushTmpIfNeeded()
        return lines
    }

    nonisolated private static func nestedListLines(
        _ list: ListItemContainer,
        ordered: Bool,
        baseFont: UIFont
    ) -> [NSMutableAttributedString] {
        var lines: [NSMutableAttributedString] = []
        let items = Array(list.listItems)
        for (idx, item) in items.enumerated() {
            let bullet = ordered ? "\(idx + 1). " : "• "
            let nested = attributedTextForListItem(for: item, baseFont: baseFont)
            for (jdx, line) in nested.enumerated() {
                let prefix = jdx == 0 ? "    \(bullet)" : "        "
                let row = NSMutableAttributedString(string: prefix, attributes: [.font: baseFont])
                row.append(line)
                lines.append(row)
            }
        }
        return lines
    }

    nonisolated static func attributedText(for block: Markup, baseFont: UIFont) -> NSAttributedString {
        // SoftBreak / LineBreak / 纯叶子节点
        if block is SoftBreak {
            return NSAttributedString(string: " ", attributes: [.font: baseFont])
        }
        if block is LineBreak {
            return NSAttributedString(string: "\n", attributes: [.font: baseFont])
        }
        if let text = block as? Markdown.Text {
            return NSAttributedString(string: text.string, attributes: [.font: baseFont])
        }
        if let code = block as? InlineCode {
            return NSAttributedString(string: code.code, attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular),
                .backgroundColor: UIColor.systemGray5,
                .foregroundColor: UIColor.systemRed
            ])
        }

        let result = NSMutableAttributedString()
        for child in block.children {
            switch child {
            case let text as Markdown.Text:
                result.append(NSAttributedString(string: text.string, attributes: [.font: baseFont]))

            case let strong as Strong:
                let sub = attributedText(for: strong, baseFont: baseFont)
                let bold = NSMutableAttributedString(attributedString: sub)
                bold.addAttributes(
                    [.font: UIFont.boldSystemFont(ofSize: baseFont.pointSize)],
                    range: NSRange(location: 0, length: bold.length)
                )
                result.append(bold)

            case let em as Emphasis:
                let sub = attributedText(for: em, baseFont: baseFont)
                let italic = NSMutableAttributedString(attributedString: sub)
                italic.addAttributes(
                    [.font: UIFont.italicSystemFont(ofSize: baseFont.pointSize)],
                    range: NSRange(location: 0, length: italic.length)
                )
                result.append(italic)

            case let strike as Strikethrough:
                let sub = attributedText(for: strike, baseFont: baseFont)
                let struck = NSMutableAttributedString(attributedString: sub)
                struck.addAttributes(
                    [.strikethroughStyle: NSUnderlineStyle.single.rawValue],
                    range: NSRange(location: 0, length: struck.length)
                )
                result.append(struck)

            case let code as InlineCode:
                result.append(NSAttributedString(string: code.code, attributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular),
                    .backgroundColor: UIColor.systemGray5,
                    .foregroundColor: UIColor.systemRed
                ]))

            case let link as Link:
                let sub = attributedText(for: link, baseFont: baseFont)
                let linked = NSMutableAttributedString(attributedString: sub)
                linked.addAttributes([
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: link.destination ?? ""
                ], range: NSRange(location: 0, length: linked.length))
                result.append(linked)

            case is SoftBreak:
                result.append(NSAttributedString(string: " ", attributes: [.font: baseFont]))

            case is LineBreak:
                result.append(NSAttributedString(string: "\n", attributes: [.font: baseFont]))

            case let image as Image:
                let alt = image.title ?? image.source ?? "image"
                result.append(NSAttributedString(string: "[\(alt)]", attributes: [
                    .font: baseFont,
                    .foregroundColor: UIColor.secondaryLabel
                ]))

            default:
                result.append(attributedText(for: child, baseFont: baseFont))
            }
        }

        return result
    }
}

// MARK: - 高度计算（与 render 共用 buildRenderItems）
public extension AMMarkdownView {
    /// 预计算 Markdown 文档渲染尺寸
    /// - Parameters:
    ///   - document: Markdown 文档
    ///   - width: 可用宽度
    ///   - markdownStyle: 渲染样式
    /// - Returns: 内容尺寸
    nonisolated static func height(
        for document: Markdown.Document,
        width: CGFloat,
        markdownStyle: AMMarkdownViewStyle = .default
    ) -> CGSize {
        let items = buildRenderItems(from: document, markdownStyle: markdownStyle)
        guard !items.isEmpty else {
            return CGSize(width: width, height: 0)
        }

        var totalHeight: CGFloat = 0
        for (index, item) in items.enumerated() {
            if index > 0 {
                totalHeight += markdownStyle.blockSpacing
            }
            switch item {
            case .richText(let attr):
                totalHeight += heightWithAttiribute(
                    attr,
                    width: width,
                    markdownStyle: markdownStyle,
                    addCommonPragraph: false
                ).height
            case .codeBlock(let attr):
                let inset = markdownStyle.codeBlockContentInset
                let textHeight = heightWithAttiribute(
                    attr,
                    width: max(width - inset.left - inset.right, 1),
                    markdownStyle: markdownStyle,
                    addCommonPragraph: false
                ).height
                totalHeight += textHeight + inset.top + inset.bottom
            case .blockQuote(let attr):
                totalHeight += AMMarkdownBlockQuoteView.measuredHeight(
                    text: attr,
                    width: width,
                    style: markdownStyle
                )
            case .table(let table):
                totalHeight += tableHeight(table, width: width, markdownStyle: markdownStyle)
            case .thematicBreak:
                totalHeight += 12
            }
        }

        return CGSize(width: width, height: ceil(totalHeight))
    }

    nonisolated private static func tableHeight(
        _ table: Table,
        width: CGFloat,
        markdownStyle: AMMarkdownViewStyle
    ) -> CGFloat {
        let layout = computeTableLayout(table: table, availableWidth: width, markdownStyle: markdownStyle)
        let colWidths = layout.colWidths
        let headColCount = table.head.cells.reduce(0) { acc, _ in acc + 1 }
        let colCount = max(colWidths.count, headColCount)

        func rowHeight(for cells: [Table.Cell]) -> CGFloat {
            var hMax: CGFloat = 0
            for i in 0..<min(cells.count, colCount) {
                let attr = attributedText(for: cells[i], baseFont: markdownStyle.baseFont)
                let textWidth = max(1, (i < colWidths.count ? colWidths[i] : tableMinColWidth) - 20)
                let h = heightWithAttiribute(
                    attr,
                    width: textWidth,
                    markdownStyle: markdownStyle,
                    addCommonPragraph: false
                ).height
                hMax = max(hMax, h + 16)
            }
            return max(hMax, 16)
        }

        var tableHeight: CGFloat = 0
        tableHeight += rowHeight(for: Array(table.head.cells))
        for row in table.body.rows {
            tableHeight += rowHeight(for: Array(row.cells))
        }
        return tableHeight
    }

    internal nonisolated static func manipulateListItemAttribute(
        attribute: NSMutableAttributedString,
        bullet: String? = nil,
        markdownStyle: AMMarkdownViewStyle,
        bulletFont: UIFont? = nil
    ) -> NSMutableAttributedString {
        let attr = NSMutableAttributedString()
        if let bullet {
            let font = bulletFont ?? UIFont.systemFont(ofSize: 16)
            attr.append(NSAttributedString(string: bullet, attributes: [.font: font]))
            attr.append(attribute)

            let paragrahStyle = NSMutableParagraphStyle()
            paragrahStyle.setParagraphStyle(markdownStyle.listParagrahStyle)
            attr.addAttribute(.paragraphStyle, value: paragrahStyle, range: NSRange(location: 0, length: attr.length))
        } else {
            attr.append(attribute)

            let paragrahStyle = NSMutableParagraphStyle()
            paragrahStyle.setParagraphStyle(markdownStyle.listParagrahStyle)
            paragrahStyle.firstLineHeadIndent = markdownStyle.listParagrahStyle.headIndent
            paragrahStyle.headIndent = markdownStyle.listParagrahStyle.headIndent
            attr.addAttribute(.paragraphStyle, value: paragrahStyle, range: NSRange(location: 0, length: attr.length))
        }
        return attr
    }

    internal nonisolated static func heightWithAttiribute(
        _ attirbute: NSAttributedString,
        width: CGFloat,
        markdownStyle: AMMarkdownViewStyle,
        addCommonPragraph: Bool
    ) -> CGSize {
        let dealedAttr = NSMutableAttributedString(attributedString: attirbute)
        if addCommonPragraph {
            dealedAttr.addAttribute(
                .paragraphStyle,
                value: markdownStyle.paragrahStyle,
                range: NSRange(location: 0, length: dealedAttr.length)
            )
        }
        let size = dealedAttr.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
}
