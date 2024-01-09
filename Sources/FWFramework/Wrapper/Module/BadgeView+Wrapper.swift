//
//  BadgeView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UIView {
    
    /// 显示右上角提醒灯，上右偏移指定距离
    public func showBadgeView(_ badgeView: BadgeView, badgeValue: String? = nil) {
        base.fw_showBadgeView(badgeView, badgeValue: badgeValue)
    }

    /// 隐藏提醒灯
    public func hideBadgeView() {
        base.fw_hideBadgeView()
    }
    
}

extension Wrapper where Base: UIBarItem {
    
    /// 获取UIBarItem(UIBarButtonItem、UITabBarItem)内部的view，通常对于navigationItem和tabBarItem而言，需要在设置为item后并且在bar可见时(例如 viewDidAppear:及之后)获取fwView才有值
    public weak var view: UIView? {
        return base.fw_view
    }

    /// 当item内的view生成后就会调用一次这个block，仅对UIBarButtonItem、UITabBarItem有效
    public var viewLoadedBlock: ((Base, UIView) -> Void)? {
        get { return base.fw_viewLoadedBlock }
        set {
            if newValue != nil {
                base.fw_viewLoadedBlock = { item, view in
                    newValue?(item as! Base, view)
                }
            } else {
                base.fw_viewLoadedBlock = nil
            }
        }
    }
    
}

extension Wrapper where Base: UIBarButtonItem {
    
    /// 显示右上角提醒灯，上右偏移指定距离
    public func showBadgeView(_ badgeView: BadgeView, badgeValue: String? = nil) {
        base.fw_showBadgeView(badgeView, badgeValue: badgeValue)
    }

    /// 隐藏提醒灯
    public func hideBadgeView() {
        base.fw_hideBadgeView()
    }
    
}

extension Wrapper where Base: UITabBarItem {
    
    /// 获取一个UITabBarItem内显示图标的UIImageView，如果找不到则返回nil
    public weak var imageView: UIImageView? {
        return base.fw_imageView
    }
    
    /// 显示右上角提醒灯，上右偏移指定距离
    public func showBadgeView(_ badgeView: BadgeView, badgeValue: String? = nil) {
        base.fw_showBadgeView(badgeView, badgeValue: badgeValue)
    }

    /// 隐藏提醒灯
    public func hideBadgeView() {
        base.fw_hideBadgeView()
    }
    
}
