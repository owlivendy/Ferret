//
//  AMUIStackPassthroughView.swift
//  Ferret
//

import UIKit

/// 基于 `UIStackView` 的点击穿透容器。
///
/// 与 `AMPassthroughView` 类似，额外处理点击点落在 Stack 布局区域外、但子视图仍可能响应的情况。
@IBDesignable
open class AMUIStackPassthroughView: UIStackView {

    /// 是否允许点击穿透（默认 `false`）
    @IBInspectable open var allowHitTestPassthrough: Bool = false

    /// 创建穿透 Stack 容器
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        allowHitTestPassthrough = false
    }

    /// 命中测试：开启穿透时，区域外仍尝试命中子视图
    /// - Parameters:
    ///   - point: 相对本视图的触点
    ///   - event: 关联事件，可为 `nil`
    /// - Returns: 应接收触摸的视图；未命中子视图时返回 `nil` 以穿透
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard allowHitTestPassthrough else {
            return super.hitTest(point, with: event)
        }

        let pointInsideSelf = bounds.contains(point)

        if !pointInsideSelf {
            for subview in subviews.reversed() {
                let converted = subview.convert(point, from: self)
                if let hit = subview.hitTest(converted, with: event) {
                    return hit
                }
            }
            return nil
        }

        return super.hitTest(point, with: event)
    }
}
