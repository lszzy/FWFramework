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
/// UserDefault属性包装器注解，支持默认值
///
/// 使用示例：
/// @UserDefaultAnnotation("userName", defaultValue: "test")
/// static var userName: String
@propertyWrapper
public struct UserDefaultAnnotation<Value> {
    private let key: String
    private let defaultValue: Value
    
    public init(
        wrappedValue: Value,
        _ key: String,
        defaultValue: @autoclosure @escaping () -> Value? = nil
    ) {
        self.key = key
        self.defaultValue = defaultValue() ?? wrappedValue
    }
    
    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ key: String,
        defaultValue: @autoclosure @escaping () -> Value? = nil
    ) where WrappedValue? == Value {
        self.key = key
        self.defaultValue = defaultValue() ?? wrappedValue
    }
    
    public var wrappedValue: Value {
        get {
            return UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}

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
/// ValidatorAnnotation属性包装器注解，可指定默认值，未指定时为初始值
///
/// 使用示例：
/// @ValidatorAnnotation(.isEmail)
/// var email: String = ""
@propertyWrapper
public struct ValidatorAnnotation<Value> {
    private let validator: Validator<Value>
    private let defaultValue: Value
    private var value: Value
    
    public init(
        wrappedValue: Value,
        _ validator: Validator<Value>,
        defaultValue: @autoclosure @escaping () -> Value? = nil
    ) {
        self.validator = validator
        self.defaultValue = defaultValue() ?? wrappedValue
        self.value = wrappedValue
    }
    
    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ validator: Validator<WrappedValue>,
        defaultValue: @autoclosure @escaping () -> Value? = nil,
        defaultValid: @autoclosure @escaping () -> Bool = false
    ) where WrappedValue? == Value {
        self.init(
            wrappedValue: wrappedValue,
            Validator(validator, defaultValid: defaultValid()),
            defaultValue: defaultValue() ?? wrappedValue
        )
    }
    
    public var wrappedValue: Value {
        get {
            return self.value
        }
        set {
            if self.validator.validate(newValue) {
                self.value = newValue
            } else {
                self.value = self.defaultValue
            }
        }
    }
}
