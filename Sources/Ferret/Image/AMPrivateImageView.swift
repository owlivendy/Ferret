//
//  AMPrivateImageView.swift
//  Ferret
//

import UIKit

/// 防截屏图片视图：将图片放在 `UITextField` 安全层中，系统截屏/录屏时不会露出内容。
open class AMPrivateImageView: UIView {

    private let imageView = UIImageView(frame: .zero)

    // 借用 UITextField 的安全层实现截屏隐藏
    private let textField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.isSecureTextEntry = true
        return textField
    }()

    private var containerView: UIView? {
        textField.subviews.first(where: { type(of: $0).description().contains("CanvasView") })
    }

    /// 展示的图片
    public var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }

    /// 创建防截屏图片视图
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(textField)
        textField.isUserInteractionEnabled = false

        if let secureContainer = containerView {
            secureContainer.addSubview(imageView)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true

            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }

    /// 同步安全输入框尺寸
    open override func layoutSubviews() {
        super.layoutSubviews()
        textField.frame = bounds
    }
}
