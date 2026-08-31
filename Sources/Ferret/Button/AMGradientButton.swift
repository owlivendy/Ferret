//
//  AMGradientButton.swift
//  ChinaHomelife247
//
//  Created by meotech on 2025/8/22.
//  Copyright © 2025 吕欢. All rights reserved.
//

import UIKit

/// 渐变背景按钮，同时兼容传统 `setTitle` 与 `UIButton.Configuration`。
///
/// 渐变放在底层 `UIView` 中，避免直接往 `UIButton.layer` 插入 `CAGradientLayer`
///（Configuration 模式下会盖住标题）。
open class AMGradientButton: UIButton {
    /// 渐变背景视图（始终置于最底层）
    private let gradientBackgroundView = AMGradientView(frame: .zero)

    /// 渐变颜色数组
    open var gradientColors: [UIColor] = [] {
        didSet {
            gradientBackgroundView.gradientColors = gradientColors
        }
    }

    /// 渐变起始点（默认左中）
    open var startPoint: CGPoint = CGPoint(x: 0, y: 0.5) {
        didSet {
            gradientBackgroundView.startPoint = startPoint
        }
    }

    /// 渐变结束点（默认右中）
    open var endPoint: CGPoint = CGPoint(x: 1, y: 0.5) {
        didSet {
            gradientBackgroundView.endPoint = endPoint
        }
    }

    /// 颜色分布位置
    open var locations: [NSNumber]? {
        didSet {
            gradientBackgroundView.locations = locations
        }
    }

    /// 按钮圆角
    open var cornerRadius: CGFloat = 8 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

    /// 创建渐变按钮
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    /// 便捷初始化，可直接设置渐变属性
    /// - Parameters:
    ///   - colors: 渐变色
    ///   - startPoint: 起始点
    ///   - endPoint: 结束点
    public convenience init(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) {
        self.init(frame: .zero)
        self.gradientColors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    private func setupButton() {
        gradientBackgroundView.isUserInteractionEnabled = false
        insertSubview(gradientBackgroundView, at: 0)

        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        gradientBackgroundView.frame = bounds
        // Configuration 更新子视图层级后，确保渐变仍在标题之下
        sendSubviewToBack(gradientBackgroundView)
    }

    open override var isHighlighted: Bool {
        didSet {
            guard isEnabled else { return }
            alpha = isHighlighted ? 0.8 : 1.0
        }
    }

    open override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.45
            gradientBackgroundView.alpha = isEnabled ? 1.0 : 0.55
        }
    }
}
