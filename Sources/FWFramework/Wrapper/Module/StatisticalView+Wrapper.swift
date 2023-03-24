//
//  StatisticalView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - UIView+StatisticalView
extension Wrapper where Base: UIView {
    
    // MARK: - Click
    /// 设置并尝试自动绑定点击事件统计
    public var statisticalClick: StatisticalEvent? {
        get { base.fw_statisticalClick }
        set { base.fw_statisticalClick = newValue }
    }
    
    /// 设置统计点击事件触发时自定义监听器，默认nil
    public var statisticalClickListener: ((StatisticalEvent) -> Void)? {
        get { base.fw_statisticalClickListener }
        set { base.fw_statisticalClickListener = newValue }
    }
    
    /// 手工绑定点击事件统计，可指定容器视图，自动绑定失败时可手工调用
    @discardableResult
    public func statisticalBindClick(_ containerView: UIView? = nil) -> Bool {
        return base.fw_statisticalBindClick(containerView)
    }
    
    /// 触发视图点击事件统计，仅绑定statisticalClick后生效
    @discardableResult
    public func statisticalTrackClick(indexPath: IndexPath? = nil, event: StatisticalEvent? = nil) -> Bool {
        return base.fw_statisticalTrackClick(indexPath: indexPath, event: event)
    }
    
    // MARK: - Exposure
    /// 设置并尝试自动绑定曝光事件统计。如果对象发生变化(indexPath|name|object)，也会触发
    public var statisticalExposure: StatisticalEvent? {
        get { base.fw_statisticalExposure }
        set { base.fw_statisticalExposure = newValue }
    }
    
    /// 设置统计曝光事件触发时自定义监听器，默认nil
    public var statisticalExposureListener: ((StatisticalEvent) -> Void)? {
        get { base.fw_statisticalExposureListener }
        set { base.fw_statisticalExposureListener = newValue }
    }
    
    /// 手工绑定曝光事件统计，可指定容器视图，自动绑定失败时可手工调用
    @discardableResult
    public func statisticalBindExposure(_ containerView: UIView? = nil) -> Bool {
        return base.fw_statisticalBindExposure(containerView)
    }
    
    /// 触发视图曝光事件统计，仅绑定statisticalExposure后生效
    @discardableResult
    public func statisticalTrackExposure(indexPath: IndexPath? = nil, isFinished: Bool = false, event: StatisticalEvent? = nil) -> Bool {
        return base.fw_statisticalTrackExposure(indexPath: indexPath, isFinished: isFinished, event: event)
    }
    
    /// 检查并更新视图曝光状态，用于自定义场景
    public func statisticalCheckExposure() {
        base.fw_statisticalCheckExposure()
    }
    
}

// MARK: - UIViewController+StatisticalExposure
extension Wrapper where Base: UIViewController {
    
    /// 设置并尝试自动绑定曝光事件统计
    public var statisticalExposure: StatisticalEvent? {
        get { base.fw_statisticalExposure }
        set { base.fw_statisticalExposure = newValue }
    }
    
    /// 设置统计曝光事件触发时自定义监听器，默认nil
    public var statisticalExposureListener: ((StatisticalEvent) -> Void)? {
        get { base.fw_statisticalExposureListener }
        set { base.fw_statisticalExposureListener = newValue }
    }
    
    /// 触发控制器曝光事件统计，仅绑定statisticalExposure后生效
    @discardableResult
    public func statisticalTrackExposure(isFinished: Bool = false, event: StatisticalEvent? = nil) -> Bool {
        return base.fw_statisticalTrackExposure(isFinished: isFinished, event: event)
    }
    
    /// 检查并更新控制器曝光状态，用于自定义场景
    public func statisticalCheckExposure() {
        base.fw_statisticalCheckExposure()
    }
    
}
