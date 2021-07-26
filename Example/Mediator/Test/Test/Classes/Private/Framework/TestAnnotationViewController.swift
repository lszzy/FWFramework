//
//  TestAnnotationViewController.swift
//  Example
//
//  Created by wuyong on 2020/12/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import UIKit

// MARK: - FWPluginAnnotation

@objc protocol TestPluginProtocol {
    func pluginMethod()
}

@objc class TestPluginImpl: NSObject, TestPluginProtocol {
    func pluginMethod() {
        UIWindow.fwMain?.fwShowMessage(withText: "TestPluginImpl")
    }
}

class TestPluginManager {
    @FWPluginAnnotation(TestPluginProtocol.self)
    static var testPlugin: TestPluginProtocol
}

// MARK: - FWRouterAnnotation

class TestRouter {
    @FWRouterAnnotation("app://plugin/:id", handler: { (object) in
        let pluginId = FWSafeString(object.urlParameters["id"])
        UIWindow.fwMain?.fwShowMessage(withText: "plugin - \(pluginId)")
        return nil
    })
    static var pluginUrl: String
}

// MARK: - TestAnnotationViewController

@objcMembers class TestAnnotationViewController: TestViewController {
    var pluginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("插件注解", for: .normal)
        return button
    }()
    
    var routerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("路由注解", for: .normal)
        return button
    }()
    
    var objectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("路由参数", for: .normal)
        return button
    }()
    
    override func renderView() {
        fwView.addSubview(pluginButton)
        fwView.addSubview(routerButton)
        fwView.addSubview(objectButton)
        pluginButton.fwLayoutChain.centerX().top(50).size(CGSize(width: 100, height: 50))
        routerButton.fwLayoutChain.centerX().top(150).size(CGSize(width: 100, height: 50))
        objectButton.fwLayoutChain.centerX().top(250).size(CGSize(width: 100, height: 50))
    }
    
    @FWRouterAnnotation(TestRouter.pluginUrl)
    var pluginUrl: String
    
    override func renderData() {
        TestPluginManager.testPlugin = TestPluginImpl()
        pluginButton.fwAddTouch { (sender) in
            TestPluginManager.testPlugin.pluginMethod()
        }
        
        routerButton.fwAddTouch { (sender) in
            FWRouter.openURL(FWRouter.generateURL(TestRouter.pluginUrl, parameters: 1))
        }
        
        objectButton.fwAddTouch { (sender) in
            self.pluginUrl = FWRouter.generateURL(TestRouter.pluginUrl, parameters: 2)
            FWRouter.openURL(self.pluginUrl)
        }
    }
}
