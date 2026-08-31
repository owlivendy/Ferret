//
//  AMAttributedStringBuilder.swift
//  Ferret
//

import UIKit

/// 分段拼接 `NSAttributedString`，后一段未指定的颜色 / 字号 / 字重会继承前一段
public class AMAttributedStringBuilder {
    private var parts: [(text: String, fontSize: CGFloat?, weight: UIFont.Weight?, color: UIColor?, paragraphStyle: NSParagraphStyle?)] = []

    /// 创建空构建器
    public init() {}

    /// 以一段文本创建构建器
    /// - Parameters:
    ///   - text: 文本
    ///   - color: 文字颜色
    ///   - fontSize: 字号
    ///   - weight: 字重
    ///   - paragraphStyle: 段落样式
    public convenience init(
        _ text: String,
        color: UIColor? = nil,
        fontSize: CGFloat? = nil,
        weight: UIFont.Weight? = nil,
        paragraphStyle: NSParagraphStyle? = nil
    ) {
        self.init()
        parts.append((text, fontSize, weight, color, paragraphStyle))
    }

    /// 追加一段文本；未指定的样式继承上一段
    /// - Parameters:
    ///   - text: 文本
    ///   - color: 文字颜色
    ///   - fontSize: 字号
    ///   - weight: 字重
    ///   - paragraphStyle: 段落样式
    /// - Returns: 当前构建器，便于链式调用
    @discardableResult
    public func append(
        _ text: String,
        color: UIColor? = nil,
        fontSize: CGFloat? = nil,
        weight: UIFont.Weight? = nil,
        paragraphStyle: NSParagraphStyle? = nil
    ) -> AMAttributedStringBuilder {
        var inheritFontSize = fontSize
        var inheritWeight = weight
        var inheritColor = color

        if let last = parts.last {
            if inheritFontSize == nil { inheritFontSize = last.fontSize }
            if inheritWeight == nil { inheritWeight = last.weight }
            if inheritColor == nil { inheritColor = last.color }
        }

        parts.append((text, inheritFontSize, inheritWeight, inheritColor, paragraphStyle))
        return self
    }

    /// 拼接两个构建器；右侧未指定的样式继承左侧最后一段
    /// - Parameters:
    ///   - lhs: 左侧构建器
    ///   - rhs: 右侧构建器
    /// - Returns: 新的构建器
    public static func + (
        lhs: AMAttributedStringBuilder,
        rhs: AMAttributedStringBuilder
    ) -> AMAttributedStringBuilder {
        let builder = AMAttributedStringBuilder()
        builder.parts = lhs.parts

        if let last = lhs.parts.last {
            var newParts: [(String, CGFloat?, UIFont.Weight?, UIColor?, NSParagraphStyle?)] = []
            for (t, fs, w, c, p) in rhs.parts {
                let fontSize = fs ?? last.fontSize
                let weight = w ?? last.weight
                let color = c ?? last.color
                let paragraphStyle = p ?? last.paragraphStyle
                newParts.append((t, fontSize, weight, color, paragraphStyle))
            }
            builder.parts.append(contentsOf: newParts)
        } else {
            builder.parts.append(contentsOf: rhs.parts)
        }

        return builder
    }

    /// 输出富文本
    public var attribute: NSAttributedString {
        let result = NSMutableAttributedString()
        for part in parts {
            var attrs: [NSAttributedString.Key: Any] = [:]

            if let size = part.fontSize {
                let weight = part.weight ?? .regular
                attrs[.font] = UIFont.systemFont(ofSize: size, weight: weight)
            }
            if let color = part.color {
                attrs[.foregroundColor] = color
            }
            if let paragraphStyle = part.paragraphStyle {
                attrs[.paragraphStyle] = paragraphStyle
            }

            result.append(NSAttributedString(string: part.text, attributes: attrs))
        }
        return result
    }
}

public extension String {
    /// 将字符串转为富文本构建器
    /// - Parameters:
    ///   - color: 文字颜色
    ///   - fontSize: 字号
    ///   - weight: 字重
    ///   - paragraphStyle: 段落样式
    /// - Returns: 富文本构建器
    func attribute(
        color: UIColor? = nil,
        fontSize: CGFloat? = nil,
        weight: UIFont.Weight? = nil,
        paragraphStyle: NSParagraphStyle? = nil
    ) -> AMAttributedStringBuilder {
        return AMAttributedStringBuilder(
            self,
            color: color,
            fontSize: fontSize,
            weight: weight,
            paragraphStyle: paragraphStyle
        )
    }
}
