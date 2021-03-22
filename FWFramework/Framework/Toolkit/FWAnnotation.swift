//
//  FWAnnotation.swift
//  FWFramework
//
//  Created by wuyong on 2020/12/1.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

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
    let plugin: Protocol
    
    public init(_ plugin: Protocol) {
        self.plugin = plugin
    }
    
    public init(_ plugin: Protocol, object: Any) {
        self.plugin = plugin
        FWPluginManager.registerPlugin(plugin, with: object)
    }
    
    public init(_ plugin: Protocol, block: @escaping () -> T) {
        self.plugin = plugin
        FWPluginManager.registerPlugin(plugin, withBlock: block)
    }
    
    public init(_ plugin: Protocol, factory: @escaping () -> T) {
        self.plugin = plugin
        FWPluginManager.registerPlugin(plugin, withFactory: factory)
    }
    
    public var wrappedValue: T {
        get {
            return FWPluginManager.loadPlugin(plugin) as! T
        }
        set {
            FWPluginManager.registerPlugin(plugin, with: newValue)
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
