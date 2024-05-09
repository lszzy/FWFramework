//
//  Test.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation

// 调试环境开启，正式环境关闭
#if DEBUG

// MARK: - TestCase
/// 单元测试用例基类，所有单元测试用例必须继承。注意测试方法需标记objc，让OC可以访问
///
/// 调试模式下自动执行，按模块单元测试命名格式：TestCase_module_name
open class TestCase: NSObject {
    
    fileprivate var assertError: NSError?
    fileprivate var isAssertAsync = false
    private var assertSemaphore: DispatchSemaphore?
    
    /// 初始化方法
    required public override init() {
        super.init()
    }
    
    /// 测试初始化，每次执行测试方法开始都会调用
    open func setUp() {}
    
    /// 测试收尾，每次执行测试方法结束都会调用
    open func tearDown() {}
    
    /// 执行同步断言
    ///
    /// - Parameters:
    ///   - value: 断言表达式
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    open func assertTrue(_ value: Bool, _ expression: String = "", file: String = #file, line: Int = #line) {
        guard !value else { return }
        
        assertError = NSError(domain: "FWTest", code: 0, userInfo: [
            "expression": expression,
            "file": !file.isEmpty ? (file as NSString).lastPathComponent : "",
            "line": "\(line)"
        ])
        isAssertAsync = false
    }
    
    /// 异步断言开始
    open func assertBegin() {
        assertSemaphore = DispatchSemaphore(value: 0)
    }
    
    /// 执行异步断言并退出，一个异步周期仅支持一次异步断言
    ///
    /// - Parameters:
    ///   - value: 断言表达式
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    open func assertAsync(_ value: Bool, _ expression: String = "", file: String = #file, line: Int = #line) {
        assertTrue(value, expression, file: file, line: line)
        isAssertAsync = true
        assertSemaphore?.signal()
    }
    
    /// 异步断言结束
    open func assertEnd() {
        assertSemaphore?.wait()
    }
    
}

// MARK: - UnitTest
/// 单元测试启动器
fileprivate class UnitTest: NSObject {
    
    private static let shared = UnitTest()
    
    private var testCases: [AnyClass] = []
    private var testLogs: String?
    
    static func runTests() {
        DispatchQueue.main.async {
            let unitTest = UnitTest.shared
            unitTest.testCases.append(contentsOf: unitTest.testSuite())
            guard unitTest.testCases.count > 0 else { return }
            
            let queue = DispatchQueue(label: "site.wuyong.queue.test.async")
            queue.async {
                unitTest.run()
                Logger.debug(group: Logger.moduleName, "%@", unitTest.debugDescription)
            }
        }
    }
    
    private func testSuite() -> [AnyClass] {
        let testCases = NSObject.fw.allSubclasses(TestCase.self)
            .sorted { obj1, obj2 in
                return NSStringFromClass(obj1) < NSStringFromClass(obj2)
            }
        return testCases
    }
    
    private func testMethods(_ clazz: AnyClass) -> [String] {
        var methodNames: [String] = []
        let selectorNames = NSObject.fw.classMethods(clazz)
        for selectorName in selectorNames {
            if selectorName.hasPrefix("test"), !selectorName.contains(":") {
                methodNames.append(selectorName)
            }
        }
        return methodNames
    }
    
    private func run() {
        let testCases = self.testCases
        var failedCount: UInt = 0
        var succeedCount: UInt = 0
        var testLog = ""
        let beginTime = Date().timeIntervalSince1970
        self.testCases.removeAll()

        for classType in testCases {
            let classTime = Date().timeIntervalSince1970
            let formatClass = NSStringFromClass(classType)
                .replacingOccurrences(of: "TestCase_", with: "")
                .replacingOccurrences(of: "TestCase", with: "")
                .replacingOccurrences(of: "_", with: ".")
            var formatMethod = ""
            var formatMessage = ""
            let selectorNames = testMethods(classType)
            var testCasePassed = true
            let totalTestCount: UInt = UInt(selectorNames.count)
            var currentTestCount: UInt = 0
            var assertError: NSError?
            var assertAsync = false
            
            if let testClass = classType as? TestCase.Type, selectorNames.count > 0 {
                let testCase = testClass.init()
                for selectorName in selectorNames {
                    currentTestCount += 1
                    formatMethod = selectorName
                    let selector = NSSelectorFromString(selectorName)
                    if testCase.responds(to: selector) {
                        testCase.setUp()
                        testCase.perform(selector)
                        testCase.tearDown()
                        
                        assertError = testCase.assertError
                        assertAsync = testCase.isAssertAsync
                        if assertError != nil { break }
                    }
                }
            }
            
            if let assertError = assertError {
                let expression = assertError.userInfo["expression"] as? String ?? ""
                formatMessage = String(format: "- assert%@(%@); (%@ - %@ #%@)", assertAsync ? "Async" : "True", !expression.isEmpty ? expression : "false", formatMethod, assertError.userInfo["file"] as? String ?? "", assertError.userInfo["line"] as? String ?? "")
                testCasePassed = false
            }
            
            let time = Date().timeIntervalSince1970 - classTime
            let succeedTestCount = testCasePassed ? currentTestCount : (currentTestCount - 1)
            let classPassRate: Float = totalTestCount > 0 ? (Float(succeedTestCount) / Float(totalTestCount) * 100.0) : 100.0
            if testCasePassed {
                succeedCount += 1
                testLog += String(format: "%@. %@: %@ (%lu/%lu) (%.0f%%) (%.003fs)\n", NSNumber(value: succeedCount + failedCount), "✔️", formatClass, succeedTestCount, totalTestCount, classPassRate, time)
            } else {
                failedCount += 1
                testLog += String(format: "%@. %@: %@ (%lu/%lu) (%.0f%%) (%.003fs)\n", NSNumber(value: succeedCount + failedCount), "❌", formatClass, succeedTestCount, totalTestCount, classPassRate, time)
                testLog += String(format: "     %@\n", formatMessage)
            }
        }
        
        let totalTime = Date().timeIntervalSince1970 - beginTime
        let totalCount = succeedCount + failedCount
        let passRate: Float = totalCount > 0 ? (Float(succeedCount) / Float(totalCount) * 100.0) : 100.0
        let totalLog = String(format: "   %@: (%lu/%lu) (%.0f%%) (%.003fs)\n", failedCount < 1 ? "✔️" : "❌", succeedCount, totalCount, passRate, totalTime)
        self.testLogs = String(format: "\n========== TEST  ==========\n%@%@========== TEST  ==========", testLog, totalCount > 0 ? totalLog : "")
    }
    
    override var debugDescription: String {
        if let testLogs = testLogs { return testLogs }
        return super.debugDescription
    }
    
}

// MARK: - FrameworkAutoloader+Test
extension FrameworkAutoloader {
    
    @objc static func loadKernel_Test() {
        UnitTest.runTests()
    }
    
}

#endif
