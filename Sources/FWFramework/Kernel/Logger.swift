//
//  Logger.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation
import os

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 记录详细日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func verbose(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.verbose) { return }
        Logger.log(.verbose, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }

    /// 记录调试日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func debug(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.debug) { return }
        Logger.log(.debug, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }

    /// 记录信息日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func info(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.info) { return }
        Logger.log(.info, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }

    /// 记录警告日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func warn(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.warn) { return }
        Logger.log(.warn, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }

    /// 记录错误日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func error(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.error) { return }
        Logger.log(.error, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录类型日志
    ///
    /// - Parameters:
    ///   - type: 日志类型
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func log(
        type: LogType,
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(type) { return }
        Logger.log(type, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
}

// MARK: - Logger
/// 日志类型枚举
public struct LogType: OptionSet, Sendable {
    
    public let rawValue: UInt
    
    /// 错误类型
    public static let error: LogType = .init(rawValue: 1 << 0)
    /// 警告类型
    public static let warn: LogType = .init(rawValue: 1 << 1)
    /// 信息类型
    public static let info: LogType = .init(rawValue: 1 << 2)
    /// 调试类型
    public static let debug: LogType = .init(rawValue: 1 << 3)
    /// 详细类型
    public static let verbose: LogType = .init(rawValue: 1 << 4)
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
}

/// 日志级别定义
public struct LogLevel: RawRepresentable, Equatable, Hashable, Sendable {
    
    public typealias RawValue = UInt
    
    /// 关闭日志
    public static let off: LogLevel = .init(0)
    /// 错误以上级别
    public static let error: LogLevel = .init(LogType.error.rawValue)
    /// 警告以上级别
    public static let warn: LogLevel = .init(LogType.error.union(.warn).rawValue)
    /// 信息以上级别
    public static let info: LogLevel = .init(LogType.warn.union(.info).rawValue)
    /// 调试以上级别
    public static let debug: LogLevel = .init(LogType.info.union(.debug).rawValue)
    /// 详细以上级别
    public static let verbose: LogLevel = .init(LogType.debug.union(.verbose).rawValue)
    /// 所有级别
    public static let all: LogLevel = .init(.max)
    
    public var rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: UInt) {
        self.rawValue = rawValue
    }
    
}

/// 日志记录类。支持设置全局日志级别和自定义LoggerPlugin插件
@objc(ObjCLogger)
public class Logger: NSObject {
    
    /// 全局日志级别，默认调试为All，正式为Off
    nonisolated(unsafe) public static var level: LogLevel = {
        #if DEBUG
        .all
        #else
        .off
        #endif
    }()
    
    /// 记录类型日志，支持分组和用户信息
    /// - Parameters:
    ///   - type: 日志类型
    ///   - group: 日志分组，默认空
    ///   - message: 日志消息
    public class func log(_ type: LogType, group: String = "", message: String) {
        // 过滤不支持的级别
        if !check(type) { return }
        
        let plugin = PluginManager.loadPlugin(LoggerPlugin.self) ?? LoggerPluginImpl.shared
        plugin.log(type, group: group, message: message)
    }
    
    /// 记录详细日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func verbose(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.verbose) { return }
        log(.verbose, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录调试日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func debug(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.debug) { return }
        log(.debug, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录信息日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func info(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.info) { return }
        log(.info, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录警告日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func warn(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.warn) { return }
        log(.warn, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 记录错误日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func error(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.error) { return }
        log(.error, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
    /// 检查是否需要记录指定类型日志
    /// - Parameter type: 日志类型
    /// - Returns: 是否需要记录
    class func check(_ type: LogType) -> Bool {
        return LogType(rawValue: level.rawValue).contains(type)
    }
    
}

// MARK: - LoggerPlugin
/// 日志插件协议
public protocol LoggerPlugin {
    
    /// 记录日志协议方法
    /// - Parameters:
    ///   - type: 日志类型
    ///   - group: 日志分组
    ///   - message: 日志消息
    func log(_ type: LogType, group: String, message: String)
    
}

/// NSLog日志插件，兼容FWDebug等组件
public class LoggerPluginNSLog: NSObject, LoggerPlugin, @unchecked Sendable {
    
    @objc(sharedInstance)
    public static let shared = LoggerPluginNSLog()
    
    /// 自定义日志处理句柄
    public var logHandler: ((String) -> Void)?
    
    /// 记录日志协议方法
    public func log(_ type: LogType, group: String, message: String) {
        switch type {
        case .error:
            logMessage(String(format: "%@ ERROR:%@ %@", "❌", !group.isEmpty ? " [\(group)]" : "", message))
        case .warn:
            logMessage(String(format: "%@ WARN:%@ %@", "⚠️", !group.isEmpty ? " [\(group)]" : "", message))
        case .info:
            logMessage(String(format: "%@ INFO:%@ %@", "ℹ️", !group.isEmpty ? " [\(group)]" : "", message))
        case .debug:
            logMessage(String(format: "%@ DEBUG:%@ %@", "📝", !group.isEmpty ? " [\(group)]" : "", message))
        default:
            logMessage(String(format: "%@ VERBOSE:%@ %@", "⏱️", !group.isEmpty ? " [\(group)]" : "", message))
        }
    }
    
    private func logMessage(_ message: String) {
        if logHandler != nil {
            logHandler?(message)
            return
        }
        
        #if DEBUG
        // DEBUG模式时兼容FWDebug等组件
        let debugClass = NSClassFromString("FWDebugManager") as? NSObject.Type
        let instanceSelector = NSSelectorFromString("sharedInstance")
        let logSelector = NSSelectorFromString("systemLog:")
        if let debugClass = debugClass,
           debugClass.responds(to: instanceSelector),
           let debugManager = debugClass.perform(instanceSelector)?.takeUnretainedValue(),
           debugManager.responds(to: logSelector) {
            _ = debugManager.perform(logSelector, with: message)
            return
        }
        #endif
        
        NSLog("%@", message)
    }
    
}

/// OSLog日志插件
public class LoggerPluginOSLog: NSObject, LoggerPlugin, @unchecked Sendable {
    
    @objc(sharedInstance)
    public static let shared = LoggerPluginOSLog()
    
    private var log: OSLog
    
    /// 指定OSLog初始化，默认default
    public init(log: OSLog = .default) {
        self.log = log
        super.init()
    }
    
    /// 记录日志协议方法
    public func log(_ type: LogType, group: String, message: String) {
        switch type {
        case .error:
            os_log("%@ ERROR:%@ %@", log: log, type: .error, "❌", !group.isEmpty ? " [\(group)]" : "", message)
        case .warn:
            os_log("%@ WARN:%@ %@", log: log, type: .default, "⚠️", !group.isEmpty ? " [\(group)]" : "", message)
        case .info:
            os_log("%@ INFO:%@ %@", log: log, type: .info, "ℹ️", !group.isEmpty ? " [\(group)]" : "", message)
        case .debug:
            os_log("%@ DEBUG:%@ %@", log: log, type: .debug, "📝", !group.isEmpty ? " [\(group)]" : "", message)
        default:
            os_log("%@ VERBOSE:%@ %@", log: log, type: .debug, "⏱️", !group.isEmpty ? " [\(group)]" : "", message)
        }
    }
    
}

// MARK: - LoggerPluginImpl
/// 日志插件管理器，默认使用NSLog
public class LoggerPluginImpl: NSObject, LoggerPlugin, @unchecked Sendable {
    
    /// 单例模式对象
    @objc(sharedInstance)
    public static let shared = LoggerPluginImpl()
    
    private class Target {
        var logger: LoggerPlugin
        var level: LogLevel
        
        init(logger: LoggerPlugin, level: LogLevel) {
            self.logger = logger
            self.level = level
        }
    }
    
    private var allTargets: [Target] = []
    
    /// 初始化方法，默认使用NSLog
    public override init() {
        super.init()
        addLogger(LoggerPluginNSLog.shared)
    }
    
    /// 添加日志插件，并在指定等级生效(默认all)
    public func addLogger(_ logger: LoggerPlugin, level: LogLevel = .all) {
        allTargets.append(Target(logger: logger, level: level))
    }
    
    /// 移除指定日志插件
    public func removeLogger<T: LoggerPlugin>(_ logger: T) where T : Equatable {
        allTargets.removeAll { target in
            guard let obj = target.logger as? T else { return false }
            return logger == obj
        }
    }
    
    /// 移除所有的日志插件
    public func removeAllLoggers() {
        allTargets.removeAll()
    }
    
    /// 记录日志协议方法
    public func log(_ type: LogType, group: String, message: String) {
        allTargets.forEach { target in
            if LogType(rawValue: target.level.rawValue).contains(type) {
                target.logger.log(type, group: group, message: message)
            }
        }
    }
    
}
