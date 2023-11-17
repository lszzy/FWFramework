//
//  HTTPRequest.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

/// 请求验证错误
public enum RequestValidationError: Int, Swift.Error, CustomNSError {
    case invalidStatusCode = -8
    case invalidJSONFormat = -9
    
    public static var errorDomain: String { "site.wuyong.error.request.validation" }
    public var errorCode: Int { self.rawValue }
    public var errorUserInfo: [String: Any] {
        switch self {
        case .invalidStatusCode:
            return [NSLocalizedDescriptionKey: "Invalid status code"]
        case .invalidJSONFormat:
            return [NSLocalizedDescriptionKey: "Invalid JSON format"]
        }
    }
}

/// 请求缓存错误
public enum RequestCacheError: Int, Swift.Error, CustomNSError {
    case expired = -1
    case versionMismatch = -2
    case sensitiveDataMismatch = -3
    case appVersionMismatch = -4
    case invalidCacheTime = -5
    case invalidMetadata = -6
    case invalidCacheData = -7
    
    public static var errorDomain: String { "site.wuyong.error.request.cache" }
    public var errorCode: Int { self.rawValue }
    public var errorUserInfo: [String: Any] {
        switch self {
        case .expired:
            return [NSLocalizedDescriptionKey: "Cache expired"]
        case .versionMismatch:
            return [NSLocalizedDescriptionKey: "Cache version mismatch"]
        case .sensitiveDataMismatch:
            return [NSLocalizedDescriptionKey: "Cache sensitive data mismatch"]
        case .appVersionMismatch:
            return [NSLocalizedDescriptionKey: "App version mismatch"]
        case .invalidCacheTime:
            return [NSLocalizedDescriptionKey: "Invalid cache time"]
        case .invalidMetadata:
            return [NSLocalizedDescriptionKey: "Invalid metadata. Cache may not exist"]
        case .invalidCacheData:
            return [NSLocalizedDescriptionKey: "Invalid cache data"]
        }
    }
}

/// 请求方式
public enum RequestMethod: String {
    case GET = "GET"
    case POST = "POST"
    case HEAD = "HEAD"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
    case OPTIONS = "OPTIONS"
}

/// 请求序列化类型
public enum RequestSerializerType: Int {
    case HTTP = 0
    case JSON
}

/// 请求优先级
public enum RequestPriority: Int {
    case `default` = 0
    case low = -4
    case high = 4
}

/// 响应序列化类型
public enum ResponseSerializerType: Int {
    case HTTP = 0
    case JSON
    case xmlParser
}

/// 请求表单数据协议
public protocol RequestMultipartFormData: AnyObject {
    /// 添加文件，自动使用fileName和mimeType
    func appendPart(fileURL: URL, name: String)
    /// 添加文件，指定fileName和mimeType
    func appendPart(fileURL: URL, name: String, fileName: String, mimeType: String)
    /// 添加输入流，指定fileName和mimeType
    func appendPart(inputStream: InputStream?, name: String, fileName: String, length: Int64, mimeType: String)
    /// 添加文件数据，指定fileName和mimeType
    func appendPart(fileData: Data, name: String, fileName: String, mimeType: String)
    /// 添加表单数据
    func appendPart(formData: Data, name: String)
    /// 添加头信息和主题数据
    func appendPart(headers: [String: String]?, body: Data)
    /// 限制请求带宽
    func throttleBandwidth(packetSize numberOfBytes: UInt, dalay: TimeInterval)
}

/// 请求代理
public protocol RequestDelegate: AnyObject {
    /// 请求完成
    func requestFinished(_ request: HTTPRequest)
    /// 请求失败
    func requestFailed(_ request: HTTPRequest)
}

extension RequestDelegate {
    /// 默认实现请求完成
    public func requestFinished(_ request: HTTPRequest) {}
    /// 默认实现请求失败
    public func requestFailed(_ request: HTTPRequest) {}
}

/// 请求配件
public protocol RequestAccessoryProtocol: AnyObject {
    /// 网络请求即将开始
    func requestWillStart(_ request: Any)
    /// 网络请求即将结束
    func requestWillStop(_ request: Any)
    /// 网络请求已经结束
    func requestDidStop(_ request: Any)
}

/// 默认句柄请求配件类
open class RequestAccessory: NSObject, RequestAccessoryProtocol {
    /// 即将开始句柄
    open var willStartBlock: ((Any) -> Void)?
    /// 即将结束句柄
    open var willStopBlock: ((Any) -> Void)?
    /// 已经结束句柄
    open var didStopBlock: ((Any) -> Void)?
    
    open func requestWillStart(_ request: Any) {
        if willStartBlock != nil {
            willStartBlock?(request)
            willStartBlock = nil
        }
    }
    
    open func requestWillStop(_ request: Any) {
        if willStopBlock != nil {
            willStopBlock?(request)
            willStopBlock = nil
        }
    }
    
    open func requestDidStop(_ request: Any) {
        if didStopBlock != nil {
            didStopBlock?(request)
            didStopBlock = nil
        }
    }
}

/// 请求重试器协议
public protocol RequestRetryerProtocol: AnyObject {
    /// 请求重试次数
    func requestRetryCount(for request: HTTPRequest) -> Int
    /// 请求重试间隔
    func requestRetryInterval(for request: HTTPRequest) -> TimeInterval
    /// 请求重试超时时间
    func requestRetryTimeout(for request: HTTPRequest) -> TimeInterval
    /// 请求重试验证方法，返回是否重试，requestRetryCount大于0生效
    func requestRetryValidator(for request: HTTPRequest, response: HTTPURLResponse, responseObject: Any?, error: Error?) -> Bool
    /// 请求重试处理方法，requestRetryValidator返回true生效，必须调用completionHandler
    func requestRetryProcessor(for request: HTTPRequest, response: HTTPURLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping (Bool) -> Void)
}

/// 默认请求重试器，直接调用request的钩子方法
open class RequestRetryer: NSObject, RequestRetryerProtocol {
    public static let shared = RequestRetryer()
    
    open func requestRetryCount(for request: HTTPRequest) -> Int {
        return request.requestRetryCount()
    }
    
    open func requestRetryInterval(for request: HTTPRequest) -> TimeInterval {
        return request.requestRetryInterval()
    }
    
    open func requestRetryTimeout(for request: HTTPRequest) -> TimeInterval {
        return request.requestRetryTimeout()
    }
    
    open func requestRetryValidator(for request: HTTPRequest, response: HTTPURLResponse, responseObject: Any?, error: Error?) -> Bool {
        return request.requestRetryValidator(response, responseObject: responseObject, error: error)
    }
    
    open func requestRetryProcessor(for request: HTTPRequest, response: HTTPURLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping (Bool) -> Void) {
        request.requestRetryProcessor(response, responseObject: responseObject, error: error, completionHandler: completionHandler)
    }
}

/// HTTP请求基类，支持缓存和重试机制，使用时继承即可
///
/// [YTKNetwork](https://github.com/yuantiku/YTKNetwork)
open class HTTPRequest: NSObject {
    
    // MARK: - Accessor
    /// 自定义请求插件，未设置时自动从插件池加载
    open var requestPlugin: RequestPlugin?
    
    /// 当前URLSessionTask，请求开始后可用
    open var requestTask: URLSessionTask?
    /// 当前请求唯一标志符
    open var requestIdentifier: Int {
        return requestTask?.taskIdentifier ?? 0
    }
    /// 当前URLRequest
    open var currentRequest: URLRequest? {
        return requestTask?.currentRequest
    }
    /// 原始URLRequest
    open var originalRequest: URLRequest? {
        return requestTask?.originalRequest
    }
    /// 当前响应
    open var response: HTTPURLResponse? {
        return requestTask?.response as? HTTPURLResponse
    }
    /// 当前响应状态码
    open var responseStatusCode: Int {
        return response?.statusCode ?? 0
    }
    /// 当前响应服务器时间
    open var responseServerTime: TimeInterval {
        guard let serverDate = response?.allHeaderFields["Date"] as? String else { return 0 }
        return Date.fw_formatServerDate(serverDate)
    }
    /// 当前响应Header
    open var responseHeaders: [AnyHashable: Any]? {
        return response?.allHeaderFields
    }
    /// 当前响应数据
    open var responseData: Data?
    /// 当前响应字符串
    open var responseString: String?
    /// 当前响应对象
    open var responseObject: Any?
    /// 当前响应JSON对象
    open var responseJSONObject: Any?
    /// 当前网络错误
    open var error: Error?
    
    // MARK: - Override
    open func baseUrl() -> String {
        return ""
    }
    
    open func requestUrl() -> String {
        return ""
    }
    
    open func cdnUrl() -> String {
        return ""
    }
    
    open func requestTimeoutInterval() -> TimeInterval {
        return 60
    }
    
    open func requestMethod() -> RequestMethod {
        return .GET
    }
    
    open func requestSerializerType() -> RequestSerializerType {
        return .HTTP
    }
    
    open func responseSerializerType() -> ResponseSerializerType {
        return .JSON
    }
    
    open func filterUrlRequest(_ urlRequest: NSMutableURLRequest) {
        
    }
    
    open func filterResponse() throws {
        
    }
    
    open func requestCompletePreprocessor() {
        
    }
    
    open func requestCompleteFilter() {
        
    }
    
    open func requestFailedPreprocessor() {
        
    }
    
    open func requestFailedFilter() {
        
    }
    
    // MARK: - Action
    open func start() {
        
    }
    
    open func stop() {
        
    }
    
    open func start(success: ((Self) -> Void)?, failure: ((Self) -> Void)?) {
        
    }
    
    open func start(completion: ((Self) -> Void)?) {
        
    }
    
    open func startSynchronously(success: ((Self) -> Void)?, failure: ((Self) -> Void)?) {
        
    }
    
    open func startSynchronously(filter: (() -> Bool)? = nil, completion: ((Self) -> Void)?) {
        
    }
    
    // MARK: - Retry
    /// 自定义请求重试器，未设置时使用默认重试器
    open var requestRetryer: RequestRetryerProtocol?
    
    /// 请求重试次数，默认0
    open func requestRetryCount() -> Int {
        return 0
    }
    
    /// 请求重试间隔，默认0
    open func requestRetryInterval() -> TimeInterval {
        return 0
    }
    
    /// 请求重试超时时间，默认0
    open func requestRetryTimeout() -> TimeInterval {
        return 0
    }
    
    /// 请求重试验证方法，requestRetryCount大于0生效，默认检查状态码和错误
    open func requestRetryValidator(_ response: HTTPURLResponse, responseObject: Any?, error: Error?) -> Bool {
        let statusCode = response.statusCode
        return error != nil || statusCode < 200 || statusCode > 299
    }
    
    /// 请求重试处理方法，requestRetryValidator返回true生效，默认调用completionHandler(true)
    open func requestRetryProcessor(_ response: HTTPURLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
}
