//
//  FWAutoloader.swift
//  FWFramework
//
//  Created by wuyong on 2022/1/12.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
#if FWMacroSPM
import FWFramework
#endif

extension FWWrapper {
    /// 自动加载Swift类并调用autoload方法，参数为Class或String
    @discardableResult
    public static func autoload(_ clazz: Any) -> Bool {
        return FWAutoloader.autoload(clazz)
    }
}

/// Swift自动加载协议，配合FWAutoload方法使用
public protocol FWAutoloadProtocol {
    /// 自动加载协议方法
    static func autoload()
}

/// 兼容OC调用自动加载Swift类
@objc extension FWAutoloader {
    /// 自动加载Swift类并调用autoload方法，参数为Class或String
    @discardableResult
    public static func autoload(_ clazz: Any) -> Bool {
        var autoloader = clazz as? FWAutoloadProtocol.Type
        if autoloader == nil, let name = clazz as? String {
            if let nameClass = NSClassFromString(name) {
                autoloader = nameClass as? FWAutoloadProtocol.Type
            } else if let module = Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String,
                      let nameClass = NSClassFromString("\(module).\(name)") {
                autoloader = nameClass as? FWAutoloadProtocol.Type
            }
        }
        
        if let autoloader = autoloader {
            autoloader.autoload()
            return true
        }
        return false
    }
}

/// Swift自动加载扩展，配合FWAutoload方法使用
@objc extension FWAutoloader: FWAutoloadProtocol {
    /// 内部自动加载列表
    private static var autoloadMethods: [String] = []
    
    /// 自动加载load开头objc扩展方法
    ///
    /// 本方案采用objc扩展方法实现，相对于全局扫描类方案性能高(1/200)，使用简单。
    /// 使用方法：新增FWAutoloader扩展objc方法，以load开头即会自动调用，建议load+类名+扩展名
    public static func autoload() {
        // 获取FWAutoloader自动加载方法列表
        autoloadMethods = NSObject.fw
            .classMethods(FWAutoloader.self, superclass: false)
            .filter({ methodName in
                return methodName.hasPrefix("load") && !methodName.contains(":")
            })
            .sorted()
        
        // 调用FWAutoloader所有自动加载方法
        if autoloadMethods.count > 0 {
            let autoloader = FWAutoloader()
            for methodName in autoloadMethods {
                autoloader.perform(NSSelectorFromString(methodName))
            }
        }
        
        // 调用FWAutoloader自动加载引导方法
        bootstrap()
    }
    
    /// 自动加载引导方法
    private static func bootstrap() {
        autoload("FWFramework.FWAuthorizeAppleMusic")
        autoload("FWFramework.FWAuthorizeCalendar")
        autoload("FWFramework.FWAuthorizeContacts")
        autoload("FWFramework.FWAuthorizeMicrophone")
        autoload("FWFramework.FWAuthorizeTracking")
    }
    
    /// 插件调试描述
    public override class func debugDescription() -> String {
        var debugDescription = ""
        var debugCount = 0
        for methodName in autoloadMethods {
            debugCount += 1
            debugDescription.append(String(format: "%@. %@\n", NSNumber(value: debugCount), methodName))
        }
        return String(format: "\n========== AUTOLOADER ==========\n%@========== AUTOLOADER ==========", debugDescription)
    }
}
