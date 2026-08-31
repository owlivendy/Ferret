//
//  AMLayoutAnchor.swift
//  Ferret
//

import UIKit

/// Frame 布局锚点集合
public protocol AMLayoutAnchor {
    /// 左边缘
    var left: AMFrameLayoutAnchor { get }
    /// 右边缘
    var right: AMFrameLayoutAnchor { get }
    /// 上边缘
    var top: AMFrameLayoutAnchor { get }
    /// 下边缘
    var bottom: AMFrameLayoutAnchor { get }
    /// 水平中心
    var centerX: AMFrameLayoutAnchor { get }
    /// 垂直中心
    var centerY: AMFrameLayoutAnchor { get }
    /// 阅读方向起始边
    var leading: AMFrameLayoutAnchor { get }
    /// 阅读方向结束边
    var trailing: AMFrameLayoutAnchor { get }
    /// 尺寸
    var size: AMFrameLayoutAnchor { get }
    /// 被布局的视图
    var view: UIView { get }
}

public extension AMLayoutAnchor {
    /// 左边缘
    var left: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .left)
    }
    /// 右边缘
    var right: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .right)
    }
    /// 上边缘
    var top: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .top)
    }
    /// 下边缘
    var bottom: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .bottom)
    }
    /// 水平中心
    var centerX: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .centerX)
    }
    /// 垂直中心
    var centerY: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .centerY)
    }
    /// 阅读方向起始边
    var leading: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .leading)
    }
    /// 阅读方向结束边
    var trailing: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .trailing)
    }
    /// 尺寸
    var size: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .size)
    }
}
