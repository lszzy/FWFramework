//
//  ViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// 视图控制器挂钩协议，可覆写
@objc public protocol ViewControllerProtocol {
    
    /// 初始化完成方法，init自动调用，默认未实现
    @objc optional func didInitialize()

    /// 初始化导航栏方法，viewDidLoad自动调用，默认未实现
    @objc optional func setupNavbar()

    /// 初始化子视图方法，viewDidLoad自动调用，默认未实现
    @objc optional func setupSubviews()

    /// 初始化布局方法，viewDidLoad自动调用，默认未实现
    @objc optional func setupLayout()
    
}

/// 视图控制器拦截器
public class ViewControllerIntercepter: NSObject {
    
    public var initIntercepter: Selector?
    public var viewDidLoadIntercepter: Selector?
    public var viewWillAppearIntercepter: Selector?
    public var viewDidLayoutSubviewsIntercepter: Selector?
    public var viewDidAppearIntercepter: Selector?
    public var viewWillDisappearIntercepter: Selector?
    public var viewDidDisappearIntercepter: Selector?
    
}

/// 视图控制器管理器
///
/// 框架默认未注册ViewControllerProtocol协议拦截器，如需全局配置控制器，使用全局自定义block即可
public class ViewControllerManager: NSObject {
    
    /// 单例模式
    public static let shared = ViewControllerManager()
    
    /// 默认全局控制器init钩子句柄，init优先自动调用
    public var hookInit: ((UIViewController) -> Void)?
    /// 默认全局控制器viewDidLoad钩子句柄，viewDidLoad优先自动调用
    public var hookViewDidLoad: ((UIViewController) -> Void)?
    /// 默认全局控制器viewWillAppear钩子句柄，viewWillAppear优先自动调用
    public var hookViewWillAppear: ((UIViewController, Bool) -> Void)?
    /// 默认全局控制器viewDidLayoutSubviews钩子句柄，viewDidLayoutSubviews优先自动调用
    public var hookViewDidLayoutSubviews: ((UIViewController) -> Void)?
    /// 默认全局控制器viewDidAppear钩子句柄，viewDidAppear优先自动调用
    public var hookViewDidAppear: ((UIViewController, Bool) -> Void)?
    /// 默认全局控制器viewWillDisappear钩子句柄，viewWillDisappear优先自动调用
    public var hookViewWillDisappear: ((UIViewController, Bool) -> Void)?
    /// 默认全局控制器viewDidDisappear钩子句柄，viewDidDisappear优先自动调用
    public var hookViewDidDisappear: ((UIViewController, Bool) -> Void)?
    
    /// 默认全局scrollViewController钩子句柄，viewDidLoad自动调用，先于setupScrollView
    public var hookScrollViewController: ((UIViewController & ScrollViewControllerProtocol) -> Void)?
    /// 默认全局tableViewController钩子句柄，viewDidLoad自动调用，先于setupTableView
    public var hookTableViewController: ((UIViewController & TableViewControllerProtocol) -> Void)?
    /// 默认全局collectionViewController钩子句柄，viewDidLoad自动调用，先于setupCollectionView
    public var hookCollectionViewController: ((UIViewController & CollectionViewControllerProtocol) -> Void)?
    /// 默认全局webViewController钩子句柄，viewDidLoad自动调用，先于setupWebView
    public var hookWebViewController: ((UIViewController & WebViewControllerProtocol) -> Void)?
    
    private var intercepters: [String: ViewControllerIntercepter] = [:]
    
    private var classProtocols: [String: String] = [:]

    /// 注册协议拦截器，提供拦截和调用方法
    /// - Parameters:
    ///   - type: 控制器协议类型，如ScrollViewControllerProtocol.self
    ///   - intercepter: 控制器拦截器对象，传nil时取消注册
    public func registerProtocol<T>(_ type: T.Type, intercepter: ViewControllerIntercepter?) {
        let intercepterId = String.fw_safeString(type)
        intercepters[intercepterId] = intercepter
    }
    
    private func protocols(with: AnyClass) -> [String] {
        return []
    }
    
}

// MARK: - ViewControllerAutoloader
internal class ViewControllerAutoloader: AutoloadProtocol {
    
    static func autoload() {
        
    }
    
}
