//
//  AMFormSubmitable.swift
//  aitrade
//

import UIKit

/// 提交表单前校验协议：点击后校验 `referenceFormView` 下所有可校验控件，通过后执行 `submit`
public protocol AMFormSubmitable: AnyObject {
    /// 表单容器；校验时会遍历其子树中所有 `AMFormValidatable` 组件
    var referenceFormView: UIView? { get set }

    /// 全部校验通过后的提交回调
    var submit: (() -> Void)? { get set }
}

extension UIView {
    /// 深度优先收集自身及子树中所有 `AMFormValidatable` 组件
    /// - Returns: 可校验组件列表（先父后子）
    public func am_collectFormValidatables() -> [any AMFormValidatable] {
        var result: [any AMFormValidatable] = []
        if let validatable = self as? any AMFormValidatable {
            result.append(validatable)
        }
        for subview in subviews {
            result.append(contentsOf: subview.am_collectFormValidatables())
        }
        return result
    }
}
