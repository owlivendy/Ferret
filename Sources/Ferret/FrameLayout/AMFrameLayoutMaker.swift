//
//  AMFrameLayoutMaker.swift
//  Ferret
//

import UIKit

/// AMFrameLayout 布局闭包中的 `make` 对象
@objcMembers
public class AMFrameLayoutMaker: NSObject, AMLayoutAnchor {
    /// 被布局的视图
    public var view: UIView

    /// 创建 maker
    /// - Parameter view: 目标视图
    public init(view: UIView) {
        self.view = view
    }
}
