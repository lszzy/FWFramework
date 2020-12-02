//
//  TestPluginViewController.swift
//  Example
//
//  Created by wuyong on 2020/12/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import UIKit

/// 路由属性包装器注解
/// 使用示例：
/// 加载插件：@FWPluginAnnotation(TestPluginProtocol.self)
/// 自动注册并加载插件：@FWPluginAnnotation(TestPluginProtocol.self, object: TestPluginImpl.self)
/// static var testPlugin: TestPluginProtocol
@propertyWrapper
public struct FWRouterAnnotation {
    let url: String
    var handler: FWRouterHandler?
    var objectHandler: FWRouterObjectHandler?
    
    public init(_ url: String) {
        self.url = url
    }
    
    public init(_ url: String, handler: FWRouterHandler) {
        self.url = url
    }
    
    public init(_ url: String, objectHandler: FWRouterObjectHandler) {
        self.url = url
    }
    
    public var wrappedValue: String {
        get {
            return url
        }
    }
}

@objc protocol TestPluginProtocol {
    func pluginMethod()
}

@objc class TestPluginImpl: NSObject, TestPluginProtocol {
    func pluginMethod() {
        UIWindow.fwMain()?.fwShowMessage(withText: "TestPluginImpl")
    }
}

class TestPluginManager {
    @FWPluginAnnotation(TestPluginProtocol.self)
    static var testPlugin: TestPluginProtocol
}

@objcMembers class TestPluginViewController: BaseViewController {
    var pluginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Plugin", for: .normal)
        return button
    }()
    
    override func renderView() {
        view.addSubview(pluginButton)
        pluginButton.fwLayoutChain.center().size(CGSize(width: 100, height: 50))
    }
    
    override func renderData() {
        TestPluginManager.testPlugin = TestPluginImpl()
        pluginButton.fwAddTouch { (sender) in
            TestPluginManager.testPlugin.pluginMethod()
        }
    }
}
