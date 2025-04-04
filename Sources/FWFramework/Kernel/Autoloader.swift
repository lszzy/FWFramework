//
//  Autoloader.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 自动加载Swift类并调用autoload方法，参数为Class或String
    @discardableResult
    public static func autoload(_ clazz: Any) -> Bool {
        Autoloader.autoload(clazz)
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
/// 新增Autoloader objc扩展，以load开头且无参静态方法即会自动调用，方法名建议[load模块名_文件名|类名]
@objc(ObjCAutoloader)
public class Autoloader: NSObject, AutoloadProtocol, @unchecked Sendable {
    public static let shared = Autoloader()

    // MARK: - Accessor
    private var isAutoloaded = false
    private var debugMethods: [String] = []

    // MARK: - Public
    /// 自动加载Swift类并调用autoload方法，参数为Class或String
    @discardableResult
    public static func autoload(_ clazz: Any) -> Bool {
        var autoloader = clazz as? AutoloadProtocol.Type
        if autoloader == nil, let className = clazz as? String {
            autoloader = autoloadClass(className) as? AutoloadProtocol.Type
        }

        if let autoloader {
            autoloader.autoload()
            return true
        }
        return false
    }

    /// 自动加载objc类以load开头且无参静态方法，返回方法列表
    @discardableResult
    public static func autoloadMethods(_ aClass: Any) -> [String] {
        var clazz: Any? = aClass
        if let className = clazz as? String {
            clazz = autoloadClass(className)
        }
        guard let metaClass = NSObject.fw.metaClass(clazz) else { return [] }

        let methodNames = NSObject.fw.classMethods(metaClass)
            .filter { methodName in
                methodName.hasPrefix("load") && methodName.count > 4 && !methodName.contains(":")
            }
            .sorted()
        guard !methodNames.isEmpty else { return [] }

        if let targetClass = clazz as? NSObject.Type {
            for methodName in methodNames {
                targetClass.perform(NSSelectorFromString(methodName))
            }
            return methodNames.map { "+" + $0 }
        } else if let targetObject = clazz as? NSObject {
            for methodName in methodNames {
                targetObject.perform(NSSelectorFromString(methodName))
            }
            return methodNames
        }
        return []
    }

    private static func autoloadClass(_ className: String) -> AnyClass? {
        if let nameClass = NSClassFromString(className) {
            return nameClass
        }
        let moduleName = Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String ?? ""
        if !moduleName.isEmpty {
            return NSClassFromString("\(moduleName).\(className)")
        }
        return nil
    }

    /// 自动加载器调试描述
    override public class func debugDescription() -> String {
        var debugDescription = ""
        var debugCount = 0
        for methodName in shared.debugMethods {
            let formatName = methodName
                .replacingOccurrences(of: "load", with: "")
                .trimmingCharacters(in: .init(charactersIn: "_"))
                .replacingOccurrences(of: "_", with: ".")

            debugCount += 1
            debugDescription.append(String(format: "%@. %@\n", NSNumber(value: debugCount), formatName))
        }
        return String(format: "\n========== AUTOLOADER ==========\n%@========== AUTOLOADER ==========", debugDescription)
    }

    // MARK: - AutoloadProtocol
    /// 自动加载load开头objc扩展方法
    public static func autoload() {
        guard !shared.isAutoloaded else { return }
        shared.isAutoloaded = true

        FrameworkAutoloader.shared.debugMethods = autoloadMethods(FrameworkAutoloader.self)
        shared.debugMethods = autoloadMethods(Autoloader.self) + autoloadMethods(Autoloader.shared)

        #if DEBUG
        // Logger.debug(group: Logger.fw.moduleName, "%@", FrameworkAutoloader.debugDescription())
        Logger.debug(group: Logger.fw.moduleName, "%@", debugDescription())
        #endif
    }
}

// MARK: - FrameworkAutoloader
/// 框架内部自动加载器，自动加载框架内置组件
@_spi(FW) public class FrameworkAutoloader: NSObject, @unchecked Sendable {
    static let shared = FrameworkAutoloader()

    fileprivate var debugMethods: [String] = []

    /// 内部加载器调试描述
    override public class func debugDescription() -> String {
        var debugDescription = ""
        var debugCount = 0
        for methodName in shared.debugMethods {
            let formatName = methodName
                .replacingOccurrences(of: "load", with: "")
                .trimmingCharacters(in: .init(charactersIn: "_"))
                .replacingOccurrences(of: "_", with: ".")

            debugCount += 1
            debugDescription.append(String(format: "%@. %@\n", NSNumber(value: debugCount), formatName))
        }
        return String(format: "\n========== FRAMEWORK ==========\n%@========== FRAMEWORK ==========", debugDescription)
    }
}

// MARK: - FrameworkConfiguration
/// 框架内部静态配置，用于扩展兼容Swift 6静态属性
@_spi(FW) public actor FrameworkConfiguration {}
