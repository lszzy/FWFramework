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
    
    @objc static func testObjcCallbackBridge(_ context: WebViewJSBridge.Context) {
        print("TestJavascriptBridge.testObjcCallback called: \(context.parameters)")
        context.completion?("Response from TestJavascriptBridge.testObjcCallback")
    }
    
}

class TestBridgeController: WebController {
    
    override func setupWebView() {
        super.setupWebView()
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
        let y = APP.screenHeight - APP.toolBarHeight - 45
        
        let callbackButton = UIButton(type: .roundedRect)
        callbackButton.setTitle("Call", for: .normal)
        callbackButton.addTarget(self, action: #selector(callHandler(_:)), for: .touchUpInside)
        view.insertSubview(callbackButton, aboveSubview: webView)
        callbackButton.frame = CGRect(x: 10, y: y, width: 60, height: 35)
        callbackButton.titleLabel?.font = font
        
        let errorButton = UIButton(type: .roundedRect)
        errorButton.setTitle("Error", for: .normal)
        errorButton.addTarget(self, action: #selector(errorHandler(_:)), for: .touchUpInside)
        view.insertSubview(errorButton, aboveSubview: webView)
        errorButton.frame = CGRect(x: 70, y: y, width: 60, height: 35)
        errorButton.titleLabel?.font = font
        
        let filterButton = UIButton(type: .roundedRect)
        filterButton.setTitle("Filter", for: .normal)
        filterButton.addTarget(self, action: #selector(filterHandler(_:)), for: .touchUpInside)
        view.insertSubview(filterButton, aboveSubview: webView)
        filterButton.frame = CGRect(x: 130, y: y, width: 60, height: 35)
        filterButton.titleLabel?.font = font
        
        let reloadButton = UIButton(type: .roundedRect)
        reloadButton.setTitle("Reload", for: .normal)
        reloadButton.addTarget(webView, action: #selector(WKWebView.reload), for: .touchUpInside)
        view.insertSubview(reloadButton, aboveSubview: webView)
        reloadButton.frame = CGRect(x: 190, y: y, width: 60, height: 35)
        reloadButton.titleLabel?.font = font
        
        let jumpButton = UIButton(type: .roundedRect)
        jumpButton.setTitle("Jump", for: .normal)
        jumpButton.app.addTouch { [weak self] _ in
            self?.webRequest = "http://kvm.wuyong.site/jssdk.html"
        }
        view.insertSubview(jumpButton, aboveSubview: webView)
        jumpButton.frame = CGRect(x: 250, y: y, width: 60, height: 35)
        jumpButton.titleLabel?.font = font
    }
    
    override func setupLayout() {
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
