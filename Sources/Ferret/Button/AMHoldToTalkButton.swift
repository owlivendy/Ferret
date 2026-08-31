//
//  AMHoldToTalkButton.swift
//  Ferret
//

import UIKit

/// 按住说话按钮，根据上滑距离区分发送 / 取消
open class AMHoldToTalkButton: UIButton {
    /// 按住状态
    public enum HoldStatus {
        /// 初始
        case uninitial
        /// 上滑未超阈值（松开发送）
        case inner
        /// 上滑超过阈值（松手取消）
        case outer
    }

    /// 触发取消的上滑阈值（pt）
    private let slideThreshold: CGFloat = 60
    /// 滑动检测容错（pt）
    private let slideTolerance: CGFloat = 5

    private var isHolding = false
    private var startPoint: CGPoint = .zero
    private var currentSlideDistance: CGFloat = 0

    private var holdStatus: HoldStatus = .uninitial {
        didSet {
            guard holdStatus != oldValue else { return }
            onHoldStatusChange?(holdStatus)
        }
    }

    /// 开始按住
    public var onHoldBegan: (() -> Void)?
    /// 松手（携带最终状态）
    public var onHoldEnded: ((HoldStatus) -> Void)?
    /// 状态变化
    public var onHoldStatusChange: ((HoldStatus) -> Void)?

    /// 主动停止（权限失败等场景）
    public func activeStop() {
        handleRelease()
    }

    /// 创建按住说话按钮
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        adjustsImageWhenHighlighted = false
        showsTouchWhenHighlighted = false
    }

    /// 是否可用；禁用时半透明，提示不可按住说话
    open override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.4
        }
    }

    /// 手指按下，进入按住态
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isEnabled, let touch = touches.first else { return }
        isHolding = true
        startPoint = touch.location(in: superview)
        currentSlideDistance = 0
        holdStatus = .inner
        onHoldBegan?()
    }

    /// 手指移动，按上滑距离切换 inner / outer
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard isHolding || isEnabled, let touch = touches.first else { return }
        let currentPoint = touch.location(in: superview)
        currentSlideDistance = startPoint.y - currentPoint.y
        if currentSlideDistance >= (slideThreshold - slideTolerance) {
            if holdStatus != .outer {
                holdStatus = .outer
            }
        } else if holdStatus != .inner {
            holdStatus = .inner
        }
    }

    /// 手指抬起，结束按住
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard isHolding || isEnabled else { return }
        handleRelease()
    }

    /// 触摸取消，结束按住
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard isHolding || isEnabled else { return }
        handleRelease()
    }

    private func handleRelease() {
        guard isHolding else { return }
        isHolding = false
        onHoldEnded?(holdStatus)
        holdStatus = .uninitial
    }
}
