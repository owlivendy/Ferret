//
//  SandboxFilePreviewerController.swift
//  Ferret
//

import QuickLook
import UIKit

/// 沙盒文件或目录项
struct SandboxItem {
    /// 文件或目录名称
    let name: String
    /// 完整路径
    let path: String
    /// 是否为目录
    let isDirectory: Bool
    /// 文件大小（字节），目录为 0
    let size: UInt64
    /// 最后修改日期
    let modificationDate: Date
}

/// 沙盒文件浏览器，支持预览、以纯文本打开、导出与批量删除。
open class SandboxFilePreviewerController: UIViewController, UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDataSource {

    private static let hiddenRootFolderNames: Set<String> = ["StoreKit", "SystemData"]

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var path: String?
    private var items: [SandboxItem] = []
    private var previewFileURL: URL?
    private var isSelectionMode = false
    private var currentPath: String {
        path ?? NSHomeDirectory()
    }

    /// 创建沙盒浏览器
    /// - Parameter path: 起始目录；为 `nil` 时从沙盒根目录开始
    public init(path: String? = nil) {
        self.path = path
        super.init(nibName: nil, bundle: nil)
    }

    /// 不支持从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 搭建列表并加载当前目录
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadItems()
    }

    private func setupUI() {
        title = path == nil ? "沙盒根目录" : URL(fileURLWithPath: currentPath).lastPathComponent
        view.backgroundColor = .white

        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SandboxCell")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "选择", style: .plain, target: self, action: #selector(enterSelectionMode))

        if path == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction))
        }
    }

    private func updateNavigationBarForSelectionMode() {
        if isSelectionMode {
            let deleteItem = UIBarButtonItem(title: "删除", style: .plain, target: self, action: #selector(deleteSelectedItems))
            deleteItem.tintColor = .systemRed
            deleteItem.isEnabled = false
            navigationItem.leftBarButtonItem = deleteItem
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(exitSelectionMode))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "选择", style: .plain, target: self, action: #selector(enterSelectionMode))
            if path == nil {
                navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction))
            } else {
                navigationItem.leftBarButtonItem = nil
            }
        }
    }

    private func updateDeleteButtonState() {
        guard isSelectionMode else { return }
        let count = tableView.indexPathsForSelectedRows?.count ?? 0
        navigationItem.leftBarButtonItem?.title = count > 0 ? "删除(\(count))" : "删除"
        navigationItem.leftBarButtonItem?.isEnabled = count > 0
    }

    private func loadItems() {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: currentPath)

            items = try contents.compactMap { itemName -> SandboxItem? in
                if path == nil, Self.hiddenRootFolderNames.contains(itemName) {
                    return nil
                }
                let itemPath = currentPath + "/" + itemName
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDir) else { return nil }

                let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                let size = attributes[.size] as? UInt64 ?? 0
                let modificationDate = attributes[.modificationDate] as? Date ?? Date()

                return SandboxItem(
                    name: itemName,
                    path: itemPath,
                    isDirectory: isDir.boolValue,
                    size: size,
                    modificationDate: modificationDate
                )
            }

            items.sort { item1, item2 in
                if item1.isDirectory && !item2.isDirectory {
                    return true
                } else if !item1.isDirectory && item2.isDirectory {
                    return false
                } else {
                    return item1.name.localizedCompare(item2.name) == .orderedAscending
                }
            }

            tableView.reloadData()
        } catch {
            let alert = UIAlertController(title: "错误", message: "无法加载目录内容", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        }
    }

    private func formatFileSize(_ size: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func truncateFileName(_ name: String, maxLength: Int) -> String {
        guard name.count > maxLength else { return name }
        let prefixLength = max(0, maxLength - 3)
        return String(name.prefix(prefixLength)) + "..."
    }

    @objc private func closeAction() {
        dismiss(animated: true)
    }

    @objc private func enterSelectionMode() {
        isSelectionMode = true
        tableView.setEditing(true, animated: true)
        updateNavigationBarForSelectionMode()
        updateDeleteButtonState()
        tableView.reloadData()
    }

    @objc private func exitSelectionMode() {
        isSelectionMode = false
        if let selected = tableView.indexPathsForSelectedRows {
            for indexPath in selected {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
        tableView.setEditing(false, animated: true)
        updateNavigationBarForSelectionMode()
        tableView.reloadData()
    }

    @objc private func deleteSelectedItems() {
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows, !selectedIndexPaths.isEmpty else { return }

        let selectedItems = selectedIndexPaths.map { items[$0.row] }
        let previewNames = selectedItems.prefix(5).map(\.name).joined(separator: "\n")
        var message = "将删除 \(selectedItems.count) 项"
        if !previewNames.isEmpty {
            message += "：\n\(previewNames)"
        }
        if selectedItems.count > 5 {
            message += "\n…等共 \(selectedItems.count) 项"
        }

        let alert = UIAlertController(title: "确认删除", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.performDelete(selectedItems: selectedItems)
        })
        present(alert, animated: true)
    }

    private func performDelete(selectedItems: [SandboxItem]) {
        let fileManager = FileManager.default
        var failedItems: [String] = []

        for item in selectedItems {
            do {
                try fileManager.removeItem(atPath: item.path)
            } catch {
                failedItems.append(item.name)
            }
        }

        exitSelectionMode()
        loadItems()

        if !failedItems.isEmpty {
            let alert = UIAlertController(
                title: "部分删除失败",
                message: failedItems.joined(separator: "\n"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        }
    }

    /// 当前目录条目数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    /// 配置文件/目录单元格
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SandboxCell", for: indexPath)
        let item = items[indexPath.row]

        cell.textLabel?.text = truncateFileName(item.name, maxLength: 50)
        cell.detailTextLabel?.text = item.isDirectory ? "目录" : "\(formatFileSize(item.size)) · \(formatDate(item.modificationDate))"
        cell.imageView?.image = item.isDirectory ? UIImage(systemName: "folder.fill") : UIImage(systemName: "doc.text.fill")
        if isSelectionMode {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = item.isDirectory ? .disclosureIndicator : .none
        }

        return cell
    }

    /// 进入子目录或预览文件
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSelectionMode {
            updateDeleteButtonState()
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.row]
        if item.isDirectory {
            let nextController = SandboxFilePreviewerController(path: item.path)
            navigationController?.pushViewController(nextController, animated: true)
        } else {
            openFileWithSystemPreview(at: indexPath)
        }
    }

    /// 选择模式下更新删除按钮状态
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isSelectionMode {
            updateDeleteButtonState()
        }
    }

    /// 选择模式不显示删除滑钮
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    /// 选择模式不额外缩进
    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    /// 文件长按菜单：系统预览、纯文本打开、导出
    public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if isSelectionMode { return nil }

        let item = items[indexPath.row]

        if !item.isDirectory {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                let previewAction = UIAction(title: "系统预览", image: UIImage(systemName: "eye")) { [weak self] _ in
                    self?.openFileWithSystemPreview(at: indexPath)
                }
                let openAsTextAction = UIAction(title: "以纯文本打开", image: UIImage(systemName: "doc.plaintext")) { [weak self] _ in
                    self?.openFileAsPlainText(at: indexPath)
                }
                let exportAction = UIAction(title: "导出", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                    self?.exportFile(at: indexPath)
                }

                return UIMenu(title: "", children: [previewAction, openAsTextAction, exportAction])
            }
        }

        return nil
    }

    /// 固定行高
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44.0
    }

    private func openFileWithSystemPreview(at indexPath: IndexPath) {
        let item = items[indexPath.row]
        previewFileURL = URL(fileURLWithPath: item.path)

        let previewController = QLPreviewController()
        previewController.dataSource = self
        present(previewController, animated: true)
    }

    /// Quick Look 预览数量
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewFileURL == nil ? 0 : 1
    }

    /// Quick Look 预览项
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewFileURL! as QLPreviewItem
    }

    private func openFileAsPlainText(at indexPath: IndexPath) {
        let item = items[indexPath.row]
        let textController = SandboxFileTextViewController(filePath: item.path)
        navigationController?.pushViewController(textController, animated: true)
    }

    private func exportFile(at indexPath: IndexPath) {
        let item = items[indexPath.row]
        let fileURL = URL(fileURLWithPath: item.path)

        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        if let popoverPresentationController = activityViewController.popoverPresentationController {
            if let cell = tableView.cellForRow(at: indexPath) {
                popoverPresentationController.sourceView = cell
                popoverPresentationController.sourceRect = cell.bounds
            }
        }

        present(activityViewController, animated: true)
    }
}
