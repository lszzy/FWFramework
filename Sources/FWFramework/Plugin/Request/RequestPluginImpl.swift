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
    open func urlRequest(for request: HTTPRequest) throws -> NSMutableURLRequest {
        let urlString = RequestManager.shared.buildRequestUrl(request)
        let requestSerializer = requestSerializer(for: request)
        
        if request.constructingBodyBlock != nil {
            var error: NSError?
            let urlRequest = requestSerializer.multipartFormRequest(withMethod: request.requestMethod().rawValue, urlString: urlString, parameters: request.requestArgument() as? [String: Any], constructingBodyWith: { formData in
                if let requestFormData = formData as? RequestMultipartFormData {
                    request.constructingBodyBlock?(requestFormData)
                }
            }, error: &error)
            
            if let error = error {
                throw error
            }
            return urlRequest
        }
        
        let urlReqeust = try requestSerializer.request(withMethod: request.requestMethod().rawValue, urlString: urlString, parameters: request.requestArgument())
        return urlReqeust
    }
    
    open func resumeRequest(for request: HTTPRequest) {
        request.requestTask?.resume()
    }
    
    open func cancelRequest(for request: HTTPRequest) {
        request.requestTask?.cancel()
    }
    
    // MARK: - Private
    private func requestSerializer(for request: HTTPRequest) -> HTTPRequestSerializer {
        let requestSerializer: HTTPRequestSerializer
        if request.requestSerializerType() == .JSON {
            requestSerializer = JSONRequestSerializer()
        } else {
            requestSerializer = HTTPRequestSerializer()
        }
        
        requestSerializer.timeoutInterval = request.requestTimeoutInterval()
        requestSerializer.allowsCellularAccess = request.allowsCellularAccess()
        if let cachePolicy = request.requestCachePolicy() {
            requestSerializer.cachePolicy = cachePolicy
        }
        
        if let headerFieldArray = request.requestAuthorizationHeaderFieldArray(),
           !headerFieldArray.isEmpty {
            requestSerializer.setAuthorizationHeaderFieldWithUsername(headerFieldArray.first ?? "", password: headerFieldArray.last ?? "")
        }
        
        if let headerFieldDictionary = request.requestHeaderFieldValueDictionary(),
           !headerFieldDictionary.isEmpty {
            for (fieldKey, fieldValue) in headerFieldDictionary {
                requestSerializer.setValue(fieldValue, forHTTPHeaderField: fieldKey)
            }
        }
        return requestSerializer
    }
    
}
