//
//  TestPluginViewController.swift
//  Example
//
//  Created by wuyong on 2020/12/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import UIKit

@objc protocol TestPluginProtocol {
    func pluginMethod()
}

@objc class TestPluginImpl: NSObject, TestPluginProtocol {
    func pluginMethod() {
        UIWindow.fwMain()?.fwShowMessage(withText: "TestPluginImpl")
    }
}

class TestPluginManager {
    @FWPluginAnnotation(TestPluginProtocol.self, object: TestPluginImpl.self)
    static var testPlugin: TestPluginProtocol
}

@objcMembers class TestPluginViewController: BaseViewController {
    override func renderView() {
        let button = UIButton(type: .system)
        button.setTitle("Plugin", for: .normal)
        button.fwAddTouch { (sender) in
            TestPluginManager.testPlugin.pluginMethod()
        }
        view.addSubview(button)
        button.fwLayoutChain.center().size(CGSize(width: 100, height: 50))
    }
}
