//
//  StatisticalView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - UIView+StatisticalClick
extension Wrapper where Base: UIView {
    
    /// 设置并尝试自动绑定点击事件统计，containerView参数为nil
    public var statisticalClick: StatisticalEvent? {
        get { base.fw_statisticalClick }
        set { base.fw_statisticalClick = newValue }
    }
    
    /// 手工绑定点击事件统计，可指定containerView，自动绑定失败时可手工调用
    @discardableResult
    public func statisticalBindClick(containerView: UIView? = nil) -> Bool {
        return base.fw_statisticalBindClick(containerView: containerView)
    }
    
    /// 触发视图点击事件统计，仅绑定statisticalClick后生效
    @discardableResult
    public func statisticalTrackClick(indexPath: IndexPath? = nil, _ event: @autoclosure () -> StatisticalEvent? = nil) -> Bool {
        return base.fw_statisticalTrackClick(indexPath: indexPath, event())
    }
    
}

// MARK: - UIView+StatisticalExposure
extension Wrapper where Base: UIView {
    
    /// 设置并尝试自动绑定曝光事件统计，containerView参数为nil。如果对象发生变化(indexPath|name|object)，也会触发
    public var statisticalExposure: StatisticalEvent? {
        get { base.fw_statisticalExposure }
        set { base.fw_statisticalExposure = newValue }
    }
    
}

// MARK: - UIViewController+StatisticalExposure
extension Wrapper where Base: UIViewController {
    
    /// 设置并尝试自动绑定曝光事件统计，containerView参数为nil
    public var statisticalExposure: StatisticalEvent? {
        get { base.fw_statisticalExposure }
        set { base.fw_statisticalExposure = newValue }
    }
    
}
