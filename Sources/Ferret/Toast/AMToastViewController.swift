//
//  AMToastViewController.swift
//  Ferret
//

import UIKit

/// Toast 窗口根控制器，负责排队、布局与自动消失
public class AMToastViewController: UIViewController {
    private var toastViews: [AMToastViewPosition: [UIView]] = [:]
    private var toast_centerYs: [AMToastViewPosition: [NSLayoutConstraint]] = [:]

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    /// 延迟后将 Toast 加入展示队列
    /// - Parameters:
    ///   - toastView: Toast 视图
    ///   - position: 展示位置
    ///   - duration: 展示时长（秒）
    ///   - delay: 延迟时长（秒）
    public func addToastViewToQueue(_ toastView: UIView, position: AMToastViewPosition, duration: TimeInterval, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            self.addToastViewToQueue(toastView, position: position, duration: duration)
        }
    }

    /// 将 Toast 加入展示队列；同位置已有 Toast 时会先上移 / 下移再展示新项
    /// - Parameters:
    ///   - toastView: Toast 视图
    ///   - position: 展示位置
    ///   - duration: 展示时长（秒）
    public func addToastViewToQueue(_ toastView: UIView, position: AMToastViewPosition, duration: TimeInterval) {
        let existingViews = toastViews[position] ?? []
        let centerYConstraints = toast_centerYs[position] ?? []

        let toastViewSize = fittedSize(for: toastView)
        if !existingViews.isEmpty {
            UIView.animate(withDuration: 0.1) {
                for centerY in centerYConstraints {
                    if position == .center {
                        centerY.constant -= toastViewSize.height + 10
                    } else {
                        centerY.constant += toastViewSize.height + 10
                    }
                }
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.showToastView(toastView, position: position, duration: duration)
            }
            return
        }

        showToastView(toastView, position: position, duration: duration)
    }

    private func showToastView(_ toastView: UIView, position: AMToastViewPosition, duration: TimeInterval) {
        if toastViews[position] != nil {
            toastViews[position]?.append(toastView)
        } else {
            toastViews[position] = [toastView]
        }

        toastView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toastView)

        var vertical_constraint: NSLayoutConstraint!
        if position == .center {
            vertical_constraint = toastView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        } else {
            let isLandscape = UIDevice.current.orientation.isLandscape
            let topMargin = isLandscape ? AMToastConfig.Position.topMarginLandscape : AMToastConfig.Position.topMarginPortrait
            vertical_constraint = toastView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: topMargin)
        }

        if toast_centerYs[position] != nil {
            toast_centerYs[position]?.append(vertical_constraint)
        } else {
            toast_centerYs[position] = [vertical_constraint]
        }

        let horizontalMargin = AMToastConfig.Position.horizontalMargin
        NSLayoutConstraint.activate([
            vertical_constraint,
            toastView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            toastView.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: horizontalMargin),
            toastView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: -horizontalMargin)
        ])

        toastView.alpha = 0
        UIView.animate(withDuration: 0.1) {
            toastView.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.removeToastView(toastView, position: position)
        }
    }

    private func fittedSize(for toastView: UIView) -> CGSize {
        let maxWidth = max(view.bounds.width - AMToastConfig.Position.horizontalMargin * 2, 0)
        return toastView.systemLayoutSizeFitting(
            CGSize(width: maxWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    private func removeToastView(_ toastView: UIView, position: AMToastViewPosition) {
        if let index = toastViews[position]?.firstIndex(of: toastView) {
            toastViews[position]?.remove(at: index)
            toast_centerYs[position]?.remove(at: index)
        }

        UIView.animate(withDuration: 0.1, animations: {
            toastView.alpha = 0
        }) { _ in
            toastView.removeFromSuperview()
        }

        let key = toastViews.keys.first { position in
            if let tviews = toastViews[position], !tviews.isEmpty {
                return true
            }
            return false
        }

        if key == nil {
            (view.window as? AMToastWindow)?.hide()
        }
    }
}
