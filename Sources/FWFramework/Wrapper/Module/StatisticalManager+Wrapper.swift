//
//  StatisticalManager.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

extension Wrapper where Base: UIView {
    
    /// 绑定统计点击事件，触发管理器。view为添加的Tap手势(需先添加手势)，control为TouchUpInside|ValueChanged，tableView|collectionView为Select(需先设置delegate)
    public var statisticalClick: StatisticalObject? {
        get { return base.__fw_statisticalClick }
        set { base.__fw_statisticalClick = newValue }
    }

    /// 绑定统计点击事件，仅触发回调。view为添加的Tap手势(需先添加手势)，control为TouchUpInside|ValueChanged，tableView|collectionView为Select(需先设置delegate)
    public var statisticalClickBlock: StatisticalBlock? {
        get { return base.__fw_statisticalClickBlock }
        set { base.__fw_statisticalClickBlock = newValue }
    }

    /// 手工触发统计点击事件，更新点击次数，列表可指定cell和位置，可重复触发
    public func statisticalTriggerClick(_ cell: UIView?, indexPath: IndexPath?) {
        base.__fw_statisticalTriggerClick(cell, indexPath: indexPath)
    }
    
    /// 绑定统计曝光事件，触发管理器。如果对象发生变化(indexPath|name|object)，也会触发
    public var statisticalExposure: StatisticalObject? {
        get { return base.__fw_statisticalExposure }
        set { base.__fw_statisticalExposure = newValue }
    }

    /// 绑定统计曝光事件，仅触发回调
    public var statisticalExposureBlock: StatisticalBlock? {
        get { return base.__fw_statisticalExposureBlock }
        set { base.__fw_statisticalExposureBlock = newValue }
    }

    /// 手工触发统计曝光事件，更新曝光次数和时长，列表可指定cell和位置，duration为单次曝光时长(0表示开始)，可重复触发
    public func statisticalTriggerExposure(_ cell: UIView?, indexPath: IndexPath?, duration: TimeInterval) {
        base.__fw_statisticalTriggerExposure(cell, indexPath: indexPath, duration: duration)
    }
    
}
