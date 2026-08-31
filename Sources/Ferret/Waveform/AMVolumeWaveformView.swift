//
//  AMVolumeWaveformView.swift
//  Ferret
//

import UIKit

/// 音量波形视图：按归一化音量绘制竖条正弦波动。
open class AMVolumeWaveformView: UIView {

    /// 外部设置的音量（建议 0 ~ 1；小于 0.3 视为静音）
    open var level: CGFloat = 0.0 {
        didSet {
            let normalized: CGFloat
            if level < 0.3 {
                normalized = 0.0
            } else {
                normalized = (level - 0.2) / 0.7
            }
            targetAmplitude = max(0, min(1, normalized))
        }
    }

    private var lineLayers: [CALayer] = []
    private var displayLink: CADisplayLink?

    private var phase: CGFloat = 0
    private var targetAmplitude: CGFloat = 0
    private var currentAmplitude: CGFloat = 0

    private let lineHeight: CGFloat = 6

    /// 创建波形视图
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    /// 按当前宽度创建竖条图层
    open override func layoutSubviews() {
        super.layoutSubviews()

        if !lineLayers.isEmpty { return }

        let lineWidth: CGFloat = 3
        let spacing: CGFloat = 5
        let count = Int(bounds.width / spacing)

        for i in 0..<count {
            let lineLayer = CALayer()
            lineLayer.backgroundColor = UIColor.white.cgColor
            lineLayer.frame = CGRect(
                x: CGFloat(i) * spacing,
                y: bounds.midY,
                width: lineWidth,
                height: lineHeight
            )
            lineLayer.cornerRadius = lineWidth / 2
            lineLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            layer.addSublayer(lineLayer)
            lineLayers.append(lineLayer)
        }
    }

    /// 开始波形动画
    open func startAnimation() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(updateWave))
            displayLink?.add(to: .main, forMode: .common)
        }
    }

    /// 停止波形动画
    open func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateWave() {
        phase += 0.15

        currentAmplitude += (targetAmplitude - currentAmplitude) * 0.1

        let baseHeight: CGFloat = bounds.height - 8

        for (i, line) in lineLayers.enumerated() {
            let x = CGFloat(i)
            let value = sin((x / 10.0) + phase)

            var height = baseHeight * (value * currentAmplitude)

            let flicker = sin(phase * 12 + x) * 2
            let jitter = CGFloat.random(in: -4...4) + flicker
            height += jitter * max(0.5, currentAmplitude)

            line.bounds.size.height = max(lineHeight, abs(height))
            line.position.y = bounds.midY
        }
    }

    deinit {
        stopAnimation()
    }
}
