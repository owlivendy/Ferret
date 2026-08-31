//
//  AMButton.swift
//  Ferret
//

import UIKit

/// 通用按钮基类：扩展最小点击区域，并支持按 `UIControl.State` 设置背景色 / 边框。
open class AMButton: UIButton {

    /// 最小可点击区域尺寸，默认 `44×44`（符合 Apple HIG）
    open var minimumHitSize: CGSize = CGSize(width: 44, height: 44)

    private var backgroundColors: [UInt: UIColor] = [:]
    private var borderColors: [UInt: UIColor] = [:]
    private var borderWidths: [UInt: CGFloat] = [:]

    /// 创建按钮
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 为指定状态设置背景色；传 `nil` 则清除该状态配置
    /// - Parameters:
    ///   - color: 背景色
    ///   - state: 控件状态
    open func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        if let color {
            backgroundColors[state.rawValue] = color
        } else {
            backgroundColors.removeValue(forKey: state.rawValue)
        }
        applyAppearance()
    }

    /// 为指定状态设置边框色；传 `nil` 则清除该状态配置
    /// - Parameters:
    ///   - color: 边框色
    ///   - state: 控件状态
    open func setBorderColor(_ color: UIColor?, for state: UIControl.State) {
        if let color {
            borderColors[state.rawValue] = color
        } else {
            borderColors.removeValue(forKey: state.rawValue)
        }
        applyAppearance()
    }

    /// 为指定状态设置边框宽度
    /// - Parameters:
    ///   - width: 边框宽度
    ///   - state: 控件状态
    open func setBorderWidth(_ width: CGFloat, for state: UIControl.State) {
        borderWidths[state.rawValue] = width
        applyAppearance()
    }

    /// 高亮变化时刷新状态外观
    open override var isHighlighted: Bool {
        didSet { applyAppearance() }
    }

    /// 选中变化时刷新状态外观
    open override var isSelected: Bool {
        didSet { applyAppearance() }
    }

    /// 启用变化时刷新状态外观
    open override var isEnabled: Bool {
        didSet { applyAppearance() }
    }

    /// 布局时同步当前状态的背景与边框
    open override func layoutSubviews() {
        super.layoutSubviews()
        applyAppearance()
    }

    /// 判断触点是否落在扩展后的可点击区域内
    /// - Parameters:
    ///   - point: 相对本视图的触点坐标
    ///   - event: 关联事件，可为 `nil`
    /// - Returns: 触点是否命中扩展后的区域
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let hitBounds = expandedHitBounds()
        guard hitBounds != bounds else {
            return super.point(inside: point, with: event)
        }
        return hitBounds.contains(point)
    }

    /// 计算扩展后的命中矩形：宽高不足 `minimumHitSize` 时向四周补齐
    private func expandedHitBounds() -> CGRect {
        let widthInset = max(0, minimumHitSize.width - bounds.width) / 2
        let heightInset = max(0, minimumHitSize.height - bounds.height) / 2
        guard widthInset > 0 || heightInset > 0 else {
            return bounds
        }
        return bounds.insetBy(dx: -widthInset, dy: -heightInset)
    }

    /// 按当前 `state` 应用背景色与边框；无精确匹配时回退到 `.normal`
    private func applyAppearance() {
        if let bgColor = resolvedValue(from: backgroundColors) {
            backgroundColor = bgColor
        }
        if let borderColor = resolvedValue(from: borderColors) {
            layer.borderColor = borderColor.cgColor
        }
        if let borderWidth = resolvedValue(from: borderWidths) {
            layer.borderWidth = borderWidth
        }
    }

    private func resolvedValue<T>(from map: [UInt: T]) -> T? {
        map[state.rawValue] ?? map[UIControl.State.normal.rawValue]
    }
}
