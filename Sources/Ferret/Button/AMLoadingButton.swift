//
//  AMLoadingButton.swift
//  Ferret
//

import UIKit

/// 带旋转 loading 图标的按钮，loading 期间禁用点击。
open class AMLoadingButton: UIControl {

    /// 是否处于加载中
    open var isLoading: Bool = false {
        didSet { updateLoadingState() }
    }

    /// loading 图标，默认使用 Ferret 内置 `loading-white-style1`
    open var loadingImage: UIImage? = UIImage.ferret("loading-white-style1") {
        didSet { imageView.image = loadingImage }
    }

    /// 正常态文案
    open var text: String? {
        didSet { label.text = text }
    }

    /// loading 态文案；为 `nil` 时沿用 `text`
    open var loadingText: String?

    /// 文案颜色
    open var textColor: UIColor? {
        didSet { label.textColor = textColor }
    }

    /// 文案字体
    open var font: UIFont? {
        didSet { label.font = font }
    }

    private let imageView = UIImageView(frame: .zero)
    private let label = UILabel(frame: .zero)
    private let hStack = UIStackView(frame: .zero)

    /// 创建 loading 按钮
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 10
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.isUserInteractionEnabled = false
        addSubview(hStack)

        imageView.image = loadingImage
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(imageView)

        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            hStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            hStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            hStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            hStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        updateLoadingState()
    }

    private func updateLoadingState() {
        if isLoading {
            label.text = loadingText ?? text
            imageView.isHidden = false
            startLoadingAnimation()
            isUserInteractionEnabled = false
        } else {
            label.text = text
            imageView.isHidden = true
            stopLoadingAnimation()
            isUserInteractionEnabled = true
        }
    }

    private func startLoadingAnimation() {
        guard imageView.layer.animation(forKey: "rotationAnimation") == nil else { return }
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = Float.infinity
        imageView.layer.add(rotation, forKey: "rotationAnimation")
    }

    private func stopLoadingAnimation() {
        imageView.layer.removeAnimation(forKey: "rotationAnimation")
    }
}
