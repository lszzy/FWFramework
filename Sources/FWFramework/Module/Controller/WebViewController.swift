//
//  WebViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import WebKit

// MARK: - WebViewControllerProtocol
/// 网页视图控制器协议，可覆写
///
/// WebViewControllerProtocol默认未开启WebView重用，如需开启，方式如下：
/// 1. 只需配置WebView.reuseConfigurationBlock并设置ViewControllerManager.webViewReuseIdentifier不为nil即可
/// 2. 其他初始化、预加载、回收等重用操作框架会自动处理，详见源码
/// 3. 如果需要预缓存资源，配置WebView.reusePreloadUrlBlock后再设置webViewReuseIdentifier即可
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
    func setupWebBridge(_ bridge: WebViewJSBridge)
    
}

extension WebViewControllerProtocol where Self: UIViewController {
    
    /// 网页视图，默认显示滚动条，启用前进后退手势
    public var webView: WebView {
        if let result = fw.property(forName: "webView") as? WebView {
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
            fw.setProperty(result, forName: "webView")
            return result
        }
    }
    
    /// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
    public var webRequest: Any? {
        get {
            return fw.property(forName: "webRequest")
        }
        set {
            fw.setProperty(newValue, forName: "webRequest")
            
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
        webView.fw.pinEdges()
    }
    
    /// 渲染网页桥接，setupSubviews之前调用，默认空实现
    public func setupWebBridge(_ bridge: WebViewJSBridge) {}
    
}

// MARK: - ViewControllerManager+WebViewControllerProtocol
internal extension ViewControllerManager {
    
    func webViewControllerViewDidLoad(_ viewController: UIViewController) {
        guard let viewController = viewController as? UIViewController & WebViewControllerProtocol else { return }
        
        let webView = viewController.webView
        webView.delegate = viewController
        viewController.view.addSubview(webView)
        
        if webViewReuseIdentifier != nil {
            viewController.fw_observeLifecycleState(object: webView) { [weak self] _, state, webView in
                guard self?.webViewReuseIdentifier != nil,
                      state == .didDeinit,
                      let webView = webView as? WebView else { return }
                
                ReusableViewPool.shared.recycleReusableView(webView)
            }
        }
        
        webView.fw.observeProperty(\.title) { [weak viewController] _, _ in
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
    
}
