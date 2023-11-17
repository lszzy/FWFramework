//
//  AlamofireImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Foundation
import Alamofire
#if FWMacroSPM
import FWObjC
import FWFramework
#endif

// MARK: - AlamofireImpl
/// Alamofire请求插件，启用Alamofire子模块后生效
open class AlamofireImpl: NSObject, RequestPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = AlamofireImpl()
    
    // MARK: - RequestPlugin
    
}

// MARK: - Autoloader+AlamofireImpl
@objc extension Autoloader {
    
    static func loadVendor_Alamofire() {
        PluginManager.presetPlugin(RequestPlugin.self, object: AlamofireImpl.self)
    }
    
}
