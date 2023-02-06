//
//  ReusableView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UIView {
    
    /// 视图持有者对象，弱引用
    public weak var viewHolder: NSObject? {
        get { return base.fw_viewHolder }
        set { base.fw_viewHolder = newValue }
    }
    
    /// 重用唯一标志，默认nil
    public var reuseIdentifier: String? {
        get { return base.fw_reuseIdentifier }
        set { base.fw_reuseIdentifier = newValue }
    }
    
    /// 视图已重用次数，默认0
    public var reusedTimes: Int {
        get { return base.fw_reusedTimes }
        set { base.fw_reusedTimes = newValue }
    }
    
    /// 标记重用准备中(true)，准备中的视图在完成(false)之前都不会被dequeue，默认false
    public var reusePrepareing: Bool {
        get { return base.fw_reusePreparing }
        set { base.fw_reusePreparing = newValue }
    }
    
    /// 标记重用失效，将自动从缓存池移除
    public var reuseInvalid: Bool {
        get { return base.fw_reuseInvalid }
        set { base.fw_reuseInvalid = newValue }
    }
    
    /// 按需预加载下一个可重用视图，仅当前视图可重用时生效
    public func preloadReusableView() {
        base.fw_preloadReusableView()
    }
    
}
