//
//  AMPassthroughView.swift
//  Ferret
//

import UIKit

/// 点击穿透视图：开启 `allowHitTestPassthrough` 后，自身空白区域不拦截触摸，子视图仍可响应。
///
/// 典型场景：全屏透明/半透明遮罩盖在页面上，需要点击下方按钮，同时保留遮罩上的浮动控件可点。
@IBDesignable
open class AMPassthroughView: UIView {

    /// 是否允许点击穿透自身空白区域（默认 `false`）
    @IBInspectable open var allowHitTestPassthrough: Bool = false

    /// 创建穿透视图
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
        allowHitTestPassthrough = false
    }

    /// 命中测试：开启穿透时仅将事件交给命中的子视图
    /// - Parameters:
    ///   - hitPoint: 相对本视图的触点
    ///   - event: 关联事件，可为 `nil`
    /// - Returns: 应接收触摸的视图；空白区域返回 `nil` 以穿透
    open override func hitTest(_ hitPoint: CGPoint, with event: UIEvent?) -> UIView? {
        guard allowHitTestPassthrough else {
            return super.hitTest(hitPoint, with: event)
        }

        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01 else {
            return nil
        }

        guard point(inside: hitPoint, with: event) else {
            return nil
        }

        for subview in subviews.reversed() {
            let converted = subview.convert(hitPoint, from: self)
            if let hit = subview.hitTest(converted, with: event) {
                return hit
            }
        }

        return nil
    }
}
