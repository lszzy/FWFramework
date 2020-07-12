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

// MARK: - Test

class FWTestCase_FWTest_Swift: FWTestCase {
    private var value: Int = 0

    override func setUp() {
        // 重置资源
        value = 0
    }

    override func tearDown() {
        // 释放资源
    }

    @objc func testSync() {
        value += 1
        assertTrue(value == 1)
        value += 1
        assertTrue(value == 2)
    }

    @objc func testAsync() {
        var result = 0
        fwSyncPerformAsyncBlock { completionHanlder in
            DispatchQueue(label: "FWTestCase_FWTest_Swift").async {
                Thread.sleep(forTimeInterval: 0.1)
                result = 1
                completionHanlder()
            }
        }
        assertTrue(value + result == 1)
    }
}

#endif
