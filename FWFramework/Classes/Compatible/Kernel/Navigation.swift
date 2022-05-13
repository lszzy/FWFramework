//
//  Navigation.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit

extension Wrapper where Base: UIWindow {
    
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
    
}
