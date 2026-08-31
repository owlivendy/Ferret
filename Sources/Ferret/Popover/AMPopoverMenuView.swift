//
//  AMPopoverMenuView.swift
//  Ferret
//

import UIKit

/// 气泡菜单项
open class AMPopoverMenuItem: NSObject {

    /// 菜单标题
    open var title: String = ""
    /// 点击回调
    open var action: (() -> Void)?

    /// 创建菜单项
    /// - Parameters:
    ///   - title: 菜单标题
    ///   - action: 点击回调
    /// - Returns: 菜单项实例
    public static func item(withTitle title: String, action: (() -> Void)?) -> AMPopoverMenuItem {
        let item = AMPopoverMenuItem()
        item.title = title
        item.action = action
        return item
    }
}

/// 基于 `AMPopoverView` 的菜单气泡
open class AMPopoverMenuView: UIView, UITableViewDelegate, UITableViewDataSource {

    /// 菜单宽度，默认 100
    open var menuWidth: CGFloat = 100
    /// 行高，默认 44
    open var rowHeight: CGFloat = 44
    /// 最大高度，默认 5 行
    open var maxHeight: CGFloat = 44 * 5

    private let tableView = UITableView(frame: .zero, style: .plain)
    private weak var popoverView: AMPopoverView?
    private let menuItems: [AMPopoverMenuItem]

    /// 使用菜单项创建气泡菜单
    /// - Parameter menuItems: 菜单项列表
    public init(menuItems: [AMPopoverMenuItem]) {
        self.menuItems = menuItems
        super.init(frame: .zero)
        setupUI()
    }

    /// 不支持从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 显示气泡菜单
    /// - Parameter anchorView: 锚点视图，弹窗以该视图为锚点弹出
    open func show(anchorView: UIView) {
        let itemHeight = CGFloat(menuItems.count) * rowHeight
        let actualHeight = min(itemHeight, maxHeight)

        frame = CGRect(x: 0, y: 0, width: menuWidth, height: actualHeight)
        tableView.isScrollEnabled = actualHeight > maxHeight

        let popover = AMPopoverView(contentView: self)
        popoverView = popover
        popover.show(anchorView: anchorView)
    }

    /// 显示气泡菜单（位置参数版）
    /// - Parameter anchorView: 锚点视图
    open func show(_ anchorView: UIView) {
        show(anchorView: anchorView)
    }

    /// 关闭气泡菜单
    open func hide() {
        popoverView?.hide()
    }

    // MARK: - Private

    private func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - UITableViewDataSource

    /// 菜单行数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        menuItems.count
    }

    /// 配置菜单单元格
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = menuItems[indexPath.row]
        cell.textLabel?.text = item.title
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.font = .systemFont(ofSize: 14)
        cell.textLabel?.textColor = .black
        cell.backgroundColor = .clear
        return cell
    }

    // MARK: - UITableViewDelegate

    /// 行高
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        rowHeight
    }

    /// 选中行后执行对应 action 并关闭菜单
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        menuItems[indexPath.row].action?()
        popoverView?.hide()
    }
}
