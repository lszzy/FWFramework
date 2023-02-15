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

// MARK: - ModuleAnnotation
/// 模块属性包装器注解
///
/// 使用示例：
/// @ModuleAnnotation(UserModuleService.self)
/// static var userModule: UserModuleService
@propertyWrapper
public struct ModuleAnnotation<T> {
    private let serviceProtocol: T.Type
    private var module: T?
    
    public init(
        _ serviceProtocol: T.Type
    ) {
        self.serviceProtocol = serviceProtocol
    }
    
    public init(
        _ serviceProtocol: T.Type,
        module: ModuleProtocol.Type
    ) {
        self.serviceProtocol = serviceProtocol
        Mediator.registerService(serviceProtocol, module: module)
    }
    
    public var wrappedValue: T {
        get {
            if let value = module {
                return value
            } else {
                return Mediator.loadModule(serviceProtocol)!
            }
        }
        set {
            module = newValue
        }
    }
}

// MARK: - PluginAnnotation
/// 插件属性包装器注解
///
/// 使用示例：
/// @PluginAnnotation(TestPluginProtocol.self)
/// static var testPlugin: TestPluginProtocol
@propertyWrapper
public struct PluginAnnotation<T> {
    private let pluginProtocol: T.Type
    private var plugin: T?
    
    public init(
        _ pluginProtocol: T.Type
    ) {
        self.pluginProtocol = pluginProtocol
    }
    
    public init(
        _ pluginProtocol: T.Type,
        object: Any
    ) {
        self.pluginProtocol = pluginProtocol
        PluginManager.registerPlugin(pluginProtocol, object: object)
    }
    
    public var wrappedValue: T {
        get {
            if let value = plugin {
                return value
            } else {
                return PluginManager.loadPlugin(pluginProtocol)!
            }
        }
        set {
            plugin = newValue
        }
    }
}

// MARK: - RouterAnnotation
/// 路由属性包装器注解
///
/// 使用示例：
/// @RouterAnnotation(AppRouter.pluginRouter(_:))
/// static var pluginUrl: String = "app://plugin/:id"
@propertyWrapper
public struct RouterAnnotation {
    private var pattern: String
    
    public init(
        wrappedValue value: String,
        _ handler: @escaping RouterHandler
    ) {
        self.pattern = value
        Router.registerURL(value, handler: handler)
    }
    
    public init(
        _ pattern: String,
        handler: @escaping RouterHandler
    ) {
        self.pattern = pattern
        Router.registerURL(pattern, handler: handler)
    }
    
    public var wrappedValue: String {
        get { return pattern }
        set { pattern = newValue }
    }
}

// MARK: - ValidatorAnnotation
/// ValidatorAnnotation属性包装器注解，默认初始值
///
/// 使用示例：
/// @ValidatorAnnotation(.isEmail)
/// var email: String = ""
@propertyWrapper
public struct ValidatorAnnotation<T> {
    private let validator: Validator<T>
    private let initialValue: T
    private var value: T
    
    public init(
        wrappedValue: T,
        _ validator: Validator<T>
    ) {
        self.validator = validator
        self.initialValue = wrappedValue
        self.value = wrappedValue
    }
    
    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ validator: Validator<WrappedValue>,
        defaultValid: @autoclosure @escaping () -> Bool = false
    ) where WrappedValue? == T {
        self.init(
            wrappedValue: wrappedValue,
            Validator(validator, defaultValid: defaultValid())
        )
    }
    
    public var wrappedValue: T {
        get { return value }
        set { value = validator.validate(newValue) ? newValue : initialValue }
    }
}

// MARK: - UserDefaultAnnotation
/// UserDefault属性包装器注解，默认初始值
///
/// 使用示例：
/// @UserDefaultAnnotation("userName")
/// static var userName: String = ""
@propertyWrapper
public struct UserDefaultAnnotation<T> {
    private let key: String
    private let initialValue: T
    private let wrappedGetter: (String, T) -> T
    private let wrappedSetter: (String, T) -> Void
    
    public init(
        wrappedValue: T,
        _ key: String
    ) {
        self.key = key
        self.initialValue = wrappedValue
        self.wrappedGetter = { key, initialValue in
            UserDefaults.standard.object(forKey: key) as? T ?? initialValue
        }
        self.wrappedSetter = { key, value in
            UserDefaults.standard.set(value, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
    
    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ key: String
    ) where WrappedValue? == T {
        self.key = key
        self.initialValue = wrappedValue
        self.wrappedGetter = { key, initialValue in
            UserDefaults.standard.object(forKey: key) as? WrappedValue ?? initialValue
        }
        self.wrappedSetter = { key, value in
            if let value = value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    public var wrappedValue: T {
        get { wrappedGetter(key, initialValue) }
        set { wrappedSetter(key, newValue) }
    }
}
