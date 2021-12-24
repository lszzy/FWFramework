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
