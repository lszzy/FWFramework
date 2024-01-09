//
//  CollectionView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UICollectionView {
    public var collectionDelegate: CollectionViewDelegate {
        get { base.fw_collectionDelegate }
        set { base.fw_collectionDelegate = newValue }
    }
    
    public static func collectionView() -> Base {
        return Base.fw_collectionView()
    }
    
    public static func collectionView(_ collectionViewLayout: UICollectionViewLayout) -> Base {
        return Base.fw_collectionView(collectionViewLayout)
    }
}

extension Wrapper where Base: UICollectionViewFlowLayout {
    
    /// 初始化布局section配置，在prepareLayout调用即可
    public func sectionConfigPrepareLayout() {
        base.fw_sectionConfigPrepareLayout()
    }

    /// 获取布局section属性，在layoutAttributesForElementsInRect:调用并添加即可
    public func sectionConfigLayoutAttributes(forElementsIn rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        return base.fw_sectionConfigLayoutAttributes(forElementsIn: rect)
    }
    
}
