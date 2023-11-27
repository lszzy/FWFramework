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
    
    // MARK: - Public
    /// 构建请求URLRequest
    open func buildUrlRequest(for request: HTTPRequest) throws -> URLRequest {
        if let customUrlRequest = request.customUrlRequest() {
            return customUrlRequest
        }
        
        let urlRequest = try urlRequest(for: request)
        
        request.filterUrlRequest(urlRequest)
        
        let filters = request.config.requestFilters
        for filter in filters {
            filter.filterUrlRequest?(urlRequest, with: request)
        }
        
        if request.requestSerializerType() == .JSON,
           urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if request.responseSerializerType() == .JSON,
           urlRequest.value(forHTTPHeaderField: "Accept") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        
        return urlRequest as URLRequest
    }
    
    private func urlRequest(for request: HTTPRequest) throws -> NSMutableURLRequest {
        let requestUrl = RequestManager.shared.buildRequestUrl(for: request)
        
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
            let urlRequest = requestSerializer.multipartFormRequest(withMethod: request.requestMethod().rawValue, urlString: requestUrl.absoluteString, parameters: request.requestArgument() as? [String: Any], constructingBodyWith: { formData in
                request.constructingBodyBlock?(formData)
            }, error: &error)
            
            if let error = error {
                throw error
            }
            return urlRequest
        }
        
        let urlReqeust = try requestSerializer.request(withMethod: request.requestMethod().rawValue, urlString: requestUrl.absoluteString, parameters: request.requestArgument())
        return urlReqeust
    }
    
    private func handleResponse(_ request: HTTPRequest, response: URLResponse, responseObject: Any?, error: Error?, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        var serializationError: NSError?
        request.responseObject = responseObject
        if let responseData = request.responseObject as? Data {
            request.responseData = responseData
            request.responseString = String(data: responseData, encoding: RequestManager.shared.stringEncoding(for: request))
            
            switch request.responseSerializerType() {
            case .JSON:
                request.responseObject = jsonResponseSerializer.responseObject(for: response, data: request.responseData, error: &serializationError)
                request.responseJSONObject = request.responseObject
            case .xmlParser:
                request.responseObject = xmlParserResponseSerialzier.responseObject(for: response, data: request.responseData, error: &serializationError)
            default:
                break
            }
        }
        
        completionHandler?(response, request.responseObject, error ?? serializationError)
    }
    
    // MARK: - RequestPlugin
    open func dataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) throws {
        let urlRequest = try buildUrlRequest(for: request)
        request.requestTask = manager.dataTask(with: urlRequest, uploadProgress: request.uploadProgressBlock, downloadProgress: nil, completionHandler: { [weak self] response, responseObject, error in
            self?.handleResponse(request, response: response, responseObject: responseObject, error: error, completionHandler: completionHandler)
        })
    }
    
    open func downloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) throws {
        if let resumeData = resumeData {
            request.requestTask = manager.downloadTask(withResumeData: resumeData, progress: request.downloadProgressBlock, destination: { _, _ in
                return URL(fileURLWithPath: destination, isDirectory: false)
            }, completionHandler: { [weak self] response, fileUrl, error in
                self?.handleResponse(request, response: response, responseObject: fileUrl, error: error, completionHandler: { response, responseObject, error in
                    completionHandler?(response, responseObject as? URL, error)
                })
            })
            return
        }
        
        let urlRequest = try buildUrlRequest(for: request)
        request.requestTask = manager.downloadTask(with: urlRequest, progress: request.downloadProgressBlock, destination: { _, _ in
            return URL(fileURLWithPath: destination, isDirectory: false)
        }, completionHandler: { [weak self] response, fileUrl, error in
            self?.handleResponse(request, response: response, responseObject: fileUrl, error: error, completionHandler: { response, responseObject, error in
                completionHandler?(response, responseObject as? URL, error)
            })
        })
    }
    
    open func startRequest(for request: HTTPRequest) {
        request.requestTask?.resume()
    }
    
    open func cancelRequest(for request: HTTPRequest) {
        request.requestTask?.cancel()
    }
    
    open func retryRequest(for request: HTTPRequest) -> Bool {
        return true
    }
    
}
