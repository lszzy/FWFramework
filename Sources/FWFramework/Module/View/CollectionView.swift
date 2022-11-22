//
//  CollectionView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - CollectionViewDelegate
/// 便捷集合视图代理
@objc(FWCollectionViewDelegate)
@objcMembers open class CollectionViewDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    /// 集合section数
    open var countForSection: (() -> Int)?
    /// 集合section数，优先级低
    open var sectionCount: Int = 0
    /// 集合item数句柄
    open var countForItem: ((Int) -> Int)?
    /// 集合item数，优先级低
    open var itemCount: Int = 0
    
    /// 集合section边距句柄，默认nil
    open var insetForSection: ((Int) -> UIEdgeInsets)?
    /// 集合section边距，默认zero，优先级低
    open var sectionInset: UIEdgeInsets = .zero
    
    /// 集合section头视图句柄，支持UICollectionReusableView，默认nil
    open var viewForHeader: ((IndexPath) -> Any?)?
    /// 集合section头视图，支持UICollectionReusableView，默认nil，优先级低
    open var headerViewClass: Any?
    /// 集合section头视图配置句柄，参数为headerClass对象，默认为nil
    open var headerConfiguration: ReusableViewIndexPathBlock?
    /// 集合section头尺寸句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var sizeForHeader: ((Int) -> CGSize)?
    /// 集合section头尺寸，默认nil，可设置为automaticSize，优先级低
    open var headerSize: CGSize?
    
    /// 集合section尾视图句柄，支持UICollectionReusableView，默认nil
    open var viewForFooter: ((IndexPath) -> Any?)?
    /// 集合section尾视图，支持UICollectionReusableView，默认nil，优先级低
    open var footerViewClass: Any?
    /// 集合section头视图配置句柄，参数为headerClass对象，默认为nil
    open var footerConfiguration: ReusableViewIndexPathBlock?
    /// 集合section尾尺寸句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var sizeForFooter: ((Int) -> CGSize)?
    /// 集合section尾尺寸，默认nil，可设置为automaticSize，优先级低
    open var footerSize: CGSize?
    
    /// 集合cell类句柄，支持UICollectionViewCell，默认nil
    open var cellForItem: ((IndexPath) -> Any?)?
    /// 集合cell类，支持UICollectionViewCell，默认nil，优先级低
    open var cellClass: Any?
    /// 集合cell配置句柄，参数为对应cellClass对象
    open var cellConfiguration: CollectionCellIndexPathBlock?
    /// 集合cell尺寸句柄，不指定时默认使用FWDynamicLayout自动计算并按indexPath缓存
    open var sizeForItem: ((IndexPath) -> CGSize)?
    /// 集合cell尺寸，默认nil，可设置为automaticSize，优先级低
    open var itemSize: CGSize?
    
    /// 集合选中事件，默认nil
    open var didSelectItem: ((IndexPath) -> Void)?
    
    func sectionInset(_ section: Int, _ collectionView: UICollectionView) -> UIEdgeInsets {
        if let insetBlock = insetForSection {
            return insetBlock(section)
        }
        if sectionInset != .zero {
            return sectionInset
        }
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.sectionInset
        }
        return .zero
    }
    
    // MARK: - UICollectionView
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let countBlock = countForSection {
            return countBlock()
        }
        return sectionCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let countBlock = countForItem {
            return countBlock(section)
        }
        return itemCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemCell = cellForItem?(indexPath) ?? cellClass
        if let cell = itemCell as? UICollectionViewCell {
            return cell
        }
        guard let clazz = itemCell as? UICollectionViewCell.Type else {
            return UICollectionViewCell(frame: .zero)
        }
        
        // 注意：此处必须使用.fw_创建，否则返回的对象类型不对
        let cell = clazz.fw_cell(collectionView: collectionView, indexPath: indexPath)
        cellConfiguration?(cell, indexPath)
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let sizeBlock = sizeForItem {
            return sizeBlock(indexPath)
        }
        if let itemSize = itemSize {
            return itemSize
        }
        
        let itemCell = cellForItem?(indexPath) ?? cellClass
        if let cell = itemCell as? UICollectionViewCell {
            return cell.frame.size
        }
        guard let clazz = itemCell as? UICollectionViewCell.Type else {
            return .zero
        }
        
        let inset = sectionInset(indexPath.section, collectionView)
        var width: CGFloat = 0
        if inset != .zero && collectionView.frame.size.width > 0 {
            width = collectionView.frame.size.width - inset.left - inset.right
        }
        return collectionView.fw.size(cellClass: clazz, width: width, cacheBy: indexPath) { [weak self] (cell) in
            self?.cellConfiguration?(cell, indexPath)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInset(section, collectionView)
    }
    
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let viewClass = viewForHeader?(indexPath) ?? headerViewClass
            if let view = viewClass as? UICollectionReusableView { return view }
            guard let clazz = viewClass as? UICollectionReusableView.Type else { return UICollectionReusableView() }
            
            // 注意：此处必须使用.fw_创建，否则返回的对象类型不对
            let view = clazz.fw_reusableView(collectionView: collectionView, kind: kind, indexPath: indexPath)
            headerConfiguration?(view, indexPath)
            return view
        }
        
        if kind == UICollectionView.elementKindSectionFooter {
            let viewClass = viewForFooter?(indexPath) ?? footerViewClass
            if let view = viewClass as? UICollectionReusableView { return view }
            guard let clazz = viewClass as? UICollectionReusableView.Type else { return UICollectionReusableView() }
            
            // 注意：此处必须使用.fw_创建，否则返回的对象类型不对
            let view = clazz.fw_reusableView(collectionView: collectionView, kind: kind, indexPath: indexPath)
            footerConfiguration?(view, indexPath)
            return view
        }
        
        return UICollectionReusableView()
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let sizeBlock = sizeForHeader {
            return sizeBlock(section)
        }
        if let headerSize = headerSize {
            return headerSize
        }
        
        let indexPath = IndexPath(item: 0, section: section)
        let viewClass = viewForHeader?(indexPath) ?? headerViewClass
        if let view = viewClass as? UICollectionReusableView { return view.frame.size }
        guard let clazz = viewClass as? UICollectionReusableView.Type else { return .zero }
        
        return collectionView.fw.size(reusableViewClass: clazz, kind: UICollectionView.elementKindSectionHeader, cacheBy: section) { [weak self] (reusableView) in
            self?.headerConfiguration?(reusableView, indexPath)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if let sizeBlock = sizeForFooter {
            return sizeBlock(section)
        }
        if let footerSize = footerSize {
            return footerSize
        }
        
        let indexPath = IndexPath(item: 0, section: section)
        let viewClass = viewForFooter?(indexPath) ?? footerViewClass
        if let view = viewClass as? UICollectionReusableView { return view.frame.size }
        guard let clazz = viewClass as? UICollectionReusableView.Type else { return .zero }
        
        return collectionView.fw.size(reusableViewClass: clazz, kind: UICollectionView.elementKindSectionFooter, cacheBy: section) { [weak self] (reusableView) in
            self?.footerConfiguration?(reusableView, indexPath)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectItem?(indexPath)
    }
}

extension Wrapper where Base: UICollectionView {
    public var delegate: CollectionViewDelegate {
        if let result = base.fw.property(forName: "fwDelegate") as? CollectionViewDelegate {
            return result
        } else {
            let result = CollectionViewDelegate()
            base.fw.setProperty(result, forName: "fwDelegate")
            base.dataSource = result
            base.delegate = result
            return result
        }
    }
    
    public static func collectionView() -> Base {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        return collectionView(flowLayout)
    }
    
    public static func collectionView(_ collectionViewLayout: UICollectionViewLayout) -> Base {
        let collectionView = Base(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }
}

extension Wrapper where Base: UICollectionViewFlowLayout {
    
    /// 初始化布局section配置，在prepareLayout调用即可
    public func sectionConfigPrepareLayout() {
        base.__fw_sectionConfigPrepare()
    }

    /// 获取布局section属性，在layoutAttributesForElementsInRect:调用并添加即可
    public func sectionConfigLayoutAttributes(forElementsIn rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        return base.__fw_sectionConfigLayoutAttributesForElements(in: rect)
    }
    
}
