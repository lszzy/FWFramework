//
//  Logger.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - FW+Logger
extension FW {
    
    /// 记录跟踪日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func trace(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !Logger.check(.trace) { return }
        Logger.log(.trace, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }

    /// 记录调试日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func debug(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !Logger.check(.debug) { return }
        Logger.log(.debug, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }

    /// 记录信息日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func info(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !Logger.check(.info) { return }
        Logger.log(.info, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }

    /// 记录警告日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func warn(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !Logger.check(.warn) { return }
        Logger.log(.warn, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }

    /// 记录错误日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func error(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !Logger.check(.error) { return }
        Logger.log(.error, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }

    /// 记录分组日志
    ///
    /// - Parameters:
    ///   - group: 日志分组名称
    ///   - type: 日志类型
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func group(
        _ group: String,
        type: LogType,
        format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !Logger.check(type) { return }
        Logger.log(type, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)), group: group, userInfo: nil)
    }
    
}

// MARK: - Logger
/// 日志类型枚举
@objc(__FWLogType)
public enum LogType: UInt {
    /// 错误类型，0...00001
    case error = 1
    /// 警告类型，0...00010
    case warn = 2
    /// 信息类型，0...00100
    case info = 4
    /// 调试类型，0...01000
    case debug = 8
    /// 跟踪类型，0...10000
    case trace = 16
}

/// 日志级别定义
public enum LogLevel: UInt {
    /// 关闭日志，0...00000
    case off = 0
    /// 错误以上级别，0...00001
    case error = 1
    /// 警告以上级别，0...00011
    case warn = 3
    /// 信息以上级别，0...00111
    case info = 7
    /// 调试以上级别，0...01111
    case debug = 15
    /// 跟踪以上级别，0...11111
    case trace = 31
    /// 所有级别，1...11111
    case all = 63
}

/// 日志记录类。支持设置全局日志级别和自定义LoggerPlugin插件
public class Logger: NSObject {
    
    /// 全局日志级别，默认调试为All，正式为Off
    public static var level: LogLevel = {
        #if DEBUG
        .all
        #else
        .off
        #endif
    }()
    
    /// 检查是否需要记录指定类型日志
    /// - Parameter type: 日志类型
    /// - Returns: 是否需要记录
    fileprivate class func check(_ type: LogType) -> Bool {
        return (level.rawValue & type.rawValue) != 0
    }
    
    /// 记录类型日志，支持分组和用户信息
    /// - Parameters:
    ///   - type: 日志类型
    ///   - message: 日志消息
    ///   - group: 日志分组，默认nil
    ///   - userInfo: 用户信息，默认nil
    public class func log(_ type: LogType, message: String, group: String? = nil, userInfo: [AnyHashable: Any]? = nil) {
        // 过滤不支持的级别
        if !check(type) { return }
        
        var plugin: LoggerPlugin
        if let loggerPlugin = PluginManager.loadPlugin(LoggerPlugin.self) as? LoggerPlugin {
            plugin = loggerPlugin
        } else {
            plugin = LoggerPluginImpl.shared
        }
        plugin.log(type, message: message, group: group, userInfo: userInfo)
    }
    
    /// 记录跟踪日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func trace(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !check(.trace) { return }
        log(.trace, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录调试日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func debug(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !check(.debug) { return }
        log(.debug, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录信息日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func info(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !check(.info) { return }
        log(.info, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录警告日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func warn(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !check(.warn) { return }
        log(.warn, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录错误日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func error(
        _ format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !check(.error) { return }
        log(.error, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录分组日志
    ///
    /// - Parameters:
    ///   - group: 日志分组名称
    ///   - type: 日志类型
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func group(
        _ group: String,
        type: LogType,
        format: String,
        _ arguments: CVarArg...,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !check(type) { return }
        log(type, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)), group: group, userInfo: nil)
    }
    
}

// MARK: - LoggerPlugin
/// 日志插件协议
@objc(__FWLoggerPlugin)
public protocol LoggerPlugin {
    
    /// 记录日志协议方法
    /// - Parameters:
    ///   - type: 日志类型
    ///   - message: 日志消息
    ///   - group: 日志分组
    ///   - userInfo: 用户信息
    func log(_ type: LogType, message: String, group: String?, userInfo: [AnyHashable: Any]?)
    
}

// MARK: - LoggerPluginImpl
/// 默认NSLog日志插件
public class LoggerPluginImpl: NSObject, LoggerPlugin {
    
    /// 单例模式对象
    @objc(sharedInstance)
    public static let shared = LoggerPluginImpl()
    
    /// 记录日志协议方法
    /// - Parameters:
    ///   - type: 日志类型
    ///   - message: 日志消息
    ///   - group: 日志分组
    ///   - userInfo: 用户信息
    public func log(_ type: LogType, message: String, group: String?, userInfo: [AnyHashable : Any]?) {
        let groupStr = group != nil ? " [\(group ?? "")]" : ""
        let infoStr = userInfo != nil ? " \(FW.safeString(userInfo))" : ""
        switch type {
        case .error:
            NSLog("%@ ERROR:%@ %@%@", "❌", groupStr, message, infoStr)
        case .warn:
            NSLog("%@ WARN:%@ %@%@", "⚠️", groupStr, message, infoStr)
        case .info:
            NSLog("%@ INFO:%@ %@%@", "ℹ️", groupStr, message, infoStr)
        case .debug:
            NSLog("%@ DEBUG:%@ %@%@", "⏱️", groupStr, message, infoStr)
        default:
            NSLog("%@ TRACE:%@ %@%@", "📝", groupStr, message, infoStr)
        }
    }
    
}
