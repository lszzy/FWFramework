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

extension Wrapper where Base: UICollectionView {
    public var delegate: CollectionViewDelegate {
        return base.fw_delegate
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
        base.__fw_sectionConfigPrepare()
    }

    /// 获取布局section属性，在layoutAttributesForElementsInRect:调用并添加即可
    public func sectionConfigLayoutAttributes(forElementsIn rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        return base.__fw_sectionConfigLayoutAttributesForElements(in: rect)
    }
    
}
