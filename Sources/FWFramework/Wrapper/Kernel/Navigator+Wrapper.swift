//
//  Navigator+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - UIWindow+Navigation
extension Wrapper where Base: UIWindow {
    
    // MARK: - Static
    /// 获取当前主window，可自定义
    public static var main: UIWindow? {
        get { Base.fw_mainWindow }
        set { Base.fw_mainWindow = newValue }
    }

    /// 获取当前主场景
    public static var mainScene: UIWindowScene? {
        return Base.fw_mainScene
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

// MARK: - UIViewController+Navigation
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

// MARK: - UINavigationController+Navigation
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
