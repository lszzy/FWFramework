//
//  Benchmark+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/30.
//

import Foundation

extension WrapperGlobal {
    
    /// 标记时间调试开始
    ///
    /// - Parameter name: 调试标签，默认空字符串
    public static func begin(_ name: String = "") {
        Benchmark.begin(name)
    }

    /// 标记时间调试结束并打印消耗时间
    ///
    /// - Parameter name: 调试标签，默认空字符串
    /// - Returns: 消耗时间
    @discardableResult
    public static func end(_ name: String = "") -> TimeInterval {
        return Benchmark.end(name)
    }
    
}
