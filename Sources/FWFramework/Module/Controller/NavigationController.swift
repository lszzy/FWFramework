//
//  NavigationController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

/**
 优化导航栏转场动画闪烁的问题，默认关闭。全局启用后各个ViewController管理自己的导航栏样式，在viewDidLoad或viewViewAppear中设置即可
 @note 方案1：自己实现UINavigationController管理器；方案2：将原有导航栏设置透明，每个控制器添加一个NavigationBar充当导航栏；方案3：转场开始隐藏原有导航栏并添加假的NavigationBar，转场结束后还原。此处采用方案3。更多介绍：https://tech.meituan.com/2018/10/25/navigation-transition-solution-and-best-practice-in-meituan.html
 
 @see https://github.com/MoZhouqi/KMNavigationBarTransition
 @see https://github.com/Tencent/QMUI_iOS
 */
@_spi(FW) extension UINavigationController {
    
    private class FullscreenPopGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
        
        weak var navigationController: UINavigationController?
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
                  let navigationController = navigationController,
                  navigationController.viewControllers.count > 1 else {
                return false
            }
            
            guard let topViewController = navigationController.viewControllers.last,
                  !topViewController.fw_fullscreenPopGestureDisabled,
                  topViewController.shouldPopController else {
                return false
            }
            
            let beginningLocation = gestureRecognizer.location(in: gestureRecognizer.view)
            let maxAllowedDistance = topViewController.fw_fullscreenPopGestureDistance
            if maxAllowedDistance > 0 && beginningLocation.x > maxAllowedDistance {
                return false
            }
            
            if let isTransitioning = self.navigationController?.value(forKey: String(format: "%@%@%@", "_i", "sTransi", "tioning")) as? NSNumber, isTransitioning.boolValue {
                return false
            }
            
            let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
            let isLeftToRight = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight
            let multiplier: CGFloat = isLeftToRight ? 1 : -1
            if (translation.x * multiplier) <= 0 {
                return false
            }
            
            return true
        }
        
    }
    
    /// 自定义转场过程中containerView的背景色，默认透明
    public var fw_containerBackgroundColor: UIColor! {
        get {
            let backgroundColor = fw_property(forName: "fw_containerBackgroundColor") as? UIColor
            return backgroundColor ?? .clear
        }
        set {
            fw_setProperty(newValue, forName: "fw_containerBackgroundColor")
        }
    }
    
    private var fw_backgroundViewHidden: Bool {
        get {
            return fw_propertyBool(forName: "fw_backgroundViewHidden")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_backgroundViewHidden")
            self.navigationBar.fw_backgroundView?.isHidden = newValue
        }
    }
    
    private weak var fw_transitionContextToViewController: UIViewController? {
        get {
            return fw_property(forName: "fw_transitionContextToViewController") as? UIViewController
        }
        set {
            fw_setPropertyWeak(newValue, forName: "fw_transitionContextToViewController")
        }
    }
    
    private var fw_shouldBottomBarBeHidden: Bool {
        get {
            return fw_propertyBool(forName: "fw_shouldBottomBarBeHidden")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_shouldBottomBarBeHidden")
        }
    }
    
    /// 全局启用NavigationBar转场。启用后各个ViewController管理自己的导航栏样式，在viewDidLoad或viewViewAppear中设置即可
    public static func fw_enableBarTransition() {
        guard !fw_staticBarTransitionEnabled else { return }
        fw_staticBarTransitionEnabled = true
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationBar.self,
            selector: #selector(UINavigationBar.layoutSubviews),
            methodSignature: (@convention(c) (UINavigationBar, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UINavigationBar) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw_isFakeBar, let backgroundView = selfObject.fw_backgroundView {
                var frame = backgroundView.frame
                frame.size.height = selfObject.frame.size.height + abs(frame.origin.y)
                backgroundView.frame = frame
            }
        }}
        
        NSObject.fw_swizzleMethod(
            objc_getClass(String(format: "%@%@%@", "_U", "IBarBack", "ground")),
            selector: #selector(setter: UIView.isHidden),
            methodSignature: (@convention(c) (UIView, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, Bool) -> Void).self
        ) { store in { selfObject, hidden in
            var responder: UIResponder? = selfObject
            while responder != nil {
                if let navigationBar = responder as? UINavigationBar, navigationBar.fw_isFakeBar {
                    return
                }
                if let navigationController = responder as? UINavigationController {
                    store.original(selfObject, store.selector, navigationController.fw_backgroundViewHidden)
                    return
                }
                responder = responder?.next
            }
            
            store.original(selfObject, store.selector, hidden)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            let transitionController = selfObject.navigationController?.fw_transitionContextToViewController
            if let navigationBar = selfObject.fw_transitionNavigationBar {
                selfObject.navigationController?.navigationBar.fw_replaceStyle(navigationBar: navigationBar)
                if transitionController == nil || selfObject.isEqual(transitionController) {
                    selfObject.fw_transitionNavigationBar?.removeFromSuperview()
                    selfObject.fw_transitionNavigationBar = nil
                }
            }
            if selfObject.isEqual(transitionController) {
                selfObject.navigationController?.fw_transitionContextToViewController = nil
            }
            selfObject.navigationController?.fw_backgroundViewHidden = false
            store.original(selfObject, store.selector, animated)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillLayoutSubviews),
            methodSignature: (@convention(c) (UIViewController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController) -> Void).self
        ) { store in { selfObject in
            let tc = selfObject.transitionCoordinator
            let fromController = tc?.viewController(forKey: .from)
            let toController = tc?.viewController(forKey: .to)
            if !selfObject.fw_shouldCustomTransition(from: fromController, to: toController) {
                store.original(selfObject, store.selector)
                return
            }
            
            if selfObject.isEqual(selfObject.navigationController?.viewControllers.last) && selfObject.isEqual(toController) && tc?.presentationStyle == UIModalPresentationStyle.none {
                if selfObject.navigationController?.navigationBar.isTranslucent ?? false {
                    tc?.containerView.backgroundColor = selfObject.navigationController?.fw_containerBackgroundColor
                }
                fromController?.view.clipsToBounds = false
                toController?.view.clipsToBounds = false
                if selfObject.fw_transitionNavigationBar == nil {
                    selfObject.fw_addTransitionNavigationBarIfNeeded()
                    selfObject.navigationController?.fw_backgroundViewHidden = true
                }
                selfObject.fw_resizeTransitionNavigationBarFrame()
            }
            if let navigationBar = selfObject.fw_transitionNavigationBar {
                selfObject.view.bringSubviewToFront(navigationBar)
            }
            store.original(selfObject, store.selector)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.pushViewController(_:animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, UIViewController, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UINavigationController, UIViewController, Bool) -> Void).self
        ) { store in { selfObject, viewController, animated in
            guard let disappearingController = selfObject.viewControllers.last else {
                return store.original(selfObject, store.selector, viewController, animated)
            }
            if !selfObject.fw_shouldCustomTransition(from: disappearingController, to: viewController) {
                return store.original(selfObject, store.selector, viewController, animated)
            }
            
            if selfObject.viewControllers.contains(viewController) { return }
            if selfObject.fw_transitionContextToViewController == nil ||
                disappearingController.fw_transitionNavigationBar == nil {
                disappearingController.fw_addTransitionNavigationBarIfNeeded()
            }
            if animated {
                selfObject.fw_transitionContextToViewController = viewController
                if disappearingController.fw_transitionNavigationBar != nil {
                    disappearingController.navigationController?.fw_backgroundViewHidden = true
                }
            }
            return store.original(selfObject, store.selector, viewController, animated)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.popViewController(animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, Bool) -> UIViewController?).self,
            swizzleSignature: (@convention(block) (UINavigationController, Bool) -> UIViewController?).self
        ) { store in { selfObject, animated in
            if selfObject.viewControllers.count < 2 {
                return store.original(selfObject, store.selector, animated)
            }
            let disappearingController = selfObject.viewControllers.last
            let appearingController = selfObject.viewControllers[selfObject.viewControllers.count - 2]
            if !selfObject.fw_shouldCustomTransition(from: disappearingController, to: appearingController) {
                return store.original(selfObject, store.selector, animated)
            }
            
            disappearingController?.fw_addTransitionNavigationBarIfNeeded()
            if let navigationBar = appearingController.fw_transitionNavigationBar {
                selfObject.navigationBar.fw_replaceStyle(navigationBar: navigationBar)
            }
            if animated {
                disappearingController?.navigationController?.fw_backgroundViewHidden = true
            }
            return store.original(selfObject, store.selector, animated)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.popToViewController(_:animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, UIViewController, Bool) -> [UIViewController]?).self,
            swizzleSignature: (@convention(block) (UINavigationController, UIViewController, Bool) -> [UIViewController]?).self
        ) { store in { selfObject, viewController, animated in
            if !selfObject.viewControllers.contains(viewController) || selfObject.viewControllers.count < 2 {
                return store.original(selfObject, store.selector, viewController, animated)
            }
            let disappearingController = selfObject.viewControllers.last
            if !selfObject.fw_shouldCustomTransition(from: disappearingController, to: viewController) {
                return store.original(selfObject, store.selector, viewController, animated)
            }
            
            disappearingController?.fw_addTransitionNavigationBarIfNeeded()
            if let navigationBar = viewController.fw_transitionNavigationBar {
                selfObject.navigationBar.fw_replaceStyle(navigationBar: navigationBar)
            }
            if animated {
                disappearingController?.navigationController?.fw_backgroundViewHidden = true
            }
            return store.original(selfObject, store.selector, viewController, animated)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.popToRootViewController(animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, Bool) -> [UIViewController]?).self,
            swizzleSignature: (@convention(block) (UINavigationController, Bool) -> [UIViewController]?).self
        ) { store in { selfObject, animated in
            if selfObject.viewControllers.count < 2 {
                return store.original(selfObject, store.selector, animated)
            }
            let disappearingController = selfObject.viewControllers.last
            let rootViewController = selfObject.viewControllers.first
            if !selfObject.fw_shouldCustomTransition(from: disappearingController, to: rootViewController) {
                return store.original(selfObject, store.selector, animated)
            }
            
            disappearingController?.fw_addTransitionNavigationBarIfNeeded()
            if let navigationBar = rootViewController?.fw_transitionNavigationBar {
                selfObject.navigationBar.fw_replaceStyle(navigationBar: navigationBar)
            }
            if animated {
                disappearingController?.navigationController?.fw_backgroundViewHidden = true
            }
            return store.original(selfObject, store.selector, animated)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.setViewControllers(_:animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, [UIViewController], Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UINavigationController, [UIViewController], Bool) -> Void).self
        ) { store in { selfObject, viewControllers, animated in
            let disappearingController = selfObject.viewControllers.last
            let appearingController = viewControllers.last
            if !selfObject.fw_shouldCustomTransition(from: disappearingController, to: appearingController) {
                store.original(selfObject, store.selector, viewControllers, animated)
                return
            }
            
            if animated, let disappearingController = disappearingController, !disappearingController.isEqual(viewControllers.last) {
                disappearingController.fw_addTransitionNavigationBarIfNeeded()
                if disappearingController.fw_transitionNavigationBar != nil {
                    disappearingController.navigationController?.fw_backgroundViewHidden = true
                }
            }
            store.original(selfObject, store.selector, viewControllers, animated)
        }}
    }
    
    private static var fw_staticBarTransitionEnabled = false
    
    fileprivate static func fw_swizzleNavigationController() {
        // 修复iOS14.0如果pop到一个hidesBottomBarWhenPushed=NO的vc，tabBar无法正确显示出来的bug；iOS14.2已修复该问题
        if #available(iOS 14.2, *) {} else if #available(iOS 14.0, *) {
            NSObject.fw_swizzleInstanceMethod(
                UINavigationController.self,
                selector: #selector(UINavigationController.popToViewController(_:animated:)),
                methodSignature: (@convention(c) (UINavigationController, Selector, UIViewController, Bool) -> [UIViewController]?).self,
                swizzleSignature: (@convention(block) (UINavigationController, UIViewController, Bool) -> [UIViewController]?).self
            ) { store in { selfObject, viewController, animated in
                if animated && selfObject.tabBarController != nil && !viewController.hidesBottomBarWhenPushed {
                    var shouldHideTabBar = false
                    if let index = selfObject.viewControllers.firstIndex(of: viewController) {
                        let viewControllers = selfObject.viewControllers[0 ... index]
                        for vc in viewControllers {
                            if vc.hidesBottomBarWhenPushed {
                                shouldHideTabBar = true
                            }
                        }
                        if !shouldHideTabBar {
                            selfObject.fw_shouldBottomBarBeHidden = true
                        }
                    }
                }
                
                let result = store.original(selfObject, store.selector, viewController, animated)
                selfObject.fw_shouldBottomBarBeHidden = false
                return result
            }}
            
            NSObject.fw_swizzleInstanceMethod(
                UINavigationController.self,
                selector: #selector(UINavigationController.popToRootViewController(animated:)),
                methodSignature: (@convention(c) (UINavigationController, Selector, Bool) -> [UIViewController]?).self,
                swizzleSignature: (@convention(block) (UINavigationController, Bool) -> [UIViewController]?).self
            ) { store in { selfObject, animated in
                if animated && selfObject.tabBarController != nil && selfObject.viewControllers.count > 2 && !(selfObject.viewControllers.first?.hidesBottomBarWhenPushed ?? false) {
                    selfObject.fw_shouldBottomBarBeHidden = true
                }
                
                let result = store.original(selfObject, store.selector, animated)
                selfObject.fw_shouldBottomBarBeHidden = false
                return result
            }}
            
            NSObject.fw_swizzleInstanceMethod(
                UINavigationController.self,
                selector: #selector(UINavigationController.setViewControllers(_:animated:)),
                methodSignature: (@convention(c) (UINavigationController, Selector, [UIViewController], Bool) -> Void).self,
                swizzleSignature: (@convention(block) (UINavigationController, [UIViewController], Bool) -> Void).self
            ) { store in { selfObject, viewControllers, animated in
                let viewController = viewControllers.last
                if animated && selfObject.tabBarController != nil && !(viewController?.hidesBottomBarWhenPushed ?? false) {
                    var shouldHideTabBar = false
                    for vc in viewControllers {
                        if vc.hidesBottomBarWhenPushed {
                            shouldHideTabBar = true
                        }
                    }
                    if !shouldHideTabBar {
                        selfObject.fw_shouldBottomBarBeHidden = true
                    }
                }
                
                store.original(selfObject, store.selector, viewControllers, animated)
                selfObject.fw_shouldBottomBarBeHidden = false
            }}
            
            NSObject.fw_swizzleInstanceMethod(
                UINavigationController.self,
                selector: NSSelectorFromString(String(format: "%@%@%@", "_s", "houldBotto", "mBarBeHidden")),
                methodSignature: (@convention(c) (UINavigationController, Selector) -> Bool).self,
                swizzleSignature: (@convention(block) (UINavigationController) -> Bool).self
            ) { store in { selfObject in
                var result = store.original(selfObject, store.selector)
                if selfObject.fw_shouldBottomBarBeHidden {
                    result = false
                }
                return result
            }}
        }
    }
    
    /// 是否启用导航栏全屏返回手势，默认NO。启用时系统返回手势失效，禁用时还原系统手势。如果只禁用系统手势，设置interactivePopGestureRecognizer.enabled即可
    public var fw_fullscreenPopGestureEnabled: Bool {
        get {
            return self.fw_fullscreenPopGestureRecognizer.isEnabled
        }
        set {
            if !(self.interactivePopGestureRecognizer?.view?.gestureRecognizers?.contains(self.fw_fullscreenPopGestureRecognizer) ?? false) {
                self.interactivePopGestureRecognizer?.view?.addGestureRecognizer(self.fw_fullscreenPopGestureRecognizer)
                
                let internalTargets = self.interactivePopGestureRecognizer?.value(forKey: "targets") as? NSArray
                let internalTarget = (internalTargets?.firstObject as? NSObject)?.value(forKey: "target")
                let internalAction = NSSelectorFromString("handleNavigationTransition:")
                self.fw_fullscreenPopGestureRecognizer.delegate = self.fw_popGestureRecognizerDelegate
                if let internalTarget = internalTarget {
                    self.fw_fullscreenPopGestureRecognizer.addTarget(internalTarget, action: internalAction)
                }
            }
            
            self.fw_fullscreenPopGestureRecognizer.isEnabled = newValue
            self.interactivePopGestureRecognizer?.isEnabled = !newValue
        }
    }
    
    private var fw_popGestureRecognizerDelegate: FullscreenPopGestureRecognizerDelegate {
        if let delegate = fw_property(forName: "fw_popGestureRecognizerDelegate") as? FullscreenPopGestureRecognizerDelegate {
            return delegate
        } else {
            let delegate = FullscreenPopGestureRecognizerDelegate()
            delegate.navigationController = self
            fw_setProperty(delegate, forName: "fw_popGestureRecognizerDelegate")
            return delegate
        }
    }

    /// 导航栏全屏返回手势对象
    public var fw_fullscreenPopGestureRecognizer: UIPanGestureRecognizer {
        if let gestureRecognizer = fw_property(forName: "fw_fullscreenPopGestureRecognizer") as? UIPanGestureRecognizer {
            return gestureRecognizer
        } else {
            let gestureRecognizer = UIPanGestureRecognizer()
            gestureRecognizer.maximumNumberOfTouches = 1
            fw_setProperty(gestureRecognizer, forName: "fw_fullscreenPopGestureRecognizer")
            return gestureRecognizer
        }
    }
    
    /// 判断手势是否是全局返回手势对象
    public static func fw_isFullscreenPopGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.delegate is FullscreenPopGestureRecognizerDelegate {
            return true
        }
        return false
    }
    
}

/**
 视图控制器导航栏转场分类。可设置部分界面不需要自定义转场；
 如果导航栏push/pop存在黑影(tab.nav.push|present.nav.push|nav.push)，可在对应控制器的viewDidLoad设置视图背景色为白色(tab.view|present.nav.view|vc.view)。
 
 导航栏全屏返回手势分类，兼容shouldPopController返回拦截方法
 @see https://github.com/forkingdog/FDFullscreenPopGesture
 */
@_spi(FW) extension UIViewController {
    
    /// 转场动画自定义判断标识，不相等才会启用转场。默认nil启用转场。可重写或者push前设置生效
    public var fw_barTransitionIdentifier: AnyHashable? {
        get { return fw_property(forName: "fw_barTransitionIdentifier") as? AnyHashable }
        set { fw_setProperty(newValue, forName: "fw_barTransitionIdentifier") }
    }
    
    /// 标记转场导航栏样式需要刷新，如果viewDidAppear之前导航栏样式发生了改变，可调用此方法
    internal func fw_barTransitionNeedsUpdate() {
        guard let navigationBar = navigationController?.navigationBar,
              let transitionNavigationBar = fw_transitionNavigationBar else { return }
        transitionNavigationBar.fw_replaceStyle(navigationBar: navigationBar)
    }
    
    fileprivate var fw_transitionNavigationBar: UINavigationBar? {
        get { return fw_property(forName: "fw_transitionNavigationBar") as? UINavigationBar }
        set { fw_setProperty(newValue, forName: "fw_transitionNavigationBar") }
    }
    
    fileprivate func fw_resizeTransitionNavigationBarFrame() {
        if self.view.window == nil { return }
        let backgroundView = self.navigationController?.navigationBar.fw_backgroundView
        let rect = backgroundView?.superview?.convert(backgroundView?.frame ?? .zero, to: self.view) ?? .zero
        self.fw_transitionNavigationBar?.frame = rect
    }
    
    fileprivate func fw_addTransitionNavigationBarIfNeeded() {
        if !self.isViewLoaded || self.view.window == nil { return }
        guard let navigationController = self.navigationController else { return }
        let bar = UINavigationBar()
        bar.fw_isFakeBar = true
        // 修复iOS14假的NavigationBar不生效问题
        if #available(iOS 14.0, *) {
            bar.items = [UINavigationItem()]
        }
        bar.barStyle = navigationController.navigationBar.barStyle
        if bar.isTranslucent != navigationController.navigationBar.isTranslucent {
            bar.isTranslucent = navigationController.navigationBar.isTranslucent
        }
        bar.fw_replaceStyle(navigationBar: navigationController.navigationBar)
        self.fw_transitionNavigationBar?.removeFromSuperview()
        self.fw_transitionNavigationBar = bar
        self.fw_resizeTransitionNavigationBarFrame()
        if !navigationController.isNavigationBarHidden && !navigationController.navigationBar.isHidden {
            self.view.addSubview(bar)
        }
    }
    
    fileprivate func fw_shouldCustomTransition(from: UIViewController?, to: UIViewController?) -> Bool {
        guard let from = from, let to = to else { return true }
        // 如果identifier有值则比较之，不相等才启用转场
        let fromIdentifier = from.fw_barTransitionIdentifier
        let toIdentifier = to.fw_barTransitionIdentifier
        if fromIdentifier != nil || toIdentifier != nil {
            return fromIdentifier != toIdentifier
        }
        return true
    }
    
    /// 视图控制器是否禁用全屏返回手势，默认NO
    public var fw_fullscreenPopGestureDisabled: Bool {
        get { return fw_propertyBool(forName: "fw_fullscreenPopGestureDisabled") }
        set { fw_setPropertyBool(newValue, forName: "fw_fullscreenPopGestureDisabled") }
    }

    /// 视图控制器全屏手势距离左侧最大距离，默认0，无限制
    public var fw_fullscreenPopGestureDistance: CGFloat {
        get { return fw_propertyDouble(forName: "fw_fullscreenPopGestureDistance") }
        set { fw_setPropertyDouble(newValue, forName: "fw_fullscreenPopGestureDistance") }
    }
    
}

@_spi(FW) extension UINavigationBar {
    
    /// 导航栏背景视图，显示背景色和背景图片等
    public var fw_backgroundView: UIView? {
        return fw_invokeGetter(String(format: "%@%@%@", "_b", "ackgro", "undView")) as? UIView
    }
    
    /// 导航栏内容视图，iOS11+才存在，显示item和titleView等
    public var fw_contentView: UIView? {
        for subview in self.subviews {
            if NSStringFromClass(subview.classForCoder).hasSuffix("ContentView") {
                return subview
            }
        }
        return nil
    }
    
    /// 导航栏大标题视图，显示时才有值。如果要设置背景色，可使用fw_backgroundView.backgroundColor
    public var fw_largeTitleView: UIView? {
        for subview in self.subviews {
            if NSStringFromClass(subview.classForCoder).hasSuffix("LargeTitleView") {
                return subview
            }
        }
        return nil
    }
    
    /// 导航栏大标题高度，与是否隐藏无关
    public static var fw_largeTitleHeight: CGFloat {
        return 52
    }
    
    fileprivate var fw_isFakeBar: Bool {
        get { return fw_propertyBool(forName: "fw_isFakeBar") }
        set { fw_setPropertyBool(newValue, forName: "fw_isFakeBar") }
    }
    
    fileprivate func fw_replaceStyle(navigationBar: UINavigationBar) {
        self.barTintColor = navigationBar.barTintColor
        self.setBackgroundImage(navigationBar.backgroundImage(for: .default), for: .default)
        self.shadowImage = navigationBar.shadowImage
        
        self.tintColor = navigationBar.tintColor
        self.titleTextAttributes = navigationBar.titleTextAttributes
        self.largeTitleTextAttributes = navigationBar.largeTitleTextAttributes
        
        if UINavigationBar.fw_appearanceEnabled {
            self.standardAppearance = navigationBar.standardAppearance
            self.compactAppearance = navigationBar.compactAppearance
            self.scrollEdgeAppearance = navigationBar.scrollEdgeAppearance
            if #available(iOS 15.0, *) {
                self.compactScrollEdgeAppearance = navigationBar.compactScrollEdgeAppearance
            }
        }
    }
    
}

/**
 present带导航栏webview，如果存在input[type=file]，会dismiss两次，无法选择照片。
 解决方法：1.使用push 2.重写dismiss方法仅当presentedViewController存在时才调用dismiss
 */
@_spi(FW) extension UIToolbar {
    
    /// 工具栏背景视图，显示背景色和背景图片等。如果标签栏同时显示，背景视图高度也会包含标签栏高度
    public var fw_backgroundView: UIView? {
        return fw_invokeGetter(String(format: "%@%@%@", "_b", "ackgro", "undView")) as? UIView
    }
    
    /// 工具栏内容视图，iOS11+才存在，显示item等
    public var fw_contentView: UIView? {
        for subview in self.subviews {
            if NSStringFromClass(subview.classForCoder).hasSuffix("ContentView") {
                return subview
            }
        }
        return nil
    }
    
}

// MARK: - NavigationControllerAutoloader
internal class NavigationControllerAutoloader: AutoloadProtocol {
    
    static func autoload() {
        UINavigationController.fw_swizzleNavigationController()
    }
    
}
