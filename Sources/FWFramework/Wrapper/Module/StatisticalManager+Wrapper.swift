//
//  StatisticalManager+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

extension Wrapper where Base: UIView {
    
    /// 绑定统计曝光事件，触发管理器。如果对象发生变化(indexPath|name|object)，也会触发
    public var statisticalExposure: FWStatisticalObject? {
        get { return base.fw_statisticalExposure }
        set { base.fw_statisticalExposure = newValue }
    }

    /// 绑定统计曝光事件，仅触发回调
    public var statisticalExposureBlock: FWStatisticalBlock? {
        get { return base.fw_statisticalExposureBlock }
        set { base.fw_statisticalExposureBlock = newValue }
    }

    /// 手工触发统计曝光事件，更新曝光次数和时长，列表可指定cell和位置，duration为单次曝光时长(0表示开始)，可重复触发
    public func statisticalTriggerExposure(_ cell: UIView?, indexPath: IndexPath?, duration: TimeInterval = 0) {
        base.fw_statisticalTriggerExposure(cell, indexPath: indexPath, duration: duration)
    }
    
}

extension Wrapper where Base: UIViewController {
    
    /// 绑定统计曝光事件，触发管理器
    public var statisticalExposure: FWStatisticalObject? {
        get { return base.fw_statisticalExposure }
        set { base.fw_statisticalExposure = newValue }
    }

    /// 绑定统计曝光事件，仅触发回调
    public var statisticalExposureBlock: FWStatisticalBlock? {
        get { return base.fw_statisticalExposureBlock }
        set { base.fw_statisticalExposureBlock = newValue }
    }

    /// 手工触发统计曝光事件，更新曝光次数和时长，duration为单次曝光时长(0表示开始)，可重复触发
    public func statisticalTriggerExposure(duration: TimeInterval = 0) {
        base.fw_statisticalTriggerExposure(duration: duration)
    }
    
}
