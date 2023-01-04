//
//  NavigationStyle.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

@_spi(FW) extension UINavigationBar {
    
    /// 应用指定导航栏配置
    public func fw_applyBarAppearance(_ appearance: NavigationBarAppearance) {
        if appearance.isTranslucent != self.fw_isTranslucent {
            self.fw_isTranslucent = appearance.isTranslucent
        }
        if appearance.backgroundTransparent {
            self.fw_backgroundTransparent = appearance.backgroundTransparent
        } else if appearance.backgroundImage != nil {
            self.fw_backgroundImage = appearance.backgroundImage
        } else if appearance.backgroundColor != nil {
            self.fw_backgroundColor = appearance.backgroundColor
        }
        if appearance.shadowImage != nil {
            self.fw_shadowImage = appearance.shadowImage
        } else if appearance.shadowColor != nil {
            self.fw_shadowColor = appearance.shadowColor
        } else {
            self.fw_shadowColor = nil
        }
        if appearance.foregroundColor != nil {
            self.fw_foregroundColor = appearance.foregroundColor
        }
        if appearance.titleAttributes != nil {
            self.fw_titleAttributes = appearance.titleAttributes
        }
        if appearance.buttonAttributes != nil {
            self.fw_buttonAttributes = appearance.buttonAttributes
        }
        if appearance.backImage != nil {
            self.fw_backImage = appearance.backImage
        }
        if appearance.appearanceBlock != nil {
            appearance.appearanceBlock?(self)
        }
    }
    
    /// 应用指定导航栏样式
    public func fw_applyBarStyle(_ style: NavigationBarStyle) {
        if let appearance = NavigationBarAppearance(forStyle: style) {
            self.fw_applyBarAppearance(appearance)
        }
    }
    
}

@_spi(FW) extension UIViewController {
    
    fileprivate static func fw_swizzleNavigationStyle() {
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(getter: UIViewController.prefersStatusBarHidden),
            methodSignature: (@convention(c) (UIViewController, Selector) -> Bool).self,
            swizzleSignature: (@convention(block) (UIViewController) -> Bool).self
        ) { store in { selfObject in
            if let hiddenValue = selfObject.fw_property(forName: "fw_statusBarHidden") as? NSNumber {
                return hiddenValue.boolValue
            } else {
                return store.original(selfObject, store.selector)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(getter: UIViewController.preferredStatusBarStyle),
            methodSignature: (@convention(c) (UIViewController, Selector) -> UIStatusBarStyle).self,
            swizzleSignature: (@convention(block) (UIViewController) -> UIStatusBarStyle).self
        ) { store in { selfObject in
            if let styleValue = selfObject.fw_property(forName: "fw_statusBarStyle") as? NSNumber {
                return .init(rawValue: styleValue.intValue) ?? .default
            } else {
                return store.original(selfObject, store.selector)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            selfObject.fw_updateNavigationBarStyle(animated)
        }}
    }
    
    /// 状态栏样式，默认UIStatusBarStyleDefault，设置后才会生效
    public var fw_statusBarStyle: UIStatusBarStyle {
        get {
            let value = fw_propertyInt(forName: "fw_statusBarStyle")
            return .init(rawValue: value) ?? .default
        }
        set {
            fw_setPropertyInt(newValue.rawValue, forName: "fw_statusBarStyle")
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    /// 状态栏是否隐藏，默认NO，设置后才会生效
    public var fw_statusBarHidden: Bool {
        get {
            return fw_propertyBool(forName: "fw_statusBarHidden")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_statusBarHidden")
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    /// 当前导航栏设置，优先级高于style，设置后会在viewWillAppear:自动应用生效
    public var fw_navigationBarAppearance: NavigationBarAppearance? {
        get {
            return fw_property(forName: "fw_navigationBarAppearance") as? NavigationBarAppearance
        }
        set {
            fw_setProperty(newValue, forName: "fw_navigationBarAppearance")
            if self.isViewLoaded && self.view.window != nil {
                self.fw_updateNavigationBarStyle(false)
            }
        }
    }

    /// 当前导航栏样式，默认Default，设置后才会在viewWillAppear:自动应用生效
    public var fw_navigationBarStyle: NavigationBarStyle {
        get {
            let value = fw_propertyInt(forName: "fw_navigationBarStyle")
            return .init(rawValue: value)
        }
        set {
            fw_setPropertyInt(newValue.rawValue, forName: "fw_navigationBarStyle")
            if self.isViewLoaded && self.view.window != nil {
                self.fw_updateNavigationBarStyle(false)
            }
        }
    }

    /// 导航栏是否隐藏，默认NO，设置后才会在viewWillAppear:自动应用生效
    public var fw_navigationBarHidden: Bool {
        get {
            return fw_propertyBool(forName: "fw_navigationBarHidden")
        }
        set {
            self.fw_setNavigationBarHidden(newValue, animated: false)
            // 直接设置navigtionBar.isHidden不会影响右滑关闭手势
            // self.navigationController?.navigationBar.isHidden = true
        }
    }

    /// 动态隐藏导航栏，如果当前已经viewWillAppear:时立即执行
    public func fw_setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        fw_setPropertyBool(hidden, forName: "fw_navigationBarHidden")
        if self.isViewLoaded && self.view.window != nil {
            self.fw_updateNavigationBarStyle(false)
        }
    }
    
    /// 是否允许child控制器修改导航栏样式，默认false
    public var fw_allowsChildNavigation: Bool {
        get {
            return fw_propertyBool(forName: "fw_allowsChildNavigation")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_allowsChildNavigation")
        }
    }
    
    private var fw_currentNavigationBarAppearance: NavigationBarAppearance? {
        // 1. 检查VC是否自定义appearance
        if let appearance = self.fw_navigationBarAppearance {
            return appearance
        }
        // 2. 检查VC是否自定义style
        if let style = fw_property(forName: "fw_navigationBarStyle") as? NSNumber {
            return NavigationBarAppearance(forStyle: .init(rawValue: style.intValue))
        }
        // 3. 检查NAV是否自定义appearance
        if let appearance = self.navigationController?.fw_navigationBarAppearance {
            return appearance
        }
        // 4. 检查NAV是否自定义style
        if let style = self.navigationController?.fw_property(forName: "fw_navigationBarStyle") as? NSNumber {
            return NavigationBarAppearance(forStyle: .init(rawValue: style.intValue))
        }
        return nil
    }
    
    private func fw_updateNavigationBarStyle(_ animated: Bool) {
        // 含有导航栏且不是导航栏控制器，如果是child控制器且允许修改时才处理
        guard let navigationController = self.navigationController,
              !(self is UINavigationController) else { return }
        if self.fw_isChild && !self.fw_allowsChildNavigation { return }
        
        // fwNavigationBarHidden设置即生效，动态切换导航栏不突兀，一般在viewWillAppear:中调用
        if let hidden = fw_property(forName: "fw_navigationBarHidden") as? NSNumber,
           navigationController.isNavigationBarHidden != hidden.boolValue {
            navigationController.setNavigationBarHidden(hidden.boolValue, animated: animated)
        }
        
        // 获取当前用于显示的appearance，未设置时不处理
        guard let appearance = self.fw_currentNavigationBarAppearance else { return }
        
        // 配合导航栏appearance初始化返回按钮或左侧按钮
        if appearance.backImage != nil {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
        }
        if appearance.leftBackImage != nil && fw_property(forName: "fw_updateNavigationBarStyle") == nil {
            fw_setPropertyBool(true, forName: "fw_updateNavigationBarStyle")
            if navigationController.children.count > 1 && self.navigationItem.leftBarButtonItem == nil {
                self.fw_leftBarItem = appearance.leftBackImage
            }
        }
        
        // 应用当前导航栏appearance
        navigationController.navigationBar.fw_applyBarAppearance(appearance)
    }

    /// 标签栏是否隐藏，默认为NO，立即生效。如果tabBar一直存在，则用tabBar包裹navBar；如果tabBar只存在主界面，则用navBar包裹tabBar
    public var fw_tabBarHidden: Bool {
        get {
            return self.tabBarController?.tabBar.isHidden ?? false
        }
        set {
            self.tabBarController?.tabBar.isHidden = newValue
        }
    }
    
    /// 工具栏是否隐藏，默认为YES。需设置toolbarItems，立即生效
    public var fw_toolBarHidden: Bool {
        get {
            return self.navigationController?.isToolbarHidden ?? false
        }
        set {
            self.navigationController?.isToolbarHidden = newValue
        }
    }
    
    /// 动态隐藏工具栏。需设置toolbarItems，立即生效
    public func fw_setToolBarHidden(_ hidden: Bool, animated: Bool) {
        self.navigationController?.setToolbarHidden(hidden, animated: animated)
    }

    /// 设置视图布局Bar延伸类型，None为不延伸(Bar不覆盖视图)，Top|Bottom为顶部|底部延伸，All为全部延伸
    public var fw_extendedLayoutEdge: UIRectEdge {
        get {
            return self.edgesForExtendedLayout
        }
        set {
            self.edgesForExtendedLayout = newValue
            self.extendedLayoutIncludesOpaqueBars = true
        }
    }
    
}

// MARK: - NavigationStyleAutoloader
internal class NavigationStyleAutoloader: AutoloadProtocol {
    
    static func autoload() {
        UIViewController.fw_swizzleNavigationStyle()
    }
    
}
