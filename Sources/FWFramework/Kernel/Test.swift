//
//  Test.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation

// 调试环境开启，正式环境关闭
#if DEBUG

// MARK: - TestSuite
/// 可扩展测试套件，默认default
public struct TestSuite: RawRepresentable, Equatable, Hashable, Sendable {
    public typealias RawValue = String

    /// 默认测试套件，启动时自动调用
    public static let `default`: TestSuite = .init("default")

    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - TestCase
/// 单元测试用例基类，所有单元测试用例必须继承。注意测试方法需标记objc，让OC可以访问
///
/// 测试类命名建议模块+单元格式：TestCase_module_name，测试方法命名规则如下：
/// 同步测试：test开头无参方法，无需调用assertFinished
/// 异步测试：testAsync开头无参方法，必须调用assertFinished
open class TestCase: NSObject, @unchecked Sendable {
    // MARK: - Accessor
    fileprivate var assertError: NSError?
    fileprivate var assertCompletion: (@Sendable () -> Void)?

    // MARK: - Lifecycle
    /// 初始化方法
    override public required init() {
        super.init()
    }

    // MARK: - Public
    /// 所属测试套件，默认default
    open class func testSuite() -> TestSuite {
        .default
    }

    /// 测试初始化，每次执行测试方法开始都会调用
    open func setUp() {}

    /// 测试收尾，每次执行测试方法结束都会调用
    open func tearDown() {}

    /// 执行断言，异步断言完成时必须调用assertFinished
    ///
    /// - Parameters:
    ///   - value: 断言值
    ///   - expression: 断言表达式
    ///   - file: 文件名，默认传参
    ///   - line: 行数，默认传参
    @discardableResult
    open func assertTrue(_ value: Bool, _ expression: String = "", file: String = #file, line: Int = #line) -> Bool {
        guard !value else { return true }

        assertError = NSError(domain: "FWTest", code: 0, userInfo: [
            "expression": expression,
            "file": !file.isEmpty ? (file as NSString).lastPathComponent : "",
            "line": "\(line)"
        ])
        return false
    }

    /// 异步断言结束，异步断言完成时必须调用assertFinished
    open func assertFinished() {
        assertCompletion?()
    }
}

// MARK: - UnitTest
/// 单元测试启动器，调试模式启动时自动执行default测试套件
public class UnitTest: CustomDebugStringConvertible, @unchecked Sendable {
    // MARK: - Accessor
    private let testSuite: TestSuite
    private var testLogs: String = ""

    // MARK: - Lifecycle
    /// 指定测试套件初始化
    public init(testSuite: TestSuite) {
        self.testSuite = testSuite
    }

    // MARK: - Public
    /// 执行单元测试，完成时回调是否成功
    public func runTests(completion: (@Sendable (Bool) -> Void)? = nil) {
        let testCases = testCases()
        guard !testCases.isEmpty else {
            completion?(true)
            return
        }

        let queue = DispatchQueue(label: "site.wuyong.queue.test.\(testSuite.rawValue)")
        queue.async {
            let result = self.runTestCases(testCases)
            completion?(result)
        }
    }

    /// 测试结果调试信息
    public var debugDescription: String { testLogs }

    // MARK: - Private
    private func testCases() -> [AnyClass] {
        let testCases = NSObject.fw.allSubclasses(TestCase.self)
            .filter { ($0 as? TestCase.Type)?.testSuite() == testSuite }
            .sorted { NSStringFromClass($0) < NSStringFromClass($1) }
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

    private func runTestCases(_ testCases: [AnyClass]) -> Bool {
        var failedCount: UInt = 0
        var succeedCount: UInt = 0
        var testLog = ""
        let beginTime = Date().timeIntervalSince1970

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
            let totalTestCount = UInt(selectorNames.count)
            var currentTestCount: UInt = 0
            var assertError: NSError?

            if let testClass = classType as? TestCase.Type, selectorNames.count > 0 {
                let testCase = testClass.init()
                for selectorName in selectorNames {
                    currentTestCount += 1
                    formatMethod = selectorName
                    let selector = NSSelectorFromString(selectorName)
                    if testCase.responds(to: selector) {
                        testCase.setUp()
                        if selectorName.hasPrefix("testAsync") {
                            let testSemaphore = DispatchSemaphore(value: 0)
                            testCase.assertCompletion = {
                                testSemaphore.signal()
                            }
                            testCase.perform(selector)
                            testSemaphore.wait()
                        } else {
                            testCase.assertCompletion = nil
                            testCase.perform(selector)
                        }
                        testCase.tearDown()

                        assertError = testCase.assertError
                        if assertError != nil { break }
                    }
                }
            }

            if let assertError {
                let expression = assertError.userInfo["expression"] as? String ?? ""
                formatMessage = String(format: "- assertTrue(%@); (%@ - %@ #%@)", !expression.isEmpty ? expression : "false", formatMethod, assertError.userInfo["file"] as? String ?? "", assertError.userInfo["line"] as? String ?? "")
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
        let totalLog = String(format: "   %@: (%lu/%lu) (%.0f%%) (%.003fs)\n", failedCount < 1 ? "✅" : "⚠️", succeedCount, totalCount, passRate, totalTime)
        let suiteName = testSuite != .default ? "." + testSuite.rawValue : ""
        testLogs = String(format: "\n========== TEST%@ ==========\n%@%@========== TEST%@ ==========", suiteName, testLog, totalCount > 0 ? totalLog : "", suiteName)
        return failedCount < 1
    }
}

// MARK: - FrameworkAutoloader+Test
extension FrameworkAutoloader {
    @objc static func loadKernel_Test() {
        DispatchQueue.main.async {
            let unitTest = UnitTest(testSuite: .default)
            unitTest.runTests { _ in
                guard !unitTest.debugDescription.isEmpty else { return }
                Logger.debug(group: Logger.fw.moduleName, "%@", unitTest.debugDescription)
            }
        }
    }
}

#endif
