//
//  Autoloader.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - WrapperGlobal+Autoloader
extension WrapperGlobal {
    
    /// 自动加载Swift类并调用autoload方法，参数为Class或String
    @discardableResult
    public static func autoload(_ clazz: Any) -> Bool {
        return Autoloader.autoload(clazz)
    }
    
}

// MARK: - AutoloadProtocol
/// Swift自动加载协议，配合autoload(_:)方法使用
public protocol AutoloadProtocol {
    
    /// 自动加载协议方法
    static func autoload()
    
}

// MARK: - Autoloader
/// 自动加载器，处理swift不支持load方法问题
///
/// 本方案采用objc扩展方法实现，相对于全局扫描类方案性能高，使用简单，使用方法：
/// 新增Autoloader扩展objc类方法，以load开头即会自动调用，注意方法名不要重复，建议load+类名+扩展名
public class Autoloader: NSObject, AutoloadProtocol {
    
    private static var autoloadMethods: [String] = []
    private static var isAutoloaded = false
    
    // MARK: - Public
    /// 自动加载Swift类并调用autoload方法，参数为Class或String
    @discardableResult
    public static func autoload(_ clazz: Any) -> Bool {
        var autoloader = clazz as? AutoloadProtocol.Type
        if autoloader == nil, let name = clazz as? String {
            if let nameClass = NSClassFromString(name) {
                autoloader = nameClass as? AutoloadProtocol.Type
            } else if let module = Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String,
                      let nameClass = NSClassFromString("\(module).\(name)") {
                autoloader = nameClass as? AutoloadProtocol.Type
            }
        }
        
        if let autoloader = autoloader {
            autoloader.autoload()
            return true
        }
        return false
    }
    
    /// 自动加载器调试描述
    public override class func debugDescription() -> String {
        var debugDescription = ""
        var debugCount = 0
        for methodName in autoloadMethods {
            debugCount += 1
            debugDescription.append(String(format: "%@. %@\n", NSNumber(value: debugCount), methodName))
        }
        return String(format: "\n========== AUTOLOADER ==========\n%@========== AUTOLOADER ==========", debugDescription)
    }
    
    // MARK: - AutoloadProtocol
    /// 自动加载load开头objc扩展方法
    public static func autoload() {
        guard !isAutoloaded else { return }
        isAutoloaded = true
        
        // 自动加载Autoloader
        autoloadAutoloader()
        
        // 自动加载框架内置组件
        autoload(AutoLayoutAutoloader.self)
        autoload(ThemeAutoloader.self)
        autoload(LanguageAutoloader.self)
        autoload(UIKitAutoloader.self)
        autoload(ViewControllerAutoloader.self)
        autoload(NavigationControllerAutoloader.self)
        autoload(NavigationStyleAutoloader.self)
        autoload(AlertPluginAutoloader.self)
        autoload(ImagePluginAutoloader.self)
        autoload(ToolbarViewAutoloader.self)
        
        #if DEBUG
        // 调试模式自动执行单元测试
        autoload(UnitTest.self)
        #endif
    }
    
    private static func autoloadAutoloader() {
        autoloadMethods = NSObject.fw
            .classMethods(Autoloader.self)
            .filter({ methodName in
                return methodName.hasPrefix("load") && !methodName.contains(":")
            })
            .sorted()
        
        if autoloadMethods.count > 0 {
            let autoloader = Autoloader()
            for methodName in autoloadMethods {
                autoloader.perform(NSSelectorFromString(methodName))
            }
        }
        
        #if DEBUG
        Logger.debug(group: Logger.fw_moduleName, "%@", debugDescription())
        #endif
    }
    
}

// MARK: - ObjCBridge+Autoloader
@objc extension ObjCBridge: ObjCBridgeProtocol {
    
    /// 自动加载Autoloader
    public static func autoload() {
        Autoloader.autoload()
    }
    
    /// 打印日志桥接方法
    public static func log(_ message: String) {
        #if DEBUG
        Logger.log(.debug, group: Logger.fw_moduleName, message: message)
        #endif
    }
    
}
