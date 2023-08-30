//
//  Singleton.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

/// 单例模式协议
public protocol SingletonProtocol {
    
    /// 单例对象
    static var shared: Self { get }
    
    /// 实例初始化方法
    init()
    
    /// 单例初始化钩子方法
    func setupSingleton()
    
}

extension SingletonProtocol where Self: WrapperObject {
    
    /// 默认实现单例对象，NSObject子类可直接调用
    public static var shared: Self {
        return fw_synchronized {
            if let instance = self.fw_property(forName: #function) as? Self {
                return instance
            } else {
                let instance = self.init()
                self.fw_setProperty(instance, forName: #function)
                instance.setupSingleton()
                return instance
            }
        }
    }
    
    /// 默认实现单例初始化钩子方法
    public func setupSingleton() {}
    
}
