//
//  CollectionViewLayout.swift
//  Pods
//
//  Created by wuyong on 2023/3/8.
//

import UIKit

// MARK: - CollectionViewFlowLayout
/// 集合视图流式布局，支持纵向渲染和分页滚动效果
///
/// 系统FlowLayout水平滚动时默认横向渲染，可通过本类开启纵向渲染，示例效果如下：
/// [0  3  6   9 ]      [0  1   2   3 ]
/// [1  4  7  10] => [4  5   6   7 ]
/// [2  5  8  11]      [8  9  10 11]
///
/// [CenteredCollectionView](https://github.com/BenEmdon/CenteredCollectionView)
open class CollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    // MARK: - Vertical
    /// 是否启用元素纵向渲染，默认关闭，开启时需设置渲染总数itemRenderCount
    open var itemRenderVertical = false
    
    /// 纵向渲染列数，开启itemRenderVertical且大于0时生效
    open var verticalColumnCount: Int = 0
    
    /// 纵向渲染行数，开启itemRenderVertical且大于0时生效
    open var verticalRowCount: Int = 0
    
    private var allAttributes: [UICollectionViewLayoutAttributes] = []
    
    /// 计算实际渲染总数，超出部分需渲染空数据，一般numberOfItems中调用
    open func itemRenderCount(_ itemCount: Int) -> Int {
        guard verticalColumnCount > 0,
              verticalRowCount > 0 else { return itemCount }
        
        let pageCount = verticalColumnCount * verticalRowCount
        let page = ceil(Double(itemCount) / Double(pageCount))
        return Int(page) * pageCount
    }
    
    /// 转换指定indexPath为纵向索引indexPath，一般无需调用
    open func verticalIndexPath(_ indexPath: IndexPath) -> IndexPath {
        guard verticalColumnCount > 0,
              verticalRowCount > 0 else { return indexPath }
        
        let page = indexPath.item / (verticalColumnCount * verticalRowCount)
        let x = (indexPath.item % (verticalColumnCount * verticalRowCount)) / verticalRowCount
        let y = indexPath.item % verticalRowCount + page * verticalRowCount
        let item = y * verticalColumnCount + x
        return IndexPath(item: item, section: indexPath.section)
    }
    
    open override func prepare() {
        super.prepare()
        self.fw_sectionConfigPrepareLayout()
        guard let collectionView = collectionView,
              itemRenderVertical,
              verticalColumnCount > 0,
              verticalRowCount > 0 else { return }
        
        allAttributes.removeAll()
        let sectionCount = collectionView.numberOfSections
        for section in 0 ..< sectionCount {
            let itemCount = collectionView.numberOfItems(inSection: section)
            for item in 0 ..< itemCount {
                if let attributes = layoutAttributesForItem(at: IndexPath(item: item, section: section)) {
                    allAttributes.append(attributes)
                }
            }
        }
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard itemRenderVertical,
              verticalColumnCount > 0,
              verticalRowCount > 0 else {
            return super.layoutAttributesForItem(at: indexPath)
        }
        
        let page = indexPath.item / (verticalColumnCount * verticalRowCount)
        let x = indexPath.item % verticalColumnCount + page * verticalColumnCount
        let y = indexPath.item / verticalColumnCount - page * verticalRowCount
        let item = x * verticalRowCount + y
        let attributes = super.layoutAttributesForItem(at: IndexPath(item: item, section: indexPath.section))
        attributes?.indexPath = indexPath
        return attributes
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var newAttributes: [UICollectionViewLayoutAttributes] = []
        if let attributes = super.layoutAttributesForElements(in: rect) {
            if itemRenderVertical,
               verticalColumnCount > 0,
               verticalRowCount > 0 {
                for attribute in attributes {
                    if attribute.representedElementCategory != .cell {
                        newAttributes.append(attribute)
                        continue
                    }
                    for newAttribute in allAttributes {
                        if attribute.indexPath.section == newAttribute.indexPath.section,
                           attribute.indexPath.item == newAttribute.indexPath.item {
                            newAttributes.append(newAttribute)
                            break
                        }
                    }
                }
            } else {
                newAttributes.append(contentsOf: attributes)
            }
        }
        
        let sectionAttributes = fw_sectionConfigLayoutAttributes(forElementsIn: rect)
        newAttributes.append(contentsOf: sectionAttributes)
        return newAttributes
    }
    
    // MARK: - Paging
    /// 是否启用分页滚动，默认false。需设置decelerationRate为fast且关闭集合视图isPagingEnabled
    open var isPagingEnabled = false
    
    /// 是否启用居中分页，默认false
    open var isPagingCenter = false
    
    /// 获取当前页数，即居中cell的item，可能为nil
    open var currentPage: Int? {
        guard let collectionView = collectionView else { return nil }
        let centerPoint = CGPoint(x: collectionView.contentOffset.x + collectionView.bounds.width / 2, y: collectionView.contentOffset.y + collectionView.bounds.height / 2)
        return collectionView.indexPathForItem(at: centerPoint)?.item
    }
    
    /// 获取每页宽度，必须设置itemSize
    open var pageWidth: CGFloat {
        switch scrollDirection {
        case .horizontal:
            return itemSize.width + minimumLineSpacing
        case .vertical:
            return itemSize.height + minimumLineSpacing
        default:
            return 0
        }
    }
    
    private var lastCollectionViewSize: CGSize = .zero
    private var lastScrollDirection: UICollectionView.ScrollDirection = .vertical
    private var lastItemSize: CGSize = .zero
    
    /// 滚动到指定页数
    open func scrollToPage(_ index: Int, animated: Bool = true) {
        guard let collectionView = collectionView else { return }
        
        let proposedContentOffset: CGPoint
        let shouldAnimate: Bool
        switch scrollDirection {
        case .horizontal:
            var pageOffset = CGFloat(index) * pageWidth - collectionView.contentInset.left
            if !isPagingCenter {
                pageOffset = min(pageOffset, collectionView.fw_contentOffset(of: .right).x)
            }
            proposedContentOffset = CGPoint(x: pageOffset, y: collectionView.contentOffset.y)
            shouldAnimate = abs(collectionView.contentOffset.x - pageOffset) > 1 ? animated : false
        case .vertical:
            var pageOffset = CGFloat(index) * pageWidth - collectionView.contentInset.top
            if !isPagingCenter {
                pageOffset = min(pageOffset, collectionView.fw_contentOffset(of: .bottom).y)
            }
            proposedContentOffset = CGPoint(x: collectionView.contentOffset.x, y: pageOffset)
            shouldAnimate = abs(collectionView.contentOffset.y - pageOffset) > 1 ? animated : false
        default:
            proposedContentOffset = .zero
            shouldAnimate = false
        }
        collectionView.setContentOffset(proposedContentOffset, animated: shouldAnimate)
    }
    
    override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        guard isPagingEnabled, let collectionView = collectionView else { return }
        
        let currentCollectionViewSize = collectionView.bounds.size
        if (!currentCollectionViewSize.equalTo(lastCollectionViewSize) || lastScrollDirection != scrollDirection || lastItemSize != itemSize), !currentCollectionViewSize.equalTo(.zero) {
            if isPagingCenter {
                switch scrollDirection {
                case .horizontal:
                    let inset = (currentCollectionViewSize.width - itemSize.width - sectionInset.left - sectionInset.right) / 2
                    collectionView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
                    collectionView.contentOffset = CGPoint(x: -inset, y: 0)
                case .vertical:
                    let inset = (currentCollectionViewSize.height - itemSize.height - sectionInset.top - sectionInset.bottom) / 2
                    collectionView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
                    collectionView.contentOffset = CGPoint(x: 0, y: -inset)
                default:
                    collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                    collectionView.contentOffset = .zero
                }
            }
            
            lastCollectionViewSize = currentCollectionViewSize
            lastScrollDirection = scrollDirection
            lastItemSize = itemSize
        }
    }
    
    override open func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard isPagingEnabled else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        guard let collectionView = collectionView else {
            return proposedContentOffset
        }
        let proposedRect = determineProposedRect(collectionView: collectionView, proposedContentOffset: proposedContentOffset)
        guard let layoutAttributes = layoutAttributesForElements(in: proposedRect),
              let candidateAttributesForRect = attributesForRect(collectionView: collectionView, layoutAttributes: layoutAttributes, proposedContentOffset: proposedContentOffset) else {
            return proposedContentOffset
        }
        
        var newOffset: CGFloat
        let offset: CGFloat
        switch scrollDirection {
        case .horizontal:
            if isPagingCenter {
                newOffset = candidateAttributesForRect.center.x - collectionView.bounds.size.width / 2
            } else {
                newOffset = candidateAttributesForRect.center.x - collectionView.contentInset.left - sectionInset.left - itemSize.width / 2
            }
            offset = newOffset - collectionView.contentOffset.x
            
            if (velocity.x < 0 && offset > 0) || (velocity.x > 0 && offset < 0) {
                newOffset += velocity.x > 0 ? pageWidth : -pageWidth
            }
            return CGPoint(x: newOffset, y: proposedContentOffset.y)
        case .vertical:
            if isPagingCenter {
                newOffset = candidateAttributesForRect.center.y - collectionView.bounds.size.height / 2
            } else {
                newOffset = candidateAttributesForRect.center.y - collectionView.contentInset.top - sectionInset.top - itemSize.height / 2
            }
            offset = newOffset - collectionView.contentOffset.y
            
            if (velocity.y < 0 && offset > 0) || (velocity.y > 0 && offset < 0) {
                newOffset += velocity.y > 0 ? pageWidth : -pageWidth
            }
            return CGPoint(x: proposedContentOffset.x, y: newOffset)
        default:
            return .zero
        }
    }
    
    func determineProposedRect(collectionView: UICollectionView, proposedContentOffset: CGPoint) -> CGRect {
        let size = collectionView.bounds.size
        let origin: CGPoint
        switch scrollDirection {
        case .horizontal:
            origin = CGPoint(x: proposedContentOffset.x, y: collectionView.contentOffset.y)
        case .vertical:
            origin = CGPoint(x: collectionView.contentOffset.x, y: proposedContentOffset.y)
        default:
            origin = .zero
        }
        return CGRect(origin: origin, size: size)
    }
    
    func attributesForRect(collectionView: UICollectionView, layoutAttributes: [UICollectionViewLayoutAttributes], proposedContentOffset: CGPoint) -> UICollectionViewLayoutAttributes? {
        var candidateAttributes: UICollectionViewLayoutAttributes?
        let proposedCenterOffset: CGFloat
        
        switch scrollDirection {
        case .horizontal:
            if isPagingCenter {
                proposedCenterOffset = proposedContentOffset.x + collectionView.bounds.size.width / 2
            } else {
                proposedCenterOffset = proposedContentOffset.x + collectionView.contentInset.left + sectionInset.left + itemSize.width / 2
            }
        case .vertical:
            if isPagingCenter {
                proposedCenterOffset = proposedContentOffset.y + collectionView.bounds.size.height / 2
            } else {
                proposedCenterOffset = proposedContentOffset.y + collectionView.contentInset.top + sectionInset.top + itemSize.height / 2
            }
        default:
            proposedCenterOffset = .zero
        }
        
        for attributes in layoutAttributes {
            guard attributes.representedElementCategory == .cell else { continue }
            guard candidateAttributes != nil else {
                candidateAttributes = attributes
                continue
            }
            
            switch scrollDirection {
            case .horizontal where abs(attributes.center.x - proposedCenterOffset) < abs(candidateAttributes!.center.x - proposedCenterOffset):
                candidateAttributes = attributes
            case .vertical where abs(attributes.center.y - proposedCenterOffset) < abs(candidateAttributes!.center.y - proposedCenterOffset):
                candidateAttributes = attributes
            default:
                continue
            }
        }
        return candidateAttributes
    }
    
}

// MARK: - CollectionViewAlignLayout
/// 集合视图元素水平对齐方式枚举
@objc public enum CollectionViewItemsHorizontalAlignment: Int {
    /// 水平流式（水平方向效果与 UICollectionViewDelegateFlowLayout 一致）
    case flow
    /// 水平流式并充满（行内各 item 均分行内剩余空间，使行内充满显示）
    case flowFilled
    /// 水平居左
    case left
    /// 水平居中
    case center
    /// 水平居右
    case right
}

/// 集合视图元素水平对齐方式枚举
@objc public enum CollectionViewItemsVerticalAlignment: Int {
    /// 竖直方向居中
    case center
    /// 竖直方向顶部对齐
    case top
    /// 竖直方向底部对齐
    case bottom
}

/// 集合视图元素排布方向枚举
@objc public enum CollectionViewItemsDirection: Int {
    // 排布方向从左到右
    case ltr
    // 排布方向从右到左
    case rtl
}

/// 扩展 UICollectionViewDelegateFlowLayout/NSCollectionViewDelegateFlowLayout 协议，
/// 添加设置水平、竖直方向的对齐方式以及 items 排布方向协议方法
@objc public protocol CollectionViewDelegateAlignLayout: CollectionViewDelegateFlowLayout {
    // 设置不同 section items 水平方向的对齐方式
    @objc optional func collectionView(_ collectionView: UICollectionView, layout: CollectionViewAlignLayout, itemsHorizontalAlignmentForSectionAt section: Int) -> CollectionViewItemsHorizontalAlignment
    
    // 设置不同 section items 竖直方向的对齐方式
    @objc optional func collectionView(_ collectionView: UICollectionView, layout: CollectionViewAlignLayout, itemsVerticalAlignmentForSectionAt section: Int) -> CollectionViewItemsVerticalAlignment
    
    // 设置不同 section items 的排布方向
    @objc optional func collectionView(_ collectionView: UICollectionView, layout: CollectionViewAlignLayout, itemsDirectionForSectionAt section: Int) -> CollectionViewItemsDirection
}

/// 在 UICollectionViewFlowLayout 基础上，自定义 UICollectionView 对齐布局
/// 注意：滚动方向默认为垂直滚动，不可设置滚动方向
///
/// 实现以下功能：
/// 1. 设置水平方向对齐方式：流式（默认）、流式填充、居左、居中、居右、平铺；
/// 2. 设置竖直方向对齐方式：居中（默认）、置顶、置底；
/// 3. 设置显示条目排布方向：从左到右（默认）、从右到左。
/// [JQCollectionViewAlignLayout](https://github.com/Coder-ZJQ/JQCollectionViewAlignLayout)
open class CollectionViewAlignLayout: UICollectionViewFlowLayout {
    
    /// 水平方向对齐方式，默认为流式(flow)
    open var itemsHorizontalAlignment: CollectionViewItemsHorizontalAlignment = .flow
    /// 竖直方向对齐方式，默认为居中(center)
    open var itemsVerticalAlignment: CollectionViewItemsVerticalAlignment = .center
    /// items 排布方向，默认为从左到右(ltr)
    open var itemsDirection: CollectionViewItemsDirection = .ltr
    /// 禁用 setScrollDirection: 方法，不可设置滚动方向，默认为竖直滚动
    open override var scrollDirection: UICollectionView.ScrollDirection {
        get { super.scrollDirection }
        @available(*, unavailable)
        set { super.scrollDirection = newValue }
    }
    
    private var cachedFrame: [IndexPath: CGRect] = [:]
    
    open override func prepare() {
        super.prepare()
        fw_sectionConfigPrepareLayout()
        cachedFrame = [:]
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let originalAttributes = super.layoutAttributesForElements(in: rect) ?? []
        var updatedAttributes = originalAttributes
        for attributes in originalAttributes {
            if attributes.representedElementKind == nil || attributes.representedElementCategory == .cell {
                if let index = updatedAttributes.firstIndex(of: attributes),
                   let indexAttributes = layoutAttributesForItem(at: attributes.indexPath) {
                    updatedAttributes[index] = indexAttributes
                }
            }
        }
        let sectionAttributes = fw_sectionConfigLayoutAttributes(forElementsIn: rect)
        updatedAttributes.append(contentsOf: sectionAttributes)
        return updatedAttributes
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // 需要调用copy复制后再修改
        let currentAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes
        
        // 获取缓存的当前 indexPath 的 item frame value
        var frameValue = cachedFrame[indexPath]
        // 如果没有缓存的 item frame value，则计算并缓存然后获取
        if frameValue == nil {
            // 判断是否为一行中的首个
            let isLineStart = innerIsLineStart(at: indexPath)
            // 如果是一行中的首个
            if isLineStart, let currentAttributes = currentAttributes {
                // 获取当前行的所有 UICollectionViewLayoutAttributes
                let line = innerLineAttributesArray(startAttributes: currentAttributes)
                if !line.isEmpty {
                    // 计算并缓存当前行的所有 UICollectionViewLayoutAttributes frame
                    innerCalculateAndCacheFrame(for: line)
                }
            }
            // 获取位于当前 indexPath 的 item frame
            frameValue = cachedFrame[indexPath]
        }
        if let frameValue = frameValue {
            // 获取当前 indexPath 的 item frame 后修改当前 layoutAttributes.frame
            currentAttributes?.frame = frameValue
        }
        
        return currentAttributes
    }
    
    private func innerMinimumInteritemSpacing(for section: Int) -> CGFloat {
        if let collectionView = collectionView,
           let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
           let minimumInteritemSpacing = delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) {
            return minimumInteritemSpacing
        } else {
            return minimumInteritemSpacing
        }
    }

    private func innerInset(for section: Int) -> UIEdgeInsets {
        if let collectionView = collectionView,
           let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
           let sectionInset = delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section) {
            return sectionInset
        } else {
            return sectionInset
        }
    }

    private func innerItemsHorizontalAlignment(for section: Int) -> CollectionViewItemsHorizontalAlignment {
        if let collectionView = collectionView,
           let delegate = collectionView.delegate as? CollectionViewDelegateAlignLayout,
           let itemsHorizontalAlignment = delegate.collectionView?(collectionView, layout: self, itemsHorizontalAlignmentForSectionAt: section) {
            return itemsHorizontalAlignment
        } else {
            return itemsHorizontalAlignment
        }
    }

    private func innerItemsVerticalAlignment(for section: Int) -> CollectionViewItemsVerticalAlignment {
        if let collectionView = collectionView,
           let delegate = collectionView.delegate as? CollectionViewDelegateAlignLayout,
           let itemsVerticalAlignment = delegate.collectionView?(collectionView, layout: self, itemsVerticalAlignmentForSectionAt: section) {
            return itemsVerticalAlignment
        } else {
            return itemsVerticalAlignment
        }
    }

    private func innerItemsDirection(for section: Int) -> CollectionViewItemsDirection {
        if let collectionView = collectionView,
           let delegate = collectionView.delegate as? CollectionViewDelegateAlignLayout,
           let itemsDirection = delegate.collectionView?(collectionView, layout: self, itemsDirectionForSectionAt: section) {
            return itemsDirection
        } else {
            return itemsDirection
        }
    }
    
    private func innerIsLineStart(at indexPath: IndexPath) -> Bool {
        if indexPath.item == 0 { return true }
        
        let currentIndexPath = indexPath
        let previousIndexPath = indexPath.item == 0 ? nil : IndexPath(item: indexPath.item - 1, section: indexPath.section)
        let currentAttributes = super.layoutAttributesForItem(at: currentIndexPath)
        let previousAttributes = previousIndexPath != nil ? super.layoutAttributesForItem(at: previousIndexPath!) : nil
        let currentFrame = currentAttributes?.frame ?? CGRect.zero
        let previousFrame = previousAttributes?.frame ?? CGRect.zero
        
        let insets = innerInset(for: currentIndexPath.section)
        let currentLineFrame = CGRect(x: insets.left, y: currentFrame.origin.y, width: collectionView?.frame.width ?? 0, height: currentFrame.size.height)
        let previousLineFrame = CGRect(x: insets.left, y: previousFrame.origin.y, width: collectionView?.frame.width ?? 0, height: previousFrame.size.height)
        return !currentLineFrame.intersects(previousLineFrame)
    }
    
    private func innerLineAttributesArray(startAttributes: UICollectionViewLayoutAttributes) -> [UICollectionViewLayoutAttributes] {
        var lineAttributesArray = [startAttributes]
        let itemCount = collectionView?.numberOfItems(inSection: startAttributes.indexPath.section) ?? 0
        let insets = innerInset(for: startAttributes.indexPath.section)
        var index = startAttributes.indexPath.item
        var isLineEnd = index == itemCount - 1
        while !isLineEnd {
            index += 1
            if index == itemCount {
                break
            }
            let nextIndexPath = IndexPath(item: index, section: startAttributes.indexPath.section)
            let nextAttributes = super.layoutAttributesForItem(at: nextIndexPath)
            let nextLineFrame = CGRect(x: insets.left, y: nextAttributes?.frame.origin.y ?? 0, width: collectionView?.frame.width ?? 0, height: nextAttributes?.frame.size.height ?? 0)
            isLineEnd = !startAttributes.frame.intersects(nextLineFrame)
            if isLineEnd {
                break
            }
            if let nextAttributes = nextAttributes {
                lineAttributesArray.append(nextAttributes)
            }
        }
        return lineAttributesArray
    }
    
    private func innerCalculateAndCacheFrame(for itemAttributesArray: [UICollectionViewLayoutAttributes]) {
        let section = itemAttributesArray.first?.indexPath.section ?? 0
        
        // 相关布局属性
        let horizontalAlignment = innerItemsHorizontalAlignment(for: section)
        let verticalAlignment = innerItemsVerticalAlignment(for: section)
        let direction = innerItemsDirection(for: section)
        let isR2L = direction == .rtl
        let sectionInsets = innerInset(for: section)
        let minimumInteritemSpacing = innerMinimumInteritemSpacing(for: section)
        let contentInsets = collectionView?.contentInset ?? .zero
        let collectionViewWidth = collectionView?.frame.width ?? .zero
        var widthArray = [CGFloat]()
        for attr in itemAttributesArray {
            widthArray.append(attr.frame.width)
        }
        let totalWidth = widthArray.reduce(0, +)
        let totalCount = itemAttributesArray.count
        let extra = collectionViewWidth - totalWidth - contentInsets.left - contentInsets.right - sectionInsets.left - sectionInsets.right - minimumInteritemSpacing * CGFloat(totalCount - 1)
        
        // 竖直方向位置(origin.y)，用于竖直方向对齐方式计算
        var tempOriginY: CGFloat = 0
        let frameValues = itemAttributesArray.map { $0.frame }
        if verticalAlignment == .top {
            tempOriginY = CGFloat.greatestFiniteMagnitude
            for frameValue in frameValues {
                tempOriginY = min(tempOriginY, frameValue.minY)
            }
        } else if verticalAlignment == .bottom {
            tempOriginY = CGFloat.leastNormalMagnitude
            for frameValue in frameValues {
                tempOriginY = max(tempOriginY, frameValue.maxY)
            }
        }
        
        // 计算起点及间距
        var start: CGFloat = 0, space: CGFloat = 0
        switch horizontalAlignment {
        case .left:
            start = isR2L ? (collectionViewWidth - totalWidth - contentInsets.left - contentInsets.right - sectionInsets.left - minimumInteritemSpacing * CGFloat(totalCount - 1)) : sectionInsets.left
            space = minimumInteritemSpacing
        case .center:
            let rest = extra / 2
            start = isR2L ? sectionInsets.right + rest : sectionInsets.left + rest
            space = minimumInteritemSpacing
        case .right:
            start = isR2L ? sectionInsets.right : (collectionViewWidth - totalWidth - contentInsets.left - contentInsets.right - sectionInsets.right - minimumInteritemSpacing * CGFloat(totalCount - 1))
            space = minimumInteritemSpacing
        case .flow:
            let isEnd = itemAttributesArray.last?.indexPath.item == (collectionView?.numberOfItems(inSection: section) ?? 0) - 1
            start = isR2L ? sectionInsets.right : sectionInsets.left
            space = isEnd ? minimumInteritemSpacing : (collectionViewWidth - totalWidth - contentInsets.left - contentInsets.right - sectionInsets.left - sectionInsets.right) / CGFloat(totalCount - 1)
        case .flowFilled:
            start = isR2L ? sectionInsets.right : sectionInsets.left
            space = minimumInteritemSpacing
        default:
            break
        }
        
        // 计算并缓存 frame
        var lastMaxX: CGFloat = 0
        for i in 0..<widthArray.count {
            var frame = itemAttributesArray[i].frame
            var width = widthArray[i]
            if horizontalAlignment == .flowFilled {
                width += extra / (totalWidth / width)
            }
            var originX: CGFloat = 0
            if isR2L {
                originX = i == 0 ? collectionViewWidth - start - contentInsets.right - contentInsets.left - width : lastMaxX - space - width
                lastMaxX = originX
            } else {
                originX = i == 0 ? start : lastMaxX + space
                lastMaxX = originX + width
            }
            var originY: CGFloat = 0
            if verticalAlignment == .bottom {
                originY = tempOriginY - frame.height
            } else if verticalAlignment == .center {
                originY = frame.origin.y
            } else {
                originY = tempOriginY
            }
            frame.origin.x = originX
            frame.origin.y = originY
            frame.size.width = width
            cachedFrame[itemAttributesArray[i].indexPath] = frame
        }
    }
    
}
