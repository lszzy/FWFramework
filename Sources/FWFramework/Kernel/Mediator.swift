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

extension FW {
    /// 中间件快速访问
    public static var mediator = Mediator.self
}

/*
/// 模块可扩展优先级
public struct ModulePriority: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = UInt
    
    public static let low: ModulePriority = .init(250)
    public static let `default`: ModulePriority = .init(500)
    public static let high: ModulePriority = .init(750)
    
    public var rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: UInt) {
        self.rawValue = rawValue
    }
    
}

/// 业务模块协议，各业务必须实现
@objc(__FWModuleProtocol)
public protocol ModuleProtocol: UIApplicationDelegate {
    
    /// 可选模块单例方法
    @objc optional static func moduleInstance() -> Self
    
    /// 模块初始化方法，默认不处理，setupAllModules自动调用
    @objc optional func setup()
    
    /// 是否主线程同步调用setup，默认为false，后台线程异步调用
    @objc optional static func setupSynchronously() -> Bool
    
    /// 模块优先级，0最低。默认为default优先级
    @objc optional static func priority() -> UInt
    
}
*/
