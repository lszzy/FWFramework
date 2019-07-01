//
//  FWLog.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/28.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 记录日志内部方法
///
/// - Parameters:
///   - type: 日志类型
///   - format: 格式化字符串
///   - arguments: 可变参数数组
///   - file: 文件名
///   - function: 方法名
///   - line: 行数
private func FWLogType_(_ type: FWLogType, _ format: String, _ arguments: [CVarArg], file: String, function: String, line: Int) {
    if FWLog.level.rawValue & type.rawValue != 0 {
        FWLog.log(type, withMessage: String(format: "(%@ #%d %@) %@", (file as NSString).lastPathComponent, line, function, String(format: format, arguments: arguments)))
    }
}

/// 记录详细日志
///
/// - Parameters:
///   - format: 格式化字符串
///   - arguments: 可变参数列表，可不传
///   - file: 文件名，默认传参
///   - function: 方法名，默认传参
///   - line: 行数，默认传参
public func FWLogVerbose(_ format: String, _ arguments: CVarArg..., file: String = #file, function: String = #function, line: Int = #line) {
    FWLogType_(.verbose, format, arguments, file: file, function: function, line: line)
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
    FWLogType_(.debug, format, arguments, file: file, function: function, line: line)
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
    FWLogType_(.info, format, arguments, file: file, function: function, line: line)
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
    FWLogType_(.warn, format, arguments, file: file, function: function, line: line)
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
    FWLogType_(.error, format, arguments, file: file, function: function, line: line)
}
