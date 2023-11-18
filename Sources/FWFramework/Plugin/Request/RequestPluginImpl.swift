//
//  RequestPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

/// 默认请求插件
open class RequestPluginImpl: NSObject, RequestPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = RequestPluginImpl()
    
    /// 自定义安全策略，默认default
    open var securityPolicy = SecurityPolicy.default()
    /// 是否移除响应JSON中的NSNull值，默认true
    open var removeNullValues = true
    /// SessionConfiguration配置，默认nil
    open var sessionConfiguration: URLSessionConfiguration?
    /// SessionTaskMetrics配置句柄，默认nil
    open var collectingMetricsBlock: ((_ session: URLSession, _ task: URLSessionTask, _ metrics: URLSessionTaskMetrics?) -> Void)?
    
    // MARK: - RequestPlugin
    
    
}
