//
//  Foundation.swift
//  FWFramework
//
//  Created by wuyong on 2020/10/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

// MARK: - Data+Foundation
extension Wrapper where Base == Data {
    /// 使用NSKeyedArchiver压缩对象
    public static func archiveObject(_ object: Any) -> Data? {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
        return data
    }
    
    /// 使用NSKeyedUnarchiver解压数据
    public func unarchiveObject<T>(_ clazz: T.Type) -> T? where T : NSObject, T : NSCoding {
        let object = try? NSKeyedUnarchiver.unarchivedObject(ofClass: clazz, from: self.base)
        return object
    }
    
    /// 保存对象归档
    public static func archiveObject(_ object: Any, file: String) -> Bool {
        guard let data = archiveObject(object) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: file))
            return true
        } catch {
            return false
        }
    }
    
    /// 读取对象归档
    public static func unarchiveObject<T>(_ clazz: T.Type, file: String) -> T? where T : NSObject, T : NSCoding {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else { return nil }
        return data.fw.unarchiveObject(clazz)
    }
}

// MARK: - Date+Foundation
extension Wrapper where Base == Date {
    /// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
    public static var currentTime: TimeInterval {
        get { return NSDate.__fw_currentTime }
        set { NSDate.__fw_currentTime = newValue }
    }
    
    /// 从字符串初始化日期，自定义格式(默认yyyy-MM-dd HH:mm:ss)和时区(默认当前时区)
    public static func date(string: String, format: String = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone? = nil) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        if let timeZone = timeZone {
            formatter.timeZone = timeZone
        }
        let date = formatter.date(from: string)
        return date
    }
    
    /// 转化为字符串，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
    public var stringValue: String {
        return string(format: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// 转化为字符串，自定义格式和时区
    public func string(format: String, timeZone: TimeZone? = nil) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        if let timeZone = timeZone {
            formatter.timeZone = timeZone
        }
        let string = formatter.string(from: self.base)
        return string
    }
    
    /// 格式化时长，格式"00:00"或"00:00:00"
    public static func formatDuration(_ duration: TimeInterval, hasHour: Bool) -> String {
        var seconds = Int64(duration)
        if hasHour {
            var minute = seconds / 60
            let hour = minute / 60
            seconds -= minute * 60
            minute -= hour * 60
            return String(format: "%02d:%02d:%02d", hour, minute, seconds)
        } else {
            let minute = seconds / 60
            let second = seconds % 60
            return String(format: "%02ld:%02ld", minute, second)
        }
    }
    
    /// 格式化16位、13位时间戳为10位(秒)
    public static func formatTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        return NSDate.__fw_formatTimestamp(timestamp)
    }
}

// MARK: - String+Foundation
extension Wrapper where Base == String {
    /// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
    public func size(font: UIFont, drawSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), attributes: [NSAttributedString.Key: Any]? = nil) -> CGSize {
        var attr: [NSAttributedString.Key: Any] = [:]
        attr[.font] = font
        if let attributes = attributes {
            attr.merge(attributes) { _, last in last }
        }
        
        let str = self.base as NSString
        let size = str.boundingRect(with: drawSize, options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attr, context: nil).size
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }
    
    /// 格式化文件大小为".0K/.1M/.1G"
    public static func sizeString(_ aFileSize: UInt) -> String {
        guard aFileSize > 0 else { return "0K" }
        var fileSize = Double(aFileSize) / 1024
        if fileSize >= 1024 {
            fileSize = fileSize / 1024
            if fileSize >= 1024 {
                fileSize = fileSize / 1024
                return String(format: "%0.1fG", fileSize)
            } else {
                return String(format: "%0.1fM", fileSize)
            }
        } else {
            return String(format: "%dK", Int(ceil(fileSize)))
        }
    }
    
    /// 是否匹配正则表达式，示例：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
    public func matchesRegex(_ regex: String) -> Bool {
        let regexPredicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return regexPredicate.evaluate(with: self.base)
    }
}

// MARK: - NSAttributedString+Foundation
/// 如果需要实现行内图片可点击效果，可使用UITextView添加附件或Link并实现delegate.shouldInteractWith方法即可
extension Wrapper where Base: NSAttributedString {
    
    /// NSAttributedString对象转换为html字符串
    public func htmlString() -> String? {
        return base.__fw_htmlString()
    }

    /// 计算所占尺寸，需设置Font等
    public var textSize: CGSize {
        return base.__fw_textSize
    }

    /// 计算在指定绘制区域内所占尺寸，需设置Font等
    public func textSize(drawSize: CGSize) -> CGSize {
        return base.__fw_textSize(withDraw: drawSize)
    }
    
    /// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
    public static func attributedString(htmlString: String) -> Base? {
        return Base.__fw_attributedString(withHtmlString: htmlString)
    }

    /// 图片转换为NSAttributedString对象，可实现行内图片样式。其中bounds.x会设置为间距，y常用算法：(font.capHeight - image.size.height) / 2.0
    public static func attributedString(image: UIImage?, bounds: CGRect) -> NSAttributedString {
        return Base.__fw_attributedString(with: image, bounds: bounds)
    }
    
}

// MARK: - NSObject+Foundation
extension Wrapper where Base: NSObject {
    
    /// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
    public func lock() {
        base.__fw_lock()
    }

    /// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
    public func unlock() {
        base.__fw_unlock()
    }
    
}

// MARK: - UserDefaults+Foundation
extension Wrapper where Base: UserDefaults {
    
    /// 从standard读取对象，支持unarchive对象
    public static func object(forKey: String) -> Any? {
        return Base.__fw_object(forKey: forKey)
    }

    /// 保存对象到standard，支持archive对象
    public static func setObject(_ object: Any?, forKey: String) {
        Base.__fw_setObject(object, forKey: forKey)
    }
    
    /// 读取对象，支持unarchive对象
    public func object(forKey: String) -> Any? {
        return base.__fw_object(forKey: forKey)
    }

    /// 保存对象，支持archive对象
    public func setObject(_ object: Any?, forKey: String) {
        base.__fw_setObject(object, forKey: forKey)
    }
    
}
