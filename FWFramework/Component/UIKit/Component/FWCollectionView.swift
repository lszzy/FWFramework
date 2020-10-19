//
//  FWCollectionView.swift
//  FWFramework
//
//  Created by wuyong on 2020/9/27.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

/// 便捷集合视图
@objcMembers open class FWCollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    /// 集合视图
    open lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewLayout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    /// 集合布局，默认UICollectionViewFlowLayout
    open var collectionViewLayout: UICollectionViewLayout
    
    /// 集合数据，可选方式，必须按[section][item]二维数组格式
    open var collectionData: [[Any]] = []
    
    /// 集合section数，默认自动计算collectionData
    open var numberOfSections: (() -> Int)?
    
    /// 集合section头视图句柄，支持UICollectionReusableView.Type
    open var viewClassForHeader: ((IndexPath) -> UICollectionReusableView.Type)?
    /// 集合section头视图配置句柄，参数为headerClass对象，默认为nil
    open var viewForHeader: FWReusableViewIndexPathBlock?
    /// 集合section头尺寸句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var sizeForHeader: ((Int) -> CGSize)?
    
    /// 集合section尾视图句柄，支持UICollectionReusableView.Type
    open var viewClassForFooter: ((IndexPath) -> UICollectionReusableView.Type)?
    /// 集合section头视图配置句柄，参数为headerClass对象，默认为nil
    open var viewForFooter: FWReusableViewIndexPathBlock?
    /// 集合section尾尺寸句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var sizeForFooter: ((Int) -> CGSize)?
    
    /// 集合item数句柄，默认自动计算collectionData
    open var numberOfItems: ((Int) -> Int)?
    /// 集合cell类句柄，默认UICollectionViewCell
    open var cellClassForItem: ((IndexPath) -> UICollectionViewCell.Type)?
    /// 集合cell配置句柄，参数为对应cellClass对象，默认设置fwViewModel为collectionData对应数据
    open var cellForItem: FWCollectionCellIndexPathBlock?
    /// 集合cell高度句柄，不指定时默认使用FWDynamicLayout自动计算并按indexPath缓存
    open var sizeForItem: ((IndexPath) -> CGSize)?
    /// 集合选中事件，默认nil
    open var didSelectItem: ((IndexPath) -> Void)?
    
    public override init(frame: CGRect) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        self.collectionViewLayout = flowLayout
        super.init(frame: frame)
        setupView()
    }
    
    public init(collectionViewLayout: UICollectionViewLayout) {
        self.collectionViewLayout = collectionViewLayout
        super.init(frame: .zero)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(collectionView)
        collectionView.fwPinEdgesToSuperview()
    }
    
    open func reloadData() {
        collectionView.reloadData()
    }
    
    // MARK: - UICollectionView
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let numberBlock = numberOfSections {
            return numberBlock()
        }
        
        return collectionData.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let numberBlock = numberOfItems {
            return numberBlock(section)
        }
        
        return collectionData.count > section ? collectionData[section].count : 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let clazz = cellClassForItem?(indexPath) ?? UICollectionViewCell.self
        let cell = clazz.fwCell(with: collectionView, indexPath: indexPath)
        if let cellBlock = cellForItem {
            cellBlock(cell, indexPath)
            return cell
        }
        
        var viewModel: Any?
        if let sectionData = collectionData.count > indexPath.section ? collectionData[indexPath.section] : nil,
           sectionData.count > indexPath.item {
            viewModel = sectionData[indexPath.item]
        }
        cell.fwViewModel = viewModel
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let sizeBlock = sizeForItem {
            return sizeBlock(indexPath)
        }
        
        let clazz = cellClassForItem?(indexPath) ?? UICollectionView.self
        if let cellBlock = cellForItem {
            return collectionView.fwSize(withCellClass: clazz, cacheBy: indexPath) { (cell) in
                cellBlock(cell, indexPath)
            }
        }
        
        var viewModel: Any?
        if let sectionData = collectionData.count > indexPath.section ? collectionData[indexPath.section] : nil,
           sectionData.count > indexPath.item {
            viewModel = sectionData[indexPath.item]
        }
        return collectionView.fwSize(withCellClass: clazz, cacheBy: indexPath) { (cell) in
            cell.fwViewModel = viewModel
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let clazz = viewClassForHeader?(indexPath) else { return UICollectionReusableView() }
            
            let view = clazz.fwReusableView(with: collectionView, kind: kind, indexPath: indexPath)
            let viewBlock = viewForHeader ?? { (header, indexPath) in header.fwViewModel = nil }
            viewBlock(view, indexPath)
            return view
        } else if kind == UICollectionView.elementKindSectionFooter {
            guard let clazz = viewClassForFooter?(indexPath) else { return UICollectionReusableView() }
            
            let view = clazz.fwReusableView(with: collectionView, kind: kind, indexPath: indexPath)
            let viewBlock = viewForFooter ?? { (footer, indexPath) in footer.fwViewModel = nil }
            viewBlock(view, indexPath)
            return view
        }
        return UICollectionReusableView()
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let sizeBlock = sizeForHeader {
            return sizeBlock(section)
        }
        
        let indexPath = IndexPath(item: 0, section: section)
        guard let clazz = viewClassForHeader?(indexPath) else { return .zero }
        let viewBlock = viewForHeader ?? { (header, indexPath) in header.fwViewModel = nil }
        return collectionView.fwSize(withReusableViewClass: clazz, kind: UICollectionView.elementKindSectionHeader, cacheBySection: section) { (reusableView) in
            viewBlock(reusableView, indexPath)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if let sizeBlock = sizeForFooter {
            return sizeBlock(section)
        }
        
        let indexPath = IndexPath(item: 0, section: section)
        guard let clazz = viewClassForFooter?(indexPath) else { return .zero }
        let viewBlock = viewForFooter ?? { (footer, indexPath) in footer.fwViewModel = nil }
        return collectionView.fwSize(withReusableViewClass: clazz, kind: UICollectionView.elementKindSectionFooter, cacheBySection: section) { (reusableView) in
            viewBlock(reusableView, indexPath)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectItem?(indexPath)
    }
}
