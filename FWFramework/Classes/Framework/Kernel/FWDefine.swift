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
    FWBenchmark.benchmarkBegin(name)
}

/// 标记时间调试结束并打印消耗时间
///
/// - Parameter name: 调试标签，默认空字符串
/// - Returns: 消耗时间
@discardableResult
public func FWBenchmarkEnd(_ name: String = "") -> TimeInterval {
    return FWBenchmark.benchmarkEnd(name)
}
