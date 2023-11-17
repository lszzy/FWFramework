//
//  HTTPRequest.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

// MARK: - HTTPRequest
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

/// 响应序列化类型
public enum ResponseSerializerType: Int {
    case HTTP = 0
    case JSON
    case xmlParser
}

/// 请求优先级
public enum RequestPriority: Int {
    case `default` = 0
    case low = -4
    case high = 4
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
    open var error: Error? {
        get {
            return _error
        }
        set {
            if let error = newValue as? NSError {
                error.fw_setPropertyBool(true, forName: "isRequestError")
                _error = error
            } else {
                _error = nil
            }
        }
    }
    private var _error: Error?
    
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

// MARK: - RequestMultipartFormData
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

// MARK: - RequestError
/// 请求错误
public enum RequestError: Int, Swift.Error, CustomNSError {
    case cacheExpired = -1
    case cacheVersionMismatch = -2
    case cacheSensitiveDataMismatch = -3
    case cacheAppVersionMismatch = -4
    case cacheInvalidCacheTime = -5
    case cacheInvalidMetadata = -6
    case cacheInvalidCacheData = -7
    case validationInvalidStatusCode = -8
    case validationInvalidJSONFormat = -9
    
    public static var errorDomain: String { "site.wuyong.error.request" }
    public var errorCode: Int { self.rawValue }
    public var errorUserInfo: [String: Any] {
        switch self {
        case .cacheExpired:
            return [NSLocalizedDescriptionKey: "Cache expired"]
        case .cacheVersionMismatch:
            return [NSLocalizedDescriptionKey: "Cache version mismatch"]
        case .cacheSensitiveDataMismatch:
            return [NSLocalizedDescriptionKey: "Cache sensitive data mismatch"]
        case .cacheAppVersionMismatch:
            return [NSLocalizedDescriptionKey: "App version mismatch"]
        case .cacheInvalidCacheTime:
            return [NSLocalizedDescriptionKey: "Invalid cache time"]
        case .cacheInvalidMetadata:
            return [NSLocalizedDescriptionKey: "Invalid metadata. Cache may not exist"]
        case .cacheInvalidCacheData:
            return [NSLocalizedDescriptionKey: "Invalid cache data"]
        case .validationInvalidStatusCode:
            return [NSLocalizedDescriptionKey: "Invalid status code"]
        case .validationInvalidJSONFormat:
            return [NSLocalizedDescriptionKey: "Invalid JSON format"]
        }
    }
    
    /// 判断是否是网络请求错误
    public static func isRequestError(_ error: Error?) -> Bool {
        guard let error = error as? NSError else { return false }
        if error.domain == NSURLErrorDomain { return true }
        return error.fw_propertyBool(forName: "isRequestError")
    }
    
    /// 判断是否是网络连接错误
    public static func isConnectionError(_ error: Error?) -> Bool {
        guard let error = error as? NSError else { return false }
        return connectionErrorCodes.contains(error.code)
    }
    
    /// 判断是否是网络取消错误
    public static func isCancelledError(_ error: Error?) -> Bool {
        guard let error = error as? NSError else { return false }
        return cancelledErrorCodes.contains(error.code)
    }
    
    private static let connectionErrorCodes: [Int] = [
        NSURLErrorCancelled,
        NSURLErrorBadURL,
        NSURLErrorTimedOut,
        NSURLErrorUnsupportedURL,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorNotConnectedToInternet,
        NSURLErrorUserCancelledAuthentication,
        NSURLErrorUserAuthenticationRequired,
        NSURLErrorAppTransportSecurityRequiresSecureConnection,
        NSURLErrorSecureConnectionFailed,
        NSURLErrorServerCertificateHasBadDate,
        NSURLErrorServerCertificateUntrusted,
        NSURLErrorServerCertificateHasUnknownRoot,
        NSURLErrorServerCertificateNotYetValid,
        NSURLErrorClientCertificateRejected,
        NSURLErrorClientCertificateRequired,
        NSURLErrorCannotLoadFromNetwork,
        NSURLErrorInternationalRoamingOff,
        NSURLErrorCallIsActive,
        NSURLErrorDataNotAllowed,
        NSURLErrorRequestBodyStreamExhausted,
    ]
    
    private static let cancelledErrorCodes: [Int] = [
        NSURLErrorCancelled,
        NSURLErrorUserCancelledAuthentication,
        NSUserCancelledError,
    ]
}
