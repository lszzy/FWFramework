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
    
    /// 单例初始化钩子方法
    func setupSingleton()
    
}

extension SingletonProtocol where Self: NSObject {
    
    /// 默认实现单例对象，NSObject子类可直接调用
    public static var shared: Self {
        var instance = self.fw_property(forName: "shared") as? Self
        if let instance = instance { return instance }
        
        fw_synchronized {
            if let object = self.fw_property(forName: "shared") as? Self {
                instance = object
            } else {
                instance = self.init()
                self.fw_setProperty(instance, forName: "shared")
                instance?.setupSingleton()
            }
        }
        return instance!
    }
    
    /// 默认实现单例初始化钩子方法
    public func setupSingleton() {}
    
}
