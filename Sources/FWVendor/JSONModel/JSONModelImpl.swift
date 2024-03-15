//
//  JSONModelImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Foundation
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - JSONModelImpl
/// 可选JSONModel读写内存插件，不推荐使用，建议迁移至JSONMappable协议
@_spi(FW) public class JSONModelImpl: NSObject, JSONModelPlugin {
    
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = JSONModelImpl()
    
    // MARK: - JSONModelPlugin
    
}

// MARK: - JSONModel

// MARK: - Autoloader+JSONModelImpl
@objc extension Autoloader {
    
    static func loadVendor_JSONModel() {
        PluginManager.presetPlugin(JSONModelPlugin.self, object: JSONModelImpl.self)
    }
    
}
