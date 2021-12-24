//
//  FWAnnotation.swift
//  FWFramework
//
//  Created by wuyong on 2020/12/1.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation
#if FWFrameworkSwift
import FWFramework
#endif

/// UserDefault属性包装器注解
/// 使用示例：
/// @FWUserDefaultAnnotation("userName", defaultValue: "test")
/// public static var userName: String
@propertyWrapper
public struct FWUserDefaultAnnotation<T> {
    let key: String
    let defaultValue: T
    
    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}

/// 模块属性包装器注解
/// 使用示例：
/// @FWModuleAnnotation(UserModuleService.self)
/// static var userModule: UserModuleService
@propertyWrapper
public struct FWModuleAnnotation<T> {
    let serviceProtocol: Protocol
    var module: T?
    
    public init(_ serviceProtocol: Protocol) {
        self.serviceProtocol = serviceProtocol
    }
    
    public init(_ serviceProtocol: Protocol, module: FWModuleProtocol.Type) {
        self.serviceProtocol = serviceProtocol
        FWMediator.registerService(serviceProtocol, withModule: module)
    }
    
    public var wrappedValue: T {
        get {
            if let value = module {
                return value
            } else {
                return FWMediator.loadModule(serviceProtocol) as! T
            }
        }
        set {
            module = newValue
        }
    }
}

/// 插件属性包装器注解
/// 使用示例：
/// @FWPluginAnnotation(TestPluginProtocol.self)
/// static var testPlugin: TestPluginProtocol
@propertyWrapper
public struct FWPluginAnnotation<T> {
    let pluginProtocol: Protocol
    var plugin: T?
    
    public init(_ pluginProtocol: Protocol) {
        self.pluginProtocol = pluginProtocol
    }
    
    public init(_ pluginProtocol: Protocol, object: Any) {
        self.pluginProtocol = pluginProtocol
        FWPluginManager.registerPlugin(pluginProtocol, with: object)
    }
    
    public var wrappedValue: T {
        get {
            if let value = plugin {
                return value
            } else {
                return FWPluginManager.loadPlugin(pluginProtocol) as! T
            }
        }
        set {
            plugin = newValue
        }
    }
}

/// 路由属性包装器注解
/// 使用示例：
/// @FWRouterAnnotation("app://plugin/:id")
/// static var pluginUrl: String
@propertyWrapper
public struct FWRouterAnnotation<T> {
    var url: Any
    
    public init(_ url: String) {
        self.url = url
    }
    
    public init(_ url: String, parameters: Any?) {
        self.url = FWRouter.generateURL(url, parameters: parameters)
    }
    
    public init(_ url: String, router: FWRouterProtocol.Type) {
        self.url = url
        FWRouter.registerClass(router)
    }
    
    public init(_ url: String, handler: @escaping FWRouterHandler) {
        self.url = url
        FWRouter.registerURL(url, withHandler: handler)
    }
    
    public var wrappedValue: T {
        get { return url as! T }
        set { url = newValue }
    }
}
