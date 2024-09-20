//
//  TestBridgeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/5.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
import WebKit

class TestJavascriptBridge: NSObject {
    @MainActor @objc static func testObjcCallbackDefaultBridge(_ context: WebViewJSBridge.Context) {
        print("TestJavascriptBridge.testObjcCallback called: \(context.parameters)")
        context.completion?("Response from TestJavascriptBridge.testObjcCallback")
    }
}

class TestBridgeController: WebController {
    private lazy var actionView: UIView = {
        let result = UIView()
        return result
    }()
    
    override func setupWebView() {
        super.setupWebView()
        
        webView.app.safeObserveProperty(\.canGoBack) { [weak self] webView, _ in
            self?.actionView.isHidden = webView.canGoBack
        }
        webView.app.jsBridgeEnabled = true
    }

    override func setupWebBridge(_ bridge: WebViewJSBridge) {
        bridge.isLogEnabled = true

        bridge.setErrorHandler { context in
            UIWindow.app.showMessage(text: "handler \(context.handlerName) undefined: \(context.parameters)", style: .default) {
                context.completion?("Response from errorHandler")
            }
        }

        bridge.setFilterHandler { context in
            if context.handlerName == "testFilterCallback" {
                print("testFilterCallback called: \(context.parameters)")
                context.completion?("Response from testFilterCallback")
                return false
            }
            return true
        }

        bridge.registerHandler("testObjcCallback") { context in
            print("testObjcCallback called: \(context.parameters)")
            context.completion?("Response from testObjcCallback")
        }

        bridge.registerClass(TestJavascriptBridge.self)
        print("registeredHandlers: \(bridge.getRegisteredHandlers())")
        bridge.callHandler("testJavascriptHandler", data: ["foo": "before ready"])
    }

    override func setupSubviews() {
        let font = UIFont.systemFont(ofSize: 12)
        let callbackButton = UIButton(type: .roundedRect)
        callbackButton.setTitle("Call", for: .normal)
        callbackButton.addTarget(self, action: #selector(callHandler(_:)), for: .touchUpInside)
        callbackButton.titleLabel?.font = font
        actionView.addSubview(callbackButton)
        callbackButton.layoutChain.size(width: 60, height: 35).left(10).bottom(10)

        let errorButton = UIButton(type: .roundedRect)
        errorButton.setTitle("Error", for: .normal)
        errorButton.addTarget(self, action: #selector(errorHandler(_:)), for: .touchUpInside)
        errorButton.titleLabel?.font = font
        actionView.addSubview(errorButton)
        errorButton.layoutChain.left(70).size(toView: callbackButton).bottom(toView: callbackButton)

        let filterButton = UIButton(type: .roundedRect)
        filterButton.setTitle("Filter", for: .normal)
        filterButton.addTarget(self, action: #selector(filterHandler(_:)), for: .touchUpInside)
        filterButton.titleLabel?.font = font
        actionView.addSubview(filterButton)
        filterButton.layoutChain.left(130).size(toView: callbackButton).bottom(toView: callbackButton)

        let reloadButton = UIButton(type: .roundedRect)
        reloadButton.setTitle("Reload", for: .normal)
        reloadButton.addTarget(webView, action: #selector(WKWebView.reload), for: .touchUpInside)
        reloadButton.titleLabel?.font = font
        actionView.addSubview(reloadButton)
        reloadButton.layoutChain.left(190).size(toView: callbackButton).bottom(toView: callbackButton)

        let jumpButton = UIButton(type: .roundedRect)
        jumpButton.setTitle("Jump", for: .normal)
        jumpButton.app.addTouch { [weak self] _ in
            self?.webRequest = "http://kvm.wuyong.site/jssdk.html"
        }
        jumpButton.titleLabel?.font = font
        actionView.addSubview(jumpButton)
        jumpButton.layoutChain.left(250).size(toView: callbackButton).bottom(toView: callbackButton)
    }

    override func setupLayout() {
        view.addSubview(actionView)
        actionView.layoutChain.horizontal(toSafeArea: .zero).bottom(toSafeArea: .zero).height(45)
        
        requestUrl = ModuleBundle.resourceURL("Bridge.html")?.absoluteString
    }

    @objc func callHandler(_ sender: Any) {
        let data = ["greetingFromObjC": "Hi there, JS!"]
        webView.app.jsBridge?.callHandler("testJavascriptHandler", data: data, callback: { response in
            print("testJavascriptHandler responded: \(APP.safeString(response))")
        })
    }

    @objc func errorHandler(_ sender: Any) {
        let data = ["greetingFromObjC": "Hi there, Error!"]
        webView.app.jsBridge?.callHandler("notFoundHandler", data: data, callback: { response in
            print("notFoundHandler responded: \(APP.safeString(response))")
        })
    }

    @objc func filterHandler(_ sender: Any) {
        let data = ["greetingFromObjC": "Hi there, Filter!"]
        webView.app.jsBridge?.callHandler("testFilterHandler", data: data, callback: { response in
            print("testFilterHandler responded: \(APP.safeString(response))")
        })
    }
}
