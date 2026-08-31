//
//  AMToastWindow.swift
//  Ferret
//

import UIKit

final class AMToastWindow: UIWindow {
    static let shared: AMToastWindow = {
        let window = AMToastWindow(frame: UIScreen.main.bounds)
        window.setupWindow()
        return window
    }()

    private var toastViewController: AMToastViewController?

    private override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupWindow() {
        windowLevel = AMToastConfig.Window.defaultWindowLevel
        backgroundColor = .clear
        isUserInteractionEnabled = false
        isHidden = true
        updateWindowScene()

        toastViewController = AMToastViewController()
        rootViewController = toastViewController
    }

    private func updateWindowScene() {
        if let activeScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            self.windowScene = activeScene
        } else if let foregroundScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundInactive }) as? UIWindowScene {
            self.windowScene = foregroundScene
        } else if let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            self.windowScene = firstScene
        }
    }

    func addToastViewToQueue(_ toastView: UIView, position: AMToastViewPosition, duration: TimeInterval, delay: TimeInterval) {
        toastViewController?.addToastViewToQueue(toastView, position: position, duration: duration, delay: delay)
    }

    func addToastViewToQueue(_ toastView: UIView, position: AMToastViewPosition, duration: TimeInterval) {
        updateWindowScene()
        show()
        toastViewController?.addToastViewToQueue(toastView, position: position, duration: duration)
    }

    private func show() {
        isHidden = false
    }

    func hide() {
        isHidden = true
    }
}
