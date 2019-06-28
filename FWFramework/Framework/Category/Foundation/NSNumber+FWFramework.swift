//
//  NSNumber+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/28.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 确保值在固定范围之内
///
/// - Parameters:
///   - min: 最小值
///   - value: 当前值
///   - max: 最大值
/// - Returns: 范围之内的值
public func FWClamp<T: Comparable>(_ min: T, _ value: T, _ max: T) -> T {
    return value < min ? min : (value > max ? max : value)
}
