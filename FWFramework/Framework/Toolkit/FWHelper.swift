//
//  FWHelper.swift
//  FWFramework
//
//  Created by wuyong on 2020/12/1.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

/// UserDefault属性包装器
/// 使用示例：@FWUserDefault("userName", defaultValue: "test")
/// public static var userName: String
@propertyWrapper
public struct FWUserDefault<T> {
    let key: String
    let defaultValue: T
    
    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}
