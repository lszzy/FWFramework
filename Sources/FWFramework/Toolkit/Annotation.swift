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
/// static var userName: String
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
    let serviceProtocol: T.Type
    var module: T?
    
    public init(_ serviceProtocol: T.Type) {
        self.serviceProtocol = serviceProtocol
    }
    
    public init(_ serviceProtocol: T.Type, module: ModuleProtocol.Type) {
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
/// 使用示例：
/// @PluginAnnotation(TestPluginProtocol.self)
/// static var testPlugin: TestPluginProtocol
@propertyWrapper
public struct PluginAnnotation<T> {
    let pluginProtocol: T.Type
    var plugin: T?
    
    public init(_ pluginProtocol: T.Type) {
        self.pluginProtocol = pluginProtocol
    }
    
    public init(_ pluginProtocol: T.Type, object: Any) {
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
/// 使用示例：
/// @RouterAnnotation(AppRouter.pluginRouter(_:))
/// static var pluginUrl: String = "app://plugin/:id"
@propertyWrapper
public struct RouterAnnotation {
    var pattern: String
    
    public init(wrappedValue value: String, _ handler: @escaping RouterHandler) {
        self.pattern = value
        Router.registerURL(value, handler: handler)
    }
    
    public init(_ pattern: String, handler: @escaping RouterHandler) {
        self.pattern = pattern
        Router.registerURL(pattern, handler: handler)
    }
    
    public var wrappedValue: String {
        get { return pattern }
        set { pattern = newValue }
    }
}

// MARK: - ValidatorAnnotation
/// ValidatorAnnotation属性包装器注解
/// 使用示例：
/// @ValidatorAnnotation(.isEmail)
/// var email: String = ""
@propertyWrapper
public struct ValidatorAnnotation<Value>: Validatable {
    
    /// 当前验证器
    public var validator: Validator<Value> {
        didSet {
            self.isValid = self.validator.validate(self.value)
        }
    }
    
    /// 是否有效
    public private(set) var isValid: Bool
    
    /// 是否无效
    public var isInvalid: Bool { !self.isValid }
    
    /// 验证后的值，如果验证未通过，返回nil
    public var validatedValue: Value? {
        self.isValid ? self.value : nil
    }
    
    private var value: Value
    
    /// 初始化并指定验证器
    public init(
        wrappedValue: Value,
        _ validator: Validator<Value>
    ) {
        self.validator = validator
        self.value = wrappedValue
        self.isValid = validator.validate(wrappedValue)
    }
    
    /// 初始化并指定包装验证器
    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ validator: Validator<WrappedValue>,
        defaultValue: @autoclosure @escaping () -> Bool = false
    ) where WrappedValue? == Value {
        self.init(
            wrappedValue: wrappedValue,
            Validator(validator, defaultValue: defaultValue())
        )
    }
    
    /// 当前包装值
    public var wrappedValue: Value {
        get {
            return self.value
        }
        set {
            self.value = newValue
            self.isValid = self.validator.validate(newValue)
        }
    }
    
}
