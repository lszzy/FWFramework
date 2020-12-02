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

/// 插件属性包装器注解
/// 使用示例：
/// 加载插件：@FWPluginAnnotation(TestPluginProtocol.self)
/// 自动注册并加载插件：@FWPluginAnnotation(TestPluginProtocol.self, object: TestPluginImpl.self)
/// static var testPlugin: TestPluginProtocol
@propertyWrapper
public struct FWPluginAnnotation<T> {
    let plugin: Protocol
    var object: Any?
    var block: (() -> T)?
    var factory: (() -> T)?
    
    public init(_ plugin: Protocol) {
        self.plugin = plugin
    }
    
    public init(_ plugin: Protocol, object: Any) {
        self.plugin = plugin
        self.object = object
    }
    
    public init(_ plugin: Protocol, block: @escaping () -> T) {
        self.plugin = plugin
        self.block = block
    }
    
    public init(_ plugin: Protocol, factory: @escaping () -> T) {
        self.plugin = plugin
        self.factory = factory
    }
    
    public var wrappedValue: T {
        get {
            if let object = object {
                FWPluginManager.sharedInstance.registerPlugin(plugin, with: object)
            } else if let block = block {
                FWPluginManager.sharedInstance.registerPlugin(plugin, withBlock: block)
            } else if let factory = factory {
                FWPluginManager.sharedInstance.registerPlugin(plugin, withFactory: factory)
            }
            
            return FWPluginManager.sharedInstance.loadPlugin(self.plugin) as! T
        }
    }
}
