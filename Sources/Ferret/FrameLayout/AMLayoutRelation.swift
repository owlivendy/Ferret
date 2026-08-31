//
//  AMLayoutRelation.swift
//  Ferret
//

import CoreGraphics

/// Frame 布局关系（相对父视图或同级视图）
public protocol AMLayoutRelation {
    /// 对齐到父视图锚点
    /// - Parameter superview: 父视图锚点
    /// - Returns: 当前锚点，便于链式调用
    func equalToSuper(view superview: AMFrameLayoutAnchor) -> AMFrameLayoutAnchor
    /// 对齐到同级视图锚点
    /// - Parameter sameLevelView: 同级视图锚点
    /// - Returns: 当前锚点，便于链式调用
    func equalTo(sameLevelView: AMFrameLayoutAnchor) -> AMFrameLayoutAnchor
    /// 设置偏移
    /// - Parameter value: 偏移量
    /// - Returns: 当前锚点，便于链式调用
    func offset(_ value: CGFloat) -> AMFrameLayoutAnchor
    /// 立刻应用布局
    func apply()
}
