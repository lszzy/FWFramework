//
//  NavigationStyle.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UINavigationBar
@MainActor extension Wrapper where Base: UINavigationBar {
    /// 应用指定导航栏配置
    public func applyBarAppearance(_ appearance: NavigationBarAppearance) {
        if appearance.isTranslucent != isTranslucent {
            isTranslucent = appearance.isTranslucent
        }
        if appearance.backgroundTransparent {
            backgroundTransparent = appearance.backgroundTransparent
        } else if appearance.backgroundImage != nil {
            backgroundImage = appearance.backgroundImage
        } else if appearance.backgroundColor != nil {
            backgroundColor = appearance.backgroundColor
        }
        if appearance.shadowImage != nil {
            shadowImage = appearance.shadowImage
        } else if appearance.shadowColor != nil {
            shadowColor = appearance.shadowColor
        } else {
            shadowColor = nil
        }
        if appearance.foregroundColor != nil {
            foregroundColor = appearance.foregroundColor
        }
        if appearance.titleAttributes != nil {
            titleAttributes = appearance.titleAttributes
        }
        if appearance.buttonAttributes != nil {
            buttonAttributes = appearance.buttonAttributes
        }
        if appearance.backImage != nil {
            backImage = appearance.backImage
        }
        if appearance.appearanceBlock != nil {
            appearance.appearanceBlock?(base)
        }
    }
    
    /// 应用指定导航栏样式
    public func applyBarStyle(_ style: NavigationBarStyle) {
        if let appearance = NavigationBarAppearance.appearance(for: style) {
            applyBarAppearance(appearance)
        }
    }
}

// MARK: - Wrapper+UIViewController
@MainActor extension Wrapper where Base: UIViewController {
    /// 状态栏样式，默认preferredStatusBarStyle，设置后才会生效
    public var statusBarStyle: UIStatusBarStyle {
        get {
            if let style = propertyNumber(forName: "statusBarStyle") {
                return .init(rawValue: style.intValue) ?? .default
            }
            return base.preferredStatusBarStyle
        }
        set {
            setPropertyNumber(NSNumber(value: newValue.rawValue), forName: "statusBarStyle")
            base.setNeedsStatusBarAppearanceUpdate()
        }
    }

    /// 状态栏是否隐藏，默认prefersStatusBarHidden，设置后才会生效
    public var statusBarHidden: Bool {
        get {
            if let hidden = propertyNumber(forName: "statusBarHidden") {
                return hidden.boolValue
            }
            return base.prefersStatusBarHidden
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "statusBarHidden")
            base.setNeedsStatusBarAppearanceUpdate()
        }
    }

    /// 当前导航栏设置，优先级高于style，设置后会在viewWillAppear:自动应用生效
    public var navigationBarAppearance: NavigationBarAppearance? {
        get {
            return property(forName: "navigationBarAppearance") as? NavigationBarAppearance
        }
        set {
            setProperty(newValue, forName: "navigationBarAppearance")
            if base.isViewLoaded && base.view.window != nil {
                updateNavigationBarStyle(false, isAppeared: true)
            }
        }
    }

    /// 当前导航栏样式，默认default，设置后才会在viewWillAppear:自动应用生效
    public var navigationBarStyle: NavigationBarStyle {
        get {
            if let style = propertyNumber(forName: "navigationBarStyle") {
                return .init(rawValue: style.intValue)
            }
            return .default
        }
        set {
            setPropertyNumber(NSNumber(value: newValue.rawValue), forName: "navigationBarStyle")
            if base.isViewLoaded && base.view.window != nil {
                updateNavigationBarStyle(false, isAppeared: true)
            }
        }
    }

    /// 导航栏是否隐藏，默认isNavigationBarHidden，设置后才会在viewWillAppear:自动应用生效
    public var navigationBarHidden: Bool {
        get {
            if let hidden = propertyNumber(forName: "navigationBarHidden") {
                return hidden.boolValue
            }
            return base.navigationController?.isNavigationBarHidden ?? true
        }
        set {
            setNavigationBarHidden(newValue, animated: false)
            // 直接设置navigtionBar.isHidden不会影响右滑关闭手势
            // base.navigationController?.navigationBar.isHidden = true
        }
    }

    /// 动态隐藏导航栏，如果当前已经viewWillAppear:时立即执行
    public func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        setPropertyNumber(NSNumber(value: hidden), forName: "navigationBarHidden")
        if base.isViewLoaded && base.view.window != nil {
            updateNavigationBarStyle(false, isAppeared: true)
        }
    }
    
    /// 是否允许修改导航栏样式，默认未设置时child控制器不能修改
    public var allowsBarAppearance: Bool {
        get {
            if let number = propertyNumber(forName: "allowsBarAppearance") {
                return number.boolValue
            }
            return !isChild
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "allowsBarAppearance")
        }
    }
    
    private var currentNavigationBarAppearance: NavigationBarAppearance? {
        // 1. 检查VC是否自定义appearance
        if let appearance = navigationBarAppearance {
            return appearance
        }
        // 2. 检查VC是否自定义style
        if let style = propertyNumber(forName: "navigationBarStyle") {
            return NavigationBarAppearance.appearance(for: .init(rawValue: style.intValue))
        }
        // 3. 检查NAV是否自定义appearance
        if let appearance = base.navigationController?.fw.navigationBarAppearance {
            return appearance
        }
        // 4. 检查NAV是否自定义style
        if let style = base.navigationController?.fw.propertyNumber(forName: "navigationBarStyle") {
            return NavigationBarAppearance.appearance(for: .init(rawValue: style.intValue))
        }
        return nil
    }
    
    fileprivate func updateNavigationBarStyle(_ animated: Bool, isAppeared: Bool) {
        // 含有导航栏且不是导航栏控制器，如果是child控制器且允许修改时才处理
        guard let navigationController = base.navigationController,
              !(base is UINavigationController) else { return }
        if !allowsBarAppearance { return }
        
        // navigationBarHidden设置即生效，动态切换导航栏不突兀，一般在viewWillAppear:中调用
        if let hidden = propertyNumber(forName: "navigationBarHidden"),
           navigationController.isNavigationBarHidden != hidden.boolValue {
            navigationController.setNavigationBarHidden(hidden.boolValue, animated: animated)
        }
        
        // 获取当前用于显示的appearance，未设置时不处理
        guard let appearance = currentNavigationBarAppearance else { return }
        
        // 配合导航栏appearance初始化返回按钮或左侧按钮
        if appearance.backImage != nil {
            base.navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
        }
        if appearance.leftBackImage != nil && property(forName: #function) == nil {
            setPropertyBool(true, forName: #function)
            if navigationController.children.count > 1 && base.navigationItem.leftBarButtonItem == nil {
                leftBarItem = appearance.leftBackImage
            }
        }
        
        // 应用当前导航栏appearance
        navigationController.navigationBar.fw.applyBarAppearance(appearance)
        
        // 标记转场导航栏样式需要刷新
        if isAppeared {
            NavigationBarAppearance.appearanceChanged?(base)
        }
    }

    /// 标签栏是否隐藏，默认为true，立即生效。如果tabBar一直存在，则用tabBar包裹navBar；如果tabBar只存在主界面，则用navBar包裹tabBar
    public var tabBarHidden: Bool {
        get {
            #if compiler(>=6.0)
            if #available(iOS 18.0, *) {
                return base.tabBarController?.isTabBarHidden ?? true
            }
            #endif
            
            return base.tabBarController?.tabBar.isHidden ?? true
        }
        set {
            #if compiler(>=6.0)
            if #available(iOS 18.0, *) {
                base.tabBarController?.isTabBarHidden = newValue
                return
            }
            #endif
            
            base.tabBarController?.tabBar.isHidden = newValue
        }
    }
    
    /// 动态隐藏标签栏。仅iOS18+支持animated参数，立即生效
    public func setTabBarHidden(_ hidden: Bool, animated: Bool) {
        #if compiler(>=6.0)
        if #available(iOS 18.0, *) {
            base.tabBarController?.setTabBarHidden(hidden, animated: animated)
            return
        }
        #endif
        
        base.tabBarController?.tabBar.isHidden = hidden
    }
    
    /// 工具栏是否隐藏，默认为true。需设置toolbarItems，立即生效
    public var toolBarHidden: Bool {
        get {
            return base.navigationController?.isToolbarHidden ?? true
        }
        set {
            base.navigationController?.isToolbarHidden = newValue
        }
    }
    
    /// 动态隐藏工具栏。需设置toolbarItems，立即生效
    public func setToolBarHidden(_ hidden: Bool, animated: Bool) {
        base.navigationController?.setToolbarHidden(hidden, animated: animated)
    }

    /// 设置视图布局Bar延伸类型，None为不延伸(Bar不覆盖视图)，Top|Bottom为顶部|底部延伸，All为全部延伸
    public var extendedLayoutEdge: UIRectEdge {
        get {
            return base.edgesForExtendedLayout
        }
        set {
            base.edgesForExtendedLayout = newValue
            base.extendedLayoutIncludesOpaqueBars = true
        }
    }
    
    /// 自适应Bar延伸类型，兼容顶部和底部栏safeArea布局方式，需在viewDidLoad及之后调用生效。开启兼容模式时仅在iOS14及以下生效
    public func adjustExtendedLayout(compatible: Bool = false) {
        base.extendedLayoutIncludesOpaqueBars = true
        // iOS15+系统默认使用safeArea布局时自适应标签栏，开启兼容模式时仅处理iOS14及以下
        var shouldAdjust = true
        if compatible, #available(iOS 15.0, *) {
            shouldAdjust = false
        }
        if shouldAdjust, !base.hidesBottomBarWhenPushed,
           base.tabBarController != nil, isHead {
            // 注意移除bottom后无法实现标签栏半透明效果，可换成bottomBarHeight布局方式等
            base.edgesForExtendedLayout.remove(.bottom)
        }
    }
}

// MARK: - NavigationStyle
/// 导航栏可扩展全局样式
public struct NavigationBarStyle: RawRepresentable, Equatable, Hashable, Sendable {
    
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
open class NavigationBarAppearance {
    
    nonisolated(unsafe) static var appearanceChanged: (@MainActor (UIViewController) -> Void)?
    nonisolated(unsafe) private static var appearances = [NavigationBarStyle: NavigationBarAppearance]()
    
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
    
    public init() {}
    
}

// MARK: - FrameworkAutoloader+BarStyle
extension FrameworkAutoloader {
    
    @objc static func loadToolkit_BarStyle() {
        swizzleBarStyle()
    }
    
    private static func swizzleBarStyle() {
        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(getter: UIViewController.prefersStatusBarHidden),
            methodSignature: (@convention(c) (UIViewController, Selector) -> Bool).self,
            swizzleSignature: (@convention(block) (UIViewController) -> Bool).self
        ) { store in { selfObject in
            if let hidden = selfObject.fw.propertyNumber(forName: "statusBarHidden") {
                return hidden.boolValue
            } else {
                return store.original(selfObject, store.selector)
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(getter: UIViewController.preferredStatusBarStyle),
            methodSignature: (@convention(c) (UIViewController, Selector) -> UIStatusBarStyle).self,
            swizzleSignature: (@convention(block) (UIViewController) -> UIStatusBarStyle).self
        ) { store in { selfObject in
            if let style = selfObject.fw.propertyNumber(forName: "statusBarStyle") {
                return .init(rawValue: style.intValue) ?? .default
            } else {
                return store.original(selfObject, store.selector)
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            selfObject.fw.updateNavigationBarStyle(animated, isAppeared: false)
        }}
    }
    
}
