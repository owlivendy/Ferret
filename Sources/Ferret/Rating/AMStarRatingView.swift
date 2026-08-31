//
//  AMStarRatingView.swift
//  ChinaHomelife247
//
//  Created by Codex on 2026/4/20.
//

import UIKit
import SnapKit

/// 星级评分视图
/// - 支持只读（`isEditable`）和禁用（`isEnabled`）两种不可交互模式
/// - 禁用态会降低透明度，与只读展示区分
/// - 选中 / 半星 / 未选中图片可通过属性替换，默认使用 Ferret 内置资源
/// - 分数默认按 1 颗星 = 1 分计算
open class AMStarRatingView: UIView {
    /// 评分变更回调，返回当前分数
    public typealias ScoreChangedBlock = (_ score: Double) -> Void

    /// 星星总数，最少为 1，默认 5 颗
    public var starCount: Int = 5 {
        didSet {
            let validCount = max(1, starCount)
            if validCount != starCount {
                starCount = validCount
                return
            }
            rebuildStarImageViews()
            setScore(score)
        }
    }

    /// 星星之间的间距，默认 6
    public var starSpacing: CGFloat = 6 {
        didSet {
            stackView.spacing = starSpacing
            invalidateIntrinsicContentSize()
        }
    }

    /// 选中状态图片；为 `nil` 时使用 Ferret 内置 `star_s`
    public var selectedImage: UIImage? = UIImage.ferret("star_s") {
        didSet { refreshStarDisplay() }
    }

    /// 半星状态图片；为 `nil` 时使用 Ferret 内置 `star_of_half`
    public var halfSelectedImage: UIImage? = UIImage.ferret("star_of_half") {
        didSet { refreshStarDisplay() }
    }

    /// 未选中状态图片；为 `nil` 时使用 Ferret 内置 `star_n`
    public var unselectedImage: UIImage? = UIImage.ferret("star_n") {
        didSet { refreshStarDisplay() }
    }

    /// 是否允许点击编辑，默认可编辑
    /// - Note: 只读时仍保持正常配色，用于展示已有评分；禁用请用 `isEnabled`
    public var isEditable: Bool = true {
        didSet {
            updateInteractionState()
        }
    }

    /// 是否可用；`false` 时不可交互并应用禁用样式，默认可用
    public var isEnabled: Bool = true {
        didSet {
            guard oldValue != isEnabled else { return }
            updateInteractionState()
            updateEnabledAppearance()
        }
    }

    /// 禁用态透明度，默认 `0.45`
    public var disabledAlpha: CGFloat = 0.45 {
        didSet {
            let clamped = min(max(disabledAlpha, 0), 1)
            if clamped != disabledAlpha {
                disabledAlpha = clamped
                return
            }
            updateEnabledAppearance()
        }
    }

    /// 是否允许选择半星，默认关闭
    public var allowsHalfStar: Bool = false {
        didSet {
            setScore(score)
            refreshStarDisplay()
        }
    }

    /// 每颗星对应的分值，默认 1 颗星 = 1 分
    public var scorePerStar: Double = 1 {
        didSet {
            if scorePerStar <= 0 {
                scorePerStar = 1
                return
            }
            setScore(score)
            refreshStarDisplay()
        }
    }

    /// 评分结果回调
    /// 返回值按“实际选中的星星数量 * scorePerStar”计算
    /// 例如选中 3 颗星且 scorePerStar = 2 时，回调分数为 6
    /// 开启半星后，选中 2.5 颗星且 scorePerStar = 2 时，回调分数为 5
    public var scoreChangedBlock: ScoreChangedBlock?

    /// 当前分数，外部只读，通过方法或点击修改
    public private(set) var score: Double = 0 {
        didSet {
            refreshStarDisplay()
        }
    }

    /// 横向承载所有星星视图
    private let stackView = UIStackView()
    /// 内部所有星星图片视图集合
    private var starImageViews: [UIImageView] = []
    /// 点击手势统一加在评分控件本身
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleStarTap(_:)))
    /// 拖动手势统一加在评分控件本身
    private lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleStarPan(_:)))
    /// 单颗星的默认参考尺寸，用于 intrinsicContentSize，外部可修改
    public var defaultStarSize: CGFloat = 24 {
        didSet {
            if defaultStarSize <= 0 {
                defaultStarSize = 24
                return
            }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 按半星开关和编辑状态初始化，星星图片默认使用 Ferret 内置资源
    /// - Parameters:
    ///   - enableHalfStar: 是否允许半星，默认关闭
    ///   - isEditable: 是否可编辑，默认 true
    public init(enableHalfStar: Bool = false, isEditable: Bool = true) {
        self.allowsHalfStar = enableHalfStar
        self.isEditable = isEditable
        super.init(frame: .zero)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(enableHalfStar:isEditable:)")
    }

    open override var intrinsicContentSize: CGSize {
        let width = CGFloat(starCount) * defaultStarSize + CGFloat(max(0, starCount - 1)) * starSpacing
        return CGSize(width: width, height: defaultStarSize)
    }

    /// 直接设置总分
    /// - Parameters:
    ///   - score: 目标分数，会自动限制在 0 ~ starCount * scorePerStar 之间
    ///   - triggerCallback: 是否触发评分回调
    public func setScore(_ score: Double, triggerCallback: Bool = false) {
        let maxScore = Double(starCount) * scorePerStar
        let minScore = 0.0
        let clampedScore = min(max(score, minScore), maxScore)
        let validScore = normalizedScore(for: clampedScore)

        guard self.score != validScore else {
            if triggerCallback {
                scoreChangedBlock?(validScore)
            }
            return
        }

        self.score = validScore

        if triggerCallback {
            scoreChangedBlock?(validScore)
        }
    }

    /// 通过选中星星数量设置分数
    /// - Parameters:
    ///   - selectedStars: 选中的星星数量
    ///   - triggerCallback: 是否触发评分回调
    public func setSelectedStars(_ selectedStars: Double, triggerCallback: Bool = false) {
        setScore(selectedStars * scorePerStar, triggerCallback: triggerCallback)
    }

    private func commonInit() {
        setupViews()
        rebuildStarImageViews()
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
        updateInteractionState()
        updateEnabledAppearance()
    }

    private func setupViews() {
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = starSpacing

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 根据当前星数重新创建星星图片视图
    /// 图片宽高保持一致，最终会随着外部高度约束自动缩放
    private func rebuildStarImageViews() {
        starImageViews.forEach { imageView in
            stackView.removeArrangedSubview(imageView)
            imageView.removeFromSuperview()
        }
        starImageViews.removeAll()

        for index in 0..<starCount {
            let imageView = UIImageView()
            imageView.tag = index + 1
            imageView.contentMode = .scaleAspectFit

            stackView.addArrangedSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.width.equalTo(imageView.snp.height)
            }

            starImageViews.append(imageView)
        }

        updateInteractionState()
        refreshStarDisplay()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    /// 根据可用 / 可编辑状态统一更新控件交互能力
    private func updateInteractionState() {
        let canEdit = isEnabled && isEditable
        tapGesture.isEnabled = canEdit
        panGesture.isEnabled = canEdit
        isUserInteractionEnabled = isEnabled
    }

    /// 按启用状态刷新禁用样式（降低透明度，保留当前星级）
    private func updateEnabledAppearance() {
        alpha = isEnabled ? 1 : disabledAlpha
    }

    /// 按当前配置把分数归一到有效步进值
    private func normalizedScore(for score: Double) -> Double {
        let step = allowsHalfStar ? (scorePerStar / 2.0) : scorePerStar
        guard step > 0 else { return score }

        let normalized = (score / step).rounded() * step
        return min(max(normalized, 0), Double(starCount) * scorePerStar)
    }

    /// 按当前分数刷新每颗星的显示状态
    private func refreshStarDisplay() {
        let selectedStars = scorePerStar > 0 ? min(Double(starCount), score / scorePerStar) : 0

        for (index, imageView) in starImageViews.enumerated() {
            let currentStarIndex = Double(index) + 1

            if selectedStars >= currentStarIndex {
                imageView.image = selectedImage ?? UIImage.ferret("star_s")
            } else if allowsHalfStar, selectedStars >= currentStarIndex - 0.5 {
                imageView.image = halfSelectedImage ?? UIImage.ferret("star_of_half") ?? selectedImage ?? UIImage.ferret("star_s")
            } else {
                imageView.image = unselectedImage ?? UIImage.ferret("star_n")
            }
        }
    }

    /// 编辑模式下根据点击位置换算评分并回调
    @objc private func handleStarTap(_ gesture: UITapGestureRecognizer) {
        guard isEnabled, isEditable else { return }
        updateScore(with: gesture.location(in: self), triggerCallback: true, animated: true)
    }

    /// 编辑模式下根据拖动位置连续换算评分并回调
    @objc private func handleStarPan(_ gesture: UIPanGestureRecognizer) {
        guard isEnabled, isEditable else { return }

        switch gesture.state {
        case .began, .changed:
            updateScore(with: gesture.location(in: self), triggerCallback: false)
        case .ended, .cancelled, .failed:
            updateScore(with: gesture.location(in: self), triggerCallback: true)
        default:
            break
        }
    }

    /// 根据控件内的横向位置换算星级并更新分数
    private func updateScore(with location: CGPoint, triggerCallback: Bool, animated: Bool = false) {
        guard !starImageViews.isEmpty else { return }
        guard scorePerStar > 0 else { return }

        guard let starIndex = starIndex(for: location) else { return }

        let relativeX = min(max(location.x - stackView.frame.minX, 0), stackView.frame.width)
        let starWidth = stackView.frame.height > 0 ? stackView.frame.height : defaultStarSize
        let unitWidth = starWidth + starSpacing
        let offsetInUnit = relativeX - CGFloat(starIndex) * unitWidth
        let offsetInStar = min(max(offsetInUnit, 0), starWidth)

        let selectedStars: Double
        if allowsHalfStar {
            selectedStars = offsetInStar <= starWidth / 2.0 ? Double(starIndex) + 0.5 : Double(starIndex) + 1
        } else {
            selectedStars = Double(starIndex) + 1
        }

        setSelectedStars(selectedStars, triggerCallback: triggerCallback)

        if animated {
            performTapAnimation(selectedStars: selectedStars)
        }
    }

    /// 根据点击位置计算命中的星星下标
    private func starIndex(for location: CGPoint) -> Int? {
        guard !starImageViews.isEmpty else { return nil }

        let relativeX = min(max(location.x - stackView.frame.minX, 0), stackView.frame.width)
        let starWidth = stackView.frame.height > 0 ? stackView.frame.height : defaultStarSize
        let unitWidth = starWidth + starSpacing
        guard unitWidth > 0 else { return nil }

        let rawIndex = Int(relativeX / unitWidth)
        return min(max(rawIndex, 0), starCount - 1)
    }

    /// 点击时让当前已选中的整排星星一起回弹，增强评分反馈
    private func performTapAnimation(selectedStars: Double) {
        let animatedCount = max(1, Int(ceil(selectedStars)))
        let targetViews = Array(starImageViews.prefix(animatedCount))
        guard !targetViews.isEmpty else { return }

        for (index, imageView) in targetViews.enumerated() {
            imageView.layer.removeAllAnimations()
            imageView.transform = .identity

            let delay = Double(index) * 0.035
            UIView.animate(withDuration: 0.12,
                           delay: delay,
                           options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut]) {
                imageView.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
            } completion: { _ in
                UIView.animate(withDuration: 0.38,
                               delay: 0,
                               usingSpringWithDamping: 0.42,
                               initialSpringVelocity: 5,
                               options: [.beginFromCurrentState, .allowUserInteraction]) {
                    imageView.transform = .identity
                }
            }
        }
    }
}
