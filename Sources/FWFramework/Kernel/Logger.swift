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
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public static func verbose(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.verbose) { return }
        Logger.log(.verbose, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 记录调试日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public static func debug(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.debug) { return }
        Logger.log(.debug, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 记录信息日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public static func info(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.info) { return }
        Logger.log(.info, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 记录警告日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public static func warn(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.warn) { return }
        Logger.log(.warn, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 记录错误日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public static func error(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(.error) { return }
        Logger.log(.error, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 记录类型日志
    ///
    /// - Parameters:
    ///   - type: 日志类型
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public static func log(
        type: LogType,
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !Logger.check(type) { return }
        Logger.log(type, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
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
    private actor Configuration {
        static var level: LogLevel = {
            #if DEBUG
            .all
            #else
            .off
            #endif
        }()
    }

    /// 全局日志级别，默认调试为All，正式为Off
    public static var level: LogLevel {
        get { Configuration.level }
        set { Configuration.level = newValue }
    }

    /// 记录类型日志，支持分组和用户信息
    /// - Parameters:
    ///   - type: 日志类型
    ///   - group: 日志分组，默认空
    ///   - message: 日志消息
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public class func log(
        _ type: LogType,
        group: String = "",
        message: String,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        // 过滤不支持的级别
        if !check(type) { return }
        
        var thread = Thread.current.name ?? ""
        if thread.isEmpty {
            if Thread.isMainThread {
                thread = "main"
            } else {
                var threadId: __uint64_t = 0
                if pthread_threadid_np(nil, &threadId) == 0 {
                    thread = String(format: "%llu", threadId)
                }
            }
        }
        
        let logMessage = LogMessage()
        logMessage.message = message
        logMessage.type = type
        logMessage.group = group
        logMessage.metadata = metadata
        logMessage.thread = thread
        logMessage.file = (file as NSString).lastPathComponent
        logMessage.line = line
        logMessage.function = function
        
        let plugin = PluginManager.loadPlugin(LoggerPlugin.self) ?? LoggerPluginImpl.shared
        plugin.log(logMessage)
    }

    /// 记录详细日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public class func verbose(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.verbose) { return }
        log(.verbose, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 记录调试日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public class func debug(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.debug) { return }
        log(.debug, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 记录信息日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public class func info(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.info) { return }
        log(.info, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 记录警告日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public class func warn(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.warn) { return }
        log(.warn, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 记录错误日志
    ///
    /// - Parameters:
    ///   - group: 日志分组，默认空
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - metadata: 日志附加metadata信息
    ///   - function: 方法名，默认传参
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public class func error(
        group: String = "",
        _ format: String,
        _ arguments: CVarArg...,
        metadata: [AnyHashable: Any]? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        if !check(.error) { return }
        log(.error, group: group, message: String(format: format, arguments: arguments), metadata: metadata, function: function, file: file, line: line)
    }

    /// 检查是否需要记录指定类型日志
    /// - Parameter type: 日志类型
    /// - Returns: 是否需要记录
    class func check(_ type: LogType) -> Bool {
        LogType(rawValue: level.rawValue).contains(type)
    }
}

// MARK: - LogMessage
/// 日志消息结构体
public class LogMessage {
    /// 日志消息
    public var message: String = ""
    /// 日志时间戳
    public var timestamp: TimeInterval = Date().timeIntervalSince1970
    /// 日志类型
    public var type: LogType = .info
    /// 日志分组，默认空
    public var group: String = ""
    /// 附加metadata信息
    public var metadata: [AnyHashable: Any]?
    /// 线程名称
    public var thread: String = ""
    /// 方法名
    public var function: String = ""
    /// 文件名
    public var file: String = ""
    /// 行数
    public var line: Int = -1
    
    public init() {}
}

// MARK: - LogFormatter
/// 日志格式化处理器协议
public protocol LogFormatter {
    /// 格式化日志消息
    func format(_ logMessage: LogMessage) -> String?
}

/// 默认日志格式化处理器实现
public class LogFormatterImpl: LogFormatter {
    public static let shared = LogFormatterImpl()
    
    public init() {}
    
    /// 格式化日志消息
    public func format(_ logMessage: LogMessage) -> String? {
        var typeName = ""
        var typeEmoji = ""
        switch logMessage.type {
        case .error:
            typeName = "ERROR"
            typeEmoji = "❌"
        case .warn:
            typeName = "WARN"
            typeEmoji = "⚠️"
        case .debug:
            typeName = "DEBUG"
            typeEmoji = "📝"
        case .verbose:
            typeName = "VERBOSE"
            typeEmoji = "⏱️"
        default:
            typeName = "INFO"
            typeEmoji = "ℹ️"
        }
        
        let message = String(
            format: "%@ %@:%@ (%@%@%@%@) %@%@",
            typeEmoji,
            typeName,
            !logMessage.group.isEmpty ? " [\(logMessage.group)]" : "",
            !logMessage.thread.isEmpty ? "[\(logMessage.thread)] " : "",
            !logMessage.file.isEmpty ? "\(logMessage.file) " : "",
            logMessage.line >= 0 ? "#\(logMessage.line) " : "",
            logMessage.function,
            logMessage.message,
            logMessage.metadata != nil ? String(format: " %@", logMessage.metadata!) : ""
        )
        return message
    }
}

// MARK: - LoggerPlugin
/// 日志插件协议
public protocol LoggerPlugin {
    /// 记录日志协议方法
    func log(_ logMessage: LogMessage)
}

/// NSLog日志插件，兼容FWDebug等组件
public class LoggerPluginNSLog: NSObject, LoggerPlugin, @unchecked Sendable {
    @objc(sharedInstance)
    public static let shared = LoggerPluginNSLog()

    /// 自定义日志格式化处理器
    public var logFormatter: LogFormatter?
    /// 自定义日志处理句柄
    public var logHandler: ((String) -> Void)?
    
    /// 自定义日期格式化
    public lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return dateFormatter
    }()

    /// 记录日志协议方法
    public func log(_ logMessage: LogMessage) {
        let formatter = logFormatter ?? LogFormatterImpl.shared
        guard let message = formatter.format(logMessage), !message.isEmpty else { return }
        
        if logHandler != nil {
            logHandler?(message)
            return
        }

        #if DEBUG
        // DEBUG模式时兼容FWDebug等组件
        let debugClass = NSClassFromString("FWDebugManager") as? NSObject.Type
        let instanceSelector = NSSelectorFromString("sharedInstance")
        let logSelector = NSSelectorFromString("systemLog:")
        if let debugClass,
           debugClass.responds(to: instanceSelector),
           let debugManager = debugClass.perform(instanceSelector)?.takeUnretainedValue(),
           debugManager.responds(to: logSelector) {
            _ = debugManager.perform(logSelector, with: message)
            return
        }
        #endif

        let timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: logMessage.timestamp))
        NSLog("%@: %@", timestamp, message)
    }
}

/// OSLog日志插件
public class LoggerPluginOSLog: NSObject, LoggerPlugin, @unchecked Sendable {
    @objc(sharedInstance)
    public static let shared = LoggerPluginOSLog()
    
    /// 自定义日志格式化处理器
    public var logFormatter: LogFormatter?
    
    /// 自定义日期格式化
    public lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return dateFormatter
    }()

    private var log: OSLog

    /// 指定OSLog初始化，默认default
    public init(log: OSLog = .default) {
        self.log = log
        super.init()
    }

    /// 记录日志协议方法
    public func log(_ logMessage: LogMessage) {
        let formatter = logFormatter ?? LogFormatterImpl.shared
        guard let message = formatter.format(logMessage), !message.isEmpty else { return }
        
        let timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: logMessage.timestamp))
        switch logMessage.type {
        case .error:
            os_log("%@: %@", log: log, type: .error, timestamp, message)
        case .warn:
            os_log("%@: %@", log: log, type: .default, timestamp, message)
        case .debug:
            os_log("%@: %@", log: log, type: .debug, timestamp, message)
        case .verbose:
            os_log("%@: %@", log: log, type: .debug, timestamp, message)
        default:
            os_log("%@: %@", log: log, type: .info, timestamp, message)
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
        var groups: [String] = []

        init(logger: LoggerPlugin, level: LogLevel, groups: [String]) {
            self.logger = logger
            self.level = level
            self.groups = groups
        }
    }

    private var allTargets: [Target] = []

    /// 初始化方法，默认使用NSLog
    override public init() {
        super.init()
        addLogger(LoggerPluginNSLog.shared)
    }

    /// 添加日志插件，并在指定等级(默认all)和指定分组(默认所有)生效
    public func addLogger(_ logger: LoggerPlugin, level: LogLevel = .all, groups: [String] = []) {
        allTargets.append(Target(logger: logger, level: level, groups: groups))
    }

    /// 移除指定日志插件
    public func removeLogger<T: LoggerPlugin>(_ logger: T) where T: Equatable {
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
    public func log(_ logMessage: LogMessage) {
        for target in allTargets {
            guard LogType(rawValue: target.level.rawValue).contains(logMessage.type) else { continue }
            guard target.groups.isEmpty || target.groups.contains(logMessage.group) else { continue }
            target.logger.log(logMessage)
        }
    }
}
