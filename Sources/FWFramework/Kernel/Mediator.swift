//
//  Mediator.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 中间件快速访问
    nonisolated(unsafe) public static var mediator = Mediator.self
}

// MARK: - ModulePriority
/// 模块可扩展优先级
public struct ModulePriority: RawRepresentable, Equatable, Hashable, Sendable {
    
    public typealias RawValue = UInt
    
    public static let low: ModulePriority = .init(250)
    public static let `default`: ModulePriority = .init(500)
    public static let high: ModulePriority = .init(750)
    
    public var rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: UInt) {
        self.rawValue = rawValue
    }
    
}

// MARK: - ModuleProtocol
/// 业务模块协议，各业务必须实现
public protocol ModuleProtocol: UIApplicationDelegate {
    
    /// 单例对象
    nonisolated static var shared: Self { get }
    
    /// 模块初始化方法，默认不处理，setupAllModules自动调用
    nonisolated func setup()
    
    /// 模块优先级，0最低。默认为default优先级
    nonisolated static func priority() -> ModulePriority
    
}

extension ModuleProtocol {
    
    /// 默认初始化不处理
    nonisolated public func setup() {}
    
    /// 默认优先级default
    nonisolated public static func priority() -> ModulePriority { .default }
    
}

extension ModuleProtocol where Self: NSObject {
    
    /// 默认实现NSObject单例对象
    nonisolated public static var shared: Self {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if let instance = NSObject.fw.getAssociatedObject(self, key: #function) as? Self {
            return instance
        } else {
            let instance = self.init()
            NSObject.fw.setAssociatedObject(self, key: #function, value: instance)
            return instance
        }
    }
    
}

// MARK: - Mediator
/// iOS模块化架构中间件，结合Router可搭建模块化架构设计
///
/// 支持两种模块加载模式：
/// 模式一：Delegate模式，推荐使用，详见方法：checkAllModules(_:)
/// 模式二：Runtime模式，详见方法：checkAllModules(selector:arguments:)
///
/// [Bifrost](https://github.com/youzan/Bifrost)
public class Mediator {
    
    nonisolated(unsafe) private static var modulePool: [String: ModuleProtocol.Type] = [:]
    nonisolated(unsafe) private static var moduleInvokePool: [String: Bool] = [:]
    
    /// 模块服务加载器，加载未注册模块时会尝试调用并注册，block返回值为register方法module参数
    public static let sharedLoader = Loader<Any, ModuleProtocol.Type>()
    /// 是否启用Delegate模式，AppResponder.setupEnvironment调用时生效，默认false
    nonisolated(unsafe) public static var delegateModeEnabled = false
    
    /// 插件调试描述
    public class func debugDescription() -> String {
        let sortedModules = modulePool.sorted { module1, module2 in
            let priority1 = module1.value.priority().rawValue
            let priority2 = module2.value.priority().rawValue
            return priority1 > priority2
        }
        
        var debugDescription = ""
        var debugCount = 0
        for (moduleId, moduleType) in sortedModules {
            debugCount += 1
            debugDescription.append(String(format: "%@. %@ : %@\n", NSNumber(value: debugCount), moduleId, NSStringFromClass(moduleType)))
        }
        return String(format: "\n========== MEDIATOR ==========\n%@========== MEDIATOR ==========", debugDescription)
    }
    
    /// 注册指定模块服务，返回注册结果
    @discardableResult
    public static func registerService<T>(_ type: T.Type, module: ModuleProtocol.Type) -> Bool {
        return registerService(type, module: module, isPreset: false)
    }
    
    /// 预置指定模块服务，仅当模块未注册时生效
    @discardableResult
    public static func presetService<T>(_ type: T.Type, module: ModuleProtocol.Type) -> Bool {
        return registerService(type, module: module, isPreset: true)
    }
    
    private static func registerService<T>(_ type: T.Type, module: ModuleProtocol.Type, isPreset: Bool) -> Bool {
        let moduleId = String(describing: type as AnyObject)
        if isPreset && modulePool[moduleId] != nil {
            return false
        }
        
        modulePool[moduleId] = module
        return true
    }
    
    /// 取消注册指定模块服务
    public static func unregisterService<T>(_ type: T.Type) {
        let moduleId = String(describing: type as AnyObject)
        modulePool.removeValue(forKey: moduleId)
    }
    
    /// 通过服务协议获取指定模块实例
    public static func loadModule<T>(_ type: T.Type) -> T? {
        let moduleId = String(describing: type as AnyObject)
        var moduleType = modulePool[moduleId]
        if moduleType == nil {
            guard let module = sharedLoader.load(type) else { return nil }
            
            registerService(type, module: module)
            moduleType = modulePool[moduleId]
        }
        guard let moduleType = moduleType else { return nil }
        
        return moduleType.shared as? T
    }
    
    /// 获取所有已注册模块类数组，按照优先级排序
    public static func allRegisteredModules() -> [ModuleProtocol.Type] {
        let sortedModules = modulePool.values.sorted { module1, module2 in
            let priority1 = module1.priority().rawValue
            let priority2 = module2.priority().rawValue
            return priority1 > priority2
        }
        return sortedModules
    }
    
    /// 初始化所有模块，推荐在willFinishLaunchingWithOptions中调用
    public static func setupAllModules() {
        let modules = allRegisteredModules()
        for moduleType in modules {
            moduleType.shared.setup()
        }
        
        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "%@", Mediator.debugDescription())
        Logger.debug(group: Logger.fw.moduleName, "%@", PluginManager.debugDescription())
        #endif
    }
    
    /// 在UIApplicationDelegate检查所有模块方法，Delegate模式，推荐使用
    public static func checkAllModules(_ block: (UIApplicationDelegate) -> Void) {
        let modules = allRegisteredModules()
        for moduleType in modules {
            block(moduleType.shared)
        }
    }
    
    /// 在UIApplicationDelegate检查所有模块方法，Runtime模式
    @discardableResult
    public static func checkAllModules(selector: Selector, arguments: [Any]?) -> Bool {
        var result = false
        let modules = allRegisteredModules()
        for moduleType in modules {
            guard let moduleInstance = moduleType.shared as? NSObject,
                  moduleInstance.responds(to: selector) else { continue }
            
            // 如果当前模块类为某个模块类的父类，则不调用当前模块类方法
            var shouldInvoke = true
            let moduleClass = NSStringFromClass(type(of: moduleInstance))
            if moduleInvokePool[moduleClass] == nil {
                for obj in modules {
                    if let objSuperclass = (obj as? NSObject.Type)?.superclass(),
                       moduleClass == NSStringFromClass(objSuperclass) {
                        shouldInvoke = false
                        break
                    }
                    
                }
            }
            guard shouldInvoke else { continue }
            
            if !moduleClass.isEmpty, moduleInvokePool[moduleClass] == nil {
                moduleInvokePool[moduleClass] = true
            }
            
            let returnValue = moduleInstance.fw.invokeMethod(selector, objects: arguments)?.takeUnretainedValue() as? Bool ?? false
            if !result {
                result = returnValue
            }
        }
        return result
    }
    
}
