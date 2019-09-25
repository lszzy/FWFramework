//
//  FWLog.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/28.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 记录详细日志
///
/// - Parameters:
///   - format: 格式化字符串
///   - arguments: 可变参数列表，可不传
///   - file: 文件名，默认传参
///   - function: 方法名，默认传参
///   - line: 行数，默认传参
public func FWLogVerbose(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
    FWLog.log(.verbose, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
    FWLog.log(.debug, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
    FWLog.log(.info, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
    FWLog.log(.warn, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
    FWLog.log(.error, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
}

/// FWLog扩展
extension FWLog {
    /// 记录详细日志
    ///
    /// - Parameters:
    ///   - format: 格式化字符串
    ///   - arguments: 可变参数列表，可不传
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public class func verbose(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
        log(.verbose, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
        log(.debug, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
        log(.info, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
        log(.warn, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
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
        log(.error, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
}
