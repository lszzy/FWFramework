//
//  Mediator.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - FW+Mediator
extension FW {
    
    /// 中间件快速访问
    public static var mediator = Mediator.self
    
    /// 插件快速访问
    public static var plugin = PluginManager.self
    
    /// 路由快速访问
    public static var router = Router.self
    
}
