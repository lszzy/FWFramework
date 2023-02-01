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
public protocol WebViewControllerProtocol: ViewControllerProtocol, WebViewDelegate {
    
    /// 网页视图，默认显示滚动条，启用前进后退手势
    var webView: WebView { get }

    /// 左侧按钮组，依次为返回|关闭，支持UIBarButtonItem|UIImage|NSString|NSNumber等。可覆写，默认nil
    var webItems: [Any]? { get set }

    /// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
    var webRequest: Any? { get set }

    /// 渲染网页配置，setupWebView之前调用，默认返回nil
    func setupWebConfiguration() -> WKWebViewConfiguration?

    /// 渲染网页视图，setupSubviews之前调用，默认空实现
    func setupWebView()

    /// 渲染网页视图布局，setupSubviews之前调用，默认铺满
    func setupWebLayout()
    
    /// 是否启用网页桥接，启用后自动调用setupWebBridge，默认false
    var webBridgeEnabled: Bool { get set }

    /// 渲染网页桥接，setupSubviews之前调用，默认空实现
    func setupWebBridge(_ bridge: WebViewJsBridge)
    
}

extension WebViewControllerProtocol where Self: UIViewController {
    
    /// 网页视图，默认显示滚动条，启用前进后退手势
    public var webView: WebView {
        if let result = fw.property(forName: "webView") as? WebView {
            return result
        } else {
            var result: WebView
            if let configuration = setupWebConfiguration() {
                result = WebView(frame: .zero, configuration: configuration)
            } else {
                result = WebView(frame: .zero)
            }
            fw.setProperty(result, forName: "webView")
            return result
        }
    }
    
    /// 左侧按钮组，依次为返回|关闭，支持UIBarButtonItem|UIImage|NSString|NSNumber等。可覆写，默认nil
    public var webItems: [Any]? {
        get {
            return fw_property(forName: "webItems") as? [Any]
        }
        set {
            fw_setProperty(newValue, forName: "webItems")
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
    
    /// 渲染网页配置，setupWebView之前调用，默认返回nil
    public func setupWebConfiguration() -> WKWebViewConfiguration? {
        return nil
    }

    /// 渲染网页视图，setupSubviews之前调用，默认空实现
    public func setupWebView() {}
    
    /// 渲染网页视图布局，setupSubviews之前调用，默认铺满
    public func setupWebLayout() {
        webView.fw_pinEdges()
    }
    
    /// 是否启用网页桥接，启用后自动调用setupWebBridge，默认false
    public var webBridgeEnabled: Bool {
        get { fw_propertyBool(forName: "webBridgeEnabled") }
        set { fw_setPropertyBool(newValue, forName: "webBridgeEnabled") }
    }
    
    /// 渲染网页桥接，setupSubviews之前调用，默认空实现
    public func setupWebBridge(_ bridge: WebViewJsBridge) {}
    
}

// MARK: - ViewControllerManager+WebViewControllerProtocol
internal extension ViewControllerManager {
    
    func webViewControllerViewDidLoad(_ viewController: UIViewController) {
        guard let viewController = viewController as? UIViewController & WebViewControllerProtocol else { return }
        
        let webView = viewController.webView
        webView.delegate = viewController
        viewController.view.addSubview(webView)
        
        webView.fw_observeProperty("title") { _, _ in
            viewController.navigationItem.title = viewController.webView.title
        }
        viewController.fw_allowsPopGesture = {
            return !viewController.webView.canGoBack
        }
        
        hookWebViewController?(viewController)
        
        viewController.setupWebView()
        viewController.setupWebLayout()
        webView.setNeedsLayout()
        webView.layoutIfNeeded()
        
        if viewController.webBridgeEnabled {
            let delegate = webView.navigationDelegate
            let bridge = WebViewJsBridge(for: webView)
            bridge.setWebViewDelegate(delegate)
            webView.fw_jsBridge = bridge
            
            viewController.setupWebBridge(bridge)
        }
        
        guard let webItems = viewController.webItems,
              !webItems.isEmpty,
              let navigationController = viewController.navigationController else {
            webView.webRequest = viewController.webRequest
            return
        }
        
        var leftItems: [UIBarButtonItem] = []
        for (i, webItem) in webItems.enumerated() {
            if let webItem = webItem as? UIBarButtonItem {
                leftItems.append(webItem)
            } else {
                if i == 0 {
                    let leftItem = UIBarButtonItem.fw_item(object: webItem) { _ in
                        if viewController.webView.canGoBack {
                            viewController.webView.goBack()
                        } else {
                            if let navigationController = viewController.navigationController,
                               navigationController.popViewController(animated: true) != nil    {
                                return
                            }
                            if viewController.presentingViewController != nil {
                                viewController.dismiss(animated: true, completion: nil)
                                return
                            }
                            
                            if let firstItem = viewController.webView.backForwardList.backList.first {
                                viewController.webView.go(to: firstItem)
                            }
                        }
                    }
                    leftItems.append(leftItem)
                } else {
                    let leftItem = UIBarButtonItem.fw_item(object: webItem) { _ in
                        if let navigationController = viewController.navigationController,
                           navigationController.popViewController(animated: true) != nil    {
                            return
                        }
                        if viewController.presentingViewController != nil {
                            viewController.dismiss(animated: true, completion: nil)
                            return
                        }
                        
                        if let firstItem = viewController.webView.backForwardList.backList.first {
                            viewController.webView.go(to: firstItem)
                        }
                    }
                    leftItems.append(leftItem)
                }
            }
        }
        
        var showClose = true
        if navigationController.viewControllers.first == viewController,
           navigationController.presentingViewController?.presentedViewController != navigationController {
            showClose = false
        }
        viewController.navigationItem.leftBarButtonItems = showClose && leftItems.count > 0 ? [leftItems[0]]  : []
        viewController.webView.fw_observeProperty("canGoBack") { [weak viewController] webView, _ in
            guard let webView = webView as? WKWebView else { return }
            if webView.canGoBack {
                viewController?.navigationItem.leftBarButtonItems = leftItems
            } else {
                viewController?.navigationItem.leftBarButtonItems = showClose && leftItems.count > 0 ? [leftItems[0]]  : []
            }
        }
        
        webView.webRequest = viewController.webRequest
    }
    
}
