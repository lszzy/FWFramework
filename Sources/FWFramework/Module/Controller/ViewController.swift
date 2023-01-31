//
//  ViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - ViewControllerProtocol
/// 视图控制器挂钩协议，可覆写
@objc private protocol ViewControllerProtocol {
    
    /// 初始化完成方法，init自动调用，默认未实现
    @objc optional func didInitialize()

    /// 初始化导航栏方法，viewDidLoad自动调用，默认未实现
    @objc optional func setupNavbar()

    /// 初始化子视图方法，viewDidLoad自动调用，默认未实现
    @objc optional func setupSubviews()

    /// 初始化布局方法，viewDidLoad自动调用，默认未实现
    @objc optional func setupLayout()
    
}

// MARK: - ViewControllerIntercepter
/// 视图控制器拦截器
private class ViewControllerIntercepter: NSObject {
    
    public var initIntercepter: Selector?
    public var viewDidLoadIntercepter: Selector?
    public var viewWillAppearIntercepter: Selector?
    public var viewDidLayoutSubviewsIntercepter: Selector?
    public var viewDidAppearIntercepter: Selector?
    public var viewWillDisappearIntercepter: Selector?
    public var viewDidDisappearIntercepter: Selector?
    
}

// MARK: - ViewControllerManager
/// 视图控制器管理器
///
/// 框架默认未注册ViewControllerProtocol协议拦截器，如需全局配置控制器，使用全局自定义block即可
private class ViewControllerManager: NSObject {
    
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
    
    private static var classProtocols: [String: [String]] = [:]

    /// 注册协议拦截器，提供拦截和调用方法
    /// - Parameters:
    ///   - type: 控制器协议类型，如ScrollViewControllerProtocol.self
    ///   - intercepter: 控制器拦截器对象，传nil时取消注册
    public func registerProtocol<T>(_ type: T.Type, intercepter: ViewControllerIntercepter?) {
        let intercepterId = String.fw_safeString(type)
        intercepters[intercepterId] = intercepter
    }
    
    private static func protocols(with aClass: AnyClass) -> [String] {
        // 同一个类只解析一次
        let className = NSStringFromClass(aClass)
        if let protocolList = classProtocols[className] {
            return protocolList
        }
        
        // 解析协议列表，包含父协议。始终包含ViewControllerProtocol，且位于第一位
        var protocolNames: [String] = []
        protocolNames.append(NSStringFromProtocol(ViewControllerProtocol.self))
        var targetClass: AnyClass? = aClass
        while targetClass != nil {
            var protocolCount: UInt32 = 0
            let protocolList = class_copyProtocolList(targetClass, &protocolCount)
            for i in 0 ..< Int(protocolCount) {
                if let proto = protocolList?[i],
                   protocol_conformsToProtocol(proto, ViewControllerProtocol.self),
                   let protocolName = String(utf8String: protocol_getName(proto)),
                   !protocolNames.contains(protocolName) {
                    protocolNames.append(protocolName)
                }
            }
            
            targetClass = class_getSuperclass(targetClass)
            if targetClass == nil || targetClass == NSObject.classForCoder() {
                break
            }
        }
        
        // 写入协议缓存
        classProtocols[className] = protocolNames
        return protocolNames
    }
    
    fileprivate static func swizzleViewController() {
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.init(nibName:bundle:)),
            methodSignature: (@convention(c) (UIViewController, Selector, String?, Bundle?) -> UIViewController).self,
            swizzleSignature: (@convention(block) (UIViewController, String?, Bundle?) -> UIViewController).self
        ) { store in { selfObject, nibNameOrNil, nibBundleOrNil in
            let viewController = store.original(selfObject, store.selector, nibNameOrNil, nibBundleOrNil)
            if viewController.conforms(to: ViewControllerProtocol.self) {
                ViewControllerManager.shared.hookInit(viewController: viewController)
            }
            return viewController
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.init(coder:)),
            methodSignature: (@convention(c) (UIViewController, Selector, NSCoder) -> UIViewController?).self,
            swizzleSignature: (@convention(block) (UIViewController, NSCoder) -> UIViewController?).self
        ) { store in { selfObject, coder in
            let viewController = store.original(selfObject, store.selector, coder)
            if let viewController = viewController, viewController.conforms(to: ViewControllerProtocol.self) {
                ViewControllerManager.shared.hookInit(viewController: viewController)
            }
            return viewController
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidLoad),
            methodSignature: (@convention(c) (UIViewController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            if selfObject.conforms(to: ViewControllerProtocol.self) {
                ViewControllerManager.shared.hookViewDidLoad(viewController: selfObject)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            if selfObject.conforms(to: ViewControllerProtocol.self) {
                ViewControllerManager.shared.hookViewWillAppear(viewController: selfObject, animated: animated)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidLayoutSubviews),
            methodSignature: (@convention(c) (UIViewController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            if selfObject.conforms(to: ViewControllerProtocol.self) {
                ViewControllerManager.shared.hookViewDidLayoutSubviews(viewController: selfObject)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            if selfObject.conforms(to: ViewControllerProtocol.self) {
                ViewControllerManager.shared.hookViewDidAppear(viewController: selfObject, animated: animated)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillDisappear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            if selfObject.conforms(to: ViewControllerProtocol.self) {
                ViewControllerManager.shared.hookViewWillDisappear(viewController: selfObject, animated: animated)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidDisappear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            if selfObject.conforms(to: ViewControllerProtocol.self) {
                ViewControllerManager.shared.hookViewDidDisappear(viewController: selfObject, animated: animated)
            }
        }}
    }
    
    // MARK: - Hook
    private func hookInit(viewController: UIViewController) {
        
    }
    
    private func hookViewDidLoad(viewController: UIViewController) {
        
    }
    
    private func hookViewWillAppear(viewController: UIViewController, animated: Bool) {
        
    }
    
    private func hookViewDidLayoutSubviews(viewController: UIViewController) {
        
    }
    
    private func hookViewDidAppear(viewController: UIViewController, animated: Bool) {
        
    }
    
    private func hookViewWillDisappear(viewController: UIViewController, animated: Bool) {
        
    }
    
    private func hookViewDidDisappear(viewController: UIViewController, animated: Bool) {
        
    }
    
}

// MARK: - ViewControllerAutoloader
internal class ViewControllerAutoloader: AutoloadProtocol {
    
    static func autoload() {
        ViewControllerManager.swizzleViewController()
    }
    
}
