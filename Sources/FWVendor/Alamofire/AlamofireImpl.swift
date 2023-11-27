//
//  AlamofireImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Foundation
import Alamofire
#if FWMacroSPM
import FWObjC
import FWFramework
#endif

// MARK: - AlamofireImpl
/// Alamofire请求插件，启用Alamofire子模块后生效
open class AlamofireImpl: NSObject, RequestPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = AlamofireImpl()
    
    /// SessionConfiguration配置，默认nil
    open var sessionConfiguration: URLSessionConfiguration?
    /// 全局intercepter配置，默认nil
    open var intercepter: RequestInterceptor?
    /// 服务器信任管理器，默认nil
    open var serverTrustManager: ServerTrustManager?
    /// 重定向处理句柄，默认nil
    open var redirectHandler: RedirectHandler?
    /// 缓存响应处理句柄，默认nil
    open var cachedResponseHandler: CachedResponseHandler?
    /// 事件模拟器数组，默认空
    open var eventMonitors: [EventMonitor] = []
    
    /// 有效状态码范围，默认为(100-600)
    open var acceptableStatusCodes: [Int] = Array(100..<600)
    /// 有效的contentType列表，默认nil不修改
    open var acceptableContentTypes: [String]?
    
    /// 自定义请求重试句柄，返回是否启用默认重试方案，默认nil
    open var requestRetryBlock: ((HTTPRequest) -> Bool)?
    /// 自定义请求intercepter句柄，如配置RetryPolicy等，默认nil
    open var requestIntercepterBlock: ((HTTPRequest) -> RequestInterceptor?)?
    
    private var rootQueue = DispatchQueue(label: "site.wuyong.queue.request.alamofire.root")
    
    /// 会话
    open lazy var session: Session = {
        let result = Session(
            configuration: sessionConfiguration ?? .af.default,
            rootQueue: rootQueue,
            startRequestsImmediately: false,
            interceptor: intercepter,
            serverTrustManager: serverTrustManager,
            redirectHandler: redirectHandler,
            cachedResponseHandler: cachedResponseHandler,
            eventMonitors: eventMonitors
        )
        return result
    }()
    
    // MARK: - Public
    /// 默认URLRequest修改器
    open func modifyUrlRequest(urlRequest: inout URLRequest, for request: HTTPRequest) {
        urlRequest.timeoutInterval = request.requestTimeoutInterval()
        urlRequest.allowsCellularAccess = request.allowsCellularAccess()
        if let cachePolicy = request.requestCachePolicy() {
            urlRequest.cachePolicy = cachePolicy
        }
        
        request.filterUrlRequest(&urlRequest)
        
        let filters = request.config.requestFilters
        for filter in filters {
            filter.filterUrlRequest(&urlRequest, for: request)
        }
        
        if request.requestSerializerType() == .JSON,
           urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if request.responseSerializerType() == .JSON,
           urlRequest.value(forHTTPHeaderField: "Accept") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        }
    }
    
    private func handleResponse(_ request: HTTPRequest, alamofireRequest: Request, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        if let dataRequest = alamofireRequest as? DataRequest {
            dataRequest.validate(statusCode: acceptableStatusCodes)
            if let contentTypes = acceptableContentTypes {
                dataRequest.validate(contentType: contentTypes)
            }
            
            switch request.responseSerializerType() {
            case .JSON:
                dataRequest.responseJSON { response in
                    switch response.result {
                    case .success(let responseObject):
                        request.responseObject = responseObject
                        request.responseJSONObject = responseObject
                    default:
                        break
                    }
                    
                    if let responseData = response.data {
                        request.responseData = responseData
                        request.responseString = String(data: responseData, encoding: RequestManager.shared.stringEncoding(for: request))
                    }
                    
                    completionHandler?(response.response ?? .init(), request.responseObject, response.error)
                }
            default:
                dataRequest.response { response in
                    request.responseObject = response.data
                    
                    if let responseData = response.data {
                        request.responseData = responseData
                        request.responseString = String(data: responseData, encoding: RequestManager.shared.stringEncoding(for: request))
                    }
                    
                    completionHandler?(response.response ?? .init(), request.responseObject, response.error)
                }
            }
        } else if let downloadRequest = alamofireRequest as? DownloadRequest {
            downloadRequest.validate(statusCode: acceptableStatusCodes)
            if let contentTypes = acceptableContentTypes {
                downloadRequest.validate(contentType: contentTypes)
            }
            
            switch request.responseSerializerType() {
            case .JSON:
                downloadRequest.responseJSON { response in
                    request.responseObject = response.fileURL
                    
                    if let responseData = response.resumeData {
                        request.responseData = responseData
                        request.responseString = String(data: responseData, encoding: RequestManager.shared.stringEncoding(for: request))
                    }
                    
                    completionHandler?(response.response ?? .init(), request.responseObject, response.error)
                }
            default:
                downloadRequest.response { response in
                    request.responseObject = response.fileURL
                    
                    if let responseData = response.resumeData {
                        request.responseData = responseData
                        request.responseString = String(data: responseData, encoding: RequestManager.shared.stringEncoding(for: request))
                    }
                    
                    completionHandler?(response.response ?? .init(), request.responseObject, response.error)
                }
            }
        }
        
        request.requestAdapter = alamofireRequest
        request.requestTaskBlock = { request in
            return (request.requestAdapter as? Request)?.task
        }
        request.requestTask = alamofireRequest.task
    }
    
    // MARK: - RequestPlugin
    open func dataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) throws {
        let alamofireRequest: DataRequest
        let requestIntercepter = requestIntercepterBlock?(request)
        
        if let customUrlRequest = request.customUrlRequest() {
            alamofireRequest = session.request(customUrlRequest, interceptor: requestIntercepter)
        } else {
            let requestUrl = RequestManager.shared.buildRequestUrl(for: request)
            let method: HTTPMethod = .init(rawValue: request.requestMethod().rawValue)
            let parameters = request.requestArgument() as? [String: Any]
            var headers: HTTPHeaders?
            if let requestHeaders = request.requestHeaders() {
                headers = .init(requestHeaders)
            }
            
            if request.constructingBodyBlock != nil {
                alamofireRequest = session.upload(multipartFormData: { formData in
                    if let parameters = parameters {
                        parameters.forEach { (field, value) in
                            var data: Data?
                            if let valueData = value as? Data {
                                data = valueData
                            } else if value is NSNull {
                                data = Data()
                            } else {
                                data = String.fw_safeString(value).data(using: .utf8)
                            }
                            if let data = data {
                                formData.append(data, name: field)
                            }
                        }
                    }
                    
                    request.constructingBodyBlock?(formData)
                }, to: requestUrl, method: method, headers: headers, interceptor: requestIntercepter, requestModifier: { [weak self] urlRequest in
                    self?.modifyUrlRequest(urlRequest: &urlRequest, for: request)
                })
            } else {
                alamofireRequest = session.request(requestUrl, method: method, parameters: parameters, encoding: request.requestSerializerType() == .JSON ? JSONEncoding.default : URLEncoding.default, headers: headers, interceptor: requestIntercepter, requestModifier: { [weak self] urlRequest in
                    self?.modifyUrlRequest(urlRequest: &urlRequest, for: request)
                })
            }
        }
        
        if let authHeaders = request.requestAuthorizationHeaders(),
           let authUser = authHeaders.first,
           let authPwd = authHeaders.last {
            alamofireRequest.authenticate(username: authUser, password: authPwd)
        }
        
        if let progressBlock = request.uploadProgressBlock {
            alamofireRequest.uploadProgress(closure: progressBlock)
        }
        
        handleResponse(request, alamofireRequest: alamofireRequest, completionHandler: completionHandler)
    }
    
    open func downloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) throws {
        let alamofireRequest: DownloadRequest
        let requestIntercepter = requestIntercepterBlock?(request)
        
        if let resumeData = resumeData {
            alamofireRequest = session.download(resumingWith: resumeData, interceptor: requestIntercepter, to: { _, _ in
                return (URL(fileURLWithPath: destination, isDirectory: false), [])
            })
        } else {
            let requestUrl = RequestManager.shared.buildRequestUrl(for: request)
            let method: HTTPMethod = .init(rawValue: request.requestMethod().rawValue)
            var headers: HTTPHeaders?
            if let requestHeaders = request.requestHeaders() {
                headers = .init(requestHeaders)
            }
            
            alamofireRequest = session.download(requestUrl, method: method, parameters: request.requestArgument() as? [String: Any], encoding: request.requestSerializerType() == .JSON ? JSONEncoding.default : URLEncoding.default, headers: headers, interceptor: requestIntercepter, requestModifier: { [weak self] urlRequest in
                self?.modifyUrlRequest(urlRequest: &urlRequest, for: request)
            }, to: { _, _ in
                return (URL(fileURLWithPath: destination, isDirectory: false), [])
            })
        }
        
        if let authHeaders = request.requestAuthorizationHeaders(),
           let authUser = authHeaders.first,
           let authPwd = authHeaders.last {
            alamofireRequest.authenticate(username: authUser, password: authPwd)
        }
        
        if let progressBlock = request.downloadProgressBlock {
            alamofireRequest.downloadProgress(closure: progressBlock)
        }
        
        handleResponse(request, alamofireRequest: alamofireRequest) { response, responseObject, error in
            completionHandler?(response, responseObject as? URL, error)
        }
    }
    
    open func startRequest(for request: HTTPRequest) {
        (request.requestAdapter as? Request)?.resume()
    }
    
    open func cancelRequest(for request: HTTPRequest) {
        (request.requestAdapter as? Request)?.cancel()
    }
    
    open func retryRequest(for request: HTTPRequest) -> Bool {
        return requestRetryBlock?(request) ?? true
    }
    
}

// MARK: - MultipartFormData+AlamofireImpl
extension Alamofire.MultipartFormData: RequestMultipartFormData {
    public func append(_ formData: Data, name: String) {
        append(formData, withName: name)
    }
    
    public func append(_ fileData: Data, name: String, fileName: String, mimeType: String) {
        append(fileData, withName: name, fileName: fileName, mimeType: mimeType)
    }
    
    public func append(_ fileURL: URL, name: String) {
        append(fileURL, withName: name)
    }
    
    public func append(_ fileURL: URL, name: String, fileName: String, mimeType: String) {
        append(fileURL, withName: name, fileName: fileName, mimeType: mimeType)
    }
    
    public func append(_ inputStream: InputStream, length: UInt64, name: String, fileName: String, mimeType: String) {
        append(inputStream, withLength: length, name: name, fileName: fileName, mimeType: mimeType)
    }
    
    public func append(_ inputStream: InputStream, length: UInt64, headers: [String: String]) {
        append(inputStream, withLength: length, headers: .init(headers))
    }
    
    public func append(_ body: Data, headers: [String: String]) {
        append(InputStream(data: body), withLength: UInt64(body.count), headers: .init(headers))
    }
}

// MARK: - Autoloader+AlamofireImpl
@objc extension Autoloader {
    
    static func loadVendor_Alamofire() {
        PluginManager.presetPlugin(RequestPlugin.self, object: AlamofireImpl.self)
    }
    
}
