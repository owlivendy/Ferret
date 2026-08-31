//
//  AMToastConfig.swift
//  Ferret
//

import UIKit

/// Toast 全局样式与时长配置
public struct AMToastConfig {
    /// 普通 Toast 默认展示时长（秒）
    public static var defaultDuration = 2.0
    /// 成功 Toast 默认展示时长（秒）
    public static var successDuration = 2.0
    /// 错误 Toast 默认展示时长（秒）
    public static var errorDuration = 2.0

    /// Toast 视图视觉样式
    public struct ToastViewStyle {
        /// 圆角半径
        public static var cornerRadius = 18.0

        /// 背景色（跟随浅色 / 深色模式）
        public static var backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(white: 0.2, alpha: 0.94) :
                UIColor.black.withAlphaComponent(0.94)
        }

        /// 文字颜色（跟随浅色 / 深色模式）
        public static var textColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                .label :
                .white
        }

        /// 文案字体
        public static var textFont: UIFont = UIFont.systemFont(ofSize: 14)
    }

    /// Toast 窗口层级
    public struct Window {
        /// 默认 windowLevel；修改后会同步到共享窗口
        public static var defaultWindowLevel = UIWindow.Level.statusBar - 1 {
            didSet {
                AMToastWindow.shared.windowLevel = defaultWindowLevel
            }
        }
    }

    /// Toast 位置边距
    public struct Position {
        /// 竖屏顶部边距
        public static var topMarginPortrait: CGFloat = 60.0
        /// 横屏顶部边距
        public static var topMarginLandscape: CGFloat = 20.0
        /// 左右边距，用于限制最大宽度，避免长文案超出屏幕
        public static var horizontalMargin: CGFloat = 20.0
    }

    /// 将全部配置恢复为默认值
    public static func resetToDefault() {
        defaultDuration = 2.0
        successDuration = 2.0
        errorDuration = 2.0
        ToastViewStyle.cornerRadius = 18.0
        ToastViewStyle.backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(white: 0.2, alpha: 0.94) :
                UIColor.black.withAlphaComponent(0.94)
        }
        ToastViewStyle.textColor = AMToastConfig.ToastViewStyle.textColor
        ToastViewStyle.textFont = UIFont.systemFont(ofSize: 14)
        Window.defaultWindowLevel = UIWindow.Level.statusBar - 1
        Position.topMarginPortrait = 60.0
        Position.topMarginLandscape = 20.0
        Position.horizontalMargin = 20.0
    }
}
