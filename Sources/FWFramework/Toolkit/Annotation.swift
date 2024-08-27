//
//  Annotation.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - StoredValue
/// UserDefault存储属性包装器注解，兼容AnyArchivable协议，默认为手工指定或初始值
///
/// 使用示例：
/// @StoredValue("userName")
/// static var userName: String = ""
@propertyWrapper
public struct StoredValue<Value> {
    private let key: String
    private let defaultValue: Value

    public init(
        wrappedValue: Value,
        _ key: String,
        defaultValue: Value? = nil
    ) {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
    }

    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ key: String,
        defaultValue: Value? = nil
    ) where WrappedValue? == Value {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
    }

    public var wrappedValue: Value {
        get {
            let object = UserDefaults.standard.object(forKey: key)
            var value = object as? Value
            if let data = object as? Data, let coder = ArchiveCoder.unarchiveData(data) {
                value = coder.archivableObject as? Value
            }
            return !Any?.isNil(value) ? (value ?? defaultValue) : defaultValue
        }
        set {
            var value: Any? = newValue
            if ArchiveCoder.isArchivableObject(newValue) {
                value = Data.fw.archivedData(newValue)
            }
            if !Any?.isNil(value) {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.synchronize()
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
public class ValidatedValue<Value> {
    private let validator: Validator<Value>
    private let defaultValue: Value
    private var value: Value
    private var isValid: Bool

    public init(
        wrappedValue: Value,
        _ validator: Validator<Value>,
        defaultValue: Value? = nil
    ) {
        self.validator = validator
        self.defaultValue = defaultValue ?? wrappedValue
        self.value = wrappedValue
        self.isValid = validator.validate(wrappedValue)
    }

    public convenience init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ validator: Validator<WrappedValue>,
        defaultValue: Value? = nil
    ) where WrappedValue? == Value {
        self.init(
            wrappedValue: wrappedValue,
            Validator(validator),
            defaultValue: defaultValue
        )
    }

    public var wrappedValue: Value {
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
public struct ModuleValue<Value> {
    private let serviceProtocol: Value.Type
    private var module: Value?

    public init(
        _ serviceProtocol: Value.Type,
        module: ModuleProtocol.Type? = nil
    ) {
        self.serviceProtocol = serviceProtocol
        if let module {
            Mediator.registerService(serviceProtocol, module: module)
        }
    }

    public var wrappedValue: Value {
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
public struct PluginValue<Value> {
    private let pluginProtocol: Value.Type
    private var plugin: Value?

    public init(
        _ pluginProtocol: Value.Type,
        object: Any? = nil
    ) {
        self.pluginProtocol = pluginProtocol
        if let object {
            PluginManager.registerPlugin(pluginProtocol, object: object)
        }
    }

    public var wrappedValue: Value {
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
        if let handler {
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
        if let handler {
            Router.registerURL(pattern, handler: handler)
        }
    }

    public var wrappedValue: String {
        get {
            if let parameters {
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
