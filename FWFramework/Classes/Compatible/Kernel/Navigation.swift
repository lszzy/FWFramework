//
//  Navigation.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

// MARK: - UIWindow+Navigation
extension Wrapper where Base: UIWindow {
    
    // MARK: - Public
    /// 获取最顶部的视图控制器
    public var topViewController: UIViewController? {
        return base.__fw.topViewController
    }

    /// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
    public var topNavigationController: UINavigationController? {
        return base.__fw.topNavigationController
    }

    /// 获取最顶部的显示控制器
    public var topPresentedController: UIViewController? {
        return base.__fw.topPresentedController
    }

    /// 使用最顶部的导航栏控制器打开控制器
    @discardableResult
    public func push(_ viewController: UIViewController, animated: Bool = true) -> Bool {
        return base.__fw.pushViewController(viewController, animated: animated)
    }

    /// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
    public func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        base.__fw.presentViewController(viewController, animated: animated, completion: completion)
    }

    /// 使用最顶部的视图控制器打开控制器，自动判断push|present
    public func open(_ viewController: UIViewController, animated: Bool = true) {
        base.__fw.openViewController(viewController, animated: animated)
    }

    /// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
    @discardableResult
    public func close(animated: Bool = true) -> Bool {
        return base.__fw.closeViewController(animated: true)
    }
    
    // MARK: - Static
    /// 获取当前主window
    public static var main: UIWindow? {
        return Base.__fw.mainWindow
    }

    /// 获取当前主场景
    @available(iOS 13.0, *)
    public static var mainScene: UIWindowScene? {
        return Base.__fw.mainScene
    }
    
    /// 获取最顶部的视图控制器
    public static var topViewController: UIViewController? {
        return Base.__fw.topViewController
    }

    /// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
    public static var topNavigationController: UINavigationController? {
        return Base.__fw.topNavigationController
    }

    /// 获取最顶部的显示控制器
    public static var topPresentedController: UIViewController? {
        return Base.__fw.topPresentedController
    }

    /// 使用最顶部的导航栏控制器打开控制器
    @discardableResult
    public static func push(_ viewController: UIViewController, animated: Bool = true) -> Bool {
        return Base.__fw.push(viewController, animated: animated)
    }

    /// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
    public static func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        Base.__fw.present(viewController, animated: animated, completion: completion)
    }

    /// 使用最顶部的视图控制器打开控制器，自动判断push|present
    public static func open(_ viewController: UIViewController, animated: Bool = true) {
        Base.__fw.open(viewController, animated: animated)
    }

    /// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
    @discardableResult
    public static func close(animated: Bool = true) -> Bool {
        return Base.__fw.closeViewController(animated: true)
    }
    
}

// MARK: - UIViewController+Navigation
extension Wrapper where Base: UIViewController {
    
    /// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
    public func open(_ viewController: UIViewController, animated: Bool = true) {
        base.__fw.open(viewController, animated: animated)
    }

    /// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
    @discardableResult
    public func close(animated: Bool = true) -> Bool {
        return base.__fw.closeViewController(animated: true)
    }
    
    // MARK: - Workflow
    /// 自定义工作流名称，支持二级("."分隔)；默认返回小写类名(去掉ViewController、Controller)
    public var workflowName: String {
        get { return base.__fw.workflowName }
        set { base.__fw.workflowName = newValue }
    }
    
}

// MARK: - UINavigationController+Navigation
extension Wrapper where Base: UINavigationController {
    
    // MARK: - Workflow
    /// 当前最外层工作流名称，即topViewController的工作流名称
    public var topWorkflowName: String? {
        return base.__fw.topWorkflowName
    }
    
    /// push控制器，并清理最外层工作流（不属于工作流则不清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
    public func push(_ viewController: UIViewController, popTopWorkflowAnimated: Bool) {
        base.__fw.push(viewController, popTopWorkflowAnimated: popTopWorkflowAnimated)
    }

    /// push控制器，并清理非根控制器（只保留根控制器）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
    public func push(_ viewController: UIViewController, popToRootWorkflowAnimated: Bool) {
        base.__fw.push(viewController, popToRootWorkflowAnimated: popToRootWorkflowAnimated)
    }

    /// push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
    public func push(_ viewController: UIViewController, popWorkflows: [String]?, animated: Bool = true) {
        base.__fw.push(viewController, popWorkflows: popWorkflows, animated: animated)
    }

    /// pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理）
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
    public func popTopWorkflow(animated: Bool = true) {
        base.__fw.popTopWorkflow(animated: animated)
    }

    /// pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器
    ///
    /// 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
    public func popWorkflows(_ workflows: [String]?, animated: Bool = true) {
        base.__fw.popWorkflows(workflows, animated: animated)
    }
    
}