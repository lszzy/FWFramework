//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation

/// NSObject内部Swift桥接方法
@_spi(FW) extension NSObject {
    
    /// 记录内部分组调试日志
    @objc public static func __fw_logDebug(_ message: String) {
        Logger.log(.debug, message: message, group: "FWFramework", userInfo: nil)
    }
    
}

/// UIWindow内部Swift桥接方法
@_spi(FW) extension UIWindow {
    
    /// 内部打开路由，支持导航选项
    @objc public func __fw_open(_ viewController: UIViewController, context: RouterContext) {
        var options: NavigatorOptions = []
        if let navigatorOptions = context.userInfo?[RouterOptionsKey] as? NavigatorOptions {
            options = navigatorOptions
        } else if let optionsNumber = context.userInfo?[RouterOptionsKey] as? NSNumber {
            options = .init(rawValue: optionsNumber.intValue)
        }
        self.fw_open(viewController, animated: true, options: options, completion: nil)
    }
    
}
