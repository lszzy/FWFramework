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
    
    /// SessionConfiguration配置，默认nil
    open var sessionConfiguration: URLSessionConfiguration?
    /// 自定义安全策略，默认default
    open var securityPolicy = SecurityPolicy.default()
    /// SessionTaskMetrics配置句柄，默认nil
    open var collectingMetricsBlock: ((_ session: URLSession, _ task: URLSessionTask, _ metrics: URLSessionTaskMetrics?) -> Void)?
    
    /// 是否移除响应JSON中的NSNull值，默认true
    open var removeNullValues = true
    /// 有效状态码范围，默认为(100-600)
    open var acceptableStatusCodes = NSIndexSet(indexesIn: NSMakeRange(100, 500)) as IndexSet
    /// 有效的contentType列表，默认nil不修改
    open var acceptableContentTypes: Set<String>?
    
    private var completionQueue = DispatchQueue(label: "site.wuyong.queue.request.completion", attributes: .concurrent)
    
    /// 管理器
    open lazy var manager: HTTPSessionManager = {
        let result = HTTPSessionManager(sessionConfiguration: sessionConfiguration)
        result.securityPolicy = securityPolicy
        result.responseSerializer = httpResponseSerializer
        result.completionQueue = completionQueue
        result.setTaskDidFinishCollectingMetricsBlock(collectingMetricsBlock)
        return result
    }()
    
    /// HTTP响应序列化
    open lazy var httpResponseSerializer: HTTPResponseSerializer = {
        let result = HTTPResponseSerializer()
        result.acceptableStatusCodes = acceptableStatusCodes
        if let acceptableContentTypes = acceptableContentTypes {
            result.acceptableContentTypes = acceptableContentTypes
        }
        return result
    }()
    
    /// JSON响应序列化
    open lazy var jsonResponseSerializer: JSONResponseSerializer = {
        let result = JSONResponseSerializer()
        result.acceptableStatusCodes = acceptableStatusCodes
        if let acceptableContentTypes = acceptableContentTypes {
            result.acceptableContentTypes = acceptableContentTypes
        }
        result.removesKeysWithNullValues = removeNullValues
        return result
    }()
    
    /// XML响应序列化
    open lazy var xmlParserResponseSerialzier: XMLParserResponseSerializer = {
        let result = XMLParserResponseSerializer()
        result.acceptableStatusCodes = acceptableStatusCodes
        if let acceptableContentTypes = acceptableContentTypes {
            result.acceptableContentTypes = acceptableContentTypes
        }
        return result
    }()
    
    // MARK: - RequestPlugin
    open func urlRequest(for request: HTTPRequest) throws -> NSMutableURLRequest {
        let urlString = RequestManager.shared.buildRequestUrl(request)
        
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
        
        if let headerFieldArray = request.requestAuthorizationHeaders(),
           !headerFieldArray.isEmpty {
            requestSerializer.setAuthorizationHeaderFieldWithUsername(headerFieldArray.first ?? "", password: headerFieldArray.last ?? "")
        }
        
        if let headerFieldDictionary = request.requestHeaders(),
           !headerFieldDictionary.isEmpty {
            for (fieldKey, fieldValue) in headerFieldDictionary {
                requestSerializer.setValue(fieldValue, forHTTPHeaderField: fieldKey)
            }
        }
        
        if request.constructingBodyBlock != nil {
            var error: NSError?
            let urlRequest = requestSerializer.multipartFormRequest(withMethod: request.requestMethod().rawValue, urlString: urlString, parameters: request.requestArgument() as? [String: Any], constructingBodyWith: { formData in
                request.constructingBodyBlock?(formData)
            }, error: &error)
            
            if let error = error {
                throw error
            }
            return urlRequest
        }
        
        let urlReqeust = try requestSerializer.request(withMethod: request.requestMethod().rawValue, urlString: urlString, parameters: request.requestArgument())
        return urlReqeust
    }
    
    open func dataTask(for request: HTTPRequest, urlRequest: URLRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        request.requestTask = manager.dataTask(with: urlRequest, uploadProgress: request.uploadProgressBlock, downloadProgress: nil, completionHandler: completionHandler)
    }
    
    open func downloadTask(for request: HTTPRequest, urlRequest: URLRequest?, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) {
        if let resumeData = resumeData {
            request.requestTask = manager.downloadTask(withResumeData: resumeData, progress: request.downloadProgressBlock, destination: { _, _ in
                return URL(fileURLWithPath: destination, isDirectory: false)
            }, completionHandler: completionHandler)
            return
        }
        
        if let urlRequest = urlRequest {
            request.requestTask = manager.downloadTask(with: urlRequest, progress: request.downloadProgressBlock, destination: { _, _ in
                return URL(fileURLWithPath: destination, isDirectory: false)
            }, completionHandler: completionHandler)
        }
    }
    
    open func startRequest(for request: HTTPRequest) {
        request.requestTask?.resume()
    }
    
    open func cancelRequest(for request: HTTPRequest) {
        request.requestTask?.cancel()
    }
    
    open func urlResponse(for request: HTTPRequest, response: URLResponse?, responseObject: Any?) throws {
        request.responseObject = responseObject
        if let responseData = request.responseObject as? Data {
            request.responseData = responseData
            request.responseString = String(data: responseData, encoding: RequestManager.shared.stringEncoding(for: request))
            
            var error: NSError?
            switch request.responseSerializerType() {
            case .JSON:
                request.responseObject = jsonResponseSerializer.responseObject(for: response, data: request.responseData, error: &error)
                request.responseJSONObject = request.responseObject
            case .xmlParser:
                request.responseObject = xmlParserResponseSerialzier.responseObject(for: response, data: request.responseData, error: &error)
            default:
                break
            }
            
            if let error = error {
                throw error
            }
        }
    }
    
    open func retryRequest(for request: HTTPRequest) -> Bool {
        return true
    }
    
}
