//
//  NetworkPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

/// 默认网络插件
open class NetworkPluginImpl: NSObject, NetworkPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = NetworkPluginImpl()
    
    // MARK: - NetworkPlugin
    
    
}
