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
extension FWTestCase {
    
    /// 断言方法
    ///
    /// - Parameters:
    ///   - value: 断言表达式
    ///   - file: 文件名，默认传参
    ///   - function: 方法名，默认传参
    ///   - line: 行数，默认传参
    public func assertTrue(_ value: Bool, file: String = #file, function: String = #function, line: Int = #line) {
        assertTrue(value, expression: function, file: file, line: line)
    }
    
}

// MARK: - Test
class FWTestCase_FWTest_Swift: FWTestCase {
    private var value: Int = 0
    
    public override func setUp() {
        // 重置资源
        value = 0
    }
    
    public override func tearDown() {
        // 释放资源
    }
    
    @objc func testPlus() {
        self.assertTrue(value + 1 == 1)
    }
    
    @objc func testMinus() {
        self.assertTrue(value - 1 == -1)
    }
}

#endif
