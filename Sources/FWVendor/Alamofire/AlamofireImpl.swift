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
@_spi(FW) import FWFramework
#endif

// MARK: - AlamofireImpl
/// Alamofire请求插件，启用Alamofire子模块后生效
open class AlamofireImpl: NSObject, RequestPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = AlamofireImpl()
    
    /// SessionConfiguration配置，默认nil
    open var sessionConfiguration: URLSessionConfiguration = .af.default
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
    /// 自定义请求intercepter句柄，如配置RetryPolicy等，默认nil
    open var requestIntercepterBlock: ((HTTPRequest) -> RequestInterceptor?)?
    
    /// 是否移除响应JSON中的NSNull值，默认true
    open var removeNullValues = true
    /// 有效状态码范围，默认为(100-600)
    open var acceptableStatusCodes: [Int] = Array(100..<600)
    /// 有效的contentType列表，默认nil不修改
    open var acceptableContentTypes: [String]?
    
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
    
    private var rootQueue = DispatchQueue(label: "site.wuyong.queue.request.alamofire.root")
    
    /// 会话，延迟加载前可配置
    open lazy var session: Session = {
        let result = Session(
            configuration: sessionConfiguration,
            rootQueue: rootQueue,
            startRequestsImmediately: true,
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
        
        request.urlRequestFilter(&urlRequest)
        
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
    
    private func adaptRequest(_ alamofireRequest: Request, for request: HTTPRequest) {
        alamofireRequest.onURLSessionTaskCreation { requestTask in
            switch request.requestPriority {
            case .high:
                requestTask.priority = URLSessionTask.highPriority
            case .low:
                requestTask.priority = URLSessionTask.lowPriority
            default:
                requestTask.priority = URLSessionTask.defaultPriority
            }
            
            request.requestTask = requestTask
        }
        
        request.requestAdapter = alamofireRequest
    }
    
    private func handleResponse(for request: HTTPRequest, response: URLResponse, responseObject: Any?, error: Error?, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        var serializationError: Error?
        request.responseObject = responseObject
        if let responseData = request.responseObject as? Data {
            request.responseData = responseData
            request.responseString = String(data: responseData, encoding: RequestManager.shared.stringEncoding(for: request))
            
            switch request.responseSerializerType() {
            case .JSON:
                do {
                    var jsonObject = try Data.fw_jsonDecode(responseData)
                    if removeNullValues {
                        jsonObject = JSONObjectByRemovingKeysWithNullValues(jsonObject, readingOptions: [])
                    }
                    
                    request.responseObject = jsonObject
                    request.responseJSONObject = request.responseObject
                } catch {
                    serializationError = AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error))
                    
                    request.responseObject = nil
                    request.responseJSONObject = request.responseObject
                }
            default:
                break
            }
        }
        
        completionHandler?(response, request.responseObject, error ?? serializationError)
    }
    
    // MARK: - RequestPlugin
    open func startDataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        let dataRequest: DataRequest
        let requestIntercepter = requestIntercepterBlock?(request)
        
        if let customUrlRequest = request.customUrlRequest() {
            dataRequest = session.request(customUrlRequest, interceptor: requestIntercepter)
        } else {
            let requestUrl = RequestManager.shared.buildRequestUrl(for: request)
            let method: HTTPMethod = .init(rawValue: request.requestMethod().rawValue)
            let parameters = request.requestArgument() as? [String: Any]
            var headers: HTTPHeaders?
            if let requestHeaders = request.requestHeaders() {
                headers = .init(requestHeaders)
            }
            
            if request.constructingBodyBlock != nil {
                dataRequest = session.upload(multipartFormData: { formData in
                    parameters?.forEach { (field, value) in
                        if let data = (value as? Data) ?? String.fw_safeString(value).data(using: .utf8) {
                            formData.append(data, name: field)
                        }
                    }
                    
                    request.constructingBodyBlock?(formData)
                }, to: requestUrl, method: method, headers: headers, interceptor: requestIntercepter, requestModifier: { [weak self] urlRequest in
                    self?.modifyUrlRequest(urlRequest: &urlRequest, for: request)
                })
            } else {
                dataRequest = session.request(requestUrl, method: method, parameters: parameters, encoding: request.requestSerializerType() == .JSON ? JSONEncoding.default : URLEncoding.default, headers: headers, interceptor: requestIntercepter, requestModifier: { [weak self] urlRequest in
                    self?.modifyUrlRequest(urlRequest: &urlRequest, for: request)
                })
            }
        }
        
        adaptRequest(dataRequest, for: request)
        
        if let authHeaders = request.requestAuthorizationHeaders(),
           let authUser = authHeaders.first,
           let authPwd = authHeaders.last {
            dataRequest.authenticate(username: authUser, password: authPwd)
        }
        if let progressBlock = request.uploadProgressBlock {
            dataRequest.uploadProgress(closure: progressBlock)
        }
        dataRequest.validate(statusCode: acceptableStatusCodes)
        if let contentTypes = acceptableContentTypes {
            dataRequest.validate(contentType: contentTypes)
        }
        dataRequest.response { [weak self] response in
            self?.handleResponse(for: request, response: response.response ?? HTTPURLResponse(), responseObject: response.data, error: response.error, completionHandler: completionHandler)
        }
    }
    
    open func startDownloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) throws {
        let downloadRequest: DownloadRequest
        let requestIntercepter = requestIntercepterBlock?(request)
        
        if let resumeData = resumeData {
            downloadRequest = session.download(resumingWith: resumeData, interceptor: requestIntercepter, to: { _, _ in
                return (URL(fileURLWithPath: destination, isDirectory: false), [])
            })
        } else {
            let requestUrl = RequestManager.shared.buildRequestUrl(for: request)
            let method: HTTPMethod = .init(rawValue: request.requestMethod().rawValue)
            var headers: HTTPHeaders?
            if let requestHeaders = request.requestHeaders() {
                headers = .init(requestHeaders)
            }
            
            downloadRequest = session.download(requestUrl, method: method, parameters: request.requestArgument() as? [String: Any], encoding: request.requestSerializerType() == .JSON ? JSONEncoding.default : URLEncoding.default, headers: headers, interceptor: requestIntercepter, requestModifier: { [weak self] urlRequest in
                self?.modifyUrlRequest(urlRequest: &urlRequest, for: request)
            }, to: { _, _ in
                return (URL(fileURLWithPath: destination, isDirectory: false), [])
            })
        }
        
        adaptRequest(downloadRequest, for: request)
        
        if let authHeaders = request.requestAuthorizationHeaders(),
           let authUser = authHeaders.first,
           let authPwd = authHeaders.last {
            downloadRequest.authenticate(username: authUser, password: authPwd)
        }
        if let progressBlock = request.downloadProgressBlock {
            downloadRequest.downloadProgress(closure: progressBlock)
        }
        downloadRequest.validate(statusCode: acceptableStatusCodes)
        if let contentTypes = acceptableContentTypes {
            downloadRequest.validate(contentType: contentTypes)
        }
        downloadRequest.response { [weak self] response in
            self?.handleResponse(for: request, response: response.response ?? HTTPURLResponse(), responseObject: response.fileURL, error: response.error, completionHandler: { response, responseObject, error in
                completionHandler?(response, responseObject as? URL, error)
            })
        }
    }
    
    open func suspendRequest(_ request: HTTPRequest) {
        (request.requestAdapter as? Request)?.suspend()
    }
    
    open func resumeRequest(_ request: HTTPRequest) {
        (request.requestAdapter as? Request)?.resume()
    }
    
    open func cancelRequest(_ request: HTTPRequest) {
        (request.requestAdapter as? Request)?.cancel()
    }
    
}

// MARK: - AFError+AlamofireImpl
extension AFError: RequestErrorProtocol, UnderlyingErrorProtocol {}

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
