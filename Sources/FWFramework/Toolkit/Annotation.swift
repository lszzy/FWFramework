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

// MARK: - StoredValue
/// UserDefault存储属性包装器注解，默认为手工指定或初始值
///
/// 使用示例：
/// @StoredValue("userName")
/// static var userName: String = ""
@propertyWrapper
public struct StoredValue<T> {
    private let key: String
    private let defaultValue: T
    
    public init(
        wrappedValue: T,
        _ key: String,
        defaultValue: T? = nil
    ) {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
    }
    
    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ key: String,
        defaultValue: T? = nil
    ) where WrappedValue? == T {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
    }
    
    public var wrappedValue: T {
        get {
            let value = UserDefaults.standard.object(forKey: key) as? T
            return !Optional<Any>.isNil(value) ? (value ?? defaultValue) : defaultValue
        }
        set {
            if !Optional<Any>.isNil(newValue) {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.synchronize()
        }
    }
}

// MARK: - CachedValue
/// 缓存属性包装器注解，默认为手工指定或初始值
///
/// 使用示例：
/// @CachedValue("cacheKey")
/// static var cacheValue: String = ""
@propertyWrapper
public struct CachedValue<T> {
    private let key: String
    private let defaultValue: T
    private let type: CacheType
    
    public init(
        wrappedValue: T,
        _ key: String,
        defaultValue: T? = nil,
        type: CacheType = .default
    ) {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
        self.type = type
    }
    
    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ key: String,
        defaultValue: T? = nil,
        type: CacheType = .default
    ) where WrappedValue? == T {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
        self.type = type
    }
    
    public var wrappedValue: T {
        get {
            let value = CacheManager.manager(type: type)?.object(forKey: key) as? T
            return !Optional<Any>.isNil(value) ? (value ?? defaultValue) : defaultValue
        }
        set {
            if !Optional<Any>.isNil(newValue) {
                CacheManager.manager(type: type)?.setObject(newValue, forKey: key)
            } else {
                CacheManager.manager(type: type)?.removeObject(forKey: key)
            }
        }
    }
}

// MARK: - ValidatedValue
/// ValidatedValue属性包装器注解，默认为手工指定或初始值
///
/// 使用示例：
/// @ValidatedValue(.isEmail)
/// var email: String = ""
@propertyWrapper
public struct ValidatedValue<T> {
    private let validator: Validator<T>
    private let defaultValue: T
    private var value: T
    private var isValid: Bool
    
    public init(
        wrappedValue: T,
        _ validator: Validator<T>,
        defaultValue: T? = nil
    ) {
        self.validator = validator
        self.defaultValue = defaultValue ?? wrappedValue
        self.value = wrappedValue
        self.isValid = validator.validate(wrappedValue)
    }
    
    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ validator: Validator<WrappedValue>,
        defaultValue: T? = nil
    ) where WrappedValue? == T {
        self.init(
            wrappedValue: wrappedValue,
            Validator(validator),
            defaultValue: defaultValue
        )
    }
    
    public var wrappedValue: T {
        get {
            isValid ? value : defaultValue
        }
        set {
            value = newValue
            isValid = validator.validate(newValue)
        }
    }
}

// MARK: - ModuleValue
/// 模块属性包装器注解
///
/// 使用示例：
/// @ModuleValue(UserModuleService.self)
/// static var userModule: UserModuleService
@propertyWrapper
public struct ModuleValue<T> {
    private let serviceProtocol: T.Type
    private var module: T?
    
    public init(
        _ serviceProtocol: T.Type,
        module: ModuleProtocol.Type? = nil
    ) {
        self.serviceProtocol = serviceProtocol
        if let module = module {
            Mediator.registerService(serviceProtocol, module: module)
        }
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

// MARK: - PluginValue
/// 插件属性包装器注解
///
/// 使用示例：
/// @PluginValue(TestPluginProtocol.self)
/// static var testPlugin: TestPluginProtocol
@propertyWrapper
public struct PluginValue<T> {
    private let pluginProtocol: T.Type
    private var plugin: T?
    
    public init(
        _ pluginProtocol: T.Type,
        object: Any? = nil
    ) {
        self.pluginProtocol = pluginProtocol
        if let object = object {
            PluginManager.registerPlugin(pluginProtocol, object: object)
        }
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

// MARK: - RouterValue
/// 路由属性包装器注解
///
/// 使用示例：
/// @RouterValue(AppRouter.pluginRouter(_:))
/// static var pluginUrl: String = "app://plugin/:id"
@propertyWrapper
public struct RouterValue {
    private var pattern: String
    private let parameters: Any?
    
    public init(
        wrappedValue value: String,
        parameters: Any? = nil,
        _ handler: Router.Handler? = nil
    ) {
        self.pattern = value
        self.parameters = parameters
        if let handler = handler {
            Router.registerURL(value, handler: handler)
        }
    }
    
    public init(
        _ pattern: String,
        parameters: Any? = nil,
        handler: Router.Handler? = nil
    ) {
        self.pattern = pattern
        self.parameters = parameters
        if let handler = handler {
            Router.registerURL(pattern, handler: handler)
        }
    }
    
    public var wrappedValue: String {
        get {
            if let parameters = parameters {
                return Router.generateURL(pattern, parameters: parameters)
            } else {
                return pattern
            }
        }
        set {
            pattern = newValue
        }
    }
}
