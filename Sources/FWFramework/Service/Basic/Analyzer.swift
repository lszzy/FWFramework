//
//  Analyzer.swift
//  FWFramework
//
//  Created by wuyong on 2023/2/20.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

/// 分析上报者协议
@objc(FWAnalysisReporter)
public protocol AnalysisReporter {
    
    /// 初始化上报者，仅调用一次
    func setupReporter()
    
    /// 上报公共参数，公共参数发生变化时调用
    func reportDefaultParameters(_ parameters: [AnyHashable: Any]?)
    
    /// 上报用户参数，用户参数发生变化时调用
    func reportUserParameters(_ parameters: [AnyHashable: Any]?)
    
    /// 上报事件，事件发生时调用
    func reportEvent(_ name: String, parameters: [AnyHashable: Any]?)
    
    /// 上报错误，错误发生时调用
    func reportError(_ name: String, error: Error, parameters: [AnyHashable: Any]?)
    
}

/// 事件分析器
@objc(FWAnalyzer)
@objcMembers public class Analyzer: NSObject {
    
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = Analyzer()
    
    /// 是否启用日志，默认调试开启，正式关闭
    public var logEnabled: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()
    
    private var reporters: [AnalysisReporter] = []
    private var queue = DispatchQueue(label: "site.wuyong.queue.analyzer")
    
    /// 添加上报者
    public func addReporter(_ reporter: AnalysisReporter) {
        queue.sync {
            reporters.append(reporter)
        }
    }
    
    /// 移除指定上报者
    public func removeReporter<T: AnalysisReporter>(_ reporter: T) where T : Equatable {
        queue.sync {
            reporters.removeAll { object in
                guard let object = object as? T else { return false }
                return reporter == object
            }
        }
    }
    
    /// 移除所有上报者
    public func removeAllReporters() {
        queue.sync {
            reporters.removeAll()
        }
    }
    
    /// 初始化所有上报者，仅调用一次
    public func setupReporters() {
        if logEnabled {
            Logger.group("FWFramework", type: .debug, format: "\n===========ANALYZER SETUP===========\n%@", !reporters.isEmpty ? reporters : "")
        }
        
        queue.sync {
            reporters.forEach { reporter in
                reporter.setupReporter()
            }
        }
    }
    
    /// 跟踪上报公共参数，公共参数发生变化时调用
    public func trackDefaultParameters(_ parameters: [AnyHashable: Any]? = nil) {
        if logEnabled {
            Logger.group("FWFramework", type: .debug, format: "\n===========ANALYZER PARAMETERS===========\n%@", parameters ?? "")
        }
        
        queue.sync {
            reporters.forEach { reporter in
                reporter.reportDefaultParameters(parameters)
            }
        }
    }
    
    /// 跟踪上报用户参数，用户参数发生变化时调用
    public func trackUserParameters(_ parameters: [AnyHashable: Any]? = nil) {
        if logEnabled {
            Logger.group("FWFramework", type: .debug, format: "\n===========ANALYZER USER===========\n%@", parameters ?? "")
        }
        
        queue.sync {
            reporters.forEach { reporter in
                reporter.reportUserParameters(parameters)
            }
        }
    }
    
    /// 跟踪上报事件，事件发生时调用
    public func trackEvent(_ name: String, parameters: [AnyHashable: Any]? = nil) {
        if logEnabled {
            Logger.group("FWFramework", type: .debug, format: "\n===========ANALYZER EVENT===========\n%@:\n%@", name, parameters ?? "")
        }
        
        queue.async { [weak self] in
            self?.reporters.forEach { reporter in
                reporter.reportEvent(name, parameters: parameters)
            }
        }
    }
    
    /// 跟踪上报错误，错误发生时调用
    public func trackError(_ name: String, error: Error, parameters: [AnyHashable: Any]? = nil) {
        if logEnabled {
            Logger.group("FWFramework", type: .debug, format: "\n===========ANALYZER ERROR===========\n%@: %@\n%@", name, error.localizedDescription, parameters ?? "")
        }
        
        queue.async { [weak self] in
            self?.reporters.forEach({ reporter in
                reporter.reportError(name, error: error, parameters: parameters)
            })
        }
    }
    
}
