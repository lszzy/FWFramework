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
    
    /// 视图已重用次数
    public var reusedTimes: Int {
        get { return base.fw_reusedTimes }
        set { base.fw_reusedTimes = newValue }
    }
    
    /// 标记重用失效，将自动从缓存池移除
    public var reuseInvalid: Bool {
        get { return base.fw_reuseInvalid }
        set { base.fw_reuseInvalid = newValue }
    }
    
    /// 按需预加载下一个可重用视图，仅当缓存池包含当前视图类型时生效
    public func preloadReusableView() {
        base.fw_preloadReusableView()
    }
    
}
