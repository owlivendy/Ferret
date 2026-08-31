//
//  AMGradientView.swift
//  ChinaHomelife247
//
//  Created by meotech on 2025/10/17.
//  Copyright © 2025 吕欢. All rights reserved.
//

import UIKit

/// 渐变背景视图，通过底层 `CAGradientLayer` 绘制颜色过渡
open class AMGradientView: UIView {
    /// 渐变层
    public let gradientLayer = CAGradientLayer()
    
    /// 渐变颜色数组
    public var gradientColors: [UIColor] = [] {
        didSet {
            updateGradientLayer()
        }
    }
    
    /// 渐变起始点（默认左中）
    public var startPoint: CGPoint = CGPoint(x: 0, y: 0.5) {
        didSet {
            updateGradientLayer()
        }
    }
    
    /// 渐变结束点（默认右中）
    public var endPoint: CGPoint = CGPoint(x: 1, y: 0.5) {
        didSet {
            updateGradientLayer()
        }
    }
    
    /// 颜色分布位置
    public var locations: [NSNumber]? {
        didSet {
            updateGradientLayer()
        }
    }
    
    /// 创建渐变视图
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
        updateGradientLayer()
    }
    
    private func setupButton() {
        // 配置渐变层
        gradientLayer.colors = gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
        gradientLayer.masksToBounds = true
        
        // 添加渐变层到按钮层
        layer.insertSublayer(gradientLayer, at: 0)
        
//        clipsToBounds = true
    }
    
    // 更新渐变层属性
    private func updateGradientLayer() {
        gradientLayer.colors = gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
