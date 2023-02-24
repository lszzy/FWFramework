//
//  StatisticalView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - UIView+StatisticalClick
extension Wrapper where Base: UIView {
    
    /// 手工触发点击统计，如果为cell需指定indexPath，点击触发时调用
    public func trackClick(_ event: StatisticalEvent, indexPath: IndexPath? = nil) {
        base.fw_trackClick(event, indexPath: indexPath)
    }
    
}

// MARK: - UIView+StatisticalExposure
extension Wrapper where Base: UIView {
    
    
    
}

// MARK: - UIViewController+StatisticalExposure
extension Wrapper where Base: UIViewController {
    
    
    
}
