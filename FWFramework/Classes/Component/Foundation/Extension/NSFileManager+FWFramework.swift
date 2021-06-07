//
//  NSFileManager+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/28.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 搜索路径
///
/// - Parameter directory: 搜索目录
/// - Returns: 目标路径
public func FWPathSearch(_ directory: FileManager.SearchPathDirectory) -> String {
    return NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true)[0]
}

/// 沙盒路径，常量
public var FWPathHome: String {
    return NSHomeDirectory()
}

/// 文档路径，iTunes会同步备份
public var FWPathDocument: String {
    return FWPathSearch(.documentDirectory)
}

/// 缓存路径，系统不会删除，iTunes会删除
public var FWPathCaches: String {
    return FWPathSearch(.cachesDirectory)
}

/// Library路径
public var FWPathLibrary: String {
    return FWPathSearch(.libraryDirectory)
}

/// 配置路径，配置文件保存位置
public var FWPathPreference: String {
    return (FWPathLibrary as NSString).appendingPathComponent("Preference")
}

/// 临时路径，App退出后可能会删除
public var FWPathTmp: String {
    return NSTemporaryDirectory()
}

/// bundle路径，不可写
public var FWPathBundle: String {
    return Bundle.main.bundlePath
}

/// 资源路径，不可写
public var FWPathResource: String {
    return Bundle.main.resourcePath ?? ""
}
