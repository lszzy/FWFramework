//
//  WebController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/11.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

@objc extension Autoloader {
    func loadWebView() {
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
        webView.allowsSchemeURL = true
        
        if navigationItem.leftBarButtonItem != nil {
            webView.fw.navigationItems = nil
        } else if let backImage = Icon.backImage, let closeImage = Icon.closeImage {
            webView.fw.navigationItems = [backImage, closeImage]
        } else {
            webView.fw.navigationItems = nil
        }
    }
    
    func setupWebLayout() {
        webView.fw.layoutChain
            .horizontal()
            .top(toSafeArea: .zero)
            .bottom(fw.bottomBarHeight)
    }
    
    func setupWebBridge(_ bridge: WebViewJsBridge) {}
    
    func setupSubviews() {}
    
    func setupLayout() {}
    
    static func toggleReuse(enabled: Bool) {
        if enabled {
            WebView.fw.reuseConfigurationBlock = { configuration, _ in
                configuration.allowsInlineMediaPlayback = true
            }
            ViewControllerManager.shared.webViewReuseIdentifier = "WebView"
        } else {
            ViewControllerManager.shared.webViewReuseIdentifier = nil
        }
    }
    
    // MARK: - WebViewDelegate
    func webViewFinishLoad() {
        if !webView.isFirstLoad { return }
        fw.hideLoading()
        
        fw.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue, target: self, action: #selector(shareRequestUrl))
        
        let loadTime = Benchmark.end("WebView")
        fw.showMessage(text: String(format: "%.3fms", loadTime * 1000))
    }
    
    func webViewFailLoad(_ error: Error) {
        if !webView.isFirstLoad { return }
        fw.hideLoading()
        
        fw.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue, target: self, action: #selector(loadRequestUrl))
        
        fw.showEmptyView(text: error.localizedDescription, detail: nil, image: nil, action: "点击重试") { [weak self] _ in
            self?.loadRequestUrl()
        }
    }
    
    func webViewShouldLoad(_ navigationAction: WKNavigationAction) -> Bool {
        if navigationAction.request.url?.scheme == "app" {
            Router.openURL(navigationAction.request.url?.absoluteString ?? "")
            return false
        }
        return true
    }
    
    // MARK: - Private
    func setupToolbar() {
        let backItem = UIBarButtonItem.fw.item(object: Icon.backImage) { [weak self] _ in
            guard let self = self else { return }
            if self.webView.canGoBack {
                self.webView.goBack()
            }
        }
        backItem.isEnabled = false
        webView.fw.observeProperty("canGoBack") { [weak self] _, _ in
            guard let self = self else { return }
            backItem.isEnabled = self.webView.canGoBack
            self.reloadToolbar(false)
        }
        
        let forwardItem = UIBarButtonItem.fw.item(object: Icon.backImage?.fw.image(rotateDegree: 180)) { [weak self] _ in
            guard let self = self else { return }
            if self.webView.canGoForward {
                self.webView.goForward()
            }
        }
        forwardItem.isEnabled = false
        webView.fw.observeProperty("canGoForward") { [weak self] _, _ in
            guard let self = self else { return }
            forwardItem.isEnabled = self.webView.canGoForward
            self.reloadToolbar(false)
        }
        
        webView.fw.observeProperty("isLoading") { [weak self] _, _ in
            self?.reloadToolbar(false)
        }
        
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceItem.width = 79
        toolbarItems = [flexibleItem, backItem, spaceItem, forwardItem, flexibleItem]
        
        navigationController?.toolbar.fw.shadowImage = UIImage.fw.image(color: AppTheme.borderColor, size: CGSize(width: self.view.bounds.width, height: 0.5))
        navigationController?.toolbar.fw.backgroundColor = AppTheme.barColor
        navigationController?.toolbar.fw.foregroundColor = AppTheme.textColor
    }
    
    func reloadToolbar(_ animated: Bool) {
        let hidden = !(webView.canGoBack || webView.canGoForward)
        if fw.toolBarHidden == hidden { return }
        
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
        fw.showSheet(title: nil, message: nil, actions: ["分享", "刷新", "重新加载", "清空堆栈", reuseEnabled ? "关闭重用" : "开启重用"]) { [weak self] index in
            if index == 0 {
                UIApplication.fw.openActivityItems([FW.safeURL(self?.requestUrl)])
            } else if index == 1 {
                self?.webView.reload()
            } else if index == 2 {
                self?.webView.load(URLRequest(url: FW.safeURL(self?.requestUrl)))
                self?.webView.fw.clearBackForwardList()
            } else if index == 3 {
                self?.webView.load(URLRequest(url: FW.safeURL(nil)))
                self?.webView.fw.clearBackForwardList()
            } else {
                UserDefaults.fw.setObject(!reuseEnabled, forKey: "WebReuseEnabled")
                WebController.toggleReuse(enabled: !reuseEnabled)
            }
        }
    }
    
    @objc func loadRequestUrl() {
        fw.hideEmptyView()
        if webView.isFirstLoad {
            fw.showLoading()
        }
        
        var urlRequest = URLRequest(url: FW.safeURL(requestUrl))
        urlRequest.timeoutInterval = 30
        urlRequest.setValue("test", forHTTPHeaderField: "Test-Token")
        webRequest = urlRequest
    }
    
}
