//
//  Logger.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation
import os
#if FWMacroSPM
import FWObjC
#endif

// MARK: - FW+Logger
extension FW {
    
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
        file: String = #file,
        function: String = #function,
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
        file: String = #file,
        function: String = #function,
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
        file: String = #file,
        function: String = #function,
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
        file: String = #file,
        function: String = #function,
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
        file: String = #file,
        function: String = #function,
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
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !Logger.check(type) { return }
        Logger.log(type, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
    
}

// MARK: - Logger
/// 日志类型枚举
public struct LogType: OptionSet {
    
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
public struct LogLevel: RawRepresentable, Equatable, Hashable {
    
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
        return LogType(rawValue: level.rawValue).contains(type)
    }
    
    /// 记录类型日志，支持分组和用户信息
    /// - Parameters:
    ///   - type: 日志类型
    ///   - group: 日志分组，默认空
    ///   - message: 日志消息
    public class func log(_ type: LogType, group: String = "", message: String) {
        // 过滤不支持的级别
        if !check(type) { return }
        
        var plugin: LoggerPlugin
        if let loggerPlugin = PluginManager.loadPlugin(LoggerPlugin.self) {
            plugin = loggerPlugin
        } else {
            plugin = LoggerPluginImpl.shared
        }
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
        file: String = #file,
        function: String = #function,
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
        file: String = #file,
        function: String = #function,
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
        file: String = #file,
        function: String = #function,
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
        file: String = #file,
        function: String = #function,
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
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if !check(.error) { return }
        log(.error, group: group, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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

// MARK: - LoggerPluginImpl
/// 默认NSLog日志插件
public class LoggerPluginImpl: NSObject, LoggerPlugin {
    
    /// 单例模式对象
    @objc(sharedInstance)
    public static let shared = LoggerPluginImpl()
    
    /// 记录日志协议方法
    /// - Parameters:
    ///   - type: 日志类型
    ///   - group: 日志分组
    ///   - message: 日志消息
    public func log(_ type: LogType, group: String, message: String) {
        switch type {
        case .error:
            NSLog("%@ ERROR:%@ %@", "❌", !group.isEmpty ? " [\(group)]" : "", message)
        case .warn:
            NSLog("%@ WARN:%@ %@", "⚠️", !group.isEmpty ? " [\(group)]" : "", message)
        case .info:
            NSLog("%@ INFO:%@ %@", "ℹ️", !group.isEmpty ? " [\(group)]" : "", message)
        case .debug:
            NSLog("%@ DEBUG:%@ %@", "⏱️", !group.isEmpty ? " [\(group)]" : "", message)
        default:
            NSLog("%@ VERBOSE:%@ %@", "📝", !group.isEmpty ? " [\(group)]" : "", message)
        }
    }
    
}
