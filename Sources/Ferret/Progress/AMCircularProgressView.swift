//
//  AMCircularProgressView.swift
//  Ferret
//

import UIKit

/// 圆环进度条，从顶部顺时针绘制。
open class AMCircularProgressView: UIView {
    private let progressLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()

    /// 当前进度，范围建议 `0...1`
    open var progress: CGFloat = 0 {
        didSet { progressLayer.strokeEnd = progress }
    }

    /// 圆环线宽，默认 3
    open var lineWidth: CGFloat = 3 {
        didSet { setNeedsLayout() }
    }

    /// 进度条颜色
    open var progressColor: UIColor = UIColor.hex(string: "E2E8F0") {
        didSet { progressLayer.strokeColor = progressColor.cgColor }
    }

    /// 轨道颜色，默认透明
    open var trackColor: UIColor = .clear {
        didSet { trackLayer.strokeColor = trackColor.cgColor }
    }

    /// 创建圆环进度条
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 按当前尺寸重建圆环路径
    open override func layoutSubviews() {
        super.layoutSubviews()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        )

        trackLayer.path = path.cgPath
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = lineWidth
        if trackLayer.superlayer == nil {
            layer.addSublayer(trackLayer)
        }

        progressLayer.path = path.cgPath
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.strokeEnd = progress
        progressLayer.lineCap = .round
        if progressLayer.superlayer == nil {
            layer.addSublayer(progressLayer)
        }
    }

    /// 更新进度
    /// - Parameters:
    ///   - value: 目标进度
    ///   - animated: 是否使用 0.3s 动画
    open func setProgress(_ value: CGFloat, animated: Bool = true) {
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = value
            animation.duration = 0.3
            progressLayer.add(animation, forKey: "progressAnim")
        }
        progressLayer.strokeEnd = value
        progress = value
    }
}
