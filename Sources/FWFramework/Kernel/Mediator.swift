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

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 中间件快速访问
    public static var mediator = Mediator.self
}

// MARK: - ModulePriority
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

// MARK: - ModuleProtocol
/// 业务模块协议，各业务必须实现
public protocol ModuleProtocol: UIApplicationDelegate {
    
    /// 单例对象
    static var shared: Self { get }
    
    /// 模块初始化方法，默认不处理，setupAllModules自动调用
    func setup()
    
    /// 是否主线程同步调用setup，默认为false，后台线程异步调用
    static func setupSynchronously() -> Bool
    
    /// 模块优先级，0最低。默认为default优先级
    static func priority() -> ModulePriority
    
}

extension ModuleProtocol {
    
    /// 默认初始化不处理
    public func setup() {}
    
    /// 默认后台线程调用setup
    public static func setupSynchronously() -> Bool { false }
    
    /// 默认优先级default
    public static func priority() -> ModulePriority { .default }
    
}

extension ModuleProtocol where Self: NSObject {
    
    /// 默认实现NSObject单例对象
    public static var shared: Self {
        return fw_synchronized {
            if let instance = self.fw_property(forName: #function) as? Self {
                return instance
            } else {
                let instance = self.init()
                self.fw_setProperty(instance, forName: #function)
                return instance
            }
        }
    }
    
}

// MARK: - Mediator
/// iOS模块化架构中间件，结合FWRouter可搭建模块化架构设计
///
/// [Bifrost](https://github.com/youzan/Bifrost)
public class Mediator: NSObject {
    
    private static var modulePool: [String: ModuleProtocol.Type] = [:]
    private static var moduleInvokePool: [String: Bool] = [:]
    
    /// 模块服务加载器，加载未注册模块时会尝试调用并注册，block返回值为register方法module参数
    public static let sharedLoader = Loader<Any, ModuleProtocol.Type>()
    
    /// 插件调试描述
    public override class func debugDescription() -> String {
        let sortedModules = modulePool.sorted { module1, module2 in
            let priority1 = module1.value.priority().rawValue
            let priority2 = module2.value.priority().rawValue
            return priority1 > priority2
        }
        
        var debugDescription = ""
        var debugCount = 0
        for (moduleId, moduleType) in sortedModules {
            debugCount += 1
            debugDescription.append(String(format: "%@. %@ : %@\n", NSNumber(value: debugCount), moduleId, String.fw_safeString(moduleType)))
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
        let moduleId = String.fw_safeString(type)
        if isPreset && modulePool[moduleId] != nil {
            return false
        }
        
        modulePool[moduleId] = module
        return true
    }
    
    /// 取消注册指定模块服务
    public static func unregisterService<T>(_ type: T.Type) {
        let moduleId = String.fw_safeString(type)
        modulePool.removeValue(forKey: moduleId)
    }
    
    /// 通过服务协议获取指定模块实例
    public static func loadModule<T>(_ type: T.Type) -> T? {
        let moduleId = String.fw_safeString(type)
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
            let setupSync = moduleType.setupSynchronously()
            if setupSync {
                moduleType.shared.setup()
            } else {
                DispatchQueue.global().async {
                    moduleType.shared.setup()
                }
            }
        }
        
        #if DEBUG
        Logger.debug(group: Logger.fw_moduleName, "%@", Mediator.debugDescription())
        Logger.debug(group: Logger.fw_moduleName, "%@", PluginManager.debugDescription())
        #endif
    }
    
    /// 在UIApplicationDelegate检查所有模块方法
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
            
            let returnValue = moduleInstance.fw_invokeMethod(selector, objects: arguments)?.takeUnretainedValue() as? Bool ?? false
            if !result {
                result = returnValue
            }
        }
        return result
    }
    
}

// MARK: - ModuleBundle
/// 业务模块Bundle基类，各模块可继承
///
/// 资源查找规则如下：
/// 1. ModuleBundle基类或主应用模块类只加载主Bundle
/// 2. ModuleBundle子模块类优先加载主应用的{模块名称}.bundle(可替换模块)，如主应用内FWFramework.bundle
/// 3. ModuleBundle子模块类其次加载该模块的{模块名称}.bundle，如框架内FWFramework.bundle
/// 4. ModuleBundle子模块类以上都不存在时返回nil加载主Bundle
open class ModuleBundle: NSObject {
    
    private class Target {
        let identifier = UUID().uuidString
        var bundle: Bundle?
        var images: [String: Any] = [:]
        var colors: [String: Any] = [:]
        var strings: [String: [String: [String: String]]] = [:]
    }
    
    /// 获取当前模块Bundle并缓存，initializeBundle为空时默认主Bundle
    open class func bundle() -> Bundle {
        if let bundle = bundleTarget.bundle {
            return bundle
        } else {
            let bundle = initializeBundle() ?? .main
            bundleTarget.bundle = bundle
            didInitialize()
            return bundle
        }
    }
    
    /// 获取当前模块图片
    open class func imageNamed(_ name: String) -> UIImage? {
        if let image = UIImage.fw_imageNamed(name, bundle: bundle()) { return image }
        
        let value = bundleTarget.images[name]
        if let image = value as? UIImage {
            return image
        } else if let block = value as? () -> UIImage? {
            return block()
        }
        return nil
    }
    
    /// 设置当前模块动态图片
    open class func addImage(_ name: String, image: UIImage?) {
        bundleTarget.images[name] = image
    }
    
    /// 设置当前模块动态图片句柄
    open class func addImage(_ name: String, block: (() -> UIImage?)?) {
        bundleTarget.images[name] = block
    }
    
    /// 获取当前模块颜色，不存在时默认clear
    open class func colorNamed(_ name: String) -> UIColor {
        if let color = UIColor(named: name, in: bundle(), compatibleWith: nil) { return color }
        
        let value = bundleTarget.colors[name]
        if let color = value as? UIColor {
            return color
        } else if let block = value as? () -> UIColor {
            return block()
        }
        return .clear
    }
    
    /// 设置当前模块动态颜色
    open class func addColor(_ name: String, color: UIColor?) {
        bundleTarget.colors[name] = color
    }
    
    /// 设置当前模块动态颜色句柄
    open class func addColor(_ name: String, block: (() -> UIColor)?) {
        bundleTarget.colors[name] = block
    }
    
    /// 获取当前模块多语言，可指定文件
    open class func localizedString(_ key: String, table: String? = nil) -> String {
        let localized = bundle().localizedString(forKey: key, value: bundleTarget.identifier, table: table)
        if localized != bundleTarget.identifier { return localized }
        
        let tableKey = table ?? "Localizable"
        let languageKey = Bundle.fw_currentLanguage ?? "en"
        let tableStrings = bundleTarget.strings[tableKey]
        let languageStrings = tableStrings?[languageKey] ?? tableStrings?["en"]
        return languageStrings?[key] ?? key
    }
    
    /// 设置当前模块动态多语言
    open class func addStrings(_ language: String? = nil, table: String? = nil, strings: [String: String]) {
        let languageKey = language ?? "en"
        let tableKey = table ?? "Localizable"
        if bundleTarget.strings[tableKey] == nil {
            bundleTarget.strings[tableKey] = [:]
        }
        if bundleTarget.strings[tableKey]?[languageKey] == nil {
            bundleTarget.strings[tableKey]?[languageKey] = strings
        } else {
            bundleTarget.strings[tableKey]?[languageKey]?.merge(strings) { _, last in last }
        }
    }
    
    /// 获取当前模块资源文件路径
    open class func resourcePath(_ name: String, type: String? = nil) -> String? {
        return bundle().path(forResource: name, ofType: type)
    }
    
    /// 获取当前模块资源文件URL
    open class func resourceURL(_ name: String, type: String? = nil) -> URL? {
        return bundle().url(forResource: name, withExtension: type)
    }
    
    private class var bundleTarget: Target {
        if let target = self.fw_property(forName: "bundleTarget") as? Target {
            return target
        } else {
            let target = Target()
            self.fw_setProperty(target, forName: "bundleTarget")
            return target
        }
    }
    
    // MARK: - Override
    /// 初始化模块Bundle，子类可重写，用于加载自定义Bundle
    open class func initializeBundle() -> Bundle? {
        // 1. ModuleBundle基类或主应用模块类只加载主Bundle
        let bundleClass: AnyClass = self
        guard self != ModuleBundle.self,
              Bundle(for: bundleClass) != .main,
              let moduleName = Bundle(for: bundleClass).executableURL?.lastPathComponent else {
            return nil
        }
        
        // 2. ModuleBundle子模块类优先加载主应用的{模块名称}.bundle(可替换模块)，如主应用内FWFramework.bundle
        if let appBundle = Bundle.fw_bundle(name: moduleName) {
            return appBundle.fw_localizedBundle()
        }
        /// 3. ModuleBundle子模块类其次加载该模块的{模块名称}.bundle，如框架内FWFramework.bundle
        if let moduleBundle = Bundle.fw_bundle(with: bundleClass, name: moduleName) {
            return moduleBundle.fw_localizedBundle()
        }
        /// 4. ModuleBundle子模块类以上都不存在时返回nil加载主Bundle
        return nil
    }
    
    /// 初始化完成钩子，bundle方法自动调用一次，子类可重写，用于加载动态资源等
    open class func didInitialize() {}
    
}
