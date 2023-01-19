//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import UIKit

/// NSObject内部Swift桥接方法
@_spi(FW) extension NSObject {
    
    /// 记录内部分组调试日志
    @objc public static func __fw_logDebug(_ message: String) {
        Logger.log(.debug, group: "FWFramework", message: message)
    }
    
    /// 读取内部Bundle图片
    @objc public static func __fw_bundleImage(_ name: String) -> UIImage? {
        return AppBundle.imageNamed(name)
    }
    
    /// 读取内部Bundle多语言
    @objc public static func __fw_bundleString(_ key: String) -> String {
        return AppBundle.localizedString(key)
    }
    
}
