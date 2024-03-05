//
//  NavigationStyle.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UINavigationBar
extension Wrapper where Base: UINavigationBar {
    /// 应用指定导航栏配置
    public func applyBarAppearance(_ appearance: NavigationBarAppearance) {
        base.fw_applyBarAppearance(appearance)
    }
    
    /// 应用指定导航栏样式
    public func applyBarStyle(_ style: NavigationBarStyle) {
        base.fw_applyBarStyle(style)
    }
}

// MARK: - Wrapper+UIViewController
extension Wrapper where Base: UIViewController {
    /// 状态栏样式，默认preferredStatusBarStyle，设置后才会生效
    public var statusBarStyle: UIStatusBarStyle {
        get { return base.fw_statusBarStyle }
        set { base.fw_statusBarStyle = newValue }
    }

    /// 状态栏是否隐藏，默认prefersStatusBarHidden，设置后才会生效
    public var statusBarHidden: Bool {
        get { return base.fw_statusBarHidden }
        set { base.fw_statusBarHidden = newValue }
    }

    /// 当前导航栏设置，优先级高于style，设置后会在viewWillAppear:自动应用生效
    public var navigationBarAppearance: NavigationBarAppearance? {
        get { return base.fw_navigationBarAppearance }
        set { base.fw_navigationBarAppearance = newValue }
    }

    /// 当前导航栏样式，默认default，设置后才会在viewWillAppear:自动应用生效
    public var navigationBarStyle: NavigationBarStyle {
        get { return base.fw_navigationBarStyle }
        set { base.fw_navigationBarStyle = newValue }
    }

    /// 导航栏是否隐藏，默认isNavigationBarHidden，设置后才会在viewWillAppear:自动应用生效
    public var navigationBarHidden: Bool {
        get { return base.fw_navigationBarHidden }
        set { base.fw_navigationBarHidden = newValue }
    }

    /// 动态隐藏导航栏，如果当前已经viewWillAppear:时立即执行
    public func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        base.fw_setNavigationBarHidden(hidden, animated: animated)
    }
    
    /// 是否允许修改导航栏样式，默认未设置时child控制器不能修改
    public var allowsBarAppearance: Bool {
        get { return base.fw_allowsBarAppearance }
        set { base.fw_allowsBarAppearance = newValue }
    }

    /// 标签栏是否隐藏，默认为true，立即生效。如果tabBar一直存在，则用tabBar包裹navBar；如果tabBar只存在主界面，则用navBar包裹tabBar
    public var tabBarHidden: Bool {
        get { return base.fw_tabBarHidden }
        set { base.fw_tabBarHidden = newValue }
    }
    
    /// 工具栏是否隐藏，默认为true。需设置toolbarItems，立即生效
    public var toolBarHidden: Bool {
        get { return base.fw_toolBarHidden }
        set { base.fw_toolBarHidden = newValue }
    }
    
    /// 动态隐藏工具栏。需设置toolbarItems，立即生效
    public func setToolBarHidden(_ hidden: Bool, animated: Bool) {
        base.fw_setToolBarHidden(hidden, animated: animated)
    }

    /// 设置视图布局Bar延伸类型，None为不延伸(Bar不覆盖视图)，Top|Bottom为顶部|底部延伸，All为全部延伸
    public var extendedLayoutEdge: UIRectEdge {
        get { return base.fw_extendedLayoutEdge }
        set { base.fw_extendedLayoutEdge = newValue }
    }
    
    /// 自适应Bar延伸类型，兼容顶部和底部栏safeArea布局方式，需在viewDidLoad及之后调用生效。开启兼容模式时仅在iOS14及以下生效
    public func adjustExtendedLayout(compatible: Bool = false) {
        base.fw_adjustExtendedLayout(compatible: compatible)
    }
}

// MARK: - NavigationStyle
/// 导航栏可扩展全局样式
public struct NavigationBarStyle: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = Int
    
    /// 默认样式，应用可配置并扩展
    public static let `default`: NavigationBarStyle = .init(0)
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

/// 导航栏样式配置
open class NavigationBarAppearance: NSObject {
    
    private static var appearances = [NavigationBarStyle: NavigationBarAppearance]()
    
    /// 根据style获取全局appearance对象
    public static func appearance(for style: NavigationBarStyle) -> NavigationBarAppearance? {
        return appearances[style]
    }
    
    /// 设置style对应全局appearance对象
    public static func setAppearance(_ appearance: NavigationBarAppearance?, for style: NavigationBarStyle) {
        appearances[style] = appearance
    }
    
    /// 是否半透明(磨砂)，需edgesForExtendedLayout为Top|All，默认false
    open var isTranslucent = false
    /// 前景色，包含标题和按钮，默认nil
    open var foregroundColor: UIColor?
    /// 标题属性，默认nil使用前景色
    open var titleAttributes: [NSAttributedString.Key: Any]?
    /// 按钮属性，默认nil。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
    open var buttonAttributes: [NSAttributedString.Key: Any]?
    /// 背景色，后设置生效，默认nil
    open var backgroundColor: UIColor?
    /// 背景图片，后设置生效，默认nil
    open var backgroundImage: UIImage?
    /// 背景透明，需edgesForExtendedLayout为Top|All，后设置生效，默认false
    open var backgroundTransparent = false
    /// 阴影颜色，后设置生效，默认nil
    open var shadowColor: UIColor?
    /// 阴影图片，后设置生效，默认nil
    open var shadowImage: UIImage?
    /// 返回按钮图片，自动配合VC导航栏样式生效，默认nil
    open var backImage: UIImage?
    /// 左侧返回按钮图片，自动配合VC导航栏样式生效，默认nil
    open var leftBackImage: UIImage?
    /// 自定义句柄，最后调用，可自定义样式，默认nil
    open var appearanceBlock: ((UINavigationBar) -> Void)?
    
}

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
        if let appearance = NavigationBarAppearance.appearance(for: style) {
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
            if let hidden = selfObject.fw_propertyNumber(forName: "fw_statusBarHidden") {
                return hidden.boolValue
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
            if let style = selfObject.fw_propertyNumber(forName: "fw_statusBarStyle") {
                return .init(rawValue: style.intValue) ?? .default
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
            selfObject.fw_updateNavigationBarStyle(animated, isAppeared: false)
        }}
    }
    
    /// 状态栏样式，默认preferredStatusBarStyle，设置后才会生效
    public var fw_statusBarStyle: UIStatusBarStyle {
        get {
            if let style = fw_propertyNumber(forName: "fw_statusBarStyle") {
                return .init(rawValue: style.intValue) ?? .default
            }
            return self.preferredStatusBarStyle
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue.rawValue), forName: "fw_statusBarStyle")
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    /// 状态栏是否隐藏，默认prefersStatusBarHidden，设置后才会生效
    public var fw_statusBarHidden: Bool {
        get {
            if let hidden = fw_propertyNumber(forName: "fw_statusBarHidden") {
                return hidden.boolValue
            }
            return self.prefersStatusBarHidden
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue), forName: "fw_statusBarHidden")
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
                self.fw_updateNavigationBarStyle(false, isAppeared: true)
            }
        }
    }

    /// 当前导航栏样式，默认default，设置后才会在viewWillAppear:自动应用生效
    public var fw_navigationBarStyle: NavigationBarStyle {
        get {
            if let style = fw_propertyNumber(forName: "fw_navigationBarStyle") {
                return .init(rawValue: style.intValue)
            }
            return .default
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue.rawValue), forName: "fw_navigationBarStyle")
            if self.isViewLoaded && self.view.window != nil {
                self.fw_updateNavigationBarStyle(false, isAppeared: true)
            }
        }
    }

    /// 导航栏是否隐藏，默认isNavigationBarHidden，设置后才会在viewWillAppear:自动应用生效
    public var fw_navigationBarHidden: Bool {
        get {
            if let hidden = fw_propertyNumber(forName: "fw_navigationBarHidden") {
                return hidden.boolValue
            }
            return navigationController?.isNavigationBarHidden ?? true
        }
        set {
            self.fw_setNavigationBarHidden(newValue, animated: false)
            // 直接设置navigtionBar.isHidden不会影响右滑关闭手势
            // self.navigationController?.navigationBar.isHidden = true
        }
    }

    /// 动态隐藏导航栏，如果当前已经viewWillAppear:时立即执行
    public func fw_setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        fw_setPropertyNumber(NSNumber(value: hidden), forName: "fw_navigationBarHidden")
        if self.isViewLoaded && self.view.window != nil {
            self.fw_updateNavigationBarStyle(false, isAppeared: true)
        }
    }
    
    /// 是否允许修改导航栏样式，默认未设置时child控制器不能修改
    public var fw_allowsBarAppearance: Bool {
        get {
            if let number = fw_propertyNumber(forName: "fw_allowsBarAppearance") {
                return number.boolValue
            }
            return !fw_isChild
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue), forName: "fw_allowsBarAppearance")
        }
    }
    
    private var fw_currentNavigationBarAppearance: NavigationBarAppearance? {
        // 1. 检查VC是否自定义appearance
        if let appearance = self.fw_navigationBarAppearance {
            return appearance
        }
        // 2. 检查VC是否自定义style
        if let style = fw_propertyNumber(forName: "fw_navigationBarStyle") {
            return NavigationBarAppearance.appearance(for: .init(rawValue: style.intValue))
        }
        // 3. 检查NAV是否自定义appearance
        if let appearance = self.navigationController?.fw_navigationBarAppearance {
            return appearance
        }
        // 4. 检查NAV是否自定义style
        if let style = self.navigationController?.fw_propertyNumber(forName: "fw_navigationBarStyle") {
            return NavigationBarAppearance.appearance(for: .init(rawValue: style.intValue))
        }
        return nil
    }
    
    private func fw_updateNavigationBarStyle(_ animated: Bool, isAppeared: Bool) {
        // 含有导航栏且不是导航栏控制器，如果是child控制器且允许修改时才处理
        guard let navigationController = self.navigationController,
              !(self is UINavigationController) else { return }
        if !fw_allowsBarAppearance { return }
        
        // fw_navigationBarHidden设置即生效，动态切换导航栏不突兀，一般在viewWillAppear:中调用
        if let hidden = fw_propertyNumber(forName: "fw_navigationBarHidden"),
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
        
        // 标记转场导航栏样式需要刷新
        if isAppeared {
            fw_barTransitionNeedsUpdate()
        }
    }

    /// 标签栏是否隐藏，默认为true，立即生效。如果tabBar一直存在，则用tabBar包裹navBar；如果tabBar只存在主界面，则用navBar包裹tabBar
    public var fw_tabBarHidden: Bool {
        get {
            return self.tabBarController?.tabBar.isHidden ?? true
        }
        set {
            self.tabBarController?.tabBar.isHidden = newValue
        }
    }
    
    /// 工具栏是否隐藏，默认为true。需设置toolbarItems，立即生效
    public var fw_toolBarHidden: Bool {
        get {
            return self.navigationController?.isToolbarHidden ?? true
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
    
    /// 自适应Bar延伸类型，兼容顶部和底部栏safeArea布局方式，需在viewDidLoad及之后调用生效。开启兼容模式时仅在iOS14及以下生效
    public func fw_adjustExtendedLayout(compatible: Bool = false) {
        self.extendedLayoutIncludesOpaqueBars = true
        // iOS15+系统默认使用safeArea布局时自适应标签栏，开启兼容模式时仅处理iOS14及以下
        var shouldAdjust = true
        if compatible, #available(iOS 15.0, *) {
            shouldAdjust = false
        }
        if shouldAdjust, !self.hidesBottomBarWhenPushed,
           self.tabBarController != nil, fw_isHead {
            // 注意移除bottom后无法实现标签栏半透明效果，可换成bottomBarHeight布局方式等
            self.edgesForExtendedLayout.remove(.bottom)
        }
    }
    
}

// MARK: - FrameworkAutoloader+NavigationStyle
@objc extension FrameworkAutoloader {
    
    static func loadModule_NavigationStyle() {
        UIViewController.fw_swizzleNavigationStyle()
    }
    
}
