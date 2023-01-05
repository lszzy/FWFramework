//
//  Test.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// 调试环境开启，正式环境关闭
#if DEBUG

// MARK: - TestCase
/// 注意测试方法需标记objc，让OC可以访问
extension TestCase {
    
    /// 同步断言方法
    ///
    /// - Parameters:
    ///   - value: 断言表达式
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public func assertTrue(_ value: Bool, _ expression: String = "", file: String = #file, line: Int = #line) {
        assertTrue(value, expression: expression, file: file, line: line)
    }
    
    /// 异步断言方法
    ///
    /// - Parameters:
    ///   - value: 断言表达式
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public func assertAsync(_ value: Bool, _ expression: String = "", file: String = #file, line: Int = #line) {
        assertAsync(value, expression: expression, file: file, line: line)
    }
    
}

#endif
