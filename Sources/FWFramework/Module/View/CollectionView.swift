//
//  CollectionView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UICollectionView
@MainActor extension Wrapper where Base: UICollectionView {
    /// 集合视图代理，延迟加载
    public var collectionDelegate: CollectionViewDelegate {
        get {
            if let result = property(forName: "collectionDelegate") as? CollectionViewDelegate {
                return result
            } else {
                let result = CollectionViewDelegate()
                setProperty(result, forName: "collectionDelegate")
                return result
            }
        }
        set {
            setProperty(newValue, forName: "collectionDelegate")
        }
    }
    
    /// 快速创建collectionView
    public static func collectionView() -> Base {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        return collectionView(flowLayout)
    }
    
    /// 快速创建collectionView，自定义collectionViewLayout
    public static func collectionView(_ collectionViewLayout: UICollectionViewLayout) -> Base {
        let collectionView = Base.init(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }
}

// MARK: - Wrapper+UICollectionViewFlowLayout
@MainActor extension Wrapper where Base: UICollectionViewFlowLayout {
    /// 初始化布局section配置，在prepareLayout调用即可
    public func sectionConfigPrepareLayout() {
        guard let collectionView = base.collectionView,
              let delegate = collectionView.delegate as? CollectionViewDelegateFlowLayout,
              delegate.responds(to: #selector(CollectionViewDelegateFlowLayout.collectionView(_:layout:configForSectionAt:))) else { return }
        
        base.register(CollectionViewReusableView.self, forDecorationViewOfKind: "FWCollectionViewElementKind")
        sectionConfigAttributes.removeAll()
        let sectionCount = collectionView.numberOfSections
        for section in 0 ..< sectionCount {
            let itemCount = collectionView.numberOfItems(inSection: section)
            if itemCount < 1 { continue }
            
            guard let firstAttr = base.layoutAttributesForItem(at: IndexPath(item: 0, section: section)),
                  let lastAttr = base.layoutAttributesForItem(at: IndexPath(item: itemCount - 1, section: section)) else { continue }
            
            var sectionInset = base.sectionInset
            if let inset = delegate.collectionView?(collectionView, layout: base, insetForSectionAt: section),
               inset != sectionInset {
                sectionInset = inset
            }
            
            var sectionFrame = firstAttr.frame.union(lastAttr.frame)
            sectionFrame.origin.x -= sectionInset.left
            sectionFrame.origin.y -= sectionInset.top
            if base.scrollDirection == .horizontal {
                sectionFrame.size.width += sectionInset.left + sectionInset.right
                sectionFrame.size.height = collectionView.frame.size.height
            } else {
                sectionFrame.size.width = collectionView.frame.size.width
                sectionFrame.size.height += sectionInset.top + sectionInset.bottom
            }
            
            let attributes = CollectionViewLayoutAttributes(forDecorationViewOfKind: "FWCollectionViewElementKind", with: IndexPath(item: 0, section: section))
            attributes.frame = sectionFrame
            attributes.zIndex = -1
            attributes.sectionConfig = delegate.collectionView?(collectionView, layout: base, configForSectionAt: section)
            sectionConfigAttributes.append(attributes)
        }
    }

    /// 获取布局section属性，在layoutAttributesForElementsInRect:调用并添加即可
    public func sectionConfigLayoutAttributes(forElementsIn rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        var attrs: [UICollectionViewLayoutAttributes] = []
        for attr in sectionConfigAttributes {
            if CGRectIntersectsRect(rect, attr.frame) {
                attrs.append(attr)
            }
        }
        return attrs
    }
    
    private var sectionConfigAttributes: [UICollectionViewLayoutAttributes] {
        get { return property(forName: "sectionConfigAttributes") as? [UICollectionViewLayoutAttributes] ?? [] }
        set { setProperty(newValue, forName: "sectionConfigAttributes") }
    }
}

// MARK: - CollectionViewDelegate
/// 常用集合视图数据源和事件代理，可继承
open class CollectionViewDelegate: DelegateProxy<UICollectionViewDelegate>, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    /// 集合section数
    open var numberOfSections: (() -> Int)?
    /// 集合section数，默认1，优先级低
    open var sectionCount: Int = 1
    /// 集合item数句柄
    open var numberOfItems: ((Int) -> Int)?
    /// 集合item数，优先级低
    open var itemCount: Int = 0
    
    /// 集合section边距句柄，默认nil
    open var insetForSection: ((UICollectionView, Int) -> UIEdgeInsets)?
    /// 集合section边距，默认nil
    open var sectionInset: UIEdgeInsets?
    /// 集合section滚动方向最小平行间距句柄，默认nil
    open var minimumLineSpacingForSection: ((UICollectionView, Int) -> CGFloat)?
    /// 集合section滚动方向最小平行间距，默认nil
    open var minimumLineSpacing: CGFloat?
    /// 集合section滚动方向最小垂直间距句柄，默认nil
    open var minimumInteritemSpacingForSection: ((UICollectionView, Int) -> CGFloat)?
    /// 集合section滚动方向最小垂直间距，默认nil
    open var minimumInteritemSpacing: CGFloat?
    
    /// 集合section头视图句柄，size未指定时为automaticSize，默认nil
    open var viewForHeader: ((UICollectionView, IndexPath) -> UICollectionReusableView?)?
    /// 集合section头视图类句柄，搭配headerConfiguration使用，默认nil
    open var viewClassForHeader: ((UICollectionView, IndexPath) -> UICollectionReusableView.Type?)?
    /// 集合section头视图类，搭配headerConfiguration使用，默认nil，优先级低
    open var headerViewClass: UICollectionReusableView.Type?
    /// 集合section头视图配置句柄，参数为headerClass对象，默认为nil
    open var headerConfiguration: ((UICollectionReusableView, IndexPath) -> Void)?
    /// 集合section头尺寸句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var sizeForHeader: ((UICollectionView, Int) -> CGSize)?
    /// 集合section头尺寸，默认nil，可设置为automaticSize，优先级低
    open var headerSize: CGSize?
    
    /// 集合section尾视图句柄，size未指定时为automaticSize，默认nil
    open var viewForFooter: ((UICollectionView, IndexPath) -> UICollectionReusableView?)?
    /// 集合section尾视图类句柄，搭配footerConfiguration使用，默认nil
    open var viewClassForFooter: ((UICollectionView, IndexPath) -> UICollectionReusableView.Type?)?
    /// 集合section尾视图类，搭配footerConfiguration使用，默认nil，优先级低
    open var footerViewClass: UICollectionReusableView.Type?
    /// 集合section头视图配置句柄，参数为headerClass对象，默认为nil
    open var footerConfiguration: ((UICollectionReusableView, IndexPath) -> Void)?
    /// 集合section尾尺寸句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var sizeForFooter: ((UICollectionView, Int) -> CGSize)?
    /// 集合section尾尺寸，默认nil，可设置为automaticSize，优先级低
    open var footerSize: CGSize?
    
    /// 集合cell视图句柄，size未指定时为automaticSize，默认nil
    open var cellForItem: ((UICollectionView, IndexPath) -> UICollectionViewCell?)?
    /// 集合cell视图类句柄，搭配cellConfiguration使用，默认nil
    open var cellClassForItem: ((UICollectionView, IndexPath) -> UICollectionViewCell.Type?)?
    /// 集合cell类，搭配cellConfiguation使用，默认nil时为UITableViewCell.Type，优先级低
    open var cellClass: UICollectionViewCell.Type?
    /// 集合cell配置句柄，参数为对应cellClass对象
    open var cellConfiguration: ((UICollectionViewCell, IndexPath) -> Void)?
    /// 集合cell尺寸句柄，不指定时默认使用FWDynamicLayout自动计算并按indexPath缓存
    open var sizeForItem: ((UICollectionView, IndexPath) -> CGSize)?
    /// 集合cell尺寸，默认nil，可设置为automaticSize，优先级低
    open var itemSize: CGSize?
    
    /// 是否启用默认尺寸缓存，优先级低于cacheKey句柄，默认false
    open var sizeCacheEnabled = false
    /// 集合cell自定义尺寸缓存key句柄，默认nil，优先级高
    open var cacheKeyForItem: ((IndexPath) -> AnyHashable?)?
    /// 集合section头自定义尺寸缓存key句柄，默认nil，优先级高
    open var cacheKeyForHeader: ((Int) -> AnyHashable?)?
    /// 集合section尾自定义尺寸缓存key句柄，默认nil，优先级高
    open var cacheKeyForFooter: ((Int) -> AnyHashable?)?
    
    /// 集合选中事件，默认nil
    open var didSelectItem: ((UICollectionView, IndexPath) -> Void)?
    /// 集合cell即将显示句柄，默认nil
    open var willDisplayCell: ((UICollectionViewCell, IndexPath) -> Void)?
    /// 集合cell即将停止显示，默认nil
    open var didEndDisplayingCell: ((UICollectionViewCell, IndexPath) -> Void)?
    
    /// 集合滚动句柄，默认nil
    open var didScroll: ((UIScrollView) -> Void)?
    /// 集合即将开始拖动句柄，默认nil
    open var willBeginDragging: ((UIScrollView) -> Void)?
    /// 集合即将停止拖动句柄，默认nil
    open var willEndDragging: ((UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void)?
    /// 集合已经停止拖动句柄，默认nil
    open var didEndDragging: ((UIScrollView, Bool) -> Void)?
    /// 集合已经停止减速句柄，默认nil
    open var didEndDecelerating: ((UIScrollView) -> Void)?
    /// 集合已经停止滚动动画句柄，默认nil
    open var didEndScrollingAnimation: ((UIScrollView) -> Void)?
    
    // MARK: - Lifecycle
    /// 初始化并绑定collectionView
    public convenience init(collectionView: UICollectionView) {
        self.init()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    // MARK: - UICollectionViewDataSource
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        let dataSource = delegate as? UICollectionViewDataSource
        if let sectionCount = dataSource?.numberOfSections?(in: collectionView) {
            return sectionCount
        }
        
        if let countBlock = numberOfSections {
            return countBlock()
        }
        return sectionCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let dataSource = delegate as? UICollectionViewDataSource
        if let itemCount = dataSource?.collectionView(collectionView, numberOfItemsInSection: section) {
            return itemCount
        }
        
        if let countBlock = numberOfItems {
            return countBlock(section)
        }
        return itemCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dataSource = delegate as? UICollectionViewDataSource
        if let cell = dataSource?.collectionView(collectionView, cellForItemAt: indexPath) {
            return cell
        }
        
        if let cell = cellForItem?(collectionView, indexPath) {
            return cell
        }
        let cellClass = cellClassForItem?(collectionView, indexPath) ?? (cellClass ?? UICollectionViewCell.self)
        // 注意：此处必须使用collectionView.fw.cell创建，否则返回的对象类型不对
        let cell = collectionView.fw.cell(of: cellClass, indexPath: indexPath)
        cellConfiguration?(cell, indexPath)
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let dataSource = delegate as? UICollectionViewDataSource
        if let view = dataSource?.collectionView?(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath) {
            return view
        }
        
        if kind == UICollectionView.elementKindSectionHeader {
            if let view = viewForHeader?(collectionView, indexPath) {
                return view
            }
            let viewClass = viewClassForHeader?(collectionView, indexPath) ?? headerViewClass
            guard let viewClass = viewClass else {
                return UICollectionReusableView()
            }
            
            // 注意：此处必须使用collectionView.fw.reusableView创建，否则返回的对象类型不对
            let view = collectionView.fw.reusableView(of: viewClass, kind: kind, indexPath: indexPath)
            headerConfiguration?(view, indexPath)
            return view
        }
        
        if kind == UICollectionView.elementKindSectionFooter {
            if let view = viewForFooter?(collectionView, indexPath) {
                return view
            }
            let viewClass = viewClassForFooter?(collectionView, indexPath) ?? footerViewClass
            guard let viewClass = viewClass else {
                return UICollectionReusableView()
            }
            
            // 注意：此处必须使用collectionView.fw.reusableView创建，否则返回的对象类型不对
            let view = collectionView.fw.reusableView(of: viewClass, kind: kind, indexPath: indexPath)
            footerConfiguration?(view, indexPath)
            return view
        }
        
        return UICollectionReusableView()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let delegateFlowLayout = delegate as? UICollectionViewDelegateFlowLayout
        if let itemSize = delegateFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) {
            return itemSize
        }
        
        if let sizeBlock = sizeForItem {
            return sizeBlock(collectionView, indexPath)
        }
        if let itemSize = itemSize {
            return itemSize
        }
        
        if cellForItem != nil || cellConfiguration == nil {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.itemSize
            }
            return UICollectionViewFlowLayout.automaticSize
        }
        let cellClass = cellClassForItem?(collectionView, indexPath) ?? (cellClass ?? UICollectionViewCell.self)
        let sectionInset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        var width: CGFloat = 0
        if sectionInset != .zero && collectionView.frame.size.width > 0 {
            width = collectionView.frame.size.width - sectionInset.left - sectionInset.right
        }
        let cacheKey = cacheKeyForItem?(indexPath) ?? (sizeCacheEnabled ? indexPath : nil)
        return collectionView.fw.size(cellClass: cellClass, width: width, cacheBy: cacheKey) { [weak self] (cell) in
            self?.cellConfiguration?(cell, indexPath)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let delegateFlowLayout = delegate as? UICollectionViewDelegateFlowLayout
        if let sectionInset = delegateFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, insetForSectionAt: section) {
            return sectionInset
        }
        
        if let insetBlock = insetForSection {
            return insetBlock(collectionView, section)
        }
        if let sectionInset = sectionInset {
            return sectionInset
        }
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.sectionInset
        }
        return .zero
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let delegateFlowLayout = delegate as? UICollectionViewDelegateFlowLayout
        if let minimumLineSpacing = delegateFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAt: section) {
            return minimumLineSpacing
        }
        
        if let spacingBlock = minimumLineSpacingForSection {
            return spacingBlock(collectionView, section)
        }
        if let minimumLineSpacing = minimumLineSpacing {
            return minimumLineSpacing
        }
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.minimumLineSpacing
        }
        return .zero
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let delegateFlowLayout = delegate as? UICollectionViewDelegateFlowLayout
        if let minimumInteritemSpacing = delegateFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: section) {
            return minimumInteritemSpacing
        }
        
        if let spacingBlock = minimumInteritemSpacingForSection {
            return spacingBlock(collectionView, section)
        }
        if let minimumInteritemSpacing = minimumInteritemSpacing {
            return minimumInteritemSpacing
        }
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.minimumInteritemSpacing
        }
        return .zero
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let delegateFlowLayout = delegate as? UICollectionViewDelegateFlowLayout
        if let headerSize = delegateFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section) {
            return headerSize
        }
        
        if let sizeBlock = sizeForHeader {
            return sizeBlock(collectionView, section)
        }
        if let headerSize = headerSize {
            return headerSize
        }
        
        let indexPath = IndexPath(item: 0, section: section)
        if viewForHeader != nil {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.headerReferenceSize
            }
            return UICollectionViewFlowLayout.automaticSize
        }
        let viewClass = viewClassForHeader?(collectionView, indexPath) ?? headerViewClass
        guard let viewClass = viewClass else {
            return .zero
        }
        if headerConfiguration == nil {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.headerReferenceSize
            }
            return UICollectionViewFlowLayout.automaticSize
        }
        
        let cacheKey = cacheKeyForHeader?(section) ?? (sizeCacheEnabled ? section : nil)
        return collectionView.fw.size(reusableViewClass: viewClass, kind: UICollectionView.elementKindSectionHeader, cacheBy: cacheKey) { [weak self] (reusableView) in
            self?.headerConfiguration?(reusableView, indexPath)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let delegateFlowLayout = delegate as? UICollectionViewDelegateFlowLayout
        if let footerSize = delegateFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForFooterInSection: section) {
            return footerSize
        }
        
        if let sizeBlock = sizeForFooter {
            return sizeBlock(collectionView, section)
        }
        if let footerSize = footerSize {
            return footerSize
        }
        
        let indexPath = IndexPath(item: 0, section: section)
        if viewForFooter != nil {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.footerReferenceSize
            }
            return UICollectionViewFlowLayout.automaticSize
        }
        let viewClass = viewClassForFooter?(collectionView, indexPath) ?? footerViewClass
        guard let viewClass = viewClass else {
            return .zero
        }
        if footerConfiguration == nil {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.footerReferenceSize
            }
            return UICollectionViewFlowLayout.automaticSize
        }
        
        let cacheKey = cacheKeyForFooter?(section) ?? (sizeCacheEnabled ? section : nil)
        return collectionView.fw.size(reusableViewClass: viewClass, kind: UICollectionView.elementKindSectionFooter, cacheBy: cacheKey) { [weak self] (reusableView) in
            self?.footerConfiguration?(reusableView, indexPath)
        }
    }
    
    // MARK: - UICollectionViewDelegate
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if delegate?.collectionView?(collectionView, didSelectItemAt: indexPath) != nil {
            return
        }
        
        didSelectItem?(collectionView, indexPath)
    }
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if delegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath) != nil {
            return
        }
        
        willDisplayCell?(cell, indexPath)
    }
    
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if delegate?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath) != nil {
            return
        }
        
        didEndDisplayingCell?(cell, indexPath)
    }
    
    // MARK: - UIScrollViewDelegate
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if delegate?.scrollViewDidScroll?(scrollView) != nil {
            return
        }
        
        didScroll?(scrollView)
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if delegate?.scrollViewWillBeginDragging?(scrollView) != nil {
            return
        }
        
        willBeginDragging?(scrollView)
    }
    
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset) != nil {
            return
        }
        
        willEndDragging?(scrollView, velocity, targetContentOffset)
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate) != nil {
            return
        }
        
        didEndDragging?(scrollView, decelerate)
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if delegate?.scrollViewDidEndDecelerating?(scrollView) != nil {
            return
        }
        
        didEndDecelerating?(scrollView)
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if delegate?.scrollViewDidEndScrollingAnimation?(scrollView) != nil {
            return
        }
        
        didEndScrollingAnimation?(scrollView)
    }
}

// MARK: - CollectionViewLayoutAttributes
fileprivate class CollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    
    var sectionConfig: CollectionViewSectionConfig?
    
}

// MARK: - CollectionViewReusableView
private class CollectionViewReusableView: UICollectionReusableView {
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let layoutAttributes = layoutAttributes as? CollectionViewLayoutAttributes,
              let sectionConfig = layoutAttributes.sectionConfig else { return }
        
        self.backgroundColor = sectionConfig.backgroundColor
        sectionConfig.customBlock?(self)
    }
    
}
