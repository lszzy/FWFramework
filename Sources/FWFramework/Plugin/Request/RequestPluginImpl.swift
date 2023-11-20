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
    
    private var allStatusCodes = NSIndexSet(indexesIn: NSMakeRange(100, 500)) as IndexSet
    private var processingQueue = DispatchQueue(label: "site.wuyong.queue.request.processing", attributes: .concurrent)
    
    /// 管理器
    open lazy var manager: HTTPSessionManager = {
        let result = HTTPSessionManager(sessionConfiguration: sessionConfiguration)
        result.securityPolicy = securityPolicy
        result.responseSerializer = httpResponseSerializer
        result.completionQueue = processingQueue
        result.setTaskDidFinishCollectingMetricsBlock(collectingMetricsBlock)
        return result
    }()
    
    /// HTTP响应序列化
    open lazy var httpResponseSerializer: HTTPResponseSerializer = {
        let result = HTTPResponseSerializer()
        result.acceptableStatusCodes = allStatusCodes
        return result
    }()
    
    /// JSON响应序列化
    open lazy var jsonResponseSerializer: JSONResponseSerializer = {
        let result = JSONResponseSerializer()
        result.acceptableStatusCodes = allStatusCodes
        result.removesKeysWithNullValues = removeNullValues
        return result
    }()
    
    /// XML响应序列化
    open lazy var xmlParserResponseSerialzier: XMLParserResponseSerializer = {
        let result = XMLParserResponseSerializer()
        result.acceptableStatusCodes = allStatusCodes
        return result
    }()
    
    /// 重置URLSessionManager
    open func resetURLSessionManager(configuration: URLSessionConfiguration? = nil) {
        manager = HTTPSessionManager(sessionConfiguration: configuration)
    }
    
    // MARK: - RequestPlugin
    
    
}
