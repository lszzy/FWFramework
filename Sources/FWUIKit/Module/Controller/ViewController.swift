//
//  ViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - ViewControllerProtocol
/// 视图控制器挂钩协议，可覆写
///
/// 如果需要支持继承，建议基类在非extension中实现该协议的所有方法，从而忽略协议扩展的默认实现
@MainActor public protocol ViewControllerProtocol: ViewControllerLifecycleObservable {
    /// 初始化完成，init自动调用，默认空实现
    func didInitialize()

    /// 初始化导航栏，viewDidLoad自动调用，默认空实现
    func setupNavbar()

    /// 初始化子视图，viewDidLoad自动调用，默认空实现
    func setupSubviews()

    /// 初始化布局，viewDidLoad自动调用，默认空实现
    func setupLayout()
}

extension ViewControllerProtocol where Self: UIViewController {
    /// 初始化完成，init自动调用，默认空实现
    public func didInitialize() {}

    /// 初始化导航栏，viewDidLoad自动调用，默认空实现
    public func setupNavbar() {}

    /// 初始化子视图，viewDidLoad自动调用，默认空实现
    public func setupSubviews() {}

    /// 初始化布局，viewDidLoad自动调用，默认空实现
    public func setupLayout() {}
}

// MARK: - ViewControllerIntercepter
/// 视图控制器拦截器
public class ViewControllerIntercepter: NSObject {
    public var initIntercepter: (@MainActor @Sendable (UIViewController) -> Void)?
    public var viewDidLoadIntercepter: (@MainActor @Sendable (UIViewController) -> Void)?
    public var viewWillAppearIntercepter: (@MainActor @Sendable (UIViewController, Bool) -> Void)?
    public var viewIsAppearingIntercepter: (@MainActor @Sendable (UIViewController, Bool) -> Void)?
    public var viewDidLayoutSubviewsIntercepter: (@MainActor @Sendable (UIViewController) -> Void)?
    public var viewDidAppearIntercepter: (@MainActor @Sendable (UIViewController, Bool) -> Void)?
    public var viewWillDisappearIntercepter: (@MainActor @Sendable (UIViewController, Bool) -> Void)?
    public var viewDidDisappearIntercepter: (@MainActor @Sendable (UIViewController, Bool) -> Void)?

    fileprivate var intercepterValidator: (@MainActor @Sendable (UIViewController) -> Bool)?
}

// MARK: - ViewControllerManager
/// 视图控制器管理器
///
/// 框架默认未注册ViewControllerProtocol协议拦截器，如需全局配置控制器，使用全局自定义block即可
public class ViewControllerManager: NSObject, @unchecked Sendable {
    /// 单例模式
    public static let shared = ViewControllerManager()

    // MARK: - Global
    /// 默认全局控制器init钩子句柄，init优先自动调用
    public var hookInit: (@MainActor @Sendable (UIViewController) -> Void)?
    /// 默认全局控制器viewDidLoad钩子句柄，viewDidLoad优先自动调用
    public var hookViewDidLoad: (@MainActor @Sendable (UIViewController) -> Void)?
    /// 默认全局控制器viewWillAppear钩子句柄，viewWillAppear优先自动调用
    public var hookViewWillAppear: (@MainActor @Sendable (UIViewController, Bool) -> Void)?
    /// 默认全局控制器viewIsAppearing钩子句柄，viewIsAppearing优先自动调用
    public var hookViewIsAppearing: (@MainActor @Sendable (UIViewController, Bool) -> Void)?
    /// 默认全局控制器viewDidLayoutSubviews钩子句柄，viewDidLayoutSubviews优先自动调用
    public var hookViewDidLayoutSubviews: (@MainActor @Sendable (UIViewController) -> Void)?
    /// 默认全局控制器viewDidAppear钩子句柄，viewDidAppear优先自动调用
    public var hookViewDidAppear: (@MainActor @Sendable (UIViewController, Bool) -> Void)?
    /// 默认全局控制器viewWillDisappear钩子句柄，viewWillDisappear优先自动调用
    public var hookViewWillDisappear: (@MainActor @Sendable (UIViewController, Bool) -> Void)?
    /// 默认全局控制器viewDidDisappear钩子句柄，viewDidDisappear优先自动调用
    public var hookViewDidDisappear: (@MainActor @Sendable (UIViewController, Bool) -> Void)?

    // MARK: - ViewController
    /// 默认全局scrollViewController钩子句柄，viewDidLoad自动调用，先于setupScrollView
    public var hookScrollViewController: (@MainActor @Sendable (UIViewController & ScrollViewControllerProtocol) -> Void)?
    /// 默认全局tableViewController钩子句柄，viewDidLoad自动调用，先于setupTableView
    public var hookTableViewController: (@MainActor @Sendable (any UIViewController & TableDelegateControllerProtocol) -> Void)?
    /// 默认全局collectionViewController钩子句柄，viewDidLoad自动调用，先于setupCollectionView
    public var hookCollectionViewController: (@MainActor @Sendable (any UIViewController & CollectionDelegateControllerProtocol) -> Void)?
    /// 默认全局webViewController钩子句柄，viewDidLoad自动调用，先于setupWebView
    public var hookWebViewController: (@MainActor @Sendable (UIViewController & WebViewControllerProtocol) -> Void)?
    /// 默认全局popupViewController钩子句柄，viewDidLoad自动调用，先于setupPopupView
    public var hookPopupViewController: (@MainActor @Sendable (UIViewController & PopupViewControllerProtocol) -> Void)?

    /// WebView重用标志，设置后自动开启重用并预加载第一个WebView，默认nil未开启重用
    public var webViewReuseIdentifier: String? {
        didSet {
            if let reuseIdentifier = webViewReuseIdentifier {
                DispatchQueue.fw.mainAsync {
                    ReusableViewPool.shared.preloadReusableView(with: WebView.self, reuseIdentifier: reuseIdentifier)
                }
            }
        }
    }

    // MARK: - Intercepter
    private var intercepters: [String: ViewControllerIntercepter] = [:]

    private var classIntercepters: [String: [String]] = [:]

    /// 注册协议拦截器，提供拦截和调用方法
    /// - Parameters:
    ///   - type: 控制器协议类型，必须继承ViewControllerProtocol
    ///   - intercepter: 控制器拦截器对象，传nil时取消注册
    public func registerProtocol<T>(_ type: T.Type, intercepter: ViewControllerIntercepter?) {
        let intercepterId = String.fw.safeString(type)
        if let intercepter {
            intercepter.intercepterValidator = { $0 is T }
            intercepters[intercepterId] = intercepter
        } else {
            intercepters.removeValue(forKey: intercepterId)
        }
    }

    @MainActor private func intercepterNames(for viewController: UIViewController) -> [String] {
        // 同一个类只解析一次，优先加载类缓存
        let className = NSStringFromClass(type(of: viewController))
        if let intercepterNames = classIntercepters[className] {
            return intercepterNames
        }

        // 解析拦截器列表，ViewControllerProtocol始终位于第一位
        var intercepterNames: [String] = []
        intercepterNames.append(String.fw.safeString(ViewControllerProtocol.self))
        for (intercepterName, intercepter) in intercepters {
            if intercepter.intercepterValidator?(viewController) ?? false,
               !intercepterNames.contains(intercepterName) {
                intercepterNames.append(intercepterName)
            }
        }

        // 写入类拦截器缓存
        classIntercepters[className] = intercepterNames
        return intercepterNames
    }

    fileprivate static func registerDefaultIntercepters() {
        let scrollIntercepter = ViewControllerIntercepter()
        scrollIntercepter.viewDidLoadIntercepter = { viewController in
            ViewControllerManager.shared.scrollViewControllerViewDidLoad(viewController)
        }
        ViewControllerManager.shared.registerProtocol(ScrollViewControllerProtocol.self, intercepter: scrollIntercepter)

        let collectionIntercepter = ViewControllerIntercepter()
        collectionIntercepter.viewDidLoadIntercepter = { viewController in
            ViewControllerManager.shared.collectionViewControllerViewDidLoad(viewController)
        }
        ViewControllerManager.shared.registerProtocol((any CollectionDelegateControllerProtocol).self, intercepter: collectionIntercepter)

        let tableIntercepter = ViewControllerIntercepter()
        tableIntercepter.viewDidLoadIntercepter = { viewController in
            ViewControllerManager.shared.tableViewControllerViewDidLoad(viewController)
        }
        ViewControllerManager.shared.registerProtocol((any TableDelegateControllerProtocol).self, intercepter: tableIntercepter)

        let webIntercepter = ViewControllerIntercepter()
        webIntercepter.viewDidLoadIntercepter = { viewController in
            ViewControllerManager.shared.webViewControllerViewDidLoad(viewController)
        }
        ViewControllerManager.shared.registerProtocol(WebViewControllerProtocol.self, intercepter: webIntercepter)

        let popupIntercepter = ViewControllerIntercepter()
        popupIntercepter.initIntercepter = { viewController in
            ViewControllerManager.shared.popupViewControllerInit(viewController)
        }
        popupIntercepter.viewDidLoadIntercepter = { viewController in
            ViewControllerManager.shared.popupViewControllerViewDidLoad(viewController)
        }
        popupIntercepter.viewDidLayoutSubviewsIntercepter = { viewController in
            ViewControllerManager.shared.popupViewControllerViewDidLayoutSubviews(viewController)
        }
        ViewControllerManager.shared.registerProtocol(PopupViewControllerProtocol.self, intercepter: popupIntercepter)
    }

    // MARK: - Hook
    @MainActor fileprivate func hookInit(_ viewController: UIViewController) {
        /*
         // ViewControllerProtocol全局拦截器init方法示例：
         // 开启不透明bar(translucent为NO)情况下视图延伸到屏幕顶部，顶部推荐safeArea方式布局
         viewController.extendedLayoutIncludesOpaqueBars = true
         // 默认push时隐藏TabBar，TabBar初始化控制器时设置为NO
         viewController.hidesBottomBarWhenPushed = true
         // 视图默认all延伸到全部工具栏，可指定top|bottom不被工具栏遮挡
         viewController.edgesForExtendedLayout = .all
          */

        // 1. 默认init
        hookInit?(viewController)

        // 2. 拦截器init
        let intercepterNames = intercepterNames(for: viewController)
        for intercepterName in intercepterNames {
            if let intercepter = intercepters[intercepterName] {
                intercepter.initIntercepter?(viewController)
            }
        }

        if let viewController = viewController as? ViewControllerProtocol {
            // 3. 控制器didInitialize
            viewController.didInitialize()
        }
    }

    @MainActor fileprivate func hookViewDidLoad(_ viewController: UIViewController) {
        // 1. 默认viewDidLoad
        hookViewDidLoad?(viewController)

        // 2. 拦截器viewDidLoad
        let intercepterNames = intercepterNames(for: viewController)
        for intercepterName in intercepterNames {
            if let intercepter = intercepters[intercepterName] {
                intercepter.viewDidLoadIntercepter?(viewController)
            }
        }

        if let viewController = viewController as? ViewControllerProtocol {
            // 3. 控制器setupNavbar
            viewController.setupNavbar()
            // 4. 控制器setupSubviews
            viewController.setupSubviews()
            // 5. 控制器setupLayout
            viewController.setupLayout()
        }
    }

    @MainActor fileprivate func hookViewWillAppear(_ viewController: UIViewController, animated: Bool) {
        // 1. 默认viewWillAppear
        hookViewWillAppear?(viewController, animated)

        // 2. 拦截器viewWillAppear
        let intercepterNames = intercepterNames(for: viewController)
        for intercepterName in intercepterNames {
            if let intercepter = intercepters[intercepterName] {
                intercepter.viewWillAppearIntercepter?(viewController, animated)
            }
        }
    }

    @MainActor fileprivate func hookViewIsAppearing(_ viewController: UIViewController, animated: Bool) {
        // 1. 默认viewIsAppearing
        hookViewIsAppearing?(viewController, animated)

        // 2. 拦截器viewIsAppearing
        let intercepterNames = intercepterNames(for: viewController)
        for intercepterName in intercepterNames {
            if let intercepter = intercepters[intercepterName] {
                intercepter.viewIsAppearingIntercepter?(viewController, animated)
            }
        }
    }

    @MainActor fileprivate func hookViewDidLayoutSubviews(_ viewController: UIViewController) {
        // 1. 默认viewDidLayoutSubviews
        hookViewDidLayoutSubviews?(viewController)

        // 2. 拦截器viewDidLayoutSubviews
        let intercepterNames = intercepterNames(for: viewController)
        for intercepterName in intercepterNames {
            if let intercepter = intercepters[intercepterName] {
                intercepter.viewDidLayoutSubviewsIntercepter?(viewController)
            }
        }
    }

    @MainActor fileprivate func hookViewDidAppear(_ viewController: UIViewController, animated: Bool) {
        // 1. 默认viewDidAppear
        hookViewDidAppear?(viewController, animated)

        // 2. 拦截器viewDidAppear
        let intercepterNames = intercepterNames(for: viewController)
        for intercepterName in intercepterNames {
            if let intercepter = intercepters[intercepterName] {
                intercepter.viewDidAppearIntercepter?(viewController, animated)
            }
        }
    }

    @MainActor fileprivate func hookViewWillDisappear(_ viewController: UIViewController, animated: Bool) {
        // 1. 默认viewWillDisappear
        hookViewWillDisappear?(viewController, animated)

        // 2. 拦截器viewWillDisappear
        let intercepterNames = intercepterNames(for: viewController)
        for intercepterName in intercepterNames {
            if let intercepter = intercepters[intercepterName] {
                intercepter.viewWillDisappearIntercepter?(viewController, animated)
            }
        }
    }

    @MainActor fileprivate func hookViewDidDisappear(_ viewController: UIViewController, animated: Bool) {
        // 1. 默认viewDidDisappear
        hookViewDidDisappear?(viewController, animated)

        // 2. 拦截器viewDidDisappear
        let intercepterNames = intercepterNames(for: viewController)
        for intercepterName in intercepterNames {
            if let intercepter = intercepters[intercepterName] {
                intercepter.viewDidDisappearIntercepter?(viewController, animated)
            }
        }
    }
}

// MARK: - FrameworkAutoloader+ViewController
extension FrameworkAutoloader {
    @objc static func loadModule_ViewController() {
        swizzleViewController()
        ViewControllerManager.registerDefaultIntercepters()
    }

    private static func swizzleViewController() {
        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.init(nibName:bundle:)),
            methodSignature: (@convention(c) (UIViewController, Selector, String?, Bundle?) -> UIViewController).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, String?, Bundle?) -> UIViewController).self
        ) { store in { selfObject, nibNameOrNil, nibBundleOrNil in
            let viewController = store.original(selfObject, store.selector, nibNameOrNil, nibBundleOrNil)

            if viewController is ViewControllerProtocol {
                ViewControllerManager.shared.hookInit(viewController)
            }
            return viewController
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.init(coder:)),
            methodSignature: (@convention(c) (UIViewController, Selector, NSCoder) -> UIViewController?).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, NSCoder) -> UIViewController?).self
        ) { store in { selfObject, coder in
            guard let viewController = store.original(selfObject, store.selector, coder) else { return nil }

            if viewController is ViewControllerProtocol {
                ViewControllerManager.shared.hookInit(viewController)
            }
            return viewController
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidLoad),
            methodSignature: (@convention(c) (UIViewController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)

            if selfObject is ViewControllerProtocol {
                ViewControllerManager.shared.hookViewDidLoad(selfObject)
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerProtocol {
                ViewControllerManager.shared.hookViewWillAppear(selfObject, animated: animated)
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: NSSelectorFromString("viewIsAppearing:"),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerProtocol {
                ViewControllerManager.shared.hookViewIsAppearing(selfObject, animated: animated)
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidLayoutSubviews),
            methodSignature: (@convention(c) (UIViewController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)

            if selfObject is ViewControllerProtocol {
                ViewControllerManager.shared.hookViewDidLayoutSubviews(selfObject)
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerProtocol {
                ViewControllerManager.shared.hookViewDidAppear(selfObject, animated: animated)
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillDisappear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerProtocol {
                ViewControllerManager.shared.hookViewWillDisappear(selfObject, animated: animated)
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidDisappear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerProtocol {
                ViewControllerManager.shared.hookViewDidDisappear(selfObject, animated: animated)
            }
        }}
    }
}
