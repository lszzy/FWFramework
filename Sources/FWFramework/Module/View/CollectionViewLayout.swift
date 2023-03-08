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
                newOffset = candidateAttributesForRect.center.x - sectionInset.left - itemSize.width / 2
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
                newOffset = candidateAttributesForRect.center.y - sectionInset.top - itemSize.height / 2
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
                proposedCenterOffset = proposedContentOffset.x + sectionInset.left + itemSize.width / 2
            }
        case .vertical:
            if isPagingCenter {
                proposedCenterOffset = proposedContentOffset.y + collectionView.bounds.size.height / 2
            } else {
                proposedCenterOffset = proposedContentOffset.y + sectionInset.top + itemSize.height / 2
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
