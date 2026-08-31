//
//  AMPopoverView.swift
//  Ferret
//

import UIKit

/// 气泡垂直显示优先级
public enum AMPopoverViewPlacementPriority: Int {
    /// 空间足够时优先显示在锚点视图下方
    case below = 0
    /// 空间足够时优先显示在锚点视图上方
    case above = 1
}

/// 带箭头的气泡弹层，锚定于指定视图显示。
open class AMPopoverView: UIView, UIGestureRecognizerDelegate {

    /// 箭头高度，默认 8
    open var arrowHeight: CGFloat = 8
    /// 箭头宽度，默认 12
    open var arrowWidth: CGFloat = 12
    /// 圆角半径，默认 8
    open var cornerRadius: CGFloat = 8 {
        didSet { contentView.layer.cornerRadius = cornerRadius }
    }
    /// 距离容器上下边缘的最小边距，默认 10
    open var verticalMargin: CGFloat = 10
    /// 距离容器左右边缘的最小边距，默认 10
    open var horizontalMargin: CGFloat = 10
    /// 垂直显示位置优先级，默认 `.below`
    open var placementPriority: AMPopoverViewPlacementPriority = .below

    /// 气泡内容视图（只读）
    public private(set) var contentView: UIView

    /// 点击气泡外部区域回调
    open var backgroundTapHandler: ((AMPopoverView) -> Void)?

    /// 点击外部是否穿透至底层视图，默认 `false`
    open var allowsBackgroundTapPassthrough: Bool = false

    /// 点击外部是否自动关闭，默认 `true`
    open var dismissOnBackgroundTap: Bool = true

    /// 气泡背景色（含箭头），默认白色
    open var bubbleFillColor: UIColor = .white {
        didSet {
            let color = bubbleFillColor
            contentView.backgroundColor = color
            arrowLayer.fillColor = color.cgColor
        }
    }

    private let arrowLayer = CAShapeLayer()
    private var isShowingAbove = false
    private var arrowOffset: CGFloat = 0
    private var backgroundView: UIView?
    private weak var displayContainer: UIView?
    private var containerTapGesture: UITapGestureRecognizer?

    /// 使用内容视图创建气泡
    /// - Parameter contentView: 气泡内展示的内容
    public init(contentView: UIView) {
        self.contentView = contentView
        super.init(frame: .zero)
        dismissOnBackgroundTap = true
        bubbleFillColor = .white
        setupUI()
    }

    /// 不支持从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let containerTapGesture, let displayContainer {
            displayContainer.removeGestureRecognizer(containerTapGesture)
        }
    }

    /// 显示气泡（容器默认 keyWindow）
    /// - Parameter anchorView: 锚点视图
    open func show(anchorView: UIView) {
        show(anchorView: anchorView, container: nil)
    }

    /// 显示气泡
    /// - Parameters:
    ///   - anchorView: 锚点视图，弹窗以该视图为锚点弹出
    ///   - container: 展示容器；为 `nil` 时使用 keyWindow
    open func show(anchorView: UIView, container: UIView?) {
        guard anchorView.superview != nil || anchorView.window != nil else { return }

        contentView.backgroundColor = bubbleFillColor
        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.masksToBounds = true
        arrowLayer.fillColor = bubbleFillColor.cgColor

        guard let displayContainer = container ?? UIApplication.am_keyWindow else { return }
        self.displayContainer = displayContainer

        setupBackgroundView(in: displayContainer)
        layoutPopover(relativeTo: anchorView, in: displayContainer)

        displayContainer.addSubview(backgroundView!)
        backgroundView!.addSubview(self)

        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    /// 显示气泡（位置参数版）
    /// - Parameter anchorView: 锚点视图
    open func show(_ anchorView: UIView) {
        show(anchorView: anchorView)
    }

    /// 显示气泡（位置参数版）
    /// - Parameters:
    ///   - anchorView: 锚点视图
    ///   - container: 展示容器；为 `nil` 时使用 keyWindow
    open func show(_ anchorView: UIView, container: UIView?) {
        show(anchorView: anchorView, container: container)
    }

    /// 关闭气泡
    open func hide() {
        if let containerTapGesture, let displayContainer {
            displayContainer.removeGestureRecognizer(containerTapGesture)
            self.containerTapGesture = nil
        }
        displayContainer = nil

        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            self.backgroundView?.removeFromSuperview()
            self.removeFromSuperview()
            self.backgroundView = nil
        })
    }

    // MARK: - Private

    private func setupUI() {
        backgroundColor = .clear
        addSubview(contentView)
        layer.addSublayer(arrowLayer)
    }

    private func setupBackgroundView(in displayContainer: UIView) {
        if allowsBackgroundTapPassthrough {
            let passthrough = AMPassthroughView(frame: displayContainer.bounds)
            passthrough.backgroundColor = .clear
            passthrough.allowHitTestPassthrough = true
            passthrough.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            backgroundView = passthrough

            let tap = UITapGestureRecognizer(target: self, action: #selector(containerBackgroundTapped(_:)))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            displayContainer.addGestureRecognizer(tap)
            containerTapGesture = tap
        } else {
            let bg = UIView(frame: displayContainer.bounds)
            bg.backgroundColor = .clear
            bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundViewTapped(_:)))
            tap.delegate = self
            bg.addGestureRecognizer(tap)
            backgroundView = bg
        }

        backgroundView?.layer.shadowColor = UIColor.black.cgColor
        backgroundView?.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView?.layer.shadowOpacity = 0.15
        backgroundView?.layer.shadowRadius = 4
    }

    private func layoutPopover(relativeTo anchorView: UIView, in displayContainer: UIView) {
        let anchorFrame = anchorView.convert(anchorView.bounds, to: displayContainer)

        contentView.sizeToFit()
        let contentSize = contentView.bounds.size

        let totalWidth = contentSize.width
        let totalHeight = contentSize.height + arrowHeight

        let containerWidth = displayContainer.bounds.width
        let containerHeight = displayContainer.bounds.height

        var x = anchorFrame.origin.x + (anchorFrame.width - totalWidth) / 2
        if x + totalWidth > containerWidth - horizontalMargin {
            x = containerWidth - totalWidth - horizontalMargin
        }
        x = max(horizontalMargin, x)

        let anchorCenterX = anchorFrame.midX
        let popoverCenterX = x + totalWidth / 2
        arrowOffset = anchorCenterX - popoverCenterX

        let belowY = anchorFrame.maxY
        let aboveY = anchorFrame.minY - totalHeight
        let fitsBelow = belowY + totalHeight <= containerHeight - verticalMargin
        let fitsAbove = aboveY >= verticalMargin

        let y: CGFloat
        if placementPriority == .above {
            if fitsAbove {
                y = aboveY
                isShowingAbove = true
            } else {
                y = belowY
                isShowingAbove = false
            }
        } else {
            if fitsBelow {
                y = belowY
                isShowingAbove = false
            } else {
                y = aboveY
                isShowingAbove = true
            }
        }

        frame = CGRect(x: x, y: y, width: totalWidth, height: totalHeight)
        if isShowingAbove {
            contentView.frame = CGRect(x: 0, y: 0, width: totalWidth, height: contentSize.height)
        } else {
            contentView.frame = CGRect(x: 0, y: arrowHeight, width: totalWidth, height: contentSize.height)
        }

        drawArrow()
    }

    private func drawArrow() {
        let path = UIBezierPath()
        let arrowX = bounds.width / 2 + arrowOffset
        let arrowY = isShowingAbove ? bounds.height - arrowHeight : 0

        if isShowingAbove {
            path.move(to: CGPoint(x: arrowX - arrowWidth / 2, y: arrowY))
            path.addLine(to: CGPoint(x: arrowX, y: arrowY + arrowHeight))
            path.addLine(to: CGPoint(x: arrowX + arrowWidth / 2, y: arrowY))
        } else {
            path.move(to: CGPoint(x: arrowX - arrowWidth / 2, y: arrowY + arrowHeight))
            path.addLine(to: CGPoint(x: arrowX, y: arrowY))
            path.addLine(to: CGPoint(x: arrowX + arrowWidth / 2, y: arrowY + arrowHeight))
        }
        path.close()
        arrowLayer.path = path.cgPath
    }

    @objc private func backgroundViewTapped(_ gesture: UITapGestureRecognizer) {
        handleOutsideTapIfNeeded(gesture)
    }

    @objc private func containerBackgroundTapped(_ gesture: UITapGestureRecognizer) {
        handleOutsideTapIfNeeded(gesture)
    }

    private func handleOutsideTapIfNeeded(_ gesture: UITapGestureRecognizer) {
        let pointInPopover = gesture.location(in: self)
        guard !bounds.contains(pointInPopover) else { return }
        notifyBackgroundTapAndDismissIfNeeded()
    }

    private func notifyBackgroundTapAndDismissIfNeeded() {
        backgroundTapHandler?(self)
        if dismissOnBackgroundTap {
            hide()
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    /// 判断手势是否应接收该触摸
    /// - Parameters:
    ///   - gestureRecognizer: 手势识别器
    ///   - touch: 触摸对象
    /// - Returns: 是否接收该触摸
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if allowsBackgroundTapPassthrough, gestureRecognizer === containerTapGesture {
            return true
        }
        let point = touch.location(in: self)
        if contentView.frame.contains(point) {
            return false
        }
        return true
    }
}
