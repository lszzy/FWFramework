//
//  FWFoundation.swift
//  FWFramework
//
//  Created by wuyong on 2020/10/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation
import UIKit

extension Data {
    /// 使用NSKeyedArchiver压缩对象
    public static func fwArchiveObject(_ object: Any) -> Data? { return NSData.fwArchiveObject(object) }
    /// 使用NSKeyedUnarchiver解压数据
    public func fwUnarchiveObject() -> Any? { return fwNSData.fwUnarchiveObject() }
    /// 保存对象归档
    public static func fwArchiveObject(_ object: Any, file: String) { NSData.fwArchiveObject(object, toFile: file) }
    /// 读取对象归档
    public static func fwUnarchiveObject(file: String) -> Any? { return NSData.fwUnarchiveObject(withFile:file) }
}

extension Date {
    /// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
    public static var fwCurrentTime: TimeInterval { return NSDate.fwCurrentTime }
    /// 从字符串初始化日期，自定义格式(默认yyyy-MM-dd HH:mm:ss)和时区(默认当前时区)
    public static func fwDate(string: String, format: String? = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone? = nil) -> Date? { return NSDate.fwDate(with: string) }
    /// 转化为字符串，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
    public var fwStringValue: String { return fwNSDate.fwStringValue }
    /// 转化为字符串，自定义格式和时区
    public func fwString(format: String?, timeZone: TimeZone? = nil) -> String { return fwNSDate.fwString(withFormat: format, timeZone: timeZone) }
    /// 格式化时长，格式"00:00"或"00:00:00"
    public static func fwFormatDuration(_ duration: TimeInterval, hasHour: Bool) -> String { return NSDate.fwFormatDuration(duration, hasHour: hasHour) }
}

extension String {
    /// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
    public func fwSize(font: UIFont, drawSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), attributes: [NSAttributedString.Key: Any]? = nil) -> CGSize { return fwNSString.fwSize(with: font, draw: drawSize, attributes: attributes) }
    /// 格式化文件大小为".0K/.1M/.1G"
    public static func fwSizeString(_ fileSize: UInt) -> String { return NSString.fwSizeString(fileSize) }
    /// 是否匹配正则表达式，示例：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
    public func fwMatchesRegex(_ regex: String) -> Bool { return fwNSString.fwMatchesRegex(regex) }
}
