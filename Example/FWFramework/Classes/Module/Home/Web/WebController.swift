//
//  WebController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/11.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
import WebKit

@objc extension Autoloader {
    func loadApp_WebView() {
        var observer: Any?
        observer = NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: nil) { _ in
            let reuseEnabled = UserDefaults.standard.bool(forKey: "WebReuseEnabled")
            WebController.toggleReuse(enabled: reuseEnabled)
            
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

// 为了支持继承，WebViewControllerProtocol必须放到非extension中实现，且必须实现子类中需要继承的所有方法
class WebController: UIViewController, WebViewControllerProtocol {
    
    var requestUrl: String?
    
    private var toolbarHidden = true
    
    @StoredValue("allowsDownloadUrl")
    private var allowsDownloadUrl: Bool = false {
        didSet {
            if allowsDownloadUrl {
                webView.allowsDownloadUrl = { url in
                    return UIApplication.app.isSchemeURL(url, schemes: ["data", "blob"])
                }
            } else {
                webView.allowsDownloadUrl = nil
            }
        }
    }
    
    // MARK: - Lifecycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        Benchmark.begin("WebView")
    }
    
    convenience init(requestUrl: String? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.requestUrl = requestUrl
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupToolbar()
        loadRequestUrl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = toolbarHidden
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.toolbarHidden = self.navigationController?.isToolbarHidden ?? false
        navigationController?.isToolbarHidden = true
    }
    
    // MARK: - WebViewControllerProtocol
    func setupWebView() {
        view.backgroundColor = AppTheme.tableColor
        webView.allowsUniversalLinks = true
        webView.allowsArbitraryLoads = true
        webView.allowsRouterSchemes = ["app"]
        let allowsDownloadUrl = self.allowsDownloadUrl
        self.allowsDownloadUrl = allowsDownloadUrl
        
        if navigationItem.leftBarButtonItem != nil {
            webView.app.navigationItems = nil
        } else if let backImage = Icon.backImage, let closeImage = Icon.closeImage {
            webView.app.navigationItems = [backImage, closeImage]
        } else {
            webView.app.navigationItems = nil
        }
    }
    
    func setupWebLayout() {
        webView.app.layoutChain
            .horizontal()
            .top(toSafeArea: .zero)
            .bottom(app.bottomBarHeight)
    }
    
    func setupWebBridge(_ bridge: WebViewJSBridge) {}
    
    func setupSubviews() {}
    
    func setupLayout() {}
    
    static func toggleReuse(enabled: Bool) {
        if enabled {
            WebView.app.reuseConfigurationBlock = { configuration, _ in
                configuration.allowsInlineMediaPlayback = true
            }
            WebView.reusePreloadUrlBlock = { _ in
                return "http://www.wuyong.site/"
            }
            ViewControllerManager.shared.webViewReuseIdentifier = "WebView"
        } else {
            ViewControllerManager.shared.webViewReuseIdentifier = nil
        }
    }
    
    // MARK: - WebViewDelegate
    func webViewFinishLoad() {
        if !webView.isFirstLoad { return }
        app.hideLoading()
        
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue, target: self, action: #selector(shareRequestUrl))
        
        let loadTime = Benchmark.end("WebView")
        app.showMessage(text: String(format: "%.3fms", loadTime * 1000))
    }
    
    func webViewFailLoad(_ error: Error) {
        if !webView.isFirstLoad { return }
        app.hideLoading()
        
        app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue, target: self, action: #selector(loadRequestUrl))
        
        app.showEmptyView(text: RequestError.isConnectionError(error) ? "网络连接失败" : "服务器异常", detail: error.localizedDescription, image: nil, action: "点击重试") { [weak self] _ in
            self?.loadRequestUrl()
        }
    }
    
    // MARK: - Private
    func setupToolbar() {
        let backItem = UIBarButtonItem.app.item(object: Icon.backImage) { [weak self] _ in
            guard let self = self else { return }
            if self.webView.canGoBack {
                self.webView.goBack()
            }
        }
        backItem.isEnabled = false
        webView.app.observeProperty(\.canGoBack) { [weak self] _, _ in
            guard let self = self else { return }
            backItem.isEnabled = self.webView.canGoBack
            self.reloadToolbar(false)
        }
        
        let forwardItem = UIBarButtonItem.app.item(object: Icon.backImage?.app.image(rotateDegree: 180)) { [weak self] _ in
            guard let self = self else { return }
            if self.webView.canGoForward {
                self.webView.goForward()
            }
        }
        forwardItem.isEnabled = false
        webView.app.observeProperty(\.canGoForward) { [weak self] _, _ in
            guard let self = self else { return }
            forwardItem.isEnabled = self.webView.canGoForward
            self.reloadToolbar(false)
        }
        
        webView.app.observeProperty(\.isLoading) { [weak self] _, _ in
            self?.reloadToolbar(false)
        }
        
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceItem.width = 79
        toolbarItems = [flexibleItem, backItem, spaceItem, forwardItem, flexibleItem]
        
        navigationController?.toolbar.app.shadowImage = UIImage.app.image(color: AppTheme.borderColor, size: CGSize(width: self.view.bounds.width, height: 0.5))
        navigationController?.toolbar.app.backgroundColor = AppTheme.barColor
        navigationController?.toolbar.app.foregroundColor = AppTheme.textColor
    }
    
    func reloadToolbar(_ animated: Bool) {
        let hidden = !(webView.canGoBack || webView.canGoForward)
        if app.toolBarHidden == hidden { return }
        
        if animated {
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                if self?.webView.superview != nil {
                    self?.setupWebLayout()
                }
            }
            navigationController?.setToolbarHidden(hidden, animated: animated)
            CATransaction.commit()
        } else {
            navigationController?.setToolbarHidden(hidden, animated: animated)
            if webView.superview != nil {
                setupWebLayout()
            }
        }
    }
    
    @objc func shareRequestUrl() {
        let reuseEnabled = UserDefaults.standard.bool(forKey: "WebReuseEnabled")
        app.showSheet(title: nil, message: nil, actions: ["分享", "刷新", "重新加载", "清空堆栈", reuseEnabled ? "关闭重用" : "开启重用", allowsDownloadUrl ? "关闭下载" : "开启下载"]) { [weak self] index in
            if index == 0 {
                UIApplication.app.openActivityItems([APP.safeURL(self?.requestUrl)])
            } else if index == 1 {
                self?.webView.reload()
            } else if index == 2 {
                let urlRequest = self?.createUrlRequest(self?.requestUrl)
                self?.webView.load(urlRequest!)
                self?.webView.app.clearBackForwardList()
            } else if index == 3 {
                let urlRequest = self?.createUrlRequest(nil)
                self?.webView.load(urlRequest!)
                self?.webView.app.clearBackForwardList()
            } else if index == 4 {
                WebView.app.processPool = WKProcessPool()
                UserDefaults.app.setObject(!reuseEnabled, forKey: "WebReuseEnabled")
                WebController.toggleReuse(enabled: !reuseEnabled)
            } else {
                self?.allowsDownloadUrl = !(self?.allowsDownloadUrl ?? false)
            }
        }
    }
    
    @objc func loadRequestUrl() {
        app.hideEmptyView()
        if webView.isFirstLoad {
            app.showLoading()
        }
        
        webRequest = createUrlRequest(requestUrl)
    }
    
    private func createUrlRequest(_ url: String?) -> URLRequest {
        var urlRequest = URLRequest(url: APP.safeURL(url))
        urlRequest.timeoutInterval = 30
        urlRequest.setValue("testToken-\(Date.app.currentTime)", forHTTPHeaderField: "Test-Token")
        return urlRequest
    }
    
}
