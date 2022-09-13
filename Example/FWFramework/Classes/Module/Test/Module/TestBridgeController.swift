//
//  TestBridgeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/5.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

@objcMembers
class TestJavascriptBridge: NSObject {
    
    static func testObjcCallback(_ webView: WKWebView, data: Any, callback: @escaping JsBridgeResponseCallback) {
        print("TestJavascriptBridge.testObjcCallback called: \(data)")
        callback("Response from TestJavascriptBridge.testObjcCallback")
    }
    
}

class TestBridgeController: WebController {
    
    func setupWebBridge(_ bridge: WebViewJsBridge) {
        WebViewJsBridge.enableLogging()
        
        bridge.setErrorHandler { handlerName, data, responseCallback in
            UIWindow.fw.showMessage(text: "handler \(handlerName) undefined: \(data)", style: .default) {
                responseCallback("Response from errorHandler")
            }
        }
        
        bridge.setFilterHandler { handlerName, data, responseCallback in
            if handlerName == "testFilterCallback" {
                print("testFilterCallback called: \(data)")
                responseCallback("Response from testFilterCallback")
                return false
            }
            return true
        }
        
        bridge.registerHandler("testObjcCallback") { data, responseCallback in
            print("testObjcCallback called: \(data)")
            responseCallback("Response from testObjcCallback")
        }
        
        bridge.registerClass(TestJavascriptBridge.self, package: nil, context: nil, withMapper: nil)
        print("registeredHandlers: \(bridge.getRegisteredHandlers())")
        bridge.callHandler("testJavascriptHandler", data: ["foo": "before ready"])
    }
    
    @objc func callHandler(_ sender: Any) {
        let data = ["greetingFromObjC": "Hi there, JS!"]
        webView.fw.jsBridge?.callHandler("testJavascriptHandler", data: data, responseCallback: { response in
            print("testJavascriptHandler responded: \(response)")
        })
    }
    
    @objc func errorHandler(_ sender: Any) {
        let data = ["greetingFromObjC": "Hi there, Error!"]
        webView.fw.jsBridge?.callHandler("notFoundHandler", data: data, responseCallback: { response in
            print("notFoundHandler responded: \(response)")
        })
    }
    
    @objc func filterHandler(_ sender: Any) {
        let data = ["greetingFromObjC": "Hi there, Filter!"]
        webView.fw.jsBridge?.callHandler("testFilterHandler", data: data, responseCallback: { response in
            print("testFilterHandler responded: \(response)")
        })
    }
    
    func setupSubviews() {
        let font = UIFont.systemFont(ofSize: 12)
        let y = FW.screenHeight - UIScreen.fw.safeAreaInsets.bottom - 45
        
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
        jumpButton.fw.addTouch { [weak self] _ in
            self?.webRequest = "http://kvm.wuyong.site/jssdk.html"
        }
        view.insertSubview(jumpButton, aboveSubview: webView)
        jumpButton.frame = CGRect(x: 250, y: y, width: 60, height: 35)
        jumpButton.titleLabel?.font = font
    }
    
    func setupLayout() {
        requestUrl = ModuleBundle.resourceURL("Bridge.html")?.absoluteString
    }
    
}
