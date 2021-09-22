//
//  FWTest.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

// 调试环境开启，正式环境关闭
#if DEBUG

// MARK: - FWTestCase

/// FWTestCase扩展，注意测试方法需标记@objc，让OC可以访问
extension FWTestCase {
    /// 断言方法
    ///
    /// - Parameters:
    ///   - value: 断言表达式
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public func assertTrue(_ value: Bool, _ expression: String = "", file: String = #file, line: Int = #line) {
        assertTrue(value, expression: expression, file: file, line: line)
    }
}

#endif
