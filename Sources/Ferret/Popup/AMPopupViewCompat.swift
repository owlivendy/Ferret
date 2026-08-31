//
//  AMPopupViewCompat.swift
//  aitrade
//

import UIKit

public extension UIApplication {
    /// 当前 keyWindow
    static var am_keyWindow: UIWindow? {
        let scenes = shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? scenes.first?.windows.first
    }
}

/// 跟踪当前键盘结束帧。登录页键盘已升起时再弹窗不会再收到 `keyboardWillShow`，需用此帧立刻避让。
public enum AMKeyboardTracker {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var cachedFrameEnd: CGRect = .zero
    nonisolated(unsafe) private static var didStart = false

    /// 当前可见键盘的窗口坐标；不可见时为 `nil`
    public static var visibleFrame: CGRect? {
        startIfNeeded()
        guard let window = UIApplication.am_keyWindow else { return nil }
        let cached = resolvedFrame(cachedFrameEnd, in: window)
        if isVisible(cached, in: window) { return cached }
        return scannedKeyboardFrame()
    }

    /// 开始监听键盘帧（可重复调用）
    public static func startIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !didStart else { return }
        didStart = true
        let center = NotificationCenter.default
        center.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { notification in
            updateCachedFrame(from: notification)
        }
        center.addObserver(
            forName: UIResponder.keyboardDidHideNotification,
            object: nil,
            queue: .main
        ) { notification in
            updateCachedFrame(from: notification)
        }
    }

    /// 兼容 iOS 16 屏幕坐标与 iOS 26 窗口坐标
    public static func resolvedFrame(_ raw: CGRect, in window: UIWindow) -> CGRect {
        let converted = window.convert(raw, from: nil)
        if isPlausibleKeyboard(converted, in: window) { return converted }
        if isPlausibleKeyboard(raw, in: window) { return raw }
        return converted
    }

    public static func isVisible(_ frame: CGRect, in window: UIWindow) -> Bool {
        frame.height > 80 && frame.minY < window.bounds.maxY - 1
    }

    private static func isPlausibleKeyboard(_ frame: CGRect, in window: UIWindow) -> Bool {
        guard frame.height > 80 else { return false }
        let intersects = frame.minY < window.bounds.maxY - 1 && frame.maxY > 0
        guard intersects else { return false }
        return frame.maxY >= window.bounds.maxY - 2 || frame.minY > window.bounds.midY
    }

    private static func updateCachedFrame(from notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        cachedFrameEnd = frame
    }

    /// 从键盘窗口扫描 `InputSetHost` 帧（窗口坐标）
    private static func scannedKeyboardFrame() -> CGRect? {
        guard let keyWindow = UIApplication.am_keyWindow else { return nil }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows where !window.isHidden {
                if let frame = findInputSetHostFrame(in: window) {
                    let resolved = resolvedFrame(frame, in: keyWindow)
                    if isVisible(resolved, in: keyWindow), isPlausibleKeyboard(resolved, in: keyWindow) {
                        return resolved
                    }
                }
            }
        }
        return nil
    }

    private static func findInputSetHostFrame(in view: UIView) -> CGRect? {
        let name = NSStringFromClass(type(of: view))
        if name.contains("InputSetHost"), view.bounds.height > 80, !view.isHidden, view.alpha > 0.01 {
            return view.convert(view.bounds, to: nil)
        }
        for subview in view.subviews {
            if let frame = findInputSetHostFrame(in: subview) {
                return frame
            }
        }
        return nil
    }
}
