//
//  FWLoader.swift
//  FWFramework
//
//  Created by wuyong on 2022/1/12.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 自动加载Swift类并调用autoload方法，参数为Class或String
@discardableResult
public func FWAutoload(_ clazz: Any) -> Bool {
    return FWLoader<NSObject, NSObject>.autoload(clazz)
}

/// Swift自动加载协议，配合FWAutoload方法使用
public protocol FWAutoloadProtocol {
    /// 自动加载协议方法
    static func autoload()
}

/// 兼容OC调用自动加载Swift类
@objc extension FWLoader {
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
