//
//  CollectionLayout.swift
//  Pods
//
//  Created by wuyong on 2023/3/8.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

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

    override open func prepare() {
        super.prepare()
        fw.sectionConfigPrepareLayout()
        guard let collectionView,
              itemRenderVertical,
              verticalColumnCount > 0,
              verticalRowCount > 0 else { return }

        allAttributes.removeAll()
        let sectionCount = collectionView.numberOfSections
        for section in 0..<sectionCount {
            let itemCount = collectionView.numberOfItems(inSection: section)
            for item in 0..<itemCount {
                if let attributes = layoutAttributesForItem(at: IndexPath(item: item, section: section)) {
                    allAttributes.append(attributes)
                }
            }
        }
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
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

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
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

        let sectionAttributes = fw.sectionConfigLayoutAttributes(forElementsIn: rect)
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
        guard let collectionView else { return nil }
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
        guard let collectionView else { return }

        let proposedContentOffset: CGPoint
        let shouldAnimate: Bool
        switch scrollDirection {
        case .horizontal:
            var pageOffset = CGFloat(index) * pageWidth - collectionView.contentInset.left
            if !isPagingCenter {
                pageOffset = min(pageOffset, collectionView.fw.contentOffset(of: .right).x)
            }
            proposedContentOffset = CGPoint(x: pageOffset, y: collectionView.contentOffset.y)
            shouldAnimate = abs(collectionView.contentOffset.x - pageOffset) > 1 ? animated : false
        case .vertical:
            var pageOffset = CGFloat(index) * pageWidth - collectionView.contentInset.top
            if !isPagingCenter {
                pageOffset = min(pageOffset, collectionView.fw.contentOffset(of: .bottom).y)
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
        guard isPagingEnabled, let collectionView else { return }

        let currentCollectionViewSize = collectionView.bounds.size
        if !currentCollectionViewSize.equalTo(lastCollectionViewSize) || lastScrollDirection != scrollDirection || lastItemSize != itemSize, !currentCollectionViewSize.equalTo(.zero) {
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

        guard let collectionView else {
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

// MARK: - CollectionViewWaterfallLayout
public enum CollectionViewWaterfallLayoutItemRenderDirection: Int, Sendable {
    case shortestFirst
    case leftToRight
    case rightToLeft
}

@MainActor @objc public protocol CollectionViewDelegateWaterfallLayout: UICollectionViewDelegate {
    @objc(collectionView:layout:sizeForItemAtIndexPath:)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize

    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnCountForSection section: Int) -> Int

    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForHeaderInSection section: Int) -> CGFloat

    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForFooterInSection section: Int) -> CGFloat

    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets

    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForHeaderInSection section: Int) -> UIEdgeInsets

    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForFooterInSection section: Int) -> UIEdgeInsets

    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat

    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumColumnSpacingForSectionAt section: Int) -> CGFloat

    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, pinOffsetForHeaderInSection section: Int) -> CGFloat
}

/// [CHTCollectionViewWaterfallLayout](https://github.com/chiahsien/CHTCollectionViewWaterfallLayout)
open class CollectionViewWaterfallLayout: UICollectionViewLayout {
    open var columnCount: Int = 2 {
        didSet {
            if columnCount != oldValue {
                invalidateLayout()
            }
        }
    }

    open var minimumColumnSpacing: CGFloat = 10.0 {
        didSet {
            if minimumColumnSpacing != oldValue {
                invalidateLayout()
            }
        }
    }

    open var minimumInteritemSpacing: CGFloat = 10.0 {
        didSet {
            if minimumInteritemSpacing != oldValue {
                invalidateLayout()
            }
        }
    }

    open var headerHeight: CGFloat = 0 {
        didSet {
            if headerHeight != oldValue {
                invalidateLayout()
            }
        }
    }

    open var footerHeight: CGFloat = 0 {
        didSet {
            if footerHeight != oldValue {
                invalidateLayout()
            }
        }
    }

    open var headerInset: UIEdgeInsets = .zero {
        didSet {
            if headerInset != oldValue {
                invalidateLayout()
            }
        }
    }

    open var footerInset: UIEdgeInsets = .zero {
        didSet {
            if footerInset != oldValue {
                invalidateLayout()
            }
        }
    }

    open var sectionInset: UIEdgeInsets = .zero {
        didSet {
            if sectionInset != oldValue {
                invalidateLayout()
            }
        }
    }

    open var itemRenderDirection: CollectionViewWaterfallLayoutItemRenderDirection = .shortestFirst {
        didSet {
            if itemRenderDirection != oldValue {
                invalidateLayout()
            }
        }
    }

    open var minimumContentHeight: CGFloat = 0
    open var sectionHeadersPinToVisibleBounds: Bool = false {
        didSet {
            if sectionHeadersPinToVisibleBounds != oldValue {
                invalidateLayout()
            }
        }
    }

    private weak var delegate: CollectionViewDelegateWaterfallLayout? {
        collectionView?.delegate as? CollectionViewDelegateWaterfallLayout
    }

    private var columnHeights: [[CGFloat]] = []
    private var sectionItemAttributes: [[UICollectionViewLayoutAttributes]] = []
    private var allItemAttributes: [UICollectionViewLayoutAttributes] = []
    private var headersAttribute: [Int: UICollectionViewLayoutAttributes] = [:]
    private var footersAttribute: [Int: UICollectionViewLayoutAttributes] = [:]
    private var unionRects: [CGRect] = []

    private static let unionSize: Int = 20
    private static func floorValue(_ value: CGFloat) -> CGFloat {
        let scale = UIScreen.main.scale
        return floor(value * scale) / scale
    }

    override public init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open func columnCountForSection(_ section: Int) -> Int {
        if let collectionView, let count = delegate?.collectionView?(collectionView, layout: self, columnCountForSection: section) {
            return count
        } else {
            return columnCount
        }
    }

    open func itemWidthInSectionAt(_ section: Int) -> CGFloat {
        var sectionInset = sectionInset
        if let collectionView, let inset = delegate?.collectionView?(collectionView, layout: self, insetForSectionAt: section) {
            sectionInset = inset
        }
        let width = (collectionView?.bounds.width ?? 0) - sectionInset.left - sectionInset.right
        let columnCount = columnCountForSection(section)

        var columnSpacing = minimumColumnSpacing
        if let collectionView, let spacing = delegate?.collectionView?(collectionView, layout: self, minimumColumnSpacingForSectionAt: section) {
            columnSpacing = spacing
        }
        return Self.floorValue((width - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount))
    }

    override open func prepare() {
        super.prepare()

        headersAttribute.removeAll()
        footersAttribute.removeAll()
        unionRects.removeAll()
        columnHeights.removeAll()
        allItemAttributes.removeAll()
        sectionItemAttributes.removeAll()

        let numberOfSections = collectionView?.numberOfSections ?? 0
        guard let collectionView, numberOfSections > 0 else {
            return
        }

        for section in 0..<numberOfSections {
            let columnCount = columnCountForSection(section)
            var sectionColumnHeights: [CGFloat] = []
            for _ in 0..<columnCount {
                sectionColumnHeights.append(0)
            }
            columnHeights.append(sectionColumnHeights)
        }

        var top: CGFloat = 0
        var attributes: UICollectionViewLayoutAttributes

        for section in 0..<numberOfSections {
            var minimumInteritemSpacing = minimumInteritemSpacing
            if let spacing = delegate?.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) {
                minimumInteritemSpacing = spacing
            }

            var columnSpacing = minimumColumnSpacing
            if let spacing = delegate?.collectionView?(collectionView, layout: self, minimumColumnSpacingForSectionAt: section) {
                columnSpacing = spacing
            }

            var sectionInset = sectionInset
            if let inset = delegate?.collectionView?(collectionView, layout: self, insetForSectionAt: section) {
                sectionInset = inset
            }

            let width = collectionView.bounds.size.width - sectionInset.left - sectionInset.right
            let columnCount = columnCountForSection(section)
            let itemWidth = Self.floorValue((width - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount))

            var headerHeight = headerHeight
            if let height = delegate?.collectionView?(collectionView, layout: self, heightForHeaderInSection: section) {
                headerHeight = height
            }

            var headerInset = headerInset
            if let inset = delegate?.collectionView?(collectionView, layout: self, insetForHeaderInSection: section) {
                headerInset = inset
            }

            top += headerInset.top

            if headerHeight > 0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: headerInset.left, y: top, width: collectionView.bounds.size.width - (headerInset.left + headerInset.right), height: headerHeight)

                headersAttribute[section] = attributes
                allItemAttributes.append(attributes)

                top = attributes.frame.maxY + headerInset.bottom
            }

            top += sectionInset.top
            for idx in 0..<columnCount {
                columnHeights[section][idx] = top
            }

            let itemCount = collectionView.numberOfItems(inSection: section)
            var itemAttributes = [UICollectionViewLayoutAttributes]()

            for idx in 0..<itemCount {
                let indexPath = IndexPath(item: idx, section: section)
                let columnIndex = nextColumnIndexForItem(idx, inSection: section)
                let xOffset = sectionInset.left + (itemWidth + columnSpacing) * CGFloat(columnIndex)
                let yOffset = columnHeights[section][columnIndex]
                let itemSize = delegate?.collectionView(collectionView, layout: self, sizeForItemAt: indexPath) ?? .zero
                var itemHeight: CGFloat = 0
                if itemSize.height > 0 && itemSize.width > 0 {
                    itemHeight = Self.floorValue(itemSize.height * itemWidth / itemSize.width)
                }

                attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemWidth, height: itemHeight)
                itemAttributes.append(attributes)
                allItemAttributes.append(attributes)
                columnHeights[section][columnIndex] = attributes.frame.maxY + minimumInteritemSpacing
            }

            sectionItemAttributes.append(itemAttributes)

            let columnIndex = longestColumnIndexInSection(section)
            if columnHeights[section].count > 0 {
                top = columnHeights[section][columnIndex] - minimumInteritemSpacing + sectionInset.bottom
            } else {
                top = 0
            }

            var footerHeight = footerHeight
            if let height = delegate?.collectionView?(collectionView, layout: self, heightForFooterInSection: section) {
                footerHeight = height
            }

            var footerInset = footerInset
            if let inset = delegate?.collectionView?(collectionView, layout: self, insetForFooterInSection: section) {
                footerInset = inset
            }

            top += footerInset.top

            if footerHeight > 0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: footerInset.left, y: top, width: collectionView.bounds.size.width - (footerInset.left + footerInset.right), height: footerHeight)

                footersAttribute[section] = attributes
                allItemAttributes.append(attributes)

                top = attributes.frame.maxY + footerInset.bottom
            }

            for idx in 0..<columnCount {
                columnHeights[section][idx] = top
            }
        }

        var idx = 0
        let itemCounts = allItemAttributes.count

        while idx < itemCounts {
            var unionRect = allItemAttributes[idx].frame
            let rectEndIndex = min(idx + Self.unionSize, itemCounts)

            for i in (idx + 1)..<rectEndIndex {
                unionRect = unionRect.union(allItemAttributes[i].frame)
            }

            idx = rectEndIndex
            unionRects.append(unionRect)
        }
    }

    override open var collectionViewContentSize: CGSize {
        let numberOfSections = collectionView?.numberOfSections ?? 0
        if numberOfSections < 1 { return .zero }

        var contentSize = collectionView?.bounds.size ?? .zero
        contentSize.height = columnHeights.last?.first ?? .zero
        if contentSize.height < minimumContentHeight {
            contentSize.height = minimumContentHeight
        }
        return contentSize
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section >= sectionItemAttributes.count {
            return nil
        }
        let sectionAttributes = sectionItemAttributes[indexPath.section]
        if indexPath.item >= sectionAttributes.count {
            return nil
        }
        return sectionAttributes[indexPath.item]
    }

    override open func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        var attribute: UICollectionViewLayoutAttributes?
        if elementKind == UICollectionView.elementKindSectionHeader {
            attribute = headersAttribute[indexPath.section]
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            attribute = footersAttribute[indexPath.section]
        }
        return attribute
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var begin = 0
        var end: Int = unionRects.count
        var cellAttrDict = [IndexPath: UICollectionViewLayoutAttributes]()
        var supplHeaderAttrDict = [IndexPath: UICollectionViewLayoutAttributes]()
        var supplFooterAttrDict = [IndexPath: UICollectionViewLayoutAttributes]()
        var decorAttrDict = [IndexPath: UICollectionViewLayoutAttributes]()

        for i in 0..<unionRects.count {
            if rect.intersects(unionRects[i]) {
                begin = i * Self.unionSize
                break
            }
        }

        for i in stride(from: unionRects.count - 1, through: 0, by: -1) {
            if rect.intersects(unionRects[i]) {
                end = min((i + 1) * Self.unionSize, allItemAttributes.count)
                break
            }
        }

        for i in begin..<end {
            let attr = allItemAttributes[i]
            if rect.intersects(attr.frame) {
                switch attr.representedElementCategory {
                case .supplementaryView:
                    if attr.representedElementKind == UICollectionView.elementKindSectionHeader {
                        supplHeaderAttrDict[attr.indexPath] = attr
                    } else if attr.representedElementKind == UICollectionView.elementKindSectionFooter {
                        supplFooterAttrDict[attr.indexPath] = attr
                    }
                case .decorationView:
                    decorAttrDict[attr.indexPath] = attr
                case .cell:
                    cellAttrDict[attr.indexPath] = attr
                default:
                    break
                }
            }
        }

        if sectionHeadersPinToVisibleBounds {
            for i in 0..<allItemAttributes.count {
                let attr = allItemAttributes[i]
                if attr.representedElementKind != UICollectionView.elementKindSectionHeader {
                    continue
                }

                let section = attr.indexPath.section
                var pinOffset: CGFloat = 0
                if let collectionView, let offset = delegate?.collectionView?(collectionView, layout: self, pinOffsetForHeaderInSection: section) {
                    pinOffset = offset
                }
                if pinOffset < 0 {
                    continue
                }

                let itemCount = collectionView?.numberOfItems(inSection: section) ?? .zero
                guard let beginAttr = layoutAttributesForItem(at: IndexPath(item: 0, section: section)),
                      let endAttr = layoutAttributesForItem(at: IndexPath(item: max(0, itemCount - 1), section: section)) else {
                    continue
                }

                var headerInset = headerInset
                if let collectionView, let inset = delegate?.collectionView?(collectionView, layout: self, insetForHeaderInSection: section) {
                    headerInset = inset
                }

                var attrFrame = attr.frame
                let beginY = max((collectionView?.contentOffset.y ?? 0) + pinOffset, beginAttr.frame.minY - attrFrame.height - headerInset.bottom)
                let endY = endAttr.frame.maxY - attrFrame.height - headerInset.bottom
                attrFrame.origin.y = min(beginY, endY)
                attr.frame = attrFrame
                attr.zIndex = 1024
                supplHeaderAttrDict[attr.indexPath] = attr
            }
        }

        let result = Array(cellAttrDict.values) + Array(supplHeaderAttrDict.values) + Array(supplFooterAttrDict.values) + Array(decorAttrDict.values)
        return result
    }

    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if sectionHeadersPinToVisibleBounds {
            return true
        }
        let oldBounds = collectionView?.bounds ?? .zero
        if newBounds.width != oldBounds.width {
            return true
        }
        return false
    }

    private func shortestColumnIndexInSection(_ section: Int) -> Int {
        var index = 0
        var shortestHeight: CGFloat = .greatestFiniteMagnitude
        for (idx, height) in columnHeights[section].enumerated() {
            if height < shortestHeight {
                shortestHeight = height
                index = idx
            }
        }
        return index
    }

    private func longestColumnIndexInSection(_ section: Int) -> Int {
        var index = 0
        var longestHeight: CGFloat = 0
        for (idx, height) in columnHeights[section].enumerated() {
            if height > longestHeight {
                longestHeight = height
                index = idx
            }
        }
        return index
    }

    private func nextColumnIndexForItem(_ item: Int, inSection section: Int) -> Int {
        var index = 0
        let columnCount = columnCountForSection(section)
        switch itemRenderDirection {
        case .leftToRight:
            index = (item % columnCount)
        case .rightToLeft:
            index = (columnCount - 1) - (item % columnCount)
        default:
            index = shortestColumnIndexInSection(section)
        }
        return index
    }
}
