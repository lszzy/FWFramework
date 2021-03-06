//
//  FWDefine.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 标记时间调试开始
///
/// - Parameter name: 调试标签，默认空字符串
public func FWBenchmarkBegin(_ name: String = "") {
    FWBenchmark.begin(name)
}

/// 标记时间调试结束并打印消耗时间
///
/// - Parameter name: 调试标签，默认空字符串
/// - Returns: 消耗时间
@discardableResult
public func FWBenchmarkEnd(_ name: String = "") -> TimeInterval {
    return FWBenchmark.end(name)
}

/// 时间调试器
@objcMembers public class FWBenchmark: NSObject {
    private static var times: [String : TimeInterval] = [:]
    
    /// 标记时间调试开始
    public static func begin(_ name: String) {
        times[name] = Date().timeIntervalSince1970
    }
    
    /// 标记时间调试结束并打印消耗时间
    public static func end(_ name: String) -> TimeInterval {
        let beginTime = times[name] ?? Date().timeIntervalSince1970
        let timeInterval = Date().timeIntervalSince1970 - beginTime
        NSLog("FWBenchmark-%@: %.3fms", name, timeInterval * 1000)
        return timeInterval
    }
}
