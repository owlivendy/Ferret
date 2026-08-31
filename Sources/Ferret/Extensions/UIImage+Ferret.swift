//
//  UIImage+Ferret.swift
//  Ferret
//

import UIKit

extension UIImage {
    /// 从 Ferret 资源包加载图片
    /// - Parameter name: Asset 名称
    /// - Returns: 图片；找不到时返回 `nil`
    static func ferret(_ name: String) -> UIImage? {
        UIImage(named: name, in: .module, compatibleWith: nil)
    }
}
