//
//  Annotation.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - UserDefaultAnnotation
/// UserDefault属性包装器注解
/// 使用示例：
/// @UserDefaultAnnotation("userName", defaultValue: "test")
/// public static var userName: String
@propertyWrapper
public struct UserDefaultAnnotation<T> {
    let key: String
    let value: T
    
    public init(wrappedValue value: T, _ key: String) {
        self.key = key
        self.value = value
    }
    
    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.value = defaultValue
    }
    
    public var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? value
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}

// MARK: - ModuleAnnotation
/// 模块属性包装器注解
/// 使用示例：
/// @ModuleAnnotation(UserModuleService.self)
/// static var userModule: UserModuleService
@propertyWrapper
public struct ModuleAnnotation<T> {
    let serviceProtocol: Protocol
    var module: T?
    
    public init(_ serviceProtocol: Protocol) {
        self.serviceProtocol = serviceProtocol
    }
    
    public init(_ serviceProtocol: Protocol, module: ModuleProtocol.Type) {
        self.serviceProtocol = serviceProtocol
        Mediator.registerService(serviceProtocol, withModule: module)
    }
    
    public var wrappedValue: T {
        get {
            if let value = module {
                return value
            } else {
                return Mediator.loadModule(serviceProtocol) as! T
            }
        }
        set {
            module = newValue
        }
    }
}

// MARK: - PluginAnnotation
/// 插件属性包装器注解
/// 使用示例：
/// @PluginAnnotation(TestPluginProtocol.self)
/// static var testPlugin: TestPluginProtocol
@propertyWrapper
public struct PluginAnnotation<T> {
    let pluginProtocol: Protocol
    var plugin: T?
    
    public init(_ pluginProtocol: Protocol) {
        self.pluginProtocol = pluginProtocol
    }
    
    public init(_ pluginProtocol: Protocol, object: Any) {
        self.pluginProtocol = pluginProtocol
        PluginManager.registerPlugin(pluginProtocol, with: object)
    }
    
    public var wrappedValue: T {
        get {
            if let value = plugin {
                return value
            } else {
                return PluginManager.loadPlugin(pluginProtocol) as! T
            }
        }
        set {
            plugin = newValue
        }
    }
}

// MARK: - RouterAnnotation
/// 路由属性包装器注解
/// 使用示例：
/// @RouterAnnotation(AppRouter.pluginRouter(_:))
/// static var pluginUrl: String = "app://plugin/:id"
@propertyWrapper
public struct RouterAnnotation {
    var pattern: String
    
    public init(wrappedValue value: String, _ handler: @escaping RouterHandler) {
        self.pattern = value
        Router.registerURL(value, withHandler: handler)
    }
    
    public init(_ pattern: String, handler: @escaping RouterHandler) {
        self.pattern = pattern
        Router.registerURL(pattern, withHandler: handler)
    }
    
    public var wrappedValue: String {
        get { return pattern }
        set { pattern = newValue }
    }
}
