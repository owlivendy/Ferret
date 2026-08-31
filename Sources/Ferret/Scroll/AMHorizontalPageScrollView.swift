//
//  AMHorizontalPageScrollView.swift
//  aitrade
//

import UIKit

/// 横向翻页滚动数据源
public protocol AMHorizontalPageScrollViewDataSource: AnyObject {
    /// 页内 item 数量
    /// - Parameter scrollView: 翻页滚动视图
    /// - Returns: item 个数
    func numberOfItems(in scrollView: AMHorizontalPageScrollView) -> Int

    /// 配置指定索引 item 的内容视图（由调用方在 `contentView` 内布局子视图）
    /// - Parameters:
    ///   - scrollView: 翻页滚动视图
    ///   - contentView: 当前 item 容器
    ///   - index: item 索引
    func horizontalPageScrollView(
        _ scrollView: AMHorizontalPageScrollView,
        configure contentView: UIView,
        at index: Int
    )
}

/// 横向翻页滚动代理（可选）
public protocol AMHorizontalPageScrollViewDelegate: AnyObject {
    /// 翻页结束后的当前页索引
    /// - Parameters:
    ///   - scrollView: 翻页滚动视图
    ///   - pageIndex: 当前页索引
    func horizontalPageScrollView(
        _ scrollView: AMHorizontalPageScrollView,
        didScrollToPage pageIndex: Int
    )
}

public extension AMHorizontalPageScrollViewDelegate {
    /// 默认空实现，调用方可按需覆盖
    func horizontalPageScrollView(
        _ scrollView: AMHorizontalPageScrollView,
        didScrollToPage pageIndex: Int
    ) {}
}

/// 横向翻页滚动视图：居中展示当前 item，两侧露出相邻 item 边缘
///
/// - Note: `item.width = fraction × scroll.width`；高度由宽高比决定，并作为组件固有高度
public final class AMHorizontalPageScrollView: UIView {
    /// 可见宽度占比（决定 item 宽度），默认 0.85
    public var fraction: CGFloat = 0.85 {
        didSet { guard fraction != oldValue else { return }; applyStyleAndReload() }
    }

    /// item 宽高比（宽 : 高），默认 5:3
    public var itemAspectRatio = CGSize(width: 5, height: 3) {
        didSet { guard itemAspectRatio != oldValue else { return }; applyStyleAndReload() }
    }

    /// 相邻 item 间距，默认 12
    public var itemSpacing: CGFloat = 12 {
        didSet { guard itemSpacing != oldValue else { return }; applyStyleAndReload() }
    }

    /// 当前页索引（只读，翻页完成后更新）
    public private(set) var currentPageIndex = 0

    /// 数据源
    public weak var dataSource: AMHorizontalPageScrollViewDataSource?
    /// 翻页代理
    public weak var delegate: AMHorizontalPageScrollViewDelegate?

    private let collectionView: UICollectionView
    private let flowLayout = AMHorizontalPageScrollFlowLayout()
    private var lastReportedPageIndex = -1
    /// 已应用过 layout 的宽度，避免拖动过程中重复 invalidate 造成闪回
    private var lastLaidOutWidth: CGFloat = 0

    /// 创建横向翻页滚动视图
    /// - Parameter frame: 初始 frame
    public override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        super.init(frame: frame)
        setupViews()
    }

    /// 从 Interface Builder 创建
    /// - Parameter coder: 归档解码器
    public required init?(coder: NSCoder) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        super.init(coder: coder)
        setupViews()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: computedItemSize().height)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 宽度未变时不 invalidate，否则拖动手势会被布局打断并闪回
        guard abs(bounds.width - lastLaidOutWidth) > 0.5 else { return }
        applyLayoutMetrics(preservingPage: true)
    }

    /// 刷新全部 item（数量或内容变化时调用）
    public func reloadData() {
        collectionView.reloadData()
        let count = dataSource?.numberOfItems(in: self) ?? 0
        let clamped = clampPageIndex(currentPageIndex, itemCount: count)
        currentPageIndex = clamped
        lastReportedPageIndex = clamped
        applyLayoutMetrics(preservingPage: false)
        collectionView.layoutIfNeeded()
        if count > 0 {
            // 初始定位到逻辑第 0 页（LTR 左侧 / RTL 右侧）
            scrollToPage(clamped, animated: false)
        } else {
            collectionView.setContentOffset(.zero, animated: false)
        }
        invalidateIntrinsicContentSize()
    }

    /// 滚动到指定页
    /// - Parameters:
    ///   - pageIndex: 目标页索引
    ///   - animated: 是否动画
    public func scrollToPage(_ pageIndex: Int, animated: Bool) {
        let count = dataSource?.numberOfItems(in: self) ?? 0
        guard count > 0 else { return }
        let target = clampPageIndex(pageIndex, itemCount: count)
        let offset = contentOffset(forPage: target)
        collectionView.setContentOffset(offset, animated: animated)
        if !animated {
            finishPageChange(to: target)
        }
    }

    private func setupViews() {
        backgroundColor = .clear
        clipsToBounds = false

        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = itemSpacing
        flowLayout.minimumInteritemSpacing = 0

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = .fast
        collectionView.clipsToBounds = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            AMHorizontalPageItemCell.self,
            forCellWithReuseIdentifier: AMHorizontalPageItemCell.reuseID
        )

        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func applyStyleAndReload() {
        applyLayoutMetrics(preservingPage: true)
        collectionView.reloadData()
        scrollToPage(currentPageIndex, animated: false)
        invalidateIntrinsicContentSize()
    }

    private func applyLayoutMetrics(preservingPage: Bool) {
        guard bounds.width > 0 else { return }
        let itemSize = computedItemSize()
        let inset = max((bounds.width - itemSize.width) / 2, 0)
        let pageStride = itemSize.width + itemSpacing

        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = itemSpacing
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        flowLayout.pageStride = pageStride

        lastLaidOutWidth = bounds.width
        flowLayout.invalidateLayout()

        if preservingPage {
            // 尺寸变化后对齐到当前页，避免内容偏移错位
            collectionView.layoutIfNeeded()
            let offset = contentOffset(forPage: currentPageIndex)
            if abs(collectionView.contentOffset.x - offset.x) > 0.5 {
                collectionView.setContentOffset(offset, animated: false)
            }
        }
    }

    private func computedItemSize() -> CGSize {
        let width = max(bounds.width * fraction, 1)
        let ratio = max(itemAspectRatio.width / max(itemAspectRatio.height, 1), 0.01)
        let height = width / ratio
        return CGSize(width: width, height: height)
    }

    private func contentOffset(forPage pageIndex: Int) -> CGPoint {
        let stride = max(computedItemSize().width + itemSpacing, 1)
        let count = dataSource?.numberOfItems(in: self) ?? 0
        guard count > 0 else { return .zero }
        let page = clampPageIndex(pageIndex, itemCount: count)
        // RTL 下 cell 从右往左排：index 0 在右侧，对应更大的 contentOffset
        let physicalIndex = isRTL ? (count - 1 - page) : page
        let maxOffsetX = max(CGFloat(count - 1) * stride, 0)
        let x = min(max(CGFloat(physicalIndex) * stride, 0), maxOffsetX)
        return CGPoint(x: x, y: 0)
    }

    private func pageIndex(forContentOffset offsetX: CGFloat) -> Int {
        let stride = max(computedItemSize().width + itemSpacing, 1)
        let count = dataSource?.numberOfItems(in: self) ?? 0
        guard count > 0 else { return 0 }
        let physicalIndex = clampPageIndex(Int((offsetX / stride).rounded()), itemCount: count)
        if isRTL {
            return clampPageIndex(count - 1 - physicalIndex, itemCount: count)
        }
        return physicalIndex
    }

    /// 当前是否为从右到左布局
    private var isRTL: Bool {
        effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    private func clampPageIndex(_ index: Int, itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        return min(max(index, 0), itemCount - 1)
    }

    private func finishPageChange(to pageIndex: Int) {
        currentPageIndex = pageIndex
        guard pageIndex != lastReportedPageIndex else { return }
        lastReportedPageIndex = pageIndex
        delegate?.horizontalPageScrollView(self, didScrollToPage: pageIndex)
    }
}

// MARK: - UICollectionViewDataSource

extension AMHorizontalPageScrollView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource?.numberOfItems(in: self) ?? 0
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AMHorizontalPageItemCell.reuseID,
            for: indexPath
        ) as! AMHorizontalPageItemCell
        cell.contentContainer.subviews.forEach { $0.removeFromSuperview() }
        dataSource?.horizontalPageScrollView(self, configure: cell.contentContainer, at: indexPath.item)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension AMHorizontalPageScrollView: UICollectionViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        finishPageChange(to: pageIndex(forContentOffset: scrollView.contentOffset.x))
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        finishPageChange(to: pageIndex(forContentOffset: scrollView.contentOffset.x))
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        finishPageChange(to: pageIndex(forContentOffset: scrollView.contentOffset.x))
    }
}

// MARK: - Cell

/// 单页 item 容器 Cell
private final class AMHorizontalPageItemCell: UICollectionViewCell {
    static let reuseID = "AMHorizontalPageItemCell"

    let contentContainer = UIView(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(contentContainer)
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - Layout

/// 横向翻页 FlowLayout：按 pageStride 吸附，结合速度决定是否翻页
private final class AMHorizontalPageScrollFlowLayout: UICollectionViewFlowLayout {
    /// 相邻页中心间距（itemWidth + spacing）
    var pageStride: CGFloat = 1

    /// 轻甩翻页速度阈值
    private let flickVelocity: CGFloat = 0.2

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        false
    }

    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let collectionView else {
            return super.targetContentOffset(
                forProposedContentOffset: proposedContentOffset,
                withScrollingVelocity: velocity
            )
        }

        let stride = max(pageStride, 1)
        let currentX = collectionView.contentOffset.x
        // 以松手时实际进度为基准（不用外部 currentPageIndex，避免过期状态）
        let progress = currentX / stride

        let targetPage: Int
        if velocity.x > flickVelocity {
            // 向右轻甩：前进至少一页
            targetPage = Int(ceil(progress + 0.01))
        } else if velocity.x < -flickVelocity {
            // 向左轻甩：后退至少一页
            targetPage = Int(floor(progress - 0.01))
        } else {
            // 慢拖：按距离落到最近页
            targetPage = Int(progress.rounded())
        }

        let itemCount = collectionView.numberOfItems(inSection: 0)
        let clamped = itemCount > 0
            ? min(max(targetPage, 0), itemCount - 1)
            : 0
        let maxOffsetX = max(collectionView.contentSize.width - collectionView.bounds.width, 0)
        let x = min(max(CGFloat(clamped) * stride, 0), maxOffsetX)
        return CGPoint(x: x, y: proposedContentOffset.y)
    }
}
