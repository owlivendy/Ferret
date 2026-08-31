//
//  UIView+FrameHelpers.swift
//  Ferret
//

import UIKit

extension UIView {
    /// 中心点 X（供 AMFrameLayout 读写）
    public var centerX: CGFloat {
        get { center.x }
        set { center.x = newValue }
    }

    /// 中心点 Y（供 AMFrameLayout 读写）
    public var centerY: CGFloat {
        get { center.y }
        set { center.y = newValue }
    }
}
