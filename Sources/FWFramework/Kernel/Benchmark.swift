//
//  Benchmark.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 标记时间调试开始
    ///
    /// - Parameter name: 调试标签，默认空字符串
    public static func begin(_ name: String = "") {
        Benchmark.begin(name)
    }

    /// 标记时间调试结束并打印消耗时间
    ///
    /// - Parameter name: 调试标签，默认空字符串
    /// - Returns: 消耗时间
    @discardableResult
    public static func end(_ name: String = "") -> TimeInterval {
        Benchmark.end(name)
    }
}

// MARK: - Benchmark
/// 时间调试器
public class Benchmark {
    // MARK: - Accessor
    private nonisolated(unsafe) static var beginTimes: [String: TimeInterval] = [:]
    private nonisolated(unsafe) static var endTimes: [String: TimeInterval] = [:]

    // MARK: - Public
    /// 标记时间调试开始
    public static func begin(_ name: String) {
        beginTimes[name] = Date().timeIntervalSince1970
    }

    /// 标记时间调试结束并打印消耗时间
    @discardableResult
    public static func end(_ name: String) -> TimeInterval {
        let beginTime = beginTimes[name] ?? Date().timeIntervalSince1970
        let endTime = Date().timeIntervalSince1970
        endTimes[name] = endTime

        let timeInterval = endTime - beginTime
        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "Benchmark-%@: %.3fms", name, timeInterval * 1000)
        #endif
        return timeInterval
    }

    /// 获取所有的消耗时间数据
    public static func benchmarks() -> [String: TimeInterval] {
        var times: [String: TimeInterval] = [:]
        for (name, endTime) in endTimes {
            let beginTime = beginTimes[name] ?? Date().timeIntervalSince1970
            times[name] = endTime - beginTime
        }
        return times
    }
}
