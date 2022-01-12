//
//  FWLanguage.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 读取本地化字符串
///
/// - Parameters:
///   - key: 本地化键名
///   - table: 本地化表名，默认Localizable.strings
/// - Returns: 本地化字符串
public func FWLocalizedString(_ key: String, _ table: String? = nil) -> String {
    return Bundle.fwLocalizedString(key, table: table)
}

/// String本地化语言扩展
extension String {
    /// 快速读取本地化语言
    public var fwLocalized: String {
        return Bundle.fwLocalizedString(self)
    }
    
    /// 快速读取本地化语言，指定Bundle
    /// - Parameter bundle: 语言所在Bundle，默认主Bundle
    /// - Returns: 本地化字符串
    public func fwLocalized(_ bundle: Bundle?) -> String {
        return Bundle.fwLocalizedString(self, bundle: bundle)
    }
    
    /// 快速读取本地化语言，指定表名和Bundle
    /// - Parameters:
    ///   - table: 本地化表名，默认Localizable.strings
    ///   - bundle: 语言所在Bundle，默认主Bundle
    /// - Returns: 本地化字符串
    public func fwLocalized(_ table: String?, _ bundle: Bundle? = nil) -> String {
        return Bundle.fwLocalizedString(self, table: table, bundle: bundle)
    }
}
