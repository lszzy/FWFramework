//
//  Mediator.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

extension FW {
    /// 中间件快速访问
    public static var mediator = Mediator.self
}

/// 模块可扩展优先级
public struct ModulePriority: RawRepresentable, Equatable, Hashable {
    
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

/// 业务模块协议，各业务必须实现
@objc(__FWModuleProtocol)
public protocol ModuleProtocol: UIApplicationDelegate {
    
    /// 可选模块单例方法，默认查找@objc(sharedInstance)属性
    @objc optional static func moduleInstance() -> Self
    
    /// 模块初始化方法，默认不处理，setupAllModules自动调用
    @objc optional func setup()
    
    /// 是否主线程同步调用setup，默认为false，后台线程异步调用
    @objc optional static func setupSynchronously() -> Bool
    
    /// 模块优先级，0最低。默认为default优先级
    @objc optional static func priority() -> UInt
    
}

/// iOS模块化架构中间件，结合FWRouter可搭建模块化架构设计
///
/// [Bifrost](https://github.com/youzan/Bifrost)
public class Mediator: NSObject {
    
    private static var modulePool: [String: ModuleProtocol.Type] = [:]
    private static var moduleInvokePool: [String: Bool] = [:]
    
    /// 模块服务加载器，加载未注册模块时会尝试调用并注册，block返回值为register方法module参数
    public static let sharedLoader = Loader<ModuleProtocol.Type, ModuleProtocol.Type>()
    
    /// 插件调试描述
    public override class func debugDescription() -> String {
        let sortedModules = modulePool.sorted { module1, module2 in
            let priority1 = module1.value.priority?() ?? ModulePriority.default.rawValue
            let priority2 = module2.value.priority?() ?? ModulePriority.default.rawValue
            return priority1 > priority2
        }
        
        var debugDescription = ""
        var debugCount = 0
        for (moduleName, moduleType) in sortedModules {
            debugCount += 1
            debugDescription.append(String(format: "%@. %@ : %@\n", NSNumber(value: debugCount), moduleName, String.fw_safeString(moduleType)))
        }
        return String(format: "\n========== MEDIATOR ==========\n%@========== MEDIATOR ==========", debugDescription)
    }
    
    /// 注册指定模块服务，返回注册结果
    @discardableResult
    public static func registerService<T: ModuleProtocol>(_ type: T.Type, module: T.Type) -> Bool {
        return registerService(type, module: module, isPreset: false)
    }
    
    /// 预置指定模块服务，仅当模块未注册时生效
    @discardableResult
    public static func presetService<T: ModuleProtocol>(_ type: T.Type, module: T.Type) -> Bool {
        return registerService(type, module: module, isPreset: true)
    }
    
    private static func registerService<T: ModuleProtocol>(_ type: T.Type, module: T.Type, isPreset: Bool) -> Bool {
        let moduleId = String(describing: type)
        if isPreset && modulePool[moduleId] != nil {
            return false
        }
        
        modulePool[moduleId] = module
        return true
    }
    
    /// 取消注册指定模块服务
    public static func unregisterService<T: ModuleProtocol>(_ type: T.Type) {
        let moduleId = String(describing: type)
        modulePool.removeValue(forKey: moduleId)
    }
    
    /// 通过服务协议获取指定模块实例
    public static func loadModule<T: ModuleProtocol>(_ type: T.Type) -> T? {
        let moduleId = String(describing: type)
        var moduleType = modulePool[moduleId]
        if moduleType == nil {
            guard let module = sharedLoader.load(type) as? T.Type else { return nil }
            
            registerService(type, module: module)
            moduleType = modulePool[moduleId]
        }
        guard let moduleType = moduleType else { return nil }
        
        let moduleInstance = moduleInstance(moduleType)
        return moduleInstance as? T
    }
    
    private static func moduleInstance(_ moduleType: ModuleProtocol.Type) -> ModuleProtocol? {
        if let instance = moduleType.moduleInstance?() {
            return instance
        } else if let moduleClass = moduleType as? NSObject.Type {
            let selector = NSSelectorFromString("sharedInstance")
            if moduleClass.responds(to: selector) {
                return moduleClass.perform(selector)?.takeUnretainedValue() as? ModuleProtocol
            }
        }
        return nil
    }
    
    /// 获取所有已注册模块类数组，按照优先级排序
    public static func allRegisteredModules() -> [ModuleProtocol.Type] {
        let sortedModules = modulePool.values.sorted { module1, module2 in
            let priority1 = module1.priority?() ?? ModulePriority.default.rawValue
            let priority2 = module2.priority?() ?? ModulePriority.default.rawValue
            return priority1 > priority2
        }
        return sortedModules
    }
    
    /// 初始化所有模块，推荐在willFinishLaunchingWithOptions中调用
    public static func setupAllModules() {
        let modules = allRegisteredModules()
        for moduleType in modules {
            guard let moduleInstance = moduleInstance(moduleType) else { continue }
            
            let setupSync = moduleType.setupSynchronously?() ?? false
            if setupSync {
                moduleInstance.setup?()
            } else {
                DispatchQueue.global().async {
                    moduleInstance.setup?()
                }
            }
        }
        
        #if DEBUG
        Logger.debug(group: "FWFramework", "%@", Mediator.debugDescription())
        Logger.debug(group: "FWFramework", "%@", PluginManager.debugDescription())
        #endif
    }
    
    /// 在UIApplicationDelegate检查所有模块方法
    @discardableResult
    public static func checkAllModules(selector: Selector, arguments: [Any]?) -> Bool {
        var result = false
        let modules = allRegisteredModules()
        for moduleType in modules {
            guard let moduleInstance = moduleInstance(moduleType),
                  moduleInstance.responds(to: selector) else { continue }
            
            var shouldInvoke = true
            var moduleClass = ""
            if let moduleInstance = moduleInstance as? NSObject {
                moduleClass = NSStringFromClass(moduleInstance.classForCoder)
                if moduleInvokePool[moduleClass] == nil {
                    for obj in modules {
                        if let objSuperclass = (obj as? NSObject.Type)?.superclass(),
                           moduleClass == NSStringFromClass(objSuperclass) {
                            shouldInvoke = false
                            break
                        }
                        
                    }
                }
            }
            guard shouldInvoke else { continue }
            
            if !moduleClass.isEmpty, moduleInvokePool[moduleClass] == nil {
                moduleInvokePool[moduleClass] = true
            }
            
            var returnValue = false
            __FWRuntime.invokeMethod(moduleInstance, selector: selector, arguments: arguments, returnValue: &returnValue)
            if !result {
                result = returnValue
            }
        }
        return result
    }
    
}

/// 业务模块Bundle基类，各模块可继承
open class ModuleBundle: NSObject {
    
    /// 获取当前模块Bundle，默认主Bundle，子类可重写
    open class func bundle() -> Bundle {
        return .main
    }
    
    /// 获取当前模块图片
    open class func imageNamed(_ name: String) -> UIImage? {
        if let image = UIImage.fw_imageNamed(name, bundle: bundle()) { return image }
        
        let nameImages = __FWRuntime.getProperty(self.classForCoder(), forName: "imageNamed") as? NSMutableDictionary
        return nameImages?[name] as? UIImage
    }
    
    /// 设置当前模块图片
    open class func setImage(_ image: UIImage?, for name: String) {
        var nameImages: NSMutableDictionary
        if let images = __FWRuntime.getProperty(self.classForCoder(), forName: "imageNamed") as? NSMutableDictionary {
            nameImages = images
        } else {
            nameImages = NSMutableDictionary()
            __FWRuntime.setPropertyPolicy(self.classForCoder(), with: nameImages, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, forName: "imageNamed")
        }
        
        if let image = image {
            nameImages[name] = image
        } else {
            nameImages.removeObject(forKey: name)
        }
    }
    
    /// 获取当前模块多语言，可指定文件
    open class func localizedString(_ key: String, table: String? = nil) -> String {
        return bundle().localizedString(forKey: key, value: nil, table: table)
    }
    
    /// 获取当前模块资源文件路径
    open class func resourcePath(_ name: String) -> String? {
        return bundle().path(forResource: name, ofType: nil)
    }
    
    /// 获取当前模块资源文件URL
    open class func resourceURL(_ name: String) -> URL? {
        return bundle().url(forResource: name, withExtension: nil)
    }
    
}
