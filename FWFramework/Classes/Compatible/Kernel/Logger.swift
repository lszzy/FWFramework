//
//  Logger.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/28.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
#if FWMacroSPM
import FWFramework
#endif

// MARK: - Wrapper+Logger
extension Wrapper {
    
    /// 记录跟踪日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public static func trace(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public static func debug(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public static func info(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public static func warn(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public static func error(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public static func group(_ group: String, type: LogType, format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
        if !Logger.check(type) { return }
        Logger.log(type, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)), group: group, userInfo: nil)
    }
    
}

// MARK: - Logger
extension Logger {
    
    /// 记录跟踪日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func trace(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public class func debug(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public class func info(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public class func warn(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public class func error(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
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
    public class func group(_ group: String, type: LogType, format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
        if !check(type) { return }
        log(type, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)), group: group, userInfo: nil)
    }
    
}
