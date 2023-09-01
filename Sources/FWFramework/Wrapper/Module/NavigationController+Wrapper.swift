//
//  NavigationController+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UINavigationController {
    
    /// 自定义转场过程中containerView的背景色，默认透明
    public var containerBackgroundColor: UIColor! {
        get { return base.fw_containerBackgroundColor }
        set { base.fw_containerBackgroundColor = newValue }
    }
    
    /// 全局启用NavigationBar转场。启用后各个ViewController管理自己的导航栏样式，在viewDidLoad或viewViewAppear中设置即可
    public static func enableBarTransition() {
        Base.fw_enableBarTransition()
    }
    
    /// 是否启用导航栏全屏返回手势，默认NO。启用时系统返回手势失效，禁用时还原系统手势。如果只禁用系统手势，设置interactivePopGestureRecognizer.enabled即可
    public var fullscreenPopGestureEnabled: Bool {
        get { return base.fw_fullscreenPopGestureEnabled }
        set { base.fw_fullscreenPopGestureEnabled = newValue }
    }

    /// 导航栏全屏返回手势对象
    public var fullscreenPopGestureRecognizer: UIPanGestureRecognizer {
        return base.fw_fullscreenPopGestureRecognizer
    }
    
    /// 判断手势是否是全局返回手势对象
    public static func isFullscreenPopGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return Base.fw_isFullscreenPopGestureRecognizer(gestureRecognizer)
    }
    
}

extension Wrapper where Base: UIViewController {
    
    /// 转场动画自定义判断标识，不相等才会启用转场。默认nil启用转场。可重写或者push前设置生效
    public var barTransitionIdentifier: AnyHashable? {
        get { return base.fw_barTransitionIdentifier }
        set { base.fw_barTransitionIdentifier = newValue }
    }
    
    /// 视图控制器是否禁用全屏返回手势，默认NO
    public var fullscreenPopGestureDisabled: Bool {
        get { return base.fw_fullscreenPopGestureDisabled }
        set { base.fw_fullscreenPopGestureDisabled = newValue }
    }

    /// 视图控制器全屏手势距离左侧最大距离，默认0，无限制
    public var fullscreenPopGestureDistance: CGFloat {
        get { return base.fw_fullscreenPopGestureDistance }
        set { base.fw_fullscreenPopGestureDistance = newValue }
    }
    
}

extension Wrapper where Base: UINavigationBar {
    
    /// 导航栏背景视图，显示背景色和背景图片等
    public var backgroundView: UIView? {
        return base.fw_backgroundView
    }
    
    /// 导航栏内容视图，iOS11+才存在，显示item和titleView等
    public var contentView: UIView? {
        return base.fw_contentView
    }
    
    /// 导航栏大标题视图，显示时才有值。如果要设置背景色，可使用backgroundView.backgroundColor
    public var largeTitleView: UIView? {
        return base.fw_largeTitleView
    }
    
    /// 导航栏大标题高度，与是否隐藏无关
    public static var largeTitleHeight: CGFloat {
        return Base.fw_largeTitleHeight
    }
    
}

extension Wrapper where Base: UIToolbar {
    
    /// 工具栏背景视图，显示背景色和背景图片等。如果标签栏同时显示，背景视图高度也会包含标签栏高度
    public var backgroundView: UIView? {
        return base.fw_backgroundView
    }
    
    /// 工具栏内容视图，iOS11+才存在，显示item等
    public var contentView: UIView? {
        return base.fw_contentView
    }
    
}
