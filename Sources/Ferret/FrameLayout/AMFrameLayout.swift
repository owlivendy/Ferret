//
//  AMFrameLayout.swift
//  Ferret
//

import UIKit

/// AMFrameLayout 布局闭包
public typealias AMFrameLayoutMakerCallback = ((AMFrameLayoutMaker) -> Void)

extension UIView {
    /// Frame 布局入口，用法类似 SnapKit 的 `snp`
    public var am: AMFrameLayout {
        return AMFrameLayout(view: self)
    }
}

/// Frame 布局 DSL，通过 `view.am.make { }` 设置子视图 frame
@objcMembers
public class AMFrameLayout: NSObject, AMLayoutAnchor {
    /// 被布局的视图
    public var view: UIView

    /// 创建布局入口
    /// - Parameter view: 目标视图
    public init(view: UIView) {
        self.view = view
    }

    /// 执行布局闭包
    /// - Parameter callback: 在闭包内通过 `make.left` / `make.top` 等设置约束
    public func make(_ callback: AMFrameLayoutMakerCallback) {
        callback(AMFrameLayoutMaker.init(view: view))
    }
}
