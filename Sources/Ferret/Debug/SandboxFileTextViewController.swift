//
//  SandboxFileTextViewController.swift
//  Ferret
//

import UIKit

/// 以 UTF-8 纯文本方式展示沙盒文件内容
open class SandboxFileTextViewController: UIViewController {

    private enum LoadError: LocalizedError {
        case invalidUTF8
        case readFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidUTF8:
                return "无法以 UTF-8 解码该文件"
            case .readFailed(let message):
                return message
            }
        }
    }

    /// 单次最多解码并展示的字节数，避免超大文件占满内存
    private static let maxDisplayBytes = 1 * 1024 * 1024

    private let filePath: String
    private let textView = UITextView(frame: .zero)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadQueue = DispatchQueue(label: "com.ferret.sandbox.text.load", qos: .userInitiated)

    /// 创建纯文本预览页
    /// - Parameter filePath: 本地文件路径
    public init(filePath: String) {
        self.filePath = filePath
        super.init(nibName: nil, bundle: nil)
    }

    /// 不支持从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 搭建文本视图并异步加载内容
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTextContent()
    }

    private func setupUI() {
        title = URL(fileURLWithPath: filePath).lastPathComponent
        view.backgroundColor = .systemBackground

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.alwaysBounceVertical = true
        textView.dataDetectorTypes = []
        textView.layoutManager.allowsNonContiguousLayout = true

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true

        view.addSubview(textView)
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadTextContent() {
        let fileURL = URL(fileURLWithPath: filePath)
        loadingIndicator.startAnimating()
        textView.isUserInteractionEnabled = false

        loadQueue.async { [weak self] in
            guard let self else { return }

            let result: Result<String, LoadError>
            do {
                let fileSize = (try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64) ?? 0
                let data: Data
                if fileSize > UInt64(Self.maxDisplayBytes) {
                    let handle = try FileHandle(forReadingFrom: fileURL)
                    defer { try? handle.close() }
                    data = handle.readData(ofLength: Self.maxDisplayBytes)
                } else {
                    data = try Data(contentsOf: fileURL)
                }

                guard let text = String(data: data, encoding: .utf8) else {
                    throw LoadError.invalidUTF8
                }

                var displayText = text
                if fileSize > UInt64(Self.maxDisplayBytes) {
                    let sizeText = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
                    let limitText = ByteCountFormatter.string(fromByteCount: Int64(Self.maxDisplayBytes), countStyle: .file)
                    displayText += "\n\n—— 文件共 \(sizeText)，仅展示前 \(limitText) ——"
                }
                result = .success(displayText)
            } catch let error as LoadError {
                result = .failure(error)
            } catch {
                result = .failure(.readFailed("读取文件失败：\(error.localizedDescription)"))
            }

            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.textView.isUserInteractionEnabled = true
                switch result {
                case .success(let text):
                    self.textView.textColor = .label
                    self.textView.text = text
                case .failure(let error):
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ message: String) {
        textView.text = message
        textView.textColor = .secondaryLabel
    }
}
