//
//  Navigator.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+UIWindow
extension Wrapper where Base: UIWindow {
    // MARK: - Static
    /// 获取当前主window，可自定义
    public static var main: UIWindow? {
        get { Base.fw_mainWindow }
        set { Base.fw_mainWindow = newValue }
    }

    /// 获取当前主场景，可自定义
    public static var mainScene: UIWindowScene? {
        get { Base.fw_mainScene }
        set { Base.fw_mainScene = newValue }
    }
    
    // MARK: - Public
    /// 获取最顶部的视图控制器
    public var topViewController: UIViewController? {
        return base.fw_topViewController
    }

    /// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
    public var topNavigationController: UINavigationController? {
        return base.fw_topNavigationController
    }

    /// 获取最顶部的显示控制器
    public var topPresentedController: UIViewController? {
        return base.fw_topPresentedController
    }

    /// 使用最顶部的导航栏控制器打开控制器
    @discardableResult
    public func push(_ viewController: UIViewController, animated: Bool = true) -> Bool {
        return base.fw_push(viewController, animated: animated)
    }
    
    /// 使用最顶部的导航栏控制器打开控制器，同时pop指定数量控制器
    @discardableResult
    public func push(_ viewController: UIViewController, pop count: Int, animated: Bool = true) -> Bool {
        return base.fw_push(viewController, pop: count, animated: animated)
    }

    /// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
    public func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        base.fw_present(viewController, animated: animated, completion: completion)
    }

    /// 使用最顶部的视图控制器打开控制器，自动判断push|present
    public func open(_ viewController: UIViewController, animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) {
        base.fw_open(viewController, animated: animated, options: options, completion: completion)
    }

    /// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
    @discardableResult
    public func close(animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) -> Bool {
        return base.fw_close(animated: animated, options: options, completion: completion)
    }
}

// MARK: - Wrapper+UIViewController
extension Wrapper where Base: UIViewController {
    // MARK: - Navigation
    /// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
    public func open(_ viewController: UIViewController, animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) {
        base.fw_open(viewController, animated: animated, options: options, completion: completion)
    }

    /// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
    @discardableResult
    public func close(animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) -> Bool {
        return base.fw_close(animated: animated, options: options, completion: completion)
    }
    
    // MARK: - Workflow
    /// 自定义工作流名称，支持二级("."分隔)；默认返回小写类名(去掉ViewController、Controller)
    public var workflowName: String {
        get { base.fw_workflowName }
        set { base.fw_workflowName = newValue }
    }
}

// MARK: - Wrapper+UINavigationController
extension Wrapper where Base: UINavigationController {
    // MARK: - Navigation
    /// push新界面，完成时回调
    public func pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        base.fw_pushViewController(viewController, animated: animated, completion: completion)
    }

    /// pop当前界面，完成时回调
    @discardableResult
    public func popViewController(animated: Bool, completion: (() -> Void)? = nil) -> UIViewController? {
        return base.fw_popViewController(animated: animated, completion: completion)
    }

    /// pop到指定界面，完成时回调
    @discardableResult
    public func popToViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
        return base.fw_popToViewController(viewController, animated: animated, completion: completion)
    }

    /// pop到根界面，完成时回调
    @discardableResult
    public func popToRootViewController(animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
        return base.fw_popToRootViewController(animated: animated, completion: completion)
    }

    /// 设置界面数组，完成时回调
    public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool, completion: (() -> Void)? = nil) {
        base.fw_setViewControllers(viewControllers, animated: animated, completion: completion)
    }
    
    /// push新界面，同时pop指定数量界面，至少保留一个根控制器，完成时回调
    public func pushViewController(_ viewController: UIViewController, pop count: Int, animated: Bool, completion: (() -> Void)? = nil) {
        base.fw_pushViewController(viewController, pop: count, animated: animated, completion: completion)
    }

    /// pop指定数量界面，0不会pop，至少保留一个根控制器，完成时回调
    @discardableResult
    public func popViewControllers(_ count: Int, animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
        return base.fw_popViewControllers(count, animated: animated, completion: completion)
    }
    
    // MARK: - Workflow
    /// 当前最外层工作流名称，即topViewController的工作流名称
    public var topWorkflowName: String? {
        return base.fw_topWorkflowName
    }
    
    /// push控制器，并清理最外层工作流（不属于工作流则不清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
    public func push(_ viewController: UIViewController, popTopWorkflowAnimated animated: Bool, completion: (() -> Void)? = nil) {
        base.fw_push(viewController, popTopWorkflowAnimated: animated, completion: completion)
    }
    
    /// push控制器，并清理到指定工作流（不属于工作流则清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、9
    public func push(_ viewController: UIViewController, popToWorkflow: String, animated: Bool, completion: (() -> Void)? = nil) {
        base.fw_push(viewController, popToWorkflow: popToWorkflow, animated: animated, completion: completion)
    }

    /// push控制器，并清理非根控制器（只保留根控制器）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
    public func push(_ viewController: UIViewController, popToRootWorkflowAnimated animated: Bool, completion: (() -> Void)? = nil) {
        base.fw_push(viewController, popToRootWorkflowAnimated: animated, completion: completion)
    }

    /// push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
    public func push(_ viewController: UIViewController, popWorkflows workflows: [String]?, animated: Bool = true, completion: (() -> Void)? = nil) {
        base.fw_push(viewController, popWorkflows: workflows, animated: animated, completion: completion)
    }

    /// pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
    public func popTopWorkflow(animated: Bool = true, completion: (() -> Void)? = nil) {
        base.fw_popTopWorkflow(animated: animated, completion: completion)
    }
    
    /// pop方式清理到指定工作流，至少保留一个根控制器（不属于工作流则清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）
    public func popToWorkflow(_ workflow: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        base.fw_popToWorkflow(workflow, animated: animated, completion: completion)
    }

    /// pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
    public func popWorkflows(_ workflows: [String]?, animated: Bool = true, completion: (() -> Void)? = nil) {
        base.fw_popWorkflows(workflows, animated: animated, completion: completion)
    }
}

// MARK: - NavigatorOptions
/// 控制器导航选项定义
public struct NavigatorOptions: OptionSet, JSONModelEnum {
    
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
    
    /// 获取最顶部的视图控制器
    public static var topViewController: UIViewController? {
        return UIWindow.fw_mainWindow?.fw_topViewController
    }

    /// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
    public static var topNavigationController: UINavigationController? {
        return UIWindow.fw_mainWindow?.fw_topNavigationController
    }

    /// 获取最顶部的显示控制器
    public static var topPresentedController: UIViewController? {
        return UIWindow.fw_mainWindow?.fw_topPresentedController
    }

    /// 使用最顶部的导航栏控制器打开控制器
    @discardableResult
    public static func push(_ viewController: UIViewController, animated: Bool = true) -> Bool {
        return UIWindow.fw_mainWindow?.fw_push(viewController, animated: animated) ?? false
    }
    
    /// 使用最顶部的导航栏控制器打开控制器，同时pop指定数量控制器
    @discardableResult
    public static func push(_ viewController: UIViewController, pop count: Int, animated: Bool = true) -> Bool {
        return UIWindow.fw_mainWindow?.fw_push(viewController, pop: count, animated: animated) ?? false
    }

    /// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
    public static func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_present(viewController, animated: animated, completion: completion)
    }

    /// 使用最顶部的视图控制器打开控制器，自动判断push|present
    public static func open(_ viewController: UIViewController, animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_open(viewController, animated: animated, options: options, completion: completion)
    }

    /// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
    @discardableResult
    public static func close(animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) -> Bool {
        return UIWindow.fw_mainWindow?.fw_close(animated: animated, options: options, completion: completion) ?? false
    }
    
}

// MARK: - UIWindow+Navigation
@_spi(FW) extension UIWindow {
    
    // MARK: - Static
    /// 获取当前主window，可自定义
    public static var fw_mainWindow: UIWindow? {
        get {
            var mainWindow = UIWindow.fw_staticWindow
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
                mainWindow = flexWindow.fw_invokeMethod(flexSelector) as? UIWindow
            }
            #endif
            
            return mainWindow
        }
        set {
            UIWindow.fw_staticWindow = newValue
        }
    }
    
    /// 获取当前主场景，可自定义
    public static var fw_mainScene: UIWindowScene? {
        get {
            return fw_staticScene ?? fw_mainWindow?.windowScene
        }
        set {
            fw_staticScene = newValue
        }
    }
    
    private static var fw_staticWindow: UIWindow?
    private static var fw_staticScene: UIWindowScene?
    
    // MARK: - Public
    /// 获取最顶部的视图控制器
    public var fw_topViewController: UIViewController? {
        guard let presentedController = fw_topPresentedController else { return nil }
        return fw_topViewController(presentedController)
    }
    
    private func fw_topViewController(_ viewController: UIViewController) -> UIViewController {
        if let tabBarController = viewController as? UITabBarController,
           let topController = tabBarController.selectedViewController {
            return fw_topViewController(topController)
        }
        
        if let navigationController = viewController as? UINavigationController,
           let topController = navigationController.topViewController {
            return fw_topViewController(topController)
        }
        
        return viewController
    }

    /// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
    public var fw_topNavigationController: UINavigationController? {
        return fw_topViewController?.navigationController
    }

    /// 获取最顶部的显示控制器
    public var fw_topPresentedController: UIViewController? {
        var presentedController = self.rootViewController
        while presentedController?.presentedViewController != nil {
            presentedController = presentedController?.presentedViewController
        }
        return presentedController
    }

    /// 使用最顶部的导航栏控制器打开控制器
    @discardableResult
    public func fw_push(_ viewController: UIViewController, animated: Bool = true) -> Bool {
        if let navigationController = fw_topNavigationController {
            navigationController.pushViewController(viewController, animated: animated)
            return true
        }
        return false
    }
    
    /// 使用最顶部的导航栏控制器打开控制器，同时pop指定数量控制器
    @discardableResult
    public func fw_push(_ viewController: UIViewController, pop count: Int, animated: Bool = true) -> Bool {
        if let navigationController = fw_topNavigationController {
            navigationController.fw_pushViewController(viewController, pop: count, animated: animated)
            return true
        }
        return false
    }

    /// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
    public func fw_present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        fw_topPresentedController?.present(viewController, animated: animated, completion: completion)
    }

    /// 使用最顶部的视图控制器打开控制器，自动判断push|present
    public func fw_open(_ viewController: UIViewController, animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) {
        fw_topViewController?.fw_open(viewController, animated: animated, options: options, completion: completion)
    }

    /// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
    @discardableResult
    public func fw_close(animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) -> Bool {
        return fw_topViewController?.fw_close(animated: animated, options: options, completion: completion) ?? false
    }
    
}

// MARK: - UIViewController+Navigation
@_spi(FW) extension UIViewController {
    
    // MARK: - Navigation
    /// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
    public func fw_open(_ viewController: UIViewController, animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) {
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
            isPush = self.navigationController != nil ? true : false
        }
        if isNavigation { isPush = false }
        
        if isPush {
            let popCount = fw_popCount(for: options)
            self.navigationController?.fw_pushViewController(targetController, pop: popCount, animated: animated, completion: completion)
        } else {
            self.present(targetController, animated: animated, completion: completion)
        }
    }

    /// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
    @discardableResult
    public func fw_close(animated: Bool = true, options: NavigatorOptions = [], completion: (() -> Void)? = nil) -> Bool {
        var isPop = false
        var isDismiss = false
        if options.contains(.transitionPop) {
            isPop = true
        } else if options.contains(.transitionDismiss) {
            isDismiss = true
        } else {
            if (self.navigationController?.viewControllers.count ?? 0) > 1 {
                isPop = true
            } else if self.presentingViewController != nil {
                isDismiss = true
            }
        }
        
        if isPop {
            let popCount = max(1, fw_popCount(for: options))
            if self.navigationController?.fw_popViewControllers(popCount, animated: animated, completion: completion) != nil {
                return true
            }
        } else if isDismiss {
            self.dismiss(animated: animated, completion: completion)
            return true
        }
        return false
    }
    
    private func fw_popCount(for options: NavigatorOptions) -> Int {
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
    public var fw_workflowName: String {
        get {
            if let workflowName = fw_property(forName: "fw_workflowName") as? String {
                return workflowName
            }
            
            let className = NSStringFromClass(classForCoder)
                .components(separatedBy: ".").last ?? ""
            let workflowName = className
                .replacingOccurrences(of: "ViewController", with: "")
                .replacingOccurrences(of: "Controller", with: "")
                .lowercased()
            fw_setPropertyCopy(workflowName, forName: "fw_workflowName")
            return workflowName
        }
        set {
            fw_setPropertyCopy(newValue, forName: "fw_workflowName")
        }
    }
    
}

// MARK: - UINavigationController+Navigation
@_spi(FW) extension UINavigationController {
    
    // MARK: - Navigation
    /// push新界面，完成时回调
    public func fw_pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            self.pushViewController(viewController, animated: animated)
            CATransaction.commit()
        } else {
            self.pushViewController(viewController, animated: animated)
        }
    }

    /// pop当前界面，完成时回调
    @discardableResult
    public func fw_popViewController(animated: Bool, completion: (() -> Void)? = nil) -> UIViewController? {
        var viewController: UIViewController?
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            viewController = self.popViewController(animated: animated)
            CATransaction.commit()
        } else {
            viewController = self.popViewController(animated: animated)
        }
        return viewController
    }

    /// pop到指定界面，完成时回调
    @discardableResult
    public func fw_popToViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
        var viewControllers: [UIViewController]?
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            viewControllers = self.popToViewController(viewController, animated: animated)
            CATransaction.commit()
        } else {
            viewControllers = self.popToViewController(viewController, animated: animated)
        }
        return viewControllers
    }

    /// pop到根界面，完成时回调
    @discardableResult
    public func fw_popToRootViewController(animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
        var viewControllers: [UIViewController]?
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            viewControllers = self.popToRootViewController(animated: animated)
            CATransaction.commit()
        } else {
            viewControllers = self.popToRootViewController(animated: animated)
        }
        return viewControllers
    }

    /// 设置界面数组，完成时回调
    public func fw_setViewControllers(_ viewControllers: [UIViewController], animated: Bool, completion: (() -> Void)? = nil) {
        if completion != nil {
            CATransaction.setCompletionBlock(completion)
            CATransaction.begin()
            self.setViewControllers(viewControllers, animated: animated)
            CATransaction.commit()
        } else {
            self.setViewControllers(viewControllers, animated: animated)
        }
    }
    
    /// push新界面，同时pop指定数量界面，至少保留一个根控制器，完成时回调
    public func fw_pushViewController(_ viewController: UIViewController, pop count: Int, animated: Bool, completion: (() -> Void)? = nil) {
        if count < 1 || self.viewControllers.count < 2 {
            fw_pushViewController(viewController, animated: animated, completion: completion)
            return
        }
        
        let remainCount = self.viewControllers.count > count ? self.viewControllers.count - count : 1
        var viewControllers = Array(self.viewControllers.prefix(upTo: remainCount))
        viewControllers.append(viewController)
        fw_setViewControllers(viewControllers, animated: animated, completion: completion)
    }

    /// pop指定数量界面，0不会pop，至少保留一个根控制器，完成时回调
    @discardableResult
    public func fw_popViewControllers(_ count: Int, animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
        if count < 1 || self.viewControllers.count < 2 {
            completion?()
            return nil
        }
        
        let toIndex = max(self.viewControllers.count - count - 1, 0)
        return fw_popToViewController(self.viewControllers[toIndex], animated: animated, completion: completion)
    }
    
    // MARK: - Workflow
    /// 当前最外层工作流名称，即topViewController的工作流名称
    public var fw_topWorkflowName: String? {
        return self.topViewController?.fw_workflowName
    }
    
    /// push控制器，并清理最外层工作流（不属于工作流则不清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
    public func fw_push(_ viewController: UIViewController, popTopWorkflowAnimated animated: Bool, completion: (() -> Void)? = nil) {
        var workflows: [String] = []
        if let workflow = fw_topWorkflowName {
            workflows.append(workflow)
        }
        fw_push(viewController, popWorkflows: workflows, animated: animated, completion: completion)
    }
    
    /// push控制器，并清理到指定工作流（不属于工作流则清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、9
    public func fw_push(_ viewController: UIViewController, popToWorkflow: String, animated: Bool, completion: (() -> Void)? = nil) {
        fw_push(viewController, popWorkflows: [popToWorkflow], isMatch: false, animated: animated, completion: completion)
    }

    /// push控制器，并清理非根控制器（只保留根控制器）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
    public func fw_push(_ viewController: UIViewController, popToRootWorkflowAnimated animated: Bool, completion: (() -> Void)? = nil) {
        if self.viewControllers.count < 2 {
            fw_pushViewController(viewController, animated: animated, completion: completion)
            return
        }
        
        var viewControllers: [UIViewController] = []
        if let firstController = self.viewControllers.first {
            viewControllers.append(firstController)
        }
        viewControllers.append(viewController)
        fw_setViewControllers(viewControllers, animated: animated, completion: completion)
    }

    /// push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
    public func fw_push(_ viewController: UIViewController, popWorkflows workflows: [String]?, animated: Bool = true, completion: (() -> Void)? = nil) {
        fw_push(viewController, popWorkflows: workflows ?? [], isMatch: true, animated: animated, completion: completion)
    }
    
    private func fw_push(_ viewController: UIViewController, popWorkflows workflows: [String], isMatch: Bool, animated: Bool, completion: (() -> Void)?) {
        if workflows.count < 1 {
            fw_pushViewController(viewController, animated: animated, completion: completion)
            return
        }
        
        // 从外到内查找移除的控制器列表
        var popControllers: [UIViewController] = []
        for controller in self.viewControllers.reversed() {
            var isStop = isMatch
            let workflowName = controller.fw_workflowName
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
            fw_pushViewController(viewController, animated: animated, completion: completion)
        } else {
            var viewControllers = self.viewControllers
            viewControllers.removeAll { popControllers.contains($0) }
            viewControllers.append(viewController)
            fw_setViewControllers(viewControllers, animated: animated, completion: completion)
        }
    }

    /// pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
    public func fw_popTopWorkflow(animated: Bool = true, completion: (() -> Void)? = nil) {
        var workflows: [String] = []
        if let workflow = fw_topWorkflowName {
            workflows.append(workflow)
        }
        fw_popWorkflows(workflows, animated: animated, completion: completion)
    }
    
    /// pop方式清理到指定工作流，至少保留一个根控制器（不属于工作流则清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）
    public func fw_popToWorkflow(_ workflow: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        fw_popWorkflows([workflow], isMatch: false, animated: animated, completion: completion)
    }

    /// pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
    public func fw_popWorkflows(_ workflows: [String]?, animated: Bool = true, completion: (() -> Void)? = nil) {
        fw_popWorkflows(workflows ?? [], isMatch: true, animated: animated, completion: completion)
    }
    
    private func fw_popWorkflows(_ workflows: [String], isMatch: Bool, animated: Bool, completion: (() -> Void)?) {
        if workflows.count < 1 {
            completion?()
            return
        }
        
        // 从外到内查找停止目标控制器
        var toController: UIViewController?
        for controller in self.viewControllers.reversed() {
            var isStop = isMatch
            let workflowName = controller.fw_workflowName
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
            fw_popToViewController(toController, animated: animated, completion: completion)
        } else {
            // 至少保留一个根控制器
            fw_popToRootViewController(animated: animated, completion: completion)
        }
    }
    
}
