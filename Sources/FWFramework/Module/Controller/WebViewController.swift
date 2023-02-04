//
//  WebViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - WebViewControllerProtocol
/// 网页视图控制器协议，可覆写
///
/// WebViewControllerProtocol默认未开启WebView重用，如需开启，步骤如下：
/// 1. 需在使用前(如应用启动完成时)设置ViewControllerManager.webViewReuseIdentifier，不能为nil
/// 2. 配置WebView.reuseConfigurationBlock并调用preloadReusableView(with: WebView.self)预加载第一个WebView
/// 3. 默认webViewFinishLoad会自动预加载下一个WebView，如果重写了该方法，需自行处理预加载逻辑
/// 4. 其他初始化、回收等重用操作框架会自动处理，详见源码
///
/// 如遇到WebView内存过大引起的白屏问题时，可在webViewWebContentProcessDidTerminate方法中调用webView.reload()即可
public protocol WebViewControllerProtocol: ViewControllerProtocol, WebViewDelegate {
    
    /// 网页视图，默认显示滚动条，启用前进后退手势
    var webView: WebView { get }

    /// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
    var webRequest: Any? { get set }

    /// 渲染网页配置，setupWebView之前调用，默认空实现
    func setupWebConfiguration(_ configuration: WKWebViewConfiguration)

    /// 渲染网页视图，setupSubviews之前调用，默认空实现
    func setupWebView()

    /// 渲染网页视图布局，setupSubviews之前调用，默认铺满
    func setupWebLayout()

    /// 渲染网页桥接，jsBridgeEnabled启用后生效，setupSubviews之前调用，默认空实现
    func setupWebBridge(_ bridge: WebViewJsBridge)
    
}

extension WebViewControllerProtocol where Self: UIViewController {
    
    /// 网页视图，默认显示滚动条，启用前进后退手势
    public var webView: WebView {
        if let result = fw_property(forName: "webView") as? WebView {
            return result
        } else {
            var result: WebView
            if let reuseIdentifier = ViewControllerManager.shared.webViewReuseIdentifier {
                result = ReusableViewPool.shared.dequeueReusableView(with: WebView.self, viewHolder: self, reuseIdentifier: reuseIdentifier)
            } else {
                let configuration = WKWebView.fw_defaultConfiguration()
                setupWebConfiguration(configuration)
                result = WebView(frame: .zero, configuration: configuration)
            }
            fw_setProperty(result, forName: "webView")
            return result
        }
    }
    
    /// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
    public var webRequest: Any? {
        get {
            return fw_property(forName: "webRequest")
        }
        set {
            fw_setProperty(newValue, forName: "webRequest")
            
            if isViewLoaded {
                webView.webRequest = newValue
            }
        }
    }
    
    /// 渲染网页配置，setupWebView之前调用，默认空实现
    public func setupWebConfiguration(_ configuration: WKWebViewConfiguration) {}

    /// 渲染网页视图，setupSubviews之前调用，默认空实现
    public func setupWebView() {}
    
    /// 渲染网页视图布局，setupSubviews之前调用，默认铺满
    public func setupWebLayout() {
        webView.fw_pinEdges()
    }
    
    /// 渲染网页桥接，setupSubviews之前调用，默认空实现
    public func setupWebBridge(_ bridge: WebViewJsBridge) {}
    
    /// 网页加载完成，默认预加载一次重用WebView。如果重写了本方法，需自行处理预加载逻辑
    public func webViewFinishLoad() {
        if ViewControllerManager.shared.webViewReuseIdentifier != nil,
           !fw_propertyBool(forName: "fw_preloadReusableView") {
            fw_setPropertyBool(true, forName: "fw_preloadReusableView")
            webView.fw_preloadReusableView()
        }
    }
    
}

// MARK: - ViewControllerManager+WebViewControllerProtocol
internal extension ViewControllerManager {
    
    func webViewControllerViewDidLoad(_ viewController: UIViewController) {
        guard let viewController = viewController as? UIViewController & WebViewControllerProtocol else { return }
        
        let webView = viewController.webView
        webView.delegate = viewController
        viewController.view.addSubview(webView)
        
        webView.fw_observeProperty("title") { [weak viewController] _, _ in
            viewController?.navigationItem.title = viewController?.webView.title
        }
        viewController.fw_allowsPopGesture = { [weak viewController] in
            return !(viewController?.webView.canGoBack ?? false)
        }
        
        hookWebViewController?(viewController)
        
        viewController.setupWebView()
        viewController.setupWebLayout()
        webView.setNeedsLayout()
        webView.layoutIfNeeded()
        
        if webView.fw_jsBridgeEnabled, let bridge = webView.fw_setupJsBridge() {
            viewController.setupWebBridge(bridge)
        }
        
        if webView.fw_navigationItems != nil {
            webView.fw_setupNavigationItems(viewController)
        }
        
        webView.webRequest = viewController.webRequest
    }
    
    func webViewControllerDeinit(_ viewController: UIViewController) {
        guard webViewReuseIdentifier != nil,
              let viewController = viewController as? UIViewController & WebViewControllerProtocol else { return }
        
        ReusableViewPool.shared.recycleReusableView(viewController.webView)
    }
    
}
