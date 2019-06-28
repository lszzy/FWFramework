//
//  NSBundle+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 读取本地化字符串
///
/// 解决Xcode中swift项目不能运行9.3及以下模拟器问题：sudo mkdir '/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 9.3.simruntime/Contents/Resources/RuntimeRoot/usr/lib/swift'
///
/// - Parameters:
///   - key: 本地化键名
///   - table: 本地化表名，默认Localizable.strings
/// - Returns: 本地化字符串
public func FWLocalizedString(_ key: String, _ table: String? = nil) -> String {
    return Bundle.main.localizedString(forKey: key, value: nil, table: table)
}
