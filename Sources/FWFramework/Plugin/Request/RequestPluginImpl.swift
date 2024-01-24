//
//  RequestPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - RequestPluginImpl
/// 默认请求插件
open class RequestPluginImpl: NSObject, RequestPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = RequestPluginImpl()
    
    /// SessionConfiguration配置，默认nil
    open var sessionConfiguration: URLSessionConfiguration = .default
    /// 自定义安全策略，默认default
    open var securityPolicy: SecurityPolicy = .default
    /// SessionTaskMetrics配置句柄，默认nil
    open var collectingMetricsBlock: ((_ session: URLSession, _ task: URLSessionTask, _ metrics: URLSessionTaskMetrics?) -> Void)?
    
    /// 是否移除响应JSON中的NSNull值，默认true
    open var removeNullValues = true
    /// 有效状态码范围，默认为(100-600)
    open var acceptableStatusCodes = IndexSet(integersIn: 100..<600)
    /// 有效的contentType列表，默认nil不修改
    open var acceptableContentTypes: Set<String>?
    
    #if DEBUG
    /// 是否启用Mock，配合NetworkMocker使用，默认false
    open var mockEnabled: Bool = false {
        didSet {
            guard mockEnabled else { return }
            
            let protocolClasses = sessionConfiguration.protocolClasses ?? []
            sessionConfiguration.protocolClasses = [NetworkMockerURLProtocol.self] + protocolClasses
        }
    }
    #endif
    
    private var completionQueue = DispatchQueue(label: "site.wuyong.queue.request.completion", attributes: .concurrent)
    
    /// 管理器，延迟加载前可配置
    open lazy var manager: HTTPSessionManager = {
        let result = HTTPSessionManager(sessionConfiguration: sessionConfiguration)
        result.securityPolicy = securityPolicy
        result.responseSerializer = httpResponseSerializer
        result.completionQueue = completionQueue
        result.taskDidFinishCollectingMetrics = collectingMetricsBlock
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
    
    // MARK: - RequestPlugin
    open func buildUrlRequest(for request: HTTPRequest) throws -> URLRequest {
        if let customUrlRequest = request.customUrlRequest() {
            return customUrlRequest
        }
        
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
            requestSerializer.setAuthorizationHeaderField(username: headerFieldArray.first ?? "", password: headerFieldArray.last ?? "")
        }
        if let headerFieldDictionary = request.requestHeaders(),
           !headerFieldDictionary.isEmpty {
            for (fieldKey, fieldValue) in headerFieldDictionary {
                requestSerializer.setValue(fieldValue, forHTTPHeaderField: fieldKey)
            }
        }
        
        var urlRequest: URLRequest
        if request.constructingBodyBlock != nil {
            var error: Error?
            let mutableRequest = requestSerializer.multipartFormRequest(method: request.requestMethod().rawValue, urlString: requestUrl.absoluteString, parameters: request.requestArgument() as? [String: Any], constructingBody: { formData in
                if let requestFormData = formData as? RequestMultipartFormData {
                    request.constructingBodyBlock?(requestFormData)
                }
            }, error: &error)
            
            if error != nil || mutableRequest == nil { throw error ?? RequestError.unknown }
            urlRequest = mutableRequest!
        } else {
            var error: Error?
            let mutableRequest = requestSerializer.request(method: request.requestMethod().rawValue, urlString: requestUrl.absoluteString, parameters: request.requestArgument(), error: &error)
            
            if error != nil || mutableRequest == nil { throw error ?? RequestError.unknown }
            urlRequest = mutableRequest!
        }
        
        RequestManager.shared.filterUrlRequest(&urlRequest, for: request)
        
        return urlRequest
    }
    
    open func startDataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        let urlRequest: URLRequest
        do {
            urlRequest = try buildUrlRequest(for: request)
        } catch {
            completionHandler?(HTTPURLResponse(), nil, error)
            return
        }
        
        let dataTask = manager.dataTask(request: urlRequest, uploadProgress: request.uploadProgressBlock, downloadProgress: nil, completionHandler: { [weak self] response, responseObject, error in
            self?.handleResponse(for: request, response: response, responseObject: responseObject, error: error, completionHandler: completionHandler)
        })
        
        startRequestTask(dataTask, for: request)
    }
    
    open func startDownloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) {
        let downloadTask: URLSessionDownloadTask
        if let resumeData = resumeData {
            downloadTask = manager.downloadTask(resumeData: resumeData, progress: request.downloadProgressBlock, destination: { _, _ in
                return URL(fileURLWithPath: destination, isDirectory: false)
            }, completionHandler: { [weak self] response, fileUrl, error in
                self?.handleResponse(for: request, response: response, responseObject: fileUrl, error: error, completionHandler: { response, responseObject, error in
                    completionHandler?(response, responseObject as? URL, error)
                })
            })
        } else {
            let urlRequest: URLRequest
            do {
                urlRequest = try buildUrlRequest(for: request)
            } catch {
                completionHandler?(HTTPURLResponse(), nil, error)
                return
            }
            
            downloadTask = manager.downloadTask(request: urlRequest, progress: request.downloadProgressBlock, destination: { _, _ in
                return URL(fileURLWithPath: destination, isDirectory: false)
            }, completionHandler: { [weak self] response, fileUrl, error in
                self?.handleResponse(for: request, response: response, responseObject: fileUrl, error: error, completionHandler: { response, responseObject, error in
                    completionHandler?(response, responseObject as? URL, error)
                })
            })
        }
        
        startRequestTask(downloadTask, for: request)
    }
    
    open func suspendRequest(_ request: HTTPRequest) {
        request.requestTask?.suspend()
    }
    
    open func resumeRequest(_ request: HTTPRequest) {
        request.requestTask?.resume()
    }
    
    open func cancelRequest(_ request: HTTPRequest) {
        request.requestTask?.cancel()
    }
    
    // MARK: - Private
    private func startRequestTask(_ requestTask: URLSessionTask, for request: HTTPRequest) {
        switch request.requestPriority {
        case .high:
            requestTask.priority = URLSessionTask.highPriority
        case .low:
            requestTask.priority = URLSessionTask.lowPriority
        default:
            requestTask.priority = URLSessionTask.defaultPriority
        }
        
        request.requestTask = requestTask
        requestTask.resume()
    }
    
    private func handleResponse(for request: HTTPRequest, response: URLResponse, responseObject: Any?, error: Error?, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        var serializationError: Error?
        request.responseObject = responseObject
        if let responseData = request.responseObject as? Data {
            request.responseData = responseData
            request.responseString = String(data: responseData, encoding: RequestManager.shared.stringEncoding(for: request))
            
            switch request.responseSerializerType() {
            case .JSON:
                request.responseObject = jsonResponseSerializer.responseObject(for: response, data: request.responseData, error: &serializationError)
                request.responseJSONObject = request.responseObject
            default:
                break
            }
        }
        
        completionHandler?(response, request.responseObject, error ?? serializationError)
    }
    
}

// MARK: - StreamingMultipartFormData+RequestPluginImpl
extension StreamingMultipartFormData: RequestMultipartFormData {
    public func append(_ formData: Data, name: String) {
        appendPart(formData: formData, name: name)
    }
    
    public func append(_ fileData: Data, name: String, fileName: String, mimeType: String) {
        appendPart(fileData: fileData, name: name, fileName: fileName, mimeType: mimeType)
    }
    
    public func append(_ fileURL: URL, name: String) {
        var error: Error?
        appendPart(fileURL: fileURL, name: name, error: &error)
    }
    
    public func append(_ fileURL: URL, name: String, fileName: String, mimeType: String) {
        var error: Error?
        appendPart(fileURL: fileURL, name: name, fileName: fileName, mimeType: mimeType, error: &error)
    }
    
    public func append(_ inputStream: InputStream, length: UInt64, name: String, fileName: String, mimeType: String) {
        appendPart(inputStream: inputStream, length: length, name: name, fileName: fileName, mimeType: mimeType)
    }
    
    public func append(_ inputStream: InputStream, length: UInt64, headers: [String: String]) {
        appendPart(inputStream: inputStream, length: length, headers: headers)
    }
    
    public func append(_ body: Data, headers: [String: String]) {
        appendPart(headers: headers, body: body)
    }
}
