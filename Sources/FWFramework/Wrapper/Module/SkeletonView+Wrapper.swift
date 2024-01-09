//
//  SkeletonView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// 视图显示骨架屏扩展
extension Wrapper where Base: UIView {
    /// 显示骨架屏，指定布局代理
    public func showSkeleton(delegate: SkeletonViewDelegate?) {
        base.fw_showSkeleton(delegate: delegate)
    }
    
    /// 显示骨架屏，指定布局句柄
    public func showSkeleton(block: ((SkeletonLayout) -> Void)?) {
        base.fw_showSkeleton(block: block)
    }
    
    /// 显示骨架屏，默认布局代理为self
    public func showSkeleton() {
        base.fw_showSkeleton()
    }
    
    /// 隐藏骨架屏
    public func hideSkeleton() {
        base.fw_hideSkeleton()
    }
    
    /// 是否正在显示骨架屏
    public var hasSkeleton: Bool {
        return base.fw_hasSkeleton
    }
}

/// 控制器显示骨架屏扩展
extension Wrapper where Base: UIViewController {
    /// 显示view骨架屏，指定布局代理
    public func showSkeleton(delegate: SkeletonViewDelegate?) {
        base.fw_showSkeleton(delegate: delegate)
    }
    
    /// 显示view骨架屏，指定布局句柄
    public func showSkeleton(block: ((SkeletonLayout) -> Void)?) {
        base.fw_showSkeleton(block: block)
    }
    
    /// 显示view骨架屏，默认布局代理为self
    public func showSkeleton() {
        base.fw_showSkeleton()
    }
    
    /// 隐藏view骨架屏
    public func hideSkeleton() {
        base.fw_hideSkeleton()
    }
    
    /// 是否正在显示view骨架屏
    public var hasSkeleton: Bool {
        return base.fw_hasSkeleton
    }
}
