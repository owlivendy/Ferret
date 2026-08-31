//
//  AMStyle1Tab.swift
//  aitrade
//

import UIKit

/// Style1 风格横向 Tab：支持滚动、底部指示线和外部可控选中态
public final class AMStyle1Tab: UIView {
    /// Tab 文案列表；设置后默认选中第一项
    public var items: [String] = [] {
        didSet {
            rebuildTabs()
        }
    }

    /// 当前选中索引；越界时会自动收敛
    public var selectedIndex: Int = 0 {
        didSet {
            updateSelection(animated: true, notify: oldValue != selectedIndex)
        }
    }

    /// 文本字号，默认 14
    public var fontSize: CGFloat = 14 {
        didSet {
            guard fontSize != oldValue else { return }
            updateButtonFonts()
            setNeedsLayout()
            layoutIfNeeded()
            updateSelection(animated: false, notify: false)
        }
    }

    /// Tab 间距，默认 15
    public var itemSpacing: CGFloat = 15 {
        didSet {
            guard itemSpacing != oldValue else { return }
            stackView.spacing = itemSpacing
            setNeedsLayout()
            layoutIfNeeded()
            updateSelection(animated: false, notify: false)
        }
    }

    /// 选中变化回调
    public var onSelectionChanged: ((Int) -> Void)?

    public override var tintColor: UIColor! {
        didSet {
            updateButtonColors()
            indicatorView.backgroundColor = tintColor
        }
    }

    private let scrollView = UIScrollView(frame: .zero)
    private let contentView = UIView(frame: .zero)
    private let stackView = UIStackView(frame: .zero)
    private let indicatorView = UIView(frame: .zero)

    private var buttons: [UIButton] = []
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    private var indicatorWidthConstraint: NSLayoutConstraint?

    private let indicatorHeight: CGFloat = 2
    private let defaultTintColor = UIColor.hex(string: "#FF4B1F")

    /// 创建 Tab 组件
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 36)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateSelection(animated: false, notify: false)
    }

    /// 外部设置选中项
    /// - Parameters:
    ///   - index: 目标索引
    ///   - animated: 是否执行动画
    public func setSelectedIndex(_ index: Int, animated: Bool) {
        selectedIndex = index
        updateSelection(animated: animated, notify: false)
    }

    private func setupViews() {
        backgroundColor = .clear
        tintColor = defaultTintColor

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = false
        addSubview(scrollView)

        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        contentView.addSubview(indicatorView)

        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = itemSpacing

        indicatorView.backgroundColor = tintColor
        indicatorView.layer.cornerRadius = indicatorHeight / 2
        indicatorView.layer.cornerCurve = .continuous

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.translatesAutoresizingMaskIntoConstraints = false

        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        indicatorWidthConstraint = indicatorView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            indicatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: indicatorHeight),
            indicatorLeadingConstraint!,
            indicatorWidthConstraint!
        ])
    }

    private func rebuildTabs() {
        buttons.forEach {
            $0.removeTarget(self, action: #selector(handleTabTapped(_:)), for: .touchUpInside)
            $0.removeFromSuperview()
        }
        buttons.removeAll()

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .custom)
            button.tag = index
            button.setTitle(item, for: .normal)
            button.setTitleColor(.label, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: .medium)
            button.contentHorizontalAlignment = .center
            button.contentVerticalAlignment = .center
            button.addTarget(self, action: #selector(handleTabTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }

        selectedIndex = items.isEmpty ? 0 : 0
        updateSelection(animated: false, notify: false)
    }

    private func updateButtonFonts() {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == clampedSelectedIndex
            button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: isSelected ? .bold : .medium)
        }
    }

    private func updateButtonColors() {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == clampedSelectedIndex
            button.setTitleColor(isSelected ? tintColor : .label, for: .normal)
        }
    }

    private func updateSelection(animated: Bool, notify: Bool) {
        guard !buttons.isEmpty else {
            indicatorWidthConstraint?.constant = 0
            return
        }

        let targetIndex = clampedSelectedIndex
        if selectedIndex != targetIndex {
            selectedIndex = targetIndex
            return
        }

        for (index, button) in buttons.enumerated() {
            let isSelected = index == targetIndex
            button.setTitleColor(isSelected ? tintColor : .label, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: isSelected ? .bold : .medium)
        }

        let button = buttons[targetIndex]
        let targetFrame = button.convert(button.bounds, to: contentView)
        indicatorLeadingConstraint?.constant = targetFrame.minX
        indicatorWidthConstraint?.constant = targetFrame.width

        let animations = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.88,
                initialSpringVelocity: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: animations
            )
        } else {
            animations()
        }

        scrollSelectedButtonToVisible(button, animated: animated)

        if notify {
            onSelectionChanged?(targetIndex)
        }
    }

    private func scrollSelectedButtonToVisible(_ button: UIButton, animated: Bool) {
        let frame = button.convert(button.bounds, to: scrollView)
        let horizontalInset = max((scrollView.bounds.width - frame.width) / 2, 0)
        let targetRect = frame.insetBy(dx: -horizontalInset, dy: 0)
        scrollView.scrollRectToVisible(targetRect, animated: animated)
    }

    private var clampedSelectedIndex: Int {
        guard !buttons.isEmpty else { return 0 }
        return min(max(selectedIndex, 0), buttons.count - 1)
    }

    @objc private func handleTabTapped(_ sender: UIButton) {
        guard sender.tag != clampedSelectedIndex else { return }
        selectedIndex = sender.tag
    }
}
