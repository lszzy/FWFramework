//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation

/// NSObject内部Swift桥接方法
@_spi(FW) extension NSObject {
    
    /// 记录内部分组调试日志
    @objc public static func __fw_logDebug(_ message: String) {
        Logger.log(.debug, message: message, group: "FWFramework", userInfo: nil)
    }
    
}
