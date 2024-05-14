//
//  Navigator.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - UIWindow+Navigator
extension Wrapper where Base: UIWindow {
    // MARK: - Static
    /// 获取当前主window，可自定义
    public static var main: UIWindow? {
        get {
            var mainWindow = Navigator.staticWindow
            if mainWindow != nil { return mainWindow }
            
            mainWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            
            #if DEBUG
            // DEBUG模式时兼容FLEX、FWDebug等组件
            let flexClass: AnyClass? = NSClassFromString("FLEXWindow")
            let flexSelector = NSSelectorFromString("previousKeyWindow")
            if let flexClass = flexClass,
               let flexWindow = mainWindow,
               flexWindow.isKind(of: flexClass),
               flexWindow.responds(to: flexSelector) {
                mainWindow = flexWindow.perform(flexSelector)?.takeUnretainedValue() as? UIWindow
            }
            #endif
            
            return mainWindow
        }
        set {
            Navigator.staticWindow = newValue
        }
    }

    /// 获取当前主场景，可自定义
    public static var mainScene: UIWindowScene? {
        get {
            return Navigator.staticScene ?? main?.windowScene
        }
        set {
            Navigator.staticScene = newValue
        }
    }
    
    // MARK: - Public
    /// 获取最顶部的视图控制器
    public var topViewController: UIViewController? {
        guard let presentedController = topPresentedController else { return nil }
        return topViewController(presentedController)
    }
    
    private func topViewController(_ viewController: UIViewController) -> UIViewController {
        if let tabBarController = viewController as? UITabBarController,
           let topController = tabBarController.selectedViewController {
            return topViewController(topController)
        }
        
        if let navigationController = viewController as? UINavigationController,
           let topController = navigationController.topViewController {
            return topViewController(topController)
        }
        
        return viewController
    }

    /// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
    public var topNavigationController: UINavigationController? {
        return topViewController?.navigationController
    }

    /// 获取最顶部的显示控制器
    public var topPresentedController: UIViewController? {
        var presentedController = base.rootViewController
        while presentedController?.presentedViewController != nil {
            presentedController = presentedController?.presentedViewController
        }
        return presentedController
    }

    /// 使用最顶部的导航栏控制器打开控制器
    @discardableResult
    public func push(_ viewController: UIViewController, animated: Bool = true) -> Bool {
        if let navigationController = topNavigationController {
            navigationController.pushViewController(viewController, animated: animated)
            return true
        }
        return false
    }
    
    /// 使用最顶部的导航栏控制器打开控制器，同时pop指定数量控制器
    @discardableResult
    public func push(_ viewController: UIViewController, pop count: Int, animated: Bool = true) -> Bool {
        if let navigationController = topNavigationController {
            navigationController.fw.pushViewController(viewController, pop: count, animated: animated)
            return true
        }
        return false
    }

    /// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
    public func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        topPresentedController?.present(viewController, animated: animated, completion: completion)
    }

    /// 使用最顶部的视图控制器打开控制器，自动判断push|present
    public func open(_ viewController: UIViewController, animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) {
        topViewController?.fw.open(viewController, animated: animated, options: options, completion: completion)
    }

    /// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
    @discardableResult
    public func close(animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) -> Bool {
        return topViewController?.fw.close(animated: animated, options: options, completion: completion) ?? false
    }
}

// MARK: - UIViewController+Navigator
extension Wrapper where Base: UIViewController {
    // MARK: - Navigation
    /// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
    public func open(_ viewController: UIViewController, animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) {
        var targetController = viewController
        var isNavigation = targetController is UINavigationController
        if options.contains(.embedInNavigation), !isNavigation {
            targetController = UINavigationController(rootViewController: targetController)
            isNavigation = true
        }
        
        if options.contains(.styleFullScreen) {
            targetController.modalPresentationStyle = .fullScreen
        } else if options.contains(.stylePageSheet) {
            targetController.modalPresentationStyle = .pageSheet
        }
        
        var isPush = false
        if options.contains(.transitionPush) {
            isPush = true
        } else if options.contains(.transitionPresent) {
            isPush = false
        } else {
            isPush = base.navigationController != nil ? true : false
        }
        if isNavigation { isPush = false }
        
        if isPush {
            let popCount = popCount(for: options)
            base.navigationController?.fw.pushViewController(targetController, pop: popCount, animated: animated, completion: completion)
        } else {
            base.present(targetController, animated: animated, completion: completion)
        }
    }

    /// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
    @discardableResult
    public func close(animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) -> Bool {
        var isPop = false
        var isDismiss = false
        if options.contains(.transitionPop) {
            isPop = true
        } else if options.contains(.transitionDismiss) {
            isDismiss = true
        } else {
            if (base.navigationController?.viewControllers.count ?? 0) > 1 {
                isPop = true
            } else if base.presentingViewController != nil {
                isDismiss = true
            }
        }
        
        if isPop {
            let popCount = max(1, popCount(for: options))
            if base.navigationController?.fw.popViewControllers(popCount, animated: animated, completion: completion) != nil {
                return true
            }
        } else if isDismiss {
            base.dismiss(animated: animated, completion: completion)
            return true
        }
        return false
    }
    
    private func popCount(for options: NavigatorOptions) -> Int {
        var popCount: Int = 0
        // 优先级：7 > 6、5、3 > 4、2、1
        if options.contains(.popToRoot) {
            popCount = .max
        } else if options.contains(.popTop6) {
            popCount = 6
        } else if options.contains(.popTop5) {
            popCount = 5
        } else if options.contains(.popTop3) {
            popCount = 3
        } else if options.contains(.popTop4) {
            popCount = 4
        } else if options.contains(.popTop2) {
            popCount = 2
        } else if options.contains(.popTop) {
            popCount = 1
        }
        return popCount
    }
    
    // MARK: - Workflow
    /// 自定义工作流名称，支持二级("."分隔)；默认返回小写类名(去掉ViewController、Controller)
    public var workflowName: String {
        get {
            if let workflowName = property(forName: "workflowName") as? String {
                return workflowName
            }
            
            let className = NSStringFromClass(type(of: base))
                .components(separatedBy: ".").last ?? ""
            let workflowName = className
                .replacingOccurrences(of: "ViewController", with: "")
                .replacingOccurrences(of: "Controller", with: "")
                .lowercased()
            setPropertyCopy(workflowName, forName: "workflowName")
            return workflowName
        }
        set {
            setPropertyCopy(newValue, forName: "workflowName")
        }
    }
}

// MARK: - UINavigationController+Navigator
extension Wrapper where Base: UINavigationController {
    // MARK: - Navigation
    /// push新界面，完成时回调
    public func pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            base.pushViewController(viewController, animated: animated)
            CATransaction.commit()
        } else {
            base.pushViewController(viewController, animated: animated)
        }
    }

    /// pop当前界面，完成时回调
    @discardableResult
    public func popViewController(animated: Bool, completion: (() -> Void)? = nil) -> UIViewController? {
        var viewController: UIViewController?
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            viewController = base.popViewController(animated: animated)
            CATransaction.commit()
        } else {
            viewController = base.popViewController(animated: animated)
        }
        return viewController
    }

    /// pop到指定界面，完成时回调
    @discardableResult
    public func popToViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
        var viewControllers: [UIViewController]?
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            viewControllers = base.popToViewController(viewController, animated: animated)
            CATransaction.commit()
        } else {
            viewControllers = base.popToViewController(viewController, animated: animated)
        }
        return viewControllers
    }

    /// pop到根界面，完成时回调
    @discardableResult
    public func popToRootViewController(animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
        var viewControllers: [UIViewController]?
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            viewControllers = base.popToRootViewController(animated: animated)
            CATransaction.commit()
        } else {
            viewControllers = base.popToRootViewController(animated: animated)
        }
        return viewControllers
    }

    /// 设置界面数组，完成时回调
    public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool, completion: (() -> Void)? = nil) {
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            base.setViewControllers(viewControllers, animated: animated)
            CATransaction.commit()
        } else {
            base.setViewControllers(viewControllers, animated: animated)
        }
    }
    
    /// push新界面，同时pop指定数量界面，至少保留一个根控制器，完成时回调
    public func pushViewController(_ viewController: UIViewController, pop count: Int, animated: Bool, completion: (() -> Void)? = nil) {
        if count < 1 || base.viewControllers.count < 2 {
            pushViewController(viewController, animated: animated, completion: completion)
            return
        }
        
        let remainCount = base.viewControllers.count > count ? base.viewControllers.count - count : 1
        var viewControllers = Array(base.viewControllers.prefix(upTo: remainCount))
        viewControllers.append(viewController)
        setViewControllers(viewControllers, animated: animated, completion: completion)
    }

    /// pop指定数量界面，0不会pop，至少保留一个根控制器，完成时回调
    @discardableResult
    public func popViewControllers(_ count: Int, animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
        if count < 1 || base.viewControllers.count < 2 {
            completion?()
            return nil
        }
        
        let toIndex = max(base.viewControllers.count - count - 1, 0)
        return popToViewController(base.viewControllers[toIndex], animated: animated, completion: completion)
    }
    
    // MARK: - Workflow
    /// 当前最外层工作流名称，即topViewController的工作流名称
    public var topWorkflowName: String? {
        return base.topViewController?.fw.workflowName
    }
    
    /// push控制器，并清理最外层工作流（不属于工作流则不清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
    public func push(_ viewController: UIViewController, popTopWorkflowAnimated animated: Bool, completion: (() -> Void)? = nil) {
        var workflows: [String] = []
        if let workflow = topWorkflowName {
            workflows.append(workflow)
        }
        push(viewController, popWorkflows: workflows, animated: animated, completion: completion)
    }
    
    /// push控制器，并清理到指定工作流（不属于工作流则清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、9
    public func push(_ viewController: UIViewController, popToWorkflow: String, animated: Bool, completion: (() -> Void)? = nil) {
        push(viewController, popWorkflows: [popToWorkflow], isMatch: false, animated: animated, completion: completion)
    }

    /// push控制器，并清理非根控制器（只保留根控制器）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
    public func push(_ viewController: UIViewController, popToRootWorkflowAnimated animated: Bool, completion: (() -> Void)? = nil) {
        if base.viewControllers.count < 2 {
            pushViewController(viewController, animated: animated, completion: completion)
            return
        }
        
        var viewControllers: [UIViewController] = []
        if let firstController = base.viewControllers.first {
            viewControllers.append(firstController)
        }
        viewControllers.append(viewController)
        setViewControllers(viewControllers, animated: animated, completion: completion)
    }

    /// push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
    public func push(_ viewController: UIViewController, popWorkflows workflows: [String]?, animated: Bool = true, completion: (() -> Void)? = nil) {
        push(viewController, popWorkflows: workflows ?? [], isMatch: true, animated: animated, completion: completion)
    }
    
    private func push(_ viewController: UIViewController, popWorkflows workflows: [String], isMatch: Bool, animated: Bool, completion: (() -> Void)?) {
        if workflows.count < 1 {
            pushViewController(viewController, animated: animated, completion: completion)
            return
        }
        
        // 从外到内查找移除的控制器列表
        var popControllers: [UIViewController] = []
        for controller in base.viewControllers.reversed() {
            var isStop = isMatch
            let workflowName = controller.fw.workflowName
            if !workflowName.isEmpty {
                for workflow in workflows {
                    if workflowName.hasPrefix(workflow) {
                        isStop = !isMatch
                        break
                    }
                }
            }
            
            if !isStop {
                popControllers.append(controller)
            } else {
                break
            }
        }
        
        if popControllers.count < 1 {
            pushViewController(viewController, animated: animated, completion: completion)
        } else {
            var viewControllers = base.viewControllers
            viewControllers.removeAll { popControllers.contains($0) }
            viewControllers.append(viewController)
            setViewControllers(viewControllers, animated: animated, completion: completion)
        }
    }

    /// pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
    public func popTopWorkflow(animated: Bool = true, completion: (() -> Void)? = nil) {
        var workflows: [String] = []
        if let workflow = topWorkflowName {
            workflows.append(workflow)
        }
        popWorkflows(workflows, animated: animated, completion: completion)
    }
    
    /// pop方式清理到指定工作流，至少保留一个根控制器（不属于工作流则清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）
    public func popToWorkflow(_ workflow: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        popWorkflows([workflow], isMatch: false, animated: animated, completion: completion)
    }

    /// pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
    public func popWorkflows(_ workflows: [String]?, animated: Bool = true, completion: (() -> Void)? = nil) {
        popWorkflows(workflows ?? [], isMatch: true, animated: animated, completion: completion)
    }
    
    private func popWorkflows(_ workflows: [String], isMatch: Bool, animated: Bool, completion: (() -> Void)?) {
        if workflows.count < 1 {
            completion?()
            return
        }
        
        // 从外到内查找停止目标控制器
        var toController: UIViewController?
        for controller in base.viewControllers.reversed() {
            var isStop = isMatch
            let workflowName = controller.fw.workflowName
            if !workflowName.isEmpty {
                for workflow in workflows {
                    if workflowName.hasPrefix(workflow) {
                        isStop = !isMatch
                        break
                    }
                }
            }
            
            if isStop {
                toController = controller
                break
            }
        }
        
        if let toController = toController {
            popToViewController(toController, animated: animated, completion: completion)
        } else {
            // 至少保留一个根控制器
            popToRootViewController(animated: animated, completion: completion)
        }
    }
}

// MARK: - NavigatorOptions
/// 控制器导航选项定义
public struct NavigatorOptions: OptionSet {
    
    public let rawValue: Int
    
    /// 嵌入导航控制器并使用present转场方式
    public static let embedInNavigation = NavigatorOptions(rawValue: 1 << 0)
    
    /// 指定push转场方式，仅open生效，默认自动判断转场方式
    public static let transitionPush = NavigatorOptions(rawValue: 1 << 16)
    /// 指定present转场方式，仅open生效
    public static let transitionPresent = NavigatorOptions(rawValue: 2 << 16)
    /// 指定pop转场方式，仅close生效
    public static let transitionPop = NavigatorOptions(rawValue: 3 << 16)
    /// 指定dismiss转场方式，仅close生效
    public static let transitionDismiss = NavigatorOptions(rawValue: 4 << 16)
    
    /// 同时pop顶部控制器，仅push|pop生效，默认不pop控制器
    public static let popTop = NavigatorOptions(rawValue: 1 << 20)
    /// 同时pop顶部2个控制器，仅push|pop生效
    public static let popTop2 = NavigatorOptions(rawValue: 2 << 20)
    /// 同时pop顶部3个控制器，仅push|pop生效
    public static let popTop3 = NavigatorOptions(rawValue: 3 << 20)
    /// 同时pop顶部4个控制器，仅push|pop生效
    public static let popTop4 = NavigatorOptions(rawValue: 4 << 20)
    /// 同时pop顶部5个控制器，仅push|pop生效
    public static let popTop5 = NavigatorOptions(rawValue: 5 << 20)
    /// 同时pop顶部6个控制器，仅push|pop生效
    public static let popTop6 = NavigatorOptions(rawValue: 6 << 20)
    /// 同时pop到根控制器，仅push|pop生效
    public static let popToRoot = NavigatorOptions(rawValue: 7 << 20)
    
    /// 指定present样式为ullScreen，仅present生效，默认自动使用系统present样式
    public static let styleFullScreen = NavigatorOptions(rawValue: 1 << 24)
    /// 指定present样式为pageSheet，仅present生效
    public static let stylePageSheet = NavigatorOptions(rawValue: 2 << 24)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

// MARK: - Navigator
/// 导航管理器
public class Navigator: NSObject {
    
    fileprivate static var staticWindow: UIWindow?
    fileprivate static var staticScene: UIWindowScene?
    
    /// 获取最顶部的视图控制器
    public static var topViewController: UIViewController? {
        return UIWindow.fw.main?.fw.topViewController
    }

    /// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
    public static var topNavigationController: UINavigationController? {
        return UIWindow.fw.main?.fw.topNavigationController
    }

    /// 获取最顶部的显示控制器
    public static var topPresentedController: UIViewController? {
        return UIWindow.fw.main?.fw.topPresentedController
    }

    /// 使用最顶部的导航栏控制器打开控制器
    @discardableResult
    public static func push(_ viewController: UIViewController, animated: Bool = true) -> Bool {
        return UIWindow.fw.main?.fw.push(viewController, animated: animated) ?? false
    }
    
    /// 使用最顶部的导航栏控制器打开控制器，同时pop指定数量控制器
    @discardableResult
    public static func push(_ viewController: UIViewController, pop count: Int, animated: Bool = true) -> Bool {
        return UIWindow.fw.main?.fw.push(viewController, pop: count, animated: animated) ?? false
    }

    /// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
    public static func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        UIWindow.fw.main?.fw.present(viewController, animated: animated, completion: completion)
    }

    /// 使用最顶部的视图控制器打开控制器，自动判断push|present
    public static func open(_ viewController: UIViewController, animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) {
        UIWindow.fw.main?.fw.open(viewController, animated: animated, options: options, completion: completion)
    }

    /// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
    @discardableResult
    public static func close(animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) -> Bool {
        return UIWindow.fw.main?.fw.close(animated: animated, options: options, completion: completion) ?? false
    }
    
}
