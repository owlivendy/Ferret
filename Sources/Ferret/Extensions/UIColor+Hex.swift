//
//  UIColor+Hex.swift
//  aitrade
//

import UIKit

extension UIColor {
    /// 使用十六进制字符串创建颜色
    /// - Parameter string: 形如 `#RRGGBB` / `RRGGBB` / `#RRGGBBAA`
    /// - Returns: 解析成功的颜色；失败时返回黑色
    nonisolated static func hex(string: String) -> UIColor {
        var hex = string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value) else {
            return .black
        }

        switch hex.count {
        case 6:
            return UIColor(
                red: CGFloat((value & 0xFF0000) >> 16) / 255,
                green: CGFloat((value & 0x00FF00) >> 8) / 255,
                blue: CGFloat(value & 0x0000FF) / 255,
                alpha: 1
            )
        case 8:
            return UIColor(
                red: CGFloat((value & 0xFF000000) >> 24) / 255,
                green: CGFloat((value & 0x00FF0000) >> 16) / 255,
                blue: CGFloat((value & 0x0000FF00) >> 8) / 255,
                alpha: CGFloat(value & 0x000000FF) / 255
            )
        default:
            return .black
        }
    }
}
