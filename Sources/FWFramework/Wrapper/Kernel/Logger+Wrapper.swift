//
//  Logger+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/30.
//

import Foundation

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
