//
//  FWWrapper.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
#if FWFrameworkSPM
import FWFramework
#endif

// MARK: - FWWrapper
/// Swift包装器
public struct FWWrapper<T> {
    /// 原始对象
    public let base: T
    
    /// 初始化方法
    public init(_ base: T) {
        self.base = base
    }
}

// MARK: - FWAnyWrapper
/// 对象包装器协议
public protocol FWAnyWrapper { }

extension FWAnyWrapper {
    /// 对象包装器属性
    public var fw: FWWrapper<Self> {
        return FWWrapper(self)
    }
}

// MARK: - FWTypeWrapper
/// 类包装器协议
public protocol FWTypeWrapper { }

extension FWTypeWrapper {
    /// 类包装器属性
    public static var fw: FWWrapper<Self.Type> {
        return FWWrapper(self)
    }
}

// MARK: - FWAnyWrapper

extension String: FWAnyWrapper { }

// MARK: - FWTypeWrapper

extension String: FWTypeWrapper { }
