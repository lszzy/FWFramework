//
//  FWLog.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/28.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
#if FWFrameworkSPM
import FWFramework
#endif

/// 记录跟踪日志
///
/// - Parameters:
///   - format: 格式化字符串
///   - arguments: 可变参数列表，可不传
///   - file: 文件名，默认传参
///   - function: 方法名，默认传参
///   - line: 行数，默认传参
public func FWLogTrace(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
    if !FWLog.check(.trace) { return }
    FWLog.log(with: .trace, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
}

/// 记录调试日志
///
/// - Parameters:
///   - format: 格式化字符串
///   - arguments: 可变参数列表，可不传
///   - file: 文件名，默认传参
///   - function: 方法名，默认传参
///   - line: 行数，默认传参
public func FWLogDebug(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
    if !FWLog.check(.debug) { return }
    FWLog.log(with: .debug, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
}

/// 记录信息日志
///
/// - Parameters:
///   - format: 格式化字符串
///   - arguments: 可变参数列表，可不传
///   - file: 文件名，默认传参
///   - function: 方法名，默认传参
///   - line: 行数，默认传参
public func FWLogInfo(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
    if !FWLog.check(.info) { return }
    FWLog.log(with: .info, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
}

/// 记录警告日志
///
/// - Parameters:
///   - format: 格式化字符串
///   - arguments: 可变参数列表，可不传
///   - file: 文件名，默认传参
///   - function: 方法名，默认传参
///   - line: 行数，默认传参
public func FWLogWarn(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
    if !FWLog.check(.warn) { return }
    FWLog.log(with: .warn, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
}

/// 记录错误日志
///
/// - Parameters:
///   - format: 格式化字符串
///   - arguments: 可变参数列表，可不传
///   - file: 文件名，默认传参
///   - function: 方法名，默认传参
///   - line: 行数，默认传参
public func FWLogError(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
    if !FWLog.check(.error) { return }
    FWLog.log(with: .error, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
public func FWLogGroup(_ group: String, type: FWLogType, format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
    if !FWLog.check(type) { return }
    FWLog.log(with: type, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)), group: group, userInfo: nil)
}

/// FWLog扩展
extension FWLog {
    /// 记录跟踪日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func trace(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
        if !FWLog.check(.trace) { return }
        log(with: .trace, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
        if !FWLog.check(.debug) { return }
        log(with: .debug, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
        if !FWLog.check(.info) { return }
        log(with: .info, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
        if !FWLog.check(.warn) { return }
        log(with: .warn, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
        if !FWLog.check(.error) { return }
        log(with: .error, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
    public class func group(_ group: String, type: FWLogType, format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
        if !FWLog.check(type) { return }
        log(with: type, message: String(format: "(%@ %@ #%d %@) %@", Thread.isMainThread ? "[M]" : "[T]", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)), group: group, userInfo: nil)
    }
}