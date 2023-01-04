//
//  BadgeView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

@_spi(FW) extension UIView {
    
    /// 显示右上角提醒灯，上右偏移指定距离
    public func fw_showBadgeView(_ badgeView: BadgeView, badgeValue: String? = nil) {
        self.fw_hideBadgeView()
        
        badgeView.badgeLabel?.text = badgeValue
        badgeView.tag = 2041
        self.addSubview(badgeView)
        self.bringSubviewToFront(badgeView)
        
        // 默认偏移
        badgeView.fw_pinEdge(toSuperview: .top, inset: -badgeView.badgeOffset.y)
        badgeView.fw_pinEdge(toSuperview: .right, inset: -badgeView.badgeOffset.x)
    }

    /// 隐藏提醒灯
    public func fw_hideBadgeView() {
        if let badgeView = self.viewWithTag(2041) {
            badgeView.removeFromSuperview()
        }
    }
    
}

@_spi(FW) extension UIBarItem {
    
    /// 获取UIBarItem(UIBarButtonItem、UITabBarItem)内部的view，通常对于navigationItem和tabBarItem而言，需要在设置为item后并且在bar可见时(例如 viewDidAppear:及之后)获取fwView才有值
    public weak var fw_view: UIView? {
        if let barItem = self as? UIBarButtonItem {
            if barItem.customView != nil {
                return barItem.customView
            }
        }
        
        if self.responds(to: NSSelectorFromString("view")) {
            return self.fw_invokeGetter("view") as? UIView
        }
        return nil
    }

    /// 当item内的view生成后就会调用一次这个block，仅对UIBarButtonItem、UITabBarItem有效
    public var fw_viewLoadedBlock: ((UIBarItem, UIView) -> Void)? {
        get {
            return fw_property(forName: "fw_viewLoadedBlock") as? (UIBarItem, UIView) -> Void
        }
        set {
            fw_setPropertyCopy(newValue, forName: "fw_viewLoadedBlock")
            
            if let view = self.fw_view {
                newValue?(self, view)
            } else {
                self.fw_observeProperty("view") { object, change in
                    guard let object = object as? UIBarItem, change[.newKey] != nil else { return }
                    object.fw_unobserveProperty("view")
                    
                    if let view = object.fw_view {
                        object.fw_viewLoadedBlock?(object, view)
                    }
                }
            }
        }
    }
    
}

@_spi(FW) extension UIBarButtonItem {
    
    /// 显示右上角提醒灯，上右偏移指定距离
    public func fw_showBadgeView(_ badgeView: BadgeView, badgeValue: String? = nil) {
        self.fw_hideBadgeView()
        
        // 查找内部视图，由于view只有显示到页面后才存在，所以使用回调存在后才添加
        self.fw_viewLoadedBlock = { item, view in
            badgeView.badgeLabel?.text = badgeValue
            badgeView.tag = 2041
            view.addSubview(badgeView)
            view.bringSubviewToFront(badgeView)
            
            // 自定义视图时默认偏移，否则固定偏移
            badgeView.fw_pinEdge(toSuperview: .top, inset: badgeView.badgeStyle.rawValue == 0 ? -badgeView.badgeOffset.y : 0)
            badgeView.fw_pinEdge(toSuperview: .right, inset: badgeView.badgeStyle.rawValue == 0 ? -badgeView.badgeOffset.x : 0)
        }
    }

    /// 隐藏提醒灯
    public func fw_hideBadgeView() {
        if let superview = self.fw_view,
           let badgeView = superview.viewWithTag(2041) {
            badgeView.removeFromSuperview()
        }
    }
    
}

@_spi(FW) extension UITabBarItem {
    
    fileprivate static func fw_swizzleBadgeView() {
        NSObject.fw_swizzleMethod(
            objc_getClass("UITabBarButton"),
            selector: #selector(UIView.layoutSubviews),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            // 解决因为层级关系变化导致的badgeView被遮挡问题
            for subview in selfObject.subviews {
                if let badgeView = subview as? BadgeView {
                    selfObject.bringSubviewToFront(badgeView)
                    
                    // 解决iOS13因为磨砂层切换导致的badgeView位置不对问题
                    if #available(iOS 13.0, *) {
                        if let imageView = UITabBarItem.fw_imageView(selfObject) {
                            badgeView.fw_pinEdge(.left, toEdge: .right, ofView: imageView, offset: -badgeView.badgeOffset.x)
                        }
                    }
                    break
                }
            }
        }}
    }
    
    private static func fw_imageView(_ tabBarButton: UIView) -> UIImageView? {
        var superview = tabBarButton
        if #available(iOS 13.0, *) {
            // iOS 13 下如果 tabBar 是磨砂的，则每个 button 内部都会有一个磨砂，而磨砂再包裹了 imageView、label 等 subview，但某些时机后系统又会把 imageView、label 挪出来放到 button 上，所以这里做个保护
            if let effectView = tabBarButton.subviews.first as? UIVisualEffectView,
               effectView.contentView.subviews.count > 0 {
                superview = effectView.contentView
            }
        }
        
        for subview in superview.subviews {
            // iOS10及以后，imageView都是用UITabBarSwappableImageView实现的，所以遇到这个class就直接拿
            if NSStringFromClass(subview.classForCoder) == "UITabBarSwappableImageView" {
                return subview as? UIImageView
            }
        }
        return nil
    }
    
    /// 获取一个UITabBarItem内显示图标的UIImageView，如果找不到则返回nil
    public weak var fw_imageView: UIImageView? {
        if let tabBarButton = self.fw_view {
            return UITabBarItem.fw_imageView(tabBarButton)
        }
        return nil
    }
    
    /// 显示右上角提醒灯，上右偏移指定距离
    public func fw_showBadgeView(_ badgeView: BadgeView, badgeValue: String? = nil) {
        self.fw_hideBadgeView()
        
        // 查找内部视图，由于view只有显示到页面后才存在，所以使用回调存在后才添加
        self.fw_viewLoadedBlock = { item, view in
            guard let item = item as? UITabBarItem,
                  let imageView = item.fw_imageView else { return }
            
            badgeView.badgeLabel?.text = badgeValue
            badgeView.tag = 2041
            view.addSubview(badgeView)
            view.bringSubviewToFront(badgeView)
            
            badgeView.fw_pinEdge(toSuperview: .top, inset: badgeView.badgeStyle.rawValue == 0 ? -badgeView.badgeOffset.y : 2.0)
            badgeView.fw_pinEdge(.left, toEdge: .right, ofView: imageView, offset: -badgeView.badgeOffset.x)
        }
    }

    /// 隐藏提醒灯
    public func fw_hideBadgeView() {
        if let superview = self.fw_view,
           let badgeView = superview.viewWithTag(2041) {
            badgeView.removeFromSuperview()
        }
    }
    
}

// MARK: - BadgeViewAutoloader
internal class BadgeViewAutoloader: AutoloadProtocol {
    
    static func autoload() {
        UITabBarItem.fw_swizzleBadgeView()
    }
    
}
