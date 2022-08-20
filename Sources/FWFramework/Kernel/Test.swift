//
//  Test.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation

// 仅调试环境开启
#if DEBUG

// MARK: - TestCase
/// 单元测试基类，测试方法需标记objc
open class TestCase: NSObject {
    
    // MARK: - Accessor
    var assertError: NSError?
    
    var assertAsync = false
    
    var assertSemaphore: DispatchSemaphore?
    
    // MARK: - Lifecycle
    /// 测试初始化，每次执行测试方法开始都会调用
    open func setUp() {}
    
    /// 测试收尾，每次执行测试方法结束都会调用
    open func tearDown() {}
    
    // MARK: - Public
    /// 同步断言方法
    ///
    /// - Parameters:
    ///   - value: 断言值
    ///   - expression: 断言表达式
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public func assertTrue(_ value: Bool, _ expression: String = "", file: String = #file, line: Int = #line) {
        if value { return }
        
        assertAsync = false
        assertError = NSError(domain: "FWFramework.Test", code: 2001, userInfo: [
            "expression": expression,
            "file": (file as NSString).lastPathComponent,
            "line": line,
        ])
    }
    
    /// 异步断言开始
    public func assertBegin() {
        assertSemaphore = DispatchSemaphore(value: 0)
    }
    
    /// 异步断言方法，一个异步周期仅支持一次异步断言
    ///
    /// - Parameters:
    ///   - value: 断言值
    ///   - expression: 断言表达式
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    public func assertAsync(_ value: Bool, _ expression: String = "", file: String = #file, line: Int = #line) {
        assertTrue(value, expression, file: file, line: line)
        assertAsync = true
        assertSemaphore?.signal()
    }
    
    /// 异步断言结束
    public func assertEnd() {
        assertSemaphore?.wait()
    }
    
}

// MARK: - UnitTest
class UnitTest: NSObject, AutoloadProtocol {
    
    static var shared = UnitTest()
    
    // MARK: - Accessor
    private var testCases: [TestCase.Type] = []
    
    private var testLogs: String?
    
    // MARK: - Lifecycle
    
    // MARK: - AutoloadProtocol
    static func autoload() {
        DispatchQueue.main.async {
            
        }
    }
    
}

#endif
