//
//  NavigationController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UINavigationController
/**
 优化导航栏转场动画闪烁的问题，默认关闭。全局启用后各个ViewController管理自己的导航栏样式，在viewDidLoad或viewViewAppear中设置即可
 @note 方案1：自己实现UINavigationController管理器；方案2：将原有导航栏设置透明，每个控制器添加一个NavigationBar充当导航栏；方案3：转场开始隐藏原有导航栏并添加假的NavigationBar，转场结束后还原。此处采用方案3。更多介绍：https://tech.meituan.com/2018/10/25/navigation-transition-solution-and-best-practice-in-meituan.html

 @see https://github.com/MoZhouqi/KMNavigationBarTransition
 @see https://github.com/Tencent/QMUI_iOS
 */
@MainActor extension Wrapper where Base: UINavigationController {
    /// 自定义转场过程中containerView的背景色，默认透明
    public var containerBackgroundColor: UIColor! {
        get {
            let backgroundColor = property(forName: "containerBackgroundColor") as? UIColor
            return backgroundColor ?? .clear
        }
        set {
            setProperty(newValue, forName: "containerBackgroundColor")
        }
    }

    fileprivate var backgroundViewHidden: Bool {
        get {
            propertyBool(forName: "backgroundViewHidden")
        }
        set {
            setPropertyBool(newValue, forName: "backgroundViewHidden")
            base.navigationBar.fw.backgroundView?.isHidden = newValue
        }
    }

    fileprivate weak var transitionContextToViewController: UIViewController? {
        get {
            property(forName: "transitionContextToViewController") as? UIViewController
        }
        set {
            setPropertyWeak(newValue, forName: "transitionContextToViewController")
        }
    }

    fileprivate var shouldBottomBarBeHidden: Bool {
        get {
            propertyBool(forName: "shouldBottomBarBeHidden")
        }
        set {
            setPropertyBool(newValue, forName: "shouldBottomBarBeHidden")
        }
    }

    /// 全局启用NavigationBar转场。启用后各个ViewController管理自己的导航栏样式，在viewDidLoad或viewViewAppear中设置即可
    public static func enableBarTransition() {
        FrameworkAutoloader.swizzleBarTransition()
    }

    /// 是否启用导航栏全屏返回手势，默认NO。启用时系统返回手势失效，禁用时还原系统手势。如果只禁用系统手势，设置interactivePopGestureRecognizer.enabled即可
    public var fullscreenPopGestureEnabled: Bool {
        get {
            fullscreenPopGestureRecognizer.isEnabled
        }
        set {
            if !(base.interactivePopGestureRecognizer?.view?.gestureRecognizers?.contains(fullscreenPopGestureRecognizer) ?? false) {
                base.interactivePopGestureRecognizer?.view?.addGestureRecognizer(fullscreenPopGestureRecognizer)

                let internalTargets = base.interactivePopGestureRecognizer?.value(forKey: "targets") as? NSArray
                let internalTarget = (internalTargets?.firstObject as? NSObject)?.value(forKey: "target")
                let internalAction = NSSelectorFromString("handleNavigationTransition:")
                fullscreenPopGestureRecognizer.delegate = popGestureRecognizerDelegate
                if let internalTarget {
                    fullscreenPopGestureRecognizer.addTarget(internalTarget, action: internalAction)
                }
            }

            fullscreenPopGestureRecognizer.isEnabled = newValue
            base.interactivePopGestureRecognizer?.isEnabled = !newValue
        }
    }

    private var popGestureRecognizerDelegate: FullscreenPopGestureRecognizerDelegate {
        if let delegate = property(forName: "popGestureRecognizerDelegate") as? FullscreenPopGestureRecognizerDelegate {
            return delegate
        } else {
            let delegate = FullscreenPopGestureRecognizerDelegate()
            delegate.navigationController = base
            setProperty(delegate, forName: "popGestureRecognizerDelegate")
            return delegate
        }
    }

    /// 导航栏全屏返回手势对象
    public var fullscreenPopGestureRecognizer: UIPanGestureRecognizer {
        if let gestureRecognizer = property(forName: "fullscreenPopGestureRecognizer") as? UIPanGestureRecognizer {
            return gestureRecognizer
        } else {
            let gestureRecognizer = UIPanGestureRecognizer()
            gestureRecognizer.maximumNumberOfTouches = 1
            setProperty(gestureRecognizer, forName: "fullscreenPopGestureRecognizer")
            return gestureRecognizer
        }
    }

    /// 判断手势是否是全局返回手势对象
    public static func isFullscreenPopGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.delegate is FullscreenPopGestureRecognizerDelegate {
            return true
        }
        return false
    }
}

// MARK: - Wrapper+UIViewController
/**
 视图控制器导航栏转场分类。可设置部分界面不需要自定义转场；
 如果导航栏push/pop存在黑影(tab.nav.push|present.nav.push|nav.push)，可在对应控制器的viewDidLoad设置视图背景色为白色(tab.view|present.nav.view|vc.view)。

 导航栏全屏返回手势分类，兼容shouldPopController返回拦截方法
 @see https://github.com/forkingdog/FDFullscreenPopGesture
 */
@MainActor extension Wrapper where Base: UIViewController {
    /// 转场动画自定义判断标识，不相等才会启用转场。默认nil启用转场。可重写或者push前设置生效
    public var barTransitionIdentifier: AnyHashable? {
        get { property(forName: "barTransitionIdentifier") as? AnyHashable }
        set { setProperty(newValue, forName: "barTransitionIdentifier") }
    }

    /// 标记转场导航栏样式需要刷新，如果viewDidAppear之前导航栏样式发生了改变，可调用此方法
    fileprivate func barTransitionNeedsUpdate() {
        guard let navigationBar = base.navigationController?.navigationBar,
              let transitionBar = transitionNavigationBar else { return }
        transitionBar.fw.replaceStyle(navigationBar: navigationBar)
    }

    fileprivate var transitionNavigationBar: UINavigationBar? {
        get { property(forName: "transitionNavigationBar") as? UINavigationBar }
        set { setProperty(newValue, forName: "transitionNavigationBar") }
    }

    fileprivate func resizeTransitionNavigationBarFrame() {
        if base.view.window == nil { return }
        let backgroundView = base.navigationController?.navigationBar.fw.backgroundView
        let rect = backgroundView?.superview?.convert(backgroundView?.frame ?? .zero, to: base.view) ?? .zero
        transitionNavigationBar?.frame = rect
    }

    fileprivate func addTransitionNavigationBarIfNeeded() {
        if !base.isViewLoaded || base.view.window == nil { return }
        guard let navigationController = base.navigationController else { return }
        let bar = UINavigationBar()
        bar.fw.isFakeBar = true
        // 修复iOS14假的NavigationBar不生效问题
        if #available(iOS 14.0, *) {
            bar.items = [UINavigationItem()]
        }
        bar.barStyle = navigationController.navigationBar.barStyle
        if bar.isTranslucent != navigationController.navigationBar.isTranslucent {
            bar.isTranslucent = navigationController.navigationBar.isTranslucent
        }
        bar.fw.replaceStyle(navigationBar: navigationController.navigationBar)
        transitionNavigationBar?.removeFromSuperview()
        transitionNavigationBar = bar
        resizeTransitionNavigationBarFrame()
        if !navigationController.isNavigationBarHidden && !navigationController.navigationBar.isHidden {
            base.view.addSubview(bar)
        }
    }

    fileprivate func shouldCustomTransition(from: UIViewController?, to: UIViewController?) -> Bool {
        guard let from, let to else { return true }
        // 如果identifier有值则比较之，不相等才启用转场
        let fromIdentifier = from.fw.barTransitionIdentifier
        let toIdentifier = to.fw.barTransitionIdentifier
        if fromIdentifier != nil || toIdentifier != nil {
            return fromIdentifier != toIdentifier
        }
        return true
    }

    /// 视图控制器是否禁用全屏返回手势，默认NO
    public var fullscreenPopGestureDisabled: Bool {
        get { propertyBool(forName: "fullscreenPopGestureDisabled") }
        set { setPropertyBool(newValue, forName: "fullscreenPopGestureDisabled") }
    }

    /// 视图控制器全屏手势距离左侧最大距离，默认0，无限制
    public var fullscreenPopGestureDistance: CGFloat {
        get { propertyDouble(forName: "fullscreenPopGestureDistance") }
        set { setPropertyDouble(newValue, forName: "fullscreenPopGestureDistance") }
    }
}

// MARK: - Wrapper+UINavigationBar
@MainActor extension Wrapper where Base: UINavigationBar {
    /// 导航栏背景视图，显示背景色和背景图片等
    public var backgroundView: UIView? {
        invokeGetter(String(format: "%@%@%@", "_b", "ackgro", "undView")) as? UIView
    }

    /// 导航栏内容视图，iOS11+才存在，显示item和titleView等
    public var contentView: UIView? {
        for subview in base.subviews {
            if NSStringFromClass(type(of: subview)).hasSuffix("ContentView") {
                return subview
            }
        }
        return nil
    }

    /// 导航栏大标题视图，显示时才有值。如果要设置背景色，可使用backgroundView.backgroundColor
    public var largeTitleView: UIView? {
        for subview in base.subviews {
            if NSStringFromClass(type(of: subview)).hasSuffix("LargeTitleView") {
                return subview
            }
        }
        return nil
    }

    /// 导航栏大标题高度，与是否隐藏无关
    public static var largeTitleHeight: CGFloat {
        52
    }

    fileprivate var isFakeBar: Bool {
        get { propertyBool(forName: "isFakeBar") }
        set { setPropertyBool(newValue, forName: "isFakeBar") }
    }

    fileprivate func replaceStyle(navigationBar: UINavigationBar) {
        base.barTintColor = navigationBar.barTintColor
        base.setBackgroundImage(navigationBar.backgroundImage(for: .default), for: .default)
        base.shadowImage = navigationBar.shadowImage

        base.tintColor = navigationBar.tintColor
        base.titleTextAttributes = navigationBar.titleTextAttributes
        base.largeTitleTextAttributes = navigationBar.largeTitleTextAttributes

        if UINavigationBar.fw.appearanceEnabled {
            base.standardAppearance = navigationBar.standardAppearance
            base.compactAppearance = navigationBar.compactAppearance
            base.scrollEdgeAppearance = navigationBar.scrollEdgeAppearance
            if #available(iOS 15.0, *) {
                base.compactScrollEdgeAppearance = navigationBar.compactScrollEdgeAppearance
            }
        }
    }
}

// MARK: - Wrapper+UIToolbar
/**
 present带导航栏webview，如果存在input[type=file]，会dismiss两次，无法选择照片。
 解决方法：1.使用push 2.重写dismiss方法仅当presentedViewController存在时才调用dismiss
 */
@MainActor extension Wrapper where Base: UIToolbar {
    /// 工具栏背景视图，显示背景色和背景图片等。如果标签栏同时显示，背景视图高度也会包含标签栏高度
    public var backgroundView: UIView? {
        invokeGetter(String(format: "%@%@%@", "_b", "ackgro", "undView")) as? UIView
    }

    /// 工具栏内容视图，iOS11+才存在，显示item等
    public var contentView: UIView? {
        for subview in base.subviews {
            if NSStringFromClass(type(of: subview)).hasSuffix("ContentView") {
                return subview
            }
        }
        return nil
    }
}

// MARK: - FullscreenPopGestureRecognizerDelegate
private class FullscreenPopGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController?

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
              let navigationController,
              navigationController.viewControllers.count > 1 else {
            return false
        }

        guard let topViewController = navigationController.viewControllers.last,
              !topViewController.fw.fullscreenPopGestureDisabled,
              topViewController.shouldPopController else {
            return false
        }

        let beginningLocation = gestureRecognizer.location(in: gestureRecognizer.view)
        let maxAllowedDistance = topViewController.fw.fullscreenPopGestureDistance
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

// MARK: - FrameworkStorage+NavigationController
extension FrameworkStorage {
    fileprivate static var swizzleBarTransition = false
}

// MARK: - FrameworkAutoloader+NavigationController
extension FrameworkAutoloader {
    @objc static func loadModule_NavigationController() {
        swizzleNavigationController()

        FrameworkStorage.appearanceChanged = { viewController in
            viewController.fw.barTransitionNeedsUpdate()
        }
    }

    private static func swizzleNavigationController() {
        // 修复iOS14.0如果pop到一个hidesBottomBarWhenPushed=NO的vc，tabBar无法正确显示出来的bug；iOS14.2已修复该问题
        if #available(iOS 14.2, *) {} else if #available(iOS 14.0, *) {
            NSObject.fw.swizzleInstanceMethod(
                UINavigationController.self,
                selector: #selector(UINavigationController.popToViewController(_:animated:)),
                methodSignature: (@convention(c) (UINavigationController, Selector, UIViewController, Bool) -> [UIViewController]?).self,
                swizzleSignature: (@convention(block) @MainActor (UINavigationController, UIViewController, Bool) -> [UIViewController]?).self
            ) { store in { selfObject, viewController, animated in
                if animated && selfObject.tabBarController != nil && !viewController.hidesBottomBarWhenPushed {
                    var shouldHideTabBar = false
                    if let index = selfObject.viewControllers.firstIndex(of: viewController) {
                        let viewControllers = selfObject.viewControllers[0...index]
                        for vc in viewControllers {
                            if vc.hidesBottomBarWhenPushed {
                                shouldHideTabBar = true
                            }
                        }
                        if !shouldHideTabBar {
                            selfObject.fw.shouldBottomBarBeHidden = true
                        }
                    }
                }

                let result = store.original(selfObject, store.selector, viewController, animated)
                selfObject.fw.shouldBottomBarBeHidden = false
                return result
            }}

            NSObject.fw.swizzleInstanceMethod(
                UINavigationController.self,
                selector: #selector(UINavigationController.popToRootViewController(animated:)),
                methodSignature: (@convention(c) (UINavigationController, Selector, Bool) -> [UIViewController]?).self,
                swizzleSignature: (@convention(block) @MainActor (UINavigationController, Bool) -> [UIViewController]?).self
            ) { store in { selfObject, animated in
                if animated && selfObject.tabBarController != nil && selfObject.viewControllers.count > 2 && !(selfObject.viewControllers.first?.hidesBottomBarWhenPushed ?? false) {
                    selfObject.fw.shouldBottomBarBeHidden = true
                }

                let result = store.original(selfObject, store.selector, animated)
                selfObject.fw.shouldBottomBarBeHidden = false
                return result
            }}

            NSObject.fw.swizzleInstanceMethod(
                UINavigationController.self,
                selector: #selector(UINavigationController.setViewControllers(_:animated:)),
                methodSignature: (@convention(c) (UINavigationController, Selector, [UIViewController], Bool) -> Void).self,
                swizzleSignature: (@convention(block) @MainActor (UINavigationController, [UIViewController], Bool) -> Void).self
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
                        selfObject.fw.shouldBottomBarBeHidden = true
                    }
                }

                store.original(selfObject, store.selector, viewControllers, animated)
                selfObject.fw.shouldBottomBarBeHidden = false
            }}

            NSObject.fw.swizzleInstanceMethod(
                UINavigationController.self,
                selector: NSSelectorFromString(String(format: "%@%@%@", "_s", "houldBotto", "mBarBeHidden")),
                methodSignature: (@convention(c) (UINavigationController, Selector) -> Bool).self,
                swizzleSignature: (@convention(block) @MainActor (UINavigationController) -> Bool).self
            ) { store in { selfObject in
                var result = store.original(selfObject, store.selector)
                if selfObject.fw.shouldBottomBarBeHidden {
                    result = false
                }
                return result
            }}
        }
    }

    fileprivate static func swizzleBarTransition() {
        guard !FrameworkStorage.swizzleBarTransition else { return }
        FrameworkStorage.swizzleBarTransition = true

        NSObject.fw.swizzleInstanceMethod(
            UINavigationBar.self,
            selector: #selector(UINavigationBar.layoutSubviews),
            methodSignature: (@convention(c) (UINavigationBar, Selector) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationBar) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)

            if selfObject.fw.isFakeBar, let backgroundView = selfObject.fw.backgroundView {
                var frame = backgroundView.frame
                frame.size.height = selfObject.frame.size.height + abs(frame.origin.y)
                backgroundView.frame = frame
            }
        }}

        NSObject.fw.swizzleMethod(
            objc_getClass(String(format: "%@%@%@", "_U", "IBarBack", "ground")),
            selector: #selector(setter: UIView.isHidden),
            methodSignature: (@convention(c) (UIView, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIView, Bool) -> Void).self
        ) { store in { selfObject, hidden in
            var responder: UIResponder? = selfObject
            while responder != nil {
                if let navigationBar = responder as? UINavigationBar, navigationBar.fw.isFakeBar {
                    return
                }
                if let navigationController = responder as? UINavigationController {
                    store.original(selfObject, store.selector, navigationController.fw.backgroundViewHidden)
                    return
                }
                responder = responder?.next
            }

            store.original(selfObject, store.selector, hidden)
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            let transitionController = selfObject.navigationController?.fw.transitionContextToViewController
            if let navigationBar = selfObject.fw.transitionNavigationBar {
                selfObject.navigationController?.navigationBar.fw.replaceStyle(navigationBar: navigationBar)
                if transitionController == nil || selfObject.isEqual(transitionController) {
                    selfObject.fw.transitionNavigationBar?.removeFromSuperview()
                    selfObject.fw.transitionNavigationBar = nil
                }
            }
            if selfObject.isEqual(transitionController) {
                selfObject.navigationController?.fw.transitionContextToViewController = nil
            }
            selfObject.navigationController?.fw.backgroundViewHidden = false
            store.original(selfObject, store.selector, animated)
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillLayoutSubviews),
            methodSignature: (@convention(c) (UIViewController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController) -> Void).self
        ) { store in { selfObject in
            let tc = selfObject.transitionCoordinator
            let fromController = tc?.viewController(forKey: .from)
            let toController = tc?.viewController(forKey: .to)
            if !selfObject.fw.shouldCustomTransition(from: fromController, to: toController) {
                store.original(selfObject, store.selector)
                return
            }

            if selfObject.isEqual(selfObject.navigationController?.viewControllers.last) && selfObject.isEqual(toController) && tc?.presentationStyle == UIModalPresentationStyle.none {
                if selfObject.navigationController?.navigationBar.isTranslucent ?? false {
                    tc?.containerView.backgroundColor = selfObject.navigationController?.fw.containerBackgroundColor
                }
                fromController?.view.clipsToBounds = false
                toController?.view.clipsToBounds = false
                if selfObject.fw.transitionNavigationBar == nil {
                    selfObject.fw.addTransitionNavigationBarIfNeeded()
                    selfObject.navigationController?.fw.backgroundViewHidden = true
                }
                selfObject.fw.resizeTransitionNavigationBarFrame()
            }
            if let navigationBar = selfObject.fw.transitionNavigationBar {
                selfObject.view.bringSubviewToFront(navigationBar)
            }
            store.original(selfObject, store.selector)
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.pushViewController(_:animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, UIViewController, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationController, UIViewController, Bool) -> Void).self
        ) { store in { selfObject, viewController, animated in
            guard let disappearingController = selfObject.viewControllers.last else {
                return store.original(selfObject, store.selector, viewController, animated)
            }
            if !selfObject.fw.shouldCustomTransition(from: disappearingController, to: viewController) {
                return store.original(selfObject, store.selector, viewController, animated)
            }

            if selfObject.viewControllers.contains(viewController) { return }
            if selfObject.fw.transitionContextToViewController == nil ||
                disappearingController.fw.transitionNavigationBar == nil {
                disappearingController.fw.addTransitionNavigationBarIfNeeded()
            }
            if animated {
                selfObject.fw.transitionContextToViewController = viewController
                if disappearingController.fw.transitionNavigationBar != nil {
                    disappearingController.navigationController?.fw.backgroundViewHidden = true
                }
            }
            return store.original(selfObject, store.selector, viewController, animated)
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.popViewController(animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, Bool) -> UIViewController?).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationController, Bool) -> UIViewController?).self
        ) { store in { selfObject, animated in
            if selfObject.viewControllers.count < 2 {
                return store.original(selfObject, store.selector, animated)
            }
            let disappearingController = selfObject.viewControllers.last
            let appearingController = selfObject.viewControllers[selfObject.viewControllers.count - 2]
            if !selfObject.fw.shouldCustomTransition(from: disappearingController, to: appearingController) {
                return store.original(selfObject, store.selector, animated)
            }

            disappearingController?.fw.addTransitionNavigationBarIfNeeded()
            if let navigationBar = appearingController.fw.transitionNavigationBar {
                selfObject.navigationBar.fw.replaceStyle(navigationBar: navigationBar)
            }
            if animated {
                disappearingController?.navigationController?.fw.backgroundViewHidden = true
            }
            return store.original(selfObject, store.selector, animated)
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.popToViewController(_:animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, UIViewController, Bool) -> [UIViewController]?).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationController, UIViewController, Bool) -> [UIViewController]?).self
        ) { store in { selfObject, viewController, animated in
            if !selfObject.viewControllers.contains(viewController) || selfObject.viewControllers.count < 2 {
                return store.original(selfObject, store.selector, viewController, animated)
            }
            let disappearingController = selfObject.viewControllers.last
            if !selfObject.fw.shouldCustomTransition(from: disappearingController, to: viewController) {
                return store.original(selfObject, store.selector, viewController, animated)
            }

            disappearingController?.fw.addTransitionNavigationBarIfNeeded()
            if let navigationBar = viewController.fw.transitionNavigationBar {
                selfObject.navigationBar.fw.replaceStyle(navigationBar: navigationBar)
            }
            if animated {
                disappearingController?.navigationController?.fw.backgroundViewHidden = true
            }
            return store.original(selfObject, store.selector, viewController, animated)
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.popToRootViewController(animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, Bool) -> [UIViewController]?).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationController, Bool) -> [UIViewController]?).self
        ) { store in { selfObject, animated in
            if selfObject.viewControllers.count < 2 {
                return store.original(selfObject, store.selector, animated)
            }
            let disappearingController = selfObject.viewControllers.last
            let rootViewController = selfObject.viewControllers.first
            if !selfObject.fw.shouldCustomTransition(from: disappearingController, to: rootViewController) {
                return store.original(selfObject, store.selector, animated)
            }

            disappearingController?.fw.addTransitionNavigationBarIfNeeded()
            if let navigationBar = rootViewController?.fw.transitionNavigationBar {
                selfObject.navigationBar.fw.replaceStyle(navigationBar: navigationBar)
            }
            if animated {
                disappearingController?.navigationController?.fw.backgroundViewHidden = true
            }
            return store.original(selfObject, store.selector, animated)
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationController.setViewControllers(_:animated:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, [UIViewController], Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationController, [UIViewController], Bool) -> Void).self
        ) { store in { selfObject, viewControllers, animated in
            let disappearingController = selfObject.viewControllers.last
            let appearingController = viewControllers.last
            if !selfObject.fw.shouldCustomTransition(from: disappearingController, to: appearingController) {
                store.original(selfObject, store.selector, viewControllers, animated)
                return
            }

            if animated, let disappearingController, !disappearingController.isEqual(viewControllers.last) {
                disappearingController.fw.addTransitionNavigationBarIfNeeded()
                if disappearingController.fw.transitionNavigationBar != nil {
                    disappearingController.navigationController?.fw.backgroundViewHidden = true
                }
            }
            store.original(selfObject, store.selector, viewControllers, animated)
        }}
    }
}
