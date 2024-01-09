//
//  Codable+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/30.
//

import Foundation

extension WrapperGlobal {
    
    /// 安全字符串，不为nil
    public static func safeString(_ value: Any?) -> String {
        return String.fw_safeString(value)
    }

    /// 安全数字，不为nil
    public static func safeNumber(_ value: Any?) -> NSNumber {
        return NSNumber.fw_safeNumber(value)
    }

    /// 安全URL，不为nil，不兼容文件路径(需fileURLWithPath)
    public static func safeURL(_ value: Any?) -> URL {
        return URL.fw_safeURL(value)
    }
    
    /// 获取安全值
    public static func safeValue<T: BasicCodableType>(_ value: T?) -> T {
        return value.safeValue
    }

    /// 判断是否不为空
    public static func isNotEmpty<T: BasicCodableType>(_ value: T?) -> Bool {
        return value.isNotEmpty
    }
    
    /// 判断是否为nil，兼容嵌套Optional
    public static func isNil(_ value: Any?) -> Bool {
        return Optional<Any>.isNil(value)
    }
    
}
