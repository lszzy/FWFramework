//
//  Promise+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/30.
//

import Foundation

extension WrapperGlobal {
    
    /// 仿协程异步执行方法
    @discardableResult
    public static func async(_ block: @escaping () throws -> Any?) -> Promise {
        return Promise.async(block)
    }

    /// 仿协程同步返回结果
    @discardableResult
    public static func await(_ promise: Promise) throws -> Any? {
        return try Promise.await(promise)
    }
    
}
