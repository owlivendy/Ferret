//
//  AMToastView.swift
//  Ferret
//

import UIKit

/// Toast 容器视图，负责背景、圆角与自定义内容布局
public class AMToastView: UIView {
    /// 内容内边距；修改后会同步更新 Auto Layout 约束
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15) {
        didSet {
            content_top?.constant = contentInsets.top
            content_bottom?.constant = contentInsets.bottom
            content_leading?.constant = contentInsets.left
            content_trailing?.constant = contentInsets.right
        }
    }
    private var content_top: NSLayoutConstraint?
    private var content_bottom: NSLayoutConstraint?
    private var content_leading: NSLayoutConstraint?
    private var content_trailing: NSLayoutConstraint?
    private var content_width: NSLayoutConstraint?
    private var content_height: NSLayoutConstraint?

    /// 自定义内容视图
    /// - Note: 内部使用 Auto Layout 且能自适应尺寸时无需设置 `frame`；否则请设置 `frame.size`，会转换为宽高约束
    public var customView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let customView = customView {
                addSubview(customView)
                customView.translatesAutoresizingMaskIntoConstraints = false

                content_top = customView.topAnchor.constraint(equalTo: self.topAnchor, constant: contentInsets.top)
                content_bottom = self.bottomAnchor.constraint(equalTo: customView.bottomAnchor, constant: contentInsets.bottom)
                content_leading = customView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: contentInsets.left)
                content_trailing = self.trailingAnchor.constraint(equalTo: customView.trailingAnchor, constant: contentInsets.right)

                var constraints = [
                    content_top!,
                    content_bottom!,
                    content_leading!,
                    content_trailing!
                ]

                if customView.frame.width > 0 {
                    content_width = customView.widthAnchor.constraint(equalToConstant: customView.frame.width)
                    constraints.append(content_width!)
                }

                if customView.frame.height > 0 {
                    content_height = customView.heightAnchor.constraint(equalToConstant: customView.frame.height)
                    constraints.append(content_height!)
                }

                NSLayoutConstraint.activate(constraints)
            }
        }
    }

    /// 使用指定 frame 创建 Toast 容器
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /// 从归档创建 Toast 容器
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func setupUI() {
        backgroundColor = AMToastConfig.ToastViewStyle.backgroundColor
        layer.cornerRadius = AMToastConfig.ToastViewStyle.cornerRadius
        clipsToBounds = true
    }
}
