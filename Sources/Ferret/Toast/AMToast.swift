//
//  AMToast.swift
//  Ferret
//

import UIKit

/// Toast 展示位置
public enum AMToastViewPosition {
    /// 屏幕顶部
    case top
    /// 屏幕垂直居中
    case center
}

/// Toast 入口，支持普通文案、成功、失败与自定义视图
public final class AMToast {

    /// 展示普通文案 Toast
    /// - Parameters:
    ///   - message: 提示文案
    ///   - duration: 展示时长（秒）
    ///   - position: 展示位置，默认居中
    public static func show(
        with message: String,
        duration: TimeInterval = AMToastConfig.defaultDuration,
        position: AMToastViewPosition = .center
    ) {
        let textView = AMTextToastView(message: message)
        AMToastWindow.shared.addToastViewToQueue(textView, position: position, duration: duration)
    }

    /// 展示自定义内容 Toast
    /// - Parameters:
    ///   - customView: 自定义内容视图
    ///   - duration: 展示时长（秒）
    ///   - position: 展示位置，默认居中
    public static func show(
        with customView: UIView,
        duration: TimeInterval = AMToastConfig.defaultDuration,
        position: AMToastViewPosition = .center
    ) {
        let toastView = AMToastView()
        toastView.customView = customView
        AMToastWindow.shared.addToastViewToQueue(toastView, position: position, duration: duration)
    }

    /// 展示成功样式 Toast
    /// - Parameters:
    ///   - message: 成功提示文案
    ///   - duration: 展示时长（秒）
    ///   - position: 展示位置，默认居中
    public static func showSuccess(
        with message: String,
        duration: TimeInterval = AMToastConfig.successDuration,
        position: AMToastViewPosition = .center
    ) {
        let successView = AMSuccessToastView(message: message)
        AMToastWindow.shared.addToastViewToQueue(successView, position: position, duration: duration)
    }

    /// 展示错误样式 Toast
    /// - Parameters:
    ///   - message: 错误提示文案
    ///   - duration: 展示时长（秒）
    ///   - position: 展示位置，默认居中
    public static func showError(
        with message: String,
        duration: TimeInterval = AMToastConfig.errorDuration,
        position: AMToastViewPosition = .center
    ) {
        let errorView = AMErrorToastView(message: message)
        AMToastWindow.shared.addToastViewToQueue(errorView, position: position, duration: duration)
    }
}
