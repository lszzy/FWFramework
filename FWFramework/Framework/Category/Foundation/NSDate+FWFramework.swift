//
//  NSDate+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 内部调试时间字典
private var FWBenchmarkTimes: [String: Date] = [:]

/// 标记时间调试开始
///
/// - Parameter name: 调试标签，默认空字符串
public func FWBenchmarkBegin(_ name: String = "")
{
    FWBenchmarkTimes[name] = Date()
}

/// 标记时间调试结束并打印消耗时间
///
/// - Parameter name: 调试标签，默认空字符串
public func FWBenchmarkEnd(_ name: String = "")
{
    let beginTime = FWBenchmarkTimes.removeValue(forKey: name) ?? Date()
    print(String(format: "FWBenchmark-%@: %.3fms", name, Date().timeIntervalSince1970 * 1000 - beginTime.timeIntervalSince1970 * 1000))
}
