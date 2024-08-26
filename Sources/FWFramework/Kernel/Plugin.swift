//
//  Plugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 插件快速访问
    public nonisolated(unsafe) static var plugin = PluginManager.self
}

// MARK: - PluginProtocol
/// 插件协议，可不实现。未实现时默认调用SingletonProtocol > sharedInstance > init方法
public protocol PluginProtocol {
    /// 可选插件单例方法，优先级高，仅调用一次
    static func pluginInstance() -> Self?
    /// 可选插件工厂方法，优先级低，会调用多次
    static func pluginFactory() -> Self?

    /// 插件load时钩子方法
    func pluginDidLoad()
    /// 插件unload时钩子方法
    func pluginDidUnload()
}

extension PluginProtocol {
    /// 默认实现插件单例方法，优先级高，仅调用一次
    public static func pluginInstance() -> Self? {
        nil
    }

    /// 默认实现插件工厂方法，优先级低，会调用多次
    public static func pluginFactory() -> Self? {
        nil
    }

    /// 默认实现插件load时钩子方法
    public func pluginDidLoad() {}
    /// 默认实现插件unload时钩子方法
    public func pluginDidUnload() {}
}

// MARK: - SingletonProtocol
/// 单例协议，可不实现。未实现时默认调用sharedInstance > init方法
public protocol SingletonProtocol {
    /// 单例对象
    static var shared: Self { get }
}

// MARK: - PluginManager
/// 插件管理器类。支持插件冷替换(使用插件前)和热替换(先释放插件)
///
/// 和Mediator对比如下：
/// Plugin：和业务无关，侧重于工具类、基础设施、可替换，比如Toast、Loading等
/// Mediator: 和业务相关，侧重于架构、业务功能、模块化，比如用户模块，订单模块等
public class PluginManager {
    /// 内部Target类
    private class Target {
        var object: Any?
        var instance: Any?
        var locked: Bool = false
        var isFactory: Bool = false
    }

    /// 内部插件池
    private nonisolated(unsafe) static var pluginPool: [String: Target] = [:]

    /// 插件调试描述
    public class func debugDescription() -> String {
        var debugDescription = ""
        var debugCount = 0
        for (pluginId, target) in pluginPool {
            debugCount += 1
            debugDescription.append(String(format: "%@. %@ : %@\n", NSNumber(value: debugCount), pluginId, String(describing: (target.instance ?? target.object) as AnyObject)))
        }
        return String(format: "\n========== PLUGIN ==========\n%@========== PLUGIN ==========", debugDescription)
    }

    /// 单例插件加载器，加载未注册插件时会尝试调用并注册，block返回值为register方法object参数
    public static let sharedLoader = Loader<Any, Any>()

    /// 注册单例插件，仅当插件未使用时生效，插件类或对象必须实现protocol
    @discardableResult
    public static func registerPlugin<T>(_ type: T.Type, object: Any) -> Bool {
        registerPlugin(type, object: object, isPreset: false)
    }

    /// 预置单例插件，仅当插件未注册时生效，插件类或对象必须实现protocol
    @discardableResult
    public static func presetPlugin<T>(_ type: T.Type, object: Any) -> Bool {
        registerPlugin(type, object: object, isPreset: true)
    }

    private static func registerPlugin<T>(_ type: T.Type, object: Any, isPreset: Bool) -> Bool {
        let pluginId = String(describing: type as AnyObject)
        if let target = pluginPool[pluginId] {
            if target.locked { return false }
            if isPreset { return false }
        }

        let plugin = Target()
        plugin.object = object
        pluginPool[pluginId] = plugin
        return true
    }

    /// 取消插件注册，仅当插件未使用时生效
    public static func unregisterPlugin<T>(_ type: T.Type) {
        let pluginId = String(describing: type as AnyObject)
        guard let target = pluginPool[pluginId] else { return }
        if target.locked { return }

        pluginPool.removeValue(forKey: pluginId)
    }

    /// 延迟加载插件对象，调用后不可再注册该插件
    public static func loadPlugin<T>(_ type: T.Type) -> T? {
        let pluginId = String(describing: type as AnyObject)
        var target = pluginPool[pluginId]
        if target == nil {
            guard let object = sharedLoader.load(type) else { return nil }

            registerPlugin(type, object: object)
            target = pluginPool[pluginId]
        }
        guard let plugin = target else { return nil }
        if plugin.instance != nil && !plugin.isFactory {
            return plugin.instance as? T
        }

        plugin.locked = true
        plugin.isFactory = false
        let pluginProtocol = plugin.object as? PluginProtocol.Type
        if let instance = pluginProtocol?.pluginInstance() {
            plugin.instance = instance
        } else if let instance = pluginProtocol?.pluginFactory() {
            (plugin.instance as? PluginProtocol)?.pluginDidUnload()
            plugin.instance = instance
            plugin.isFactory = true
        } else if let pluginSingleton = plugin.object as? SingletonProtocol.Type {
            plugin.instance = pluginSingleton.shared
        } else if let pluginClass = plugin.object as? NSObject.Type {
            let selector = NSSelectorFromString("sharedInstance")
            if pluginClass.responds(to: selector) {
                plugin.instance = pluginClass.perform(selector)?.takeUnretainedValue()
            } else {
                plugin.instance = pluginClass.init()
            }
        } else {
            plugin.instance = plugin.object
        }

        (plugin.instance as? PluginProtocol)?.pluginDidLoad()
        return plugin.instance as? T
    }

    /// 释放插件对象并标记为未使用，释放后可重新注册该插件
    public static func unloadPlugin<T>(_ type: T.Type) {
        let pluginId = String(describing: type as AnyObject)
        guard let plugin = pluginPool[pluginId] else { return }

        (plugin.instance as? PluginProtocol)?.pluginDidUnload()
        plugin.instance = nil
        plugin.isFactory = false
        plugin.locked = false
    }
}
