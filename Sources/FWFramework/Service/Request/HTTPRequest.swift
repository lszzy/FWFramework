//
//  HTTPRequest.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation
import UIKit

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
    case QUERY = "QUERY"
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
/// 注意事项：
/// 如果vc请求回调句柄中未使用weak self，会产生强引用，则self会在vc关闭且等待请求完成后才会释放
/// 如果vc请求回调句柄中使用了weak self，不会产生强引用，则self会在vc关闭时立即释放，不会等待请求完成
///
/// [YTKNetwork](https://github.com/yuantiku/YTKNetwork)
open class HTTPRequest: CustomStringConvertible {
    
    /// 请求完成句柄
    public typealias Completion = (HTTPRequest) -> Void
    
    /// 请求构建器，可继承
    open class Builder {
        
        public private(set) var baseUrl: String?
        public private(set) var requestUrl: String?
        public private(set) var cdnUrl: String?
        public private(set) var useCDN: Bool?
        public private(set) var allowsCellularAccess: Bool?
        public private(set) var requestTimeoutInterval: TimeInterval?
        public private(set) var requestCachePolicy: URLRequest.CachePolicy?
        public private(set) var requestMethod: RequestMethod?
        public private(set) var requestArgument: Any?
        public private(set) var constructingBodyBlock: ((RequestMultipartFormData) -> Void)?
        public private(set) var resumableDownloadPath: String?
        public private(set) var requestSerializerType: RequestSerializerType?
        public private(set) var responseSerializerType: ResponseSerializerType?
        public private(set) var requestAuthorizationHeaders: [String]?
        public private(set) var requestHeaders: [String: String]?
        public private(set) var requestPriority: RequestPriority?
        public private(set) var requestUserInfo: [AnyHashable: Any]?
        public private(set) var customUrlRequest: URLRequest?
        public private(set) var isSynchronously: Bool?
        public private(set) var tag: Int?
        public private(set) var statusCodeValidator: ((_ request: HTTPRequest) -> Bool)?
        public private(set) var jsonValidator: Any?
        public private(set) var urlRequestFilter: ((_ request: HTTPRequest, _ urlRequest: inout URLRequest) -> Void)?
        public private(set) var responseFilter: ((_ request: HTTPRequest) throws -> Void)?
        public private(set) var responseMockValidator: ((HTTPRequest) -> Bool)?
        public private(set) var responseMockProcessor: ((HTTPRequest) -> Bool)?
        public private(set) var requestRetryCount: Int?
        public private(set) var requestRetryInterval: TimeInterval?
        public private(set) var requestRetryTimeout: TimeInterval?
        public private(set) var requestRetryValidator: ((_ request: HTTPRequest, _ response: HTTPURLResponse, _ responseObject: Any?, _ error: Error?) -> Bool)?
        public private(set) var requestRetryProcessor: ((_ request: HTTPRequest, _ response: HTTPURLResponse, _ responseObject: Any?, _ error: Error?, _ completionHandler: @escaping (Bool) -> Void) -> Void)?
        public private(set) var requestCompletePreprocessor: Completion?
        public private(set) var requestCompleteFilter: Completion?
        public private(set) var requestFailedPreprocessor: Completion?
        public private(set) var requestFailedFilter: Completion?
        public private(set) var cacheTimeInSeconds: Int?
        public private(set) var cacheVersion: Int?
        public private(set) var cacheSensitiveData: Any?
        public private(set) var cacheArgumentFilter: ((_ request: HTTPRequest, _ argument: Any?) -> Any?)?
        public private(set) var writeCacheAsynchronously: Bool?
        
        /// 构造方法
        public init() {}
        
        /// 请求基准URL，默认空，示例：https://www.wuyong.site
        @discardableResult
        public func baseUrl(_ baseUrl: String) -> Self {
            self.baseUrl = baseUrl
            return self
        }
        
        /// 请求URL地址，默认空，示例：/v1/user
        @discardableResult
        public func requestUrl(_ requestUrl: String) -> Self {
            self.requestUrl = requestUrl
            return self
        }
        
        /// 请求可选CDN地址，默认空
        @discardableResult
        public func cdnUrl(_ cdnUrl: String) -> Self {
            self.cdnUrl = cdnUrl
            return self
        }
        
        /// 是否使用CDN
        @discardableResult
        public func useCDN(_ useCDN: Bool) -> Self {
            self.useCDN = useCDN
            return self
        }
        
        /// 是否允许蜂窝网络访问，默认true
        @discardableResult
        public func allowsCellularAccess(_ allows: Bool) -> Self {
            self.allowsCellularAccess = allows
            return self
        }
        
        /// 请求超时，默认60秒
        @discardableResult
        public func requestTimeoutInterval(_ interval: TimeInterval) -> Self {
            self.requestTimeoutInterval = interval
            return self
        }
        
        /// 自定义请求缓存策略，默认nil不处理
        @discardableResult
        public func requestCachePolicy(_ cachePolicy: URLRequest.CachePolicy?) -> Self {
            self.requestCachePolicy = cachePolicy
            return self
        }
        
        /// 请求方式，默认GET
        @discardableResult
        public func requestMethod(_ requestMethod: RequestMethod) -> Self {
            self.requestMethod = requestMethod
            return self
        }
        
        /// 批量添加请求参数，建议[String: Any]?，默认nil
        @discardableResult
        public func requestArgument(_ argument: Any?) -> Self {
            if let argumentDict = argument as? [AnyHashable: Any] {
                if let dict = self.requestArgument as? [AnyHashable: Any] {
                    self.requestArgument = dict.merging(argumentDict, uniquingKeysWith: { $1 })
                } else {
                    self.requestArgument = argumentDict
                }
            } else {
                self.requestArgument = argument
            }
            return self
        }
        
        /// 添加单个参数
        @discardableResult
        public func requestArgument(_ name: String, value: Any?) -> Self {
            var dict = self.requestArgument as? [AnyHashable: Any] ?? [:]
            dict[name] = value
            self.requestArgument = dict
            return self
        }
        
        /// 自定义POST请求HTTP body数据
        @discardableResult
        public func constructingBodyBlock(_ block: ((RequestMultipartFormData) -> Void)?) -> Self {
            self.constructingBodyBlock = block
            return self
        }
        
        /// 断点续传下载路径
        @discardableResult
        public func resumableDownloadPath(_ path: String?) -> Self {
            self.resumableDownloadPath = path
            return self
        }
        
        /// 请求序列化方式，默认HTTP
        @discardableResult
        public func requestSerializerType(_ serializerType: RequestSerializerType) -> Self {
            self.requestSerializerType = serializerType
            return self
        }
        
        /// 响应序列化方式，默认JSON
        @discardableResult
        public func responseSerializerType(_ serializerType: ResponseSerializerType) -> Self {
            self.responseSerializerType = serializerType
            return self
        }
        
        /// HTTP请求授权Header数组，示例：["Username", "Password"]
        @discardableResult
        public func requestAuthorizationHeaders(_ array: [String]?) -> Self {
            self.requestAuthorizationHeaders = array
            return self
        }
        
        /// 设置HTTP请求授权用户名和密码
        @discardableResult
        public func requestAuthorization(username: String?, password: String?) -> Self {
            if let username = username, let password = password {
                self.requestAuthorizationHeaders = [username, password]
            } else {
                self.requestAuthorizationHeaders = nil
            }
            return self
        }
        
        /// 批量添加请求Header
        @discardableResult
        public func requestHeaders(_ headers: [String: String]?) -> Self {
            guard let headers = headers else { return self }
            if self.requestHeaders != nil {
                self.requestHeaders?.merge(headers, uniquingKeysWith: { $1 })
            } else {
                self.requestHeaders = headers
            }
            return self
        }
        
        /// 添加单个请求Header
        @discardableResult
        public func requestHeader(_ name: String, value: String?) -> Self {
            if self.requestHeaders == nil {
                self.requestHeaders = [:]
            }
            self.requestHeaders?[name] = value
            return self
        }
        
        /// 请求优先级，默认default
        @discardableResult
        public func requestPriority(_ priority: RequestPriority) -> Self {
            self.requestPriority = priority
            return self
        }
        
        /// 自定义用户信息
        @discardableResult
        public func requestUserInfo(_ userInfo: [AnyHashable: Any]?) -> Self {
            self.requestUserInfo = userInfo
            return self
        }
        
        /// JSON验证器，默认支持AnyValidator
        @discardableResult
        public func jsonValidator(_ validator: Any?) -> Self {
            self.jsonValidator = validator
            return self
        }
        
        /// 构建自定义URLRequest
        @discardableResult
        public func customUrlRequest(_ urlRequest: URLRequest?) -> Self {
            self.customUrlRequest = urlRequest
            return self
        }
        
        /// 设置是否是同步串行请求
        @discardableResult
        public func synchronously(_ synchronously: Bool) -> Self {
            self.isSynchronously = synchronously
            return self
        }
        
        /// 自定义标签，默认0
        @discardableResult
        public func tag(_ tag: Int) -> Self {
            self.tag = tag
            return self
        }
        
        /// 状态码验证器
        @discardableResult
        public func statusCodeValidator(_ validator: ((_ request: HTTPRequest) -> Bool)?) -> Self {
            self.statusCodeValidator = validator
            return self
        }
        
        /// 请求发送前URLRequest过滤方法，默认不处理
        @discardableResult
        public func urlRequestFilter(_ filter: ((_ request: HTTPRequest, _ urlRequest: inout URLRequest) -> Void)?) -> Self {
            self.urlRequestFilter = filter
            return self
        }
        
        /// 请求回调前Response过滤方法，默认成功不抛异常
        @discardableResult
        public func responseFilter(_ filter: ((_ request: HTTPRequest) throws -> Void)?) -> Self {
            self.responseFilter = filter
            return self
        }
        
        /// 调试请求Mock验证器，默认判断404
        @discardableResult
        public func responseMockValidator(_ validator: ((_ request: HTTPRequest) -> Bool)?) -> Self {
            self.responseMockValidator = validator
            return self
        }
        
        /// 调试请求Mock处理器，请求失败时且回调前在后台线程调用
        @discardableResult
        public func responseMockProcessor(_ block: ((_ request: HTTPRequest) -> Bool)?) -> Self {
            self.responseMockProcessor = block
            return self
        }
        
        /// 请求完成预处理器，后台线程调用
        @discardableResult
        public func requestCompletePreprocessor(_ block: Completion?) -> Self {
            self.requestCompletePreprocessor = block
            return self
        }
        
        /// 请求完成过滤器，主线程调用
        @discardableResult
        public func requestCompleteFilter(_ block: Completion?) -> Self {
            self.requestCompleteFilter = block
            return self
        }
        
        /// 请求失败预处理器，后台线程调用
        @discardableResult
        public func requestFailedPreprocessor(_ block: Completion?) -> Self {
            self.requestFailedPreprocessor = block
            return self
        }
        
        /// 请求失败过滤器，主线程调用
        @discardableResult
        public func requestFailedFilter(_ block: Completion?) -> Self {
            self.requestFailedFilter = block
            return self
        }
        
        /// 请求重试次数，默认0
        @discardableResult
        public func requestRetryCount(_ count: Int) -> Self {
            self.requestRetryCount = count
            return self
        }
        
        /// 请求重试间隔，默认0
        @discardableResult
        public func requestRetryInterval(_ interval: TimeInterval) -> Self {
            self.requestRetryInterval = interval
            return self
        }
        
        /// 请求重试超时时间，默认0
        @discardableResult
        public func requestRetryTimeout(_ timeout: TimeInterval) -> Self {
            self.requestRetryTimeout = timeout
            return self
        }
        
        /// 请求重试验证方法，默认检查状态码和错误
        @discardableResult
        public func requestRetryValidator(_ validator: ((_ request: HTTPRequest, _ response: HTTPURLResponse, _ responseObject: Any?, _ error: Error?) -> Bool)?) -> Self {
            self.requestRetryValidator = validator
            return self
        }
        
        /// 请求重试处理方法，回调处理状态，默认调用completionHandler(true)
        @discardableResult
        public func requestRetryProcessor(_ processor: ((_ request: HTTPRequest, _ response: HTTPURLResponse, _ responseObject: Any?, _ error: Error?, _ completionHandler: @escaping (Bool) -> Void) -> Void)?) -> Self {
            self.requestRetryProcessor = processor
            return self
        }
        
        /// 缓存有效期，默认-1不缓存
        @discardableResult
        public func cacheTimeInSeconds(_ seconds: Int) -> Self {
            self.cacheTimeInSeconds = seconds
            return self
        }
        
        /// 缓存版本号，默认0
        @discardableResult
        public func cacheVersion(_ version: Int) -> Self {
            self.cacheVersion = version
            return self
        }
        
        /// 缓存附加数据，变化时会更新缓存
        @discardableResult
        public func cacheSensitiveData(_ sensitiveData: Any?) -> Self {
            self.cacheSensitiveData = sensitiveData
            return self
        }
        
        /// 缓存文件名过滤器，参数为请求参数，默认返回argument
        @discardableResult
        public func cacheArgumentFilter(_ filter: ((_ request: HTTPRequest, _ argument: Any?) -> Any?)?) -> Self {
            self.cacheArgumentFilter = filter
            return self
        }
        
        /// 是否异步写入缓存，默认true
        @discardableResult
        public func writeCacheAsynchronously(_ async: Bool) -> Self {
            self.writeCacheAsynchronously = async
            return self
        }
        
        /// 构建请求
        open func build() -> HTTPRequest {
            return HTTPRequest(builder: self)
        }
        
    }
    
    // MARK: - Accessor
    /// 自定义请求代理
    open weak var delegate: RequestDelegate?
    /// 自定义标签，默认0
    open var tag: Int = 0
    /// 当前请求的上下文，支持UIViewController|UIView
    open weak var context: AnyObject?
    /// 是否自动显示错误信息，context可不存在
    open var autoShowError = false
    /// 是否自动显示加载信息，context必须存在
    open var autoShowLoading = false
    /// 自定义成功主线程回调句柄
    open var successCompletionBlock: Completion?
    /// 自定义失败主线程回调句柄
    open var failureCompletionBlock: Completion?
    /// 自定义取消回调句柄，不一定主线程调用
    open var requestCancelledBlock: Completion?
    /// 自定义请求配件数组
    open var requestAccessories: [RequestAccessoryProtocol]?
    /// 自定义POST请求HTTP body数据
    open var constructingBodyBlock: ((RequestMultipartFormData) -> Void)?
    /// 断点续传下载路径
    open var resumableDownloadPath: String?
    /// 断点续传进度句柄
    open var downloadProgressBlock: ((Progress) -> Void)?
    /// 上传进度句柄
    open var uploadProgressBlock: ((Progress) -> Void)?
    /// 请求优先级，默认default
    open var requestPriority: RequestPriority = .default
    /// 是否是同步串行请求，默认false为异步并发请求
    open var isSynchronously: Bool = false
    /// 自定义用户信息
    open var requestUserInfo: [AnyHashable: Any]?
    /// 是否使用已缓存响应
    open var useCacheResponse: Bool = false
    /// 是否是本地缓存数据
    open private(set) var isDataFromCache: Bool = false
    
    /// 当前请求唯一标志符，只读
    public let requestIdentifier = UUID().uuidString
    /// 当前请求适配器，根据插件不同而不同
    open var requestAdapter: Any?
    /// 当前URLSessionTask，请求开始后才可用
    open var requestTask: URLSessionTask?
    
    /// 当前响应Header
    open var responseHeaders: [AnyHashable: Any]? {
        return (requestTask?.response as? HTTPURLResponse)?.allHeaderFields
    }
    /// 当前响应状态码
    open var responseStatusCode: Int {
        return (requestTask?.response as? HTTPURLResponse)?.statusCode ?? 0
    }
    /// 当前响应服务器时间
    open var responseServerTime: TimeInterval {
        guard let serverDate = responseHeaders?["Date"] as? String else { return 0 }
        return Date.fw_formatServerDate(serverDate)
    }
    /// 请求开始时间
    open internal(set) var requestStartTime: TimeInterval = 0
    /// 请求总次数
    open internal(set) var requestTotalCount: Int = 0
    /// 请求总时长
    open internal(set) var requestTotalTime: TimeInterval = 0
    
    /// 请求是否已完成，requestTask必须完成且error为nil
    open var isFinished: Bool {
        guard let requestTask = requestTask else { return false }
        return requestTask.state == .completed && error == nil
    }
    /// 请求是否已失败，error不为nil，不检查requestTask
    open var isFailed: Bool {
        return error != nil
    }
    /// 请求是否已取消，含手动取消和requestTask取消
    open var isCancelled: Bool {
        if _isCancelled { return true }
        guard let requestTask = requestTask else { return false }
        return requestTask.state == .canceling
    }
    /// 请求是否已开始，已开始之后再次调用start不会生效
    open private(set) var isStarted: Bool = false
    /// 请求是否已暂停，已开始之后才可暂停
    open private(set) var isSuspended: Bool = false
    /// 请求是否执行中，requestTask状态为running
    open var isExecuting: Bool {
        guard let requestTask = requestTask else { return false }
        return requestTask.state == .running
    }
    
    /// 当前响应数据
    open var responseData: Data? {
        get { return _responseData ?? _cacheData }
        set { _responseData = newValue }
    }
    private var _responseData: Data?
    
    /// 当前响应字符串
    open var responseString: String? {
        get { return _responseString ?? _cacheString }
        set { _responseString = newValue }
    }
    private var _responseString: String?
    
    /// 当前响应对象
    open var responseObject: Any? {
        get { return _responseObject ?? (_cacheJSON ?? _cacheData) }
        set { _responseObject = newValue }
    }
    private var _responseObject: Any?
    
    /// 当前响应JSON对象
    open var responseJSONObject: Any? {
        get { return _responseJSONObject ?? _cacheJSON }
        set { _responseJSONObject = newValue }
    }
    private var _responseJSONObject: Any?
    
    /// 当前网络错误
    open var error: Error? {
        get {
            return _error
        }
        set {
            let error = newValue as? NSError
            error?.fw_setPropertyBool(true, forName: "isRequestError")
            _error = error
        }
    }
    private var _error: Error?
    
    /// 自定义请求配置，未设置时使用全局配置
    open var config: RequestConfig! {
        get { _config ?? RequestConfig.shared }
        set { _config = newValue }
    }
    private var _config: RequestConfig?
    
    /// 当前请求构建器，默认nil
    open private(set) var builder: Builder?
    
    /// 当前上下文配件，用于显示错误和加载信息
    open lazy var contextAccessory: RequestContextAccessory = {
        let result = config.contextAccessoryBlock?(self) ?? RequestContextAccessory()
        return result
    }()
    
    // MARK: - Accessor+Private
    fileprivate var cacheResponseModel: Any?
    private var responseModelBlock: Completion?
    private var _preloadResponseModel: Bool?
    private var _isCancelled = false
    private var _cacheData: Data?
    private var _cacheString: String?
    private var _cacheJSON: Any?
    private var _cacheMetadata: RequestCacheMetadata?
    
    // MARK: - Lifecycle
    /// 默认初始化
    public init() {}
    
    /// 指定Builder初始化，可用于重载Builder
    public init(builder: Builder) {
        self.builder = builder
        
        if let tag = builder.tag { self.tag = tag }
        if let block = builder.constructingBodyBlock { self.constructingBodyBlock = block }
        if let path = builder.resumableDownloadPath { self.resumableDownloadPath = path }
        if let priority = builder.requestPriority { self.requestPriority = priority }
        if let userInfo = builder.requestUserInfo { self.requestUserInfo = userInfo }
        if let synchronously = builder.isSynchronously { self.isSynchronously = synchronously }
    }
    
    /// 请求描述
    open var description: String {
        let url = requestTask?.currentRequest?.url?.absoluteString ?? requestUrl()
        let method = requestTask?.currentRequest?.httpMethod ?? requestMethod().rawValue
        var result = "\(method) \(url)"
        if requestTask?.response != nil { result += " \(responseStatusCode)" }
        return result
    }
    
    // MARK: - Override+Request
    /// 请求基准URL，默认空，示例：https://www.wuyong.site
    open func baseUrl() -> String {
        return builder?.baseUrl ?? ""
    }
    
    /// 请求URL地址，默认空，示例：/v1/user
    open func requestUrl() -> String {
        return builder?.requestUrl ?? ""
    }
    
    /// 请求可选CDN地址，默认空
    open func cdnUrl() -> String {
        return builder?.cdnUrl ?? ""
    }
    
    /// 是否使用CDN
    open func useCDN() -> Bool {
        return builder?.useCDN ?? false
    }
    
    /// 是否允许蜂窝网络访问，默认true
    open func allowsCellularAccess() -> Bool {
        return builder?.allowsCellularAccess ?? true
    }
    
    /// 请求超时，默认60秒
    open func requestTimeoutInterval() -> TimeInterval {
        return builder?.requestTimeoutInterval ?? 60
    }
    
    /// 自定义请求缓存策略，默认nil不处理
    open func requestCachePolicy() -> URLRequest.CachePolicy? {
        return builder?.requestCachePolicy
    }
    
    /// 请求方式，默认GET
    open func requestMethod() -> RequestMethod {
        return builder?.requestMethod ?? .GET
    }
    
    /// 请求附加参数，建议[String: Any]?，默认nil
    open func requestArgument() -> Any? {
        return builder?.requestArgument
    }
    
    /// 请求序列化方式，默认HTTP
    open func requestSerializerType() -> RequestSerializerType {
        return builder?.requestSerializerType ?? .HTTP
    }
    
    /// 响应序列化方式，默认JSON
    open func responseSerializerType() -> ResponseSerializerType {
        return builder?.responseSerializerType ?? .JSON
    }
    
    /// HTTP请求授权Header数组，示例：["UserName", "Password"]
    open func requestAuthorizationHeaders() -> [String]? {
        return builder?.requestAuthorizationHeaders
    }
    
    /// 自定义请求Header字典
    open func requestHeaders() -> [String: String]? {
        return builder?.requestHeaders
    }
    
    /// 请求发送前URLRequest过滤方法，默认不处理
    open func urlRequestFilter(_ urlRequest: inout URLRequest) {
        builder?.urlRequestFilter?(self, &urlRequest)
    }
    
    /// 构建自定义URLRequest
    open func customUrlRequest() -> URLRequest? {
        return builder?.customUrlRequest
    }
    
    // MARK: - Override+Response
    /// JSON验证器，默认支持AnyValidator
    open func jsonValidator() -> Any? {
        return builder?.jsonValidator
    }
    
    /// 状态码验证器
    open func statusCodeValidator() -> Bool {
        if let validator = builder?.statusCodeValidator {
            return validator(self)
        } else {
            let statusCode = responseStatusCode
            return statusCode >= 200 && statusCode <= 299
        }
    }
    
    /// 调试请求Mock验证器，默认判断404
    open func responseMockValidator() -> Bool {
        if let validator = builder?.responseMockValidator ?? config.debugMockValidator {
            return validator(self)
        }
        return responseStatusCode == 404
    }
    
    /// 调试请求Mock处理器，请求失败时且回调前在后台线程调用
    open func responseMockProcessor() -> Bool {
        if let processor = builder?.responseMockProcessor ?? config.debugMockProcessor {
            return processor(self)
        }
        return false
    }
    
    /// 请求回调前Response过滤方法，默认成功不抛异常
    open func responseFilter() throws {
        try builder?.responseFilter?(self)
    }
    
    /// 是否后台预加载响应模型，默认false，仅ResponseModelRequest生效
    open func preloadResponseModel() -> Bool {
        if let preload = _preloadResponseModel {
            return preload
        }
        return config.preloadModelFilter?(self) ?? false
    }
    
    /// 请求完成预处理器，后台线程调用。默认写入请求缓存、预加载响应模型
    open func requestCompletePreprocessor() {
        let responseData = _responseData
        if (responseData != nil) {
            if writeCacheAsynchronously() {
                RequestCache.cacheQueue.async { [weak self] in
                    self?.saveCache(responseData)
                }
            } else {
                saveCache(responseData)
            }
        }
        
        if preloadResponseModel() {
            // 访问responseModel即可自动加载并缓存响应模型
            if let modelRequest = self as? (any ResponseModelRequest) {
                _ = modelRequest.responseModel
            // 调用responseModel自定义预加载句柄
            } else {
                responseModelBlock?(self)
            }
        }
        
        builder?.requestCompletePreprocessor?(self)
    }
    
    /// 请求完成过滤器，主线程调用，默认不处理
    open func requestCompleteFilter() {
        builder?.requestCompleteFilter?(self)
    }
    
    /// 请求失败预处理器，后台线程调用，默认不处理
    open func requestFailedPreprocessor() {
        builder?.requestFailedPreprocessor?(self)
    }
    
    /// 请求失败过滤器，主线程调用，默认不处理
    open func requestFailedFilter() {
        builder?.requestFailedFilter?(self)
    }
    
    // MARK: - Override+Retry
    /// 请求重试次数，默认0
    open func requestRetryCount() -> Int {
        return builder?.requestRetryCount ?? 0
    }
    
    /// 请求重试间隔，默认0
    open func requestRetryInterval() -> TimeInterval {
        return builder?.requestRetryInterval ?? 0
    }
    
    /// 请求重试超时时间，默认0
    open func requestRetryTimeout() -> TimeInterval {
        return builder?.requestRetryTimeout ?? 0
    }
    
    /// 请求重试验证方法，默认检查状态码和错误
    open func requestRetryValidator(_ response: HTTPURLResponse, responseObject: Any?, error: Error?) -> Bool {
        if let validator = builder?.requestRetryValidator {
            return validator(self, response, responseObject, error)
        } else {
            let statusCode = response.statusCode
            return error != nil || statusCode < 200 || statusCode > 299
        }
    }
    
    /// 请求重试处理方法，回调处理状态，默认调用completionHandler(true)
    open func requestRetryProcessor(_ response: HTTPURLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping (Bool) -> Void) {
        if let processor = builder?.requestRetryProcessor {
            processor(self, response, responseObject, error, completionHandler)
        } else {
            completionHandler(true)
        }
    }
    
    // MARK: - Override+Cache
    /// 缓存有效期，默认-1不缓存
    open func cacheTimeInSeconds() -> Int {
        return builder?.cacheTimeInSeconds ?? -1
    }
    
    /// 缓存版本号，默认0
    open func cacheVersion() -> Int {
        return builder?.cacheVersion ?? 0
    }
    
    /// 缓存敏感数据，变化时会更新缓存
    open func cacheSensitiveData() -> Any? {
        return builder?.cacheSensitiveData
    }
    
    /// 缓存文件名过滤器，参数为请求参数，默认返回argument
    open func cacheArgumentFilter(_ argument: Any?) -> Any? {
        if let filter = builder?.cacheArgumentFilter {
            return filter(self, argument)
        } else {
            return argument
        }
    }
    
    /// 是否异步写入缓存，默认true
    open func writeCacheAsynchronously() -> Bool {
        return builder?.writeCacheAsynchronously ?? true
    }
    
    // MARK: - Action
    /// 当前请求的上下文，支持UIViewController|UIView
    @discardableResult
    open func context(_ context: AnyObject?) -> Self {
        self.context = context
        return self
    }
    
    /// 开始请求，如果加载缓存且缓存存在时允许再调用一次
    @discardableResult
    open func start() -> Self {
        guard !_isCancelled, !isStarted else { return self }
        
        if !useCacheResponse || resumableDownloadPath != nil {
            startWithoutCache()
            return self
        }
        
        do {
            try loadCacheResponse(isPreload: false, completion: nil)
            return self
        } catch {
            startWithoutCache()
            return self
        }
    }
    
    /// 暂停请求，已开始后调用才会生效
    @discardableResult
    open func suspend() -> Self {
        guard !_isCancelled, isStarted else { return self }
        
        isSuspended = true
        config.requestPlugin.suspendRequest(self)
        return self
    }
    
    /// 继续请求，未开始或暂停后可调用
    @discardableResult
    open func resume() -> Self {
        guard !_isCancelled else { return self }
        
        if !isStarted {
            start()
        } else {
            isSuspended = false
            config.requestPlugin.resumeRequest(self)
        }
        return self
    }
    
    /// 取消请求
    open func cancel() {
        guard !_isCancelled else { return }
        
        _isCancelled = true
        toggleAccessoriesWillStopCallBack()
        delegate = nil
        RequestManager.shared.cancelRequest(self)
        requestCancelledBlock?(self)
        requestCancelledBlock = nil
        toggleAccessoriesDidStopCallBack()
    }
    
    /// 开始请求并指定成功、失败句柄
    @discardableResult
    open func start<T: HTTPRequest>(success: ((T) -> Void)?, failure: ((T) -> Void)?) -> Self {
        successCompletionBlock = success != nil ? { success?($0 as! T) } : nil
        failureCompletionBlock = failure != nil ? { failure?($0 as! T) } : nil
        return start()
    }
    
    /// 开始请求并指定完成句柄
    @discardableResult
    open func start<T: HTTPRequest>(completion: ((T) -> Void)?) -> Self {
        return start(success: completion, failure: completion)
    }
    
    /// 请求取消句柄，不一定主线程调用
    @discardableResult
    open func requestCancelledBlock<T: HTTPRequest>(_ block: ((T) -> Void)?) -> Self {
        requestCancelledBlock = block != nil ? { block?($0 as! T) } : nil
        return self
    }
    
    /// 断点续传进度句柄
    @discardableResult
    open func downloadProgressBlock(_ block: ((Progress) -> Void)?) -> Self {
        self.downloadProgressBlock = block
        return self
    }
    
    /// 上传进度句柄
    @discardableResult
    open func uploadProgressBlock(_ block: ((Progress) -> Void)?) -> Self {
        self.uploadProgressBlock = block
        return self
    }
    
    /// 是否自动显示加载信息，context必须存在
    @discardableResult
    open func autoShowLoading(_ autoShowLoading: Bool) -> Self {
        self.autoShowLoading = autoShowLoading
        return self
    }
    
    /// 是否自动显示错误信息，context可不存在
    @discardableResult
    open func autoShowError(_ autoShowError: Bool) -> Self {
        self.autoShowError = autoShowError
        return self
    }
    
    /// 显示加载条，默认显示加载插件，context必须存在
    open func showLoading() {
        contextAccessory.showLoading(for: self)
    }
    
    /// 隐藏加载条，默认隐藏加载插件，context必须存在
    open func hideLoading() {
        contextAccessory.hideLoading(for: self)
    }
    
    /// 显示网络错误，默认显示Toast提示，context可不存在
    open func showError() {
        contextAccessory.showError(for: self)
    }
    
    /// 清理完成句柄
    open func clearCompletionBlock() {
        successCompletionBlock = nil
        failureCompletionBlock = nil
    }
    
    /// 添加请求配件
    @discardableResult
    open func addAccessory(_ accessory: RequestAccessoryProtocol) -> Self {
        if requestAccessories == nil {
            requestAccessories = []
        }
        requestAccessories?.append(accessory)
        return self
    }
    
    func toggleAccessoriesWillStartCallBack() {
        contextAccessory.requestWillStart(self)
        requestAccessories?.forEach({ accessory in
            accessory.requestWillStart(self)
        })
    }
    
    func toggleAccessoriesWillStopCallBack() {
        contextAccessory.requestWillStop(self)
        requestAccessories?.forEach({ accessory in
            accessory.requestWillStop(self)
        })
    }
    
    func toggleAccessoriesDidStopCallBack() {
        contextAccessory.requestDidStop(self)
        requestAccessories?.forEach({ accessory in
            accessory.requestDidStop(self)
        })
    }
    
    // MARK: - Response
    /// 自定义响应完成句柄
    @discardableResult
    open func response<T: HTTPRequest>(_ completion: ((T) -> Void)?) -> Self {
        return responseSuccess(completion).responseFailure(completion)
    }
    
    /// 自定义响应成功句柄
    @discardableResult
    open func responseSuccess<T: HTTPRequest>(_ block: ((T) -> Void)?) -> Self {
        successCompletionBlock = block != nil ? { block?($0 as! T) } : nil
        return self
    }
    
    /// 自定义响应失败句柄
    @discardableResult
    open func responseFailure<T: HTTPRequest>(_ block: ((T) -> Void)?) -> Self {
        failureCompletionBlock = block != nil ? { block?($0 as! T) } : nil
        return self
    }
    
    /// 快捷设置响应失败句柄
    @discardableResult
    open func responseError(_ block: ((Error) -> Void)?) -> Self {
        failureCompletionBlock = { request in
            block?(request.error ?? RequestError.unknown)
        }
        return self
    }
    
    /// 设置是否预加载响应模型，仅ResponseModelRequest生效
    @discardableResult
    open func preloadResponseModel(_ preload: Bool) -> Self {
        _preloadResponseModel = preload
        return self
    }
    
    /// 快捷设置模型响应成功句柄，解析成功时自动缓存，支持后台预加载
    @discardableResult
    open func responseModel<T: AnyCodableModel>(of type: T.Type, designatedPath: String? = nil, success: ((T?) -> Void)?) -> Self {
        responseModelBlock = { request in
            if (request.cacheResponseModel as? T) == nil {
                request.cacheResponseModel = T.decodeAnyModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
        }
        
        successCompletionBlock = { request in
            if (request.cacheResponseModel as? T) == nil {
                request.cacheResponseModel = T.decodeAnyModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
            success?(request.cacheResponseModel as? T)
        }
        return self
    }
    
    /// 快捷设置安全模型响应成功句柄，解析成功时自动缓存，支持后台预加载
    @discardableResult
    open func safeResponseModel<T: AnyCodableModel>(of type: T.Type, designatedPath: String? = nil, success: ((T) -> Void)?) -> Self {
        responseModelBlock = { request in
            if (request.cacheResponseModel as? T) == nil {
                request.cacheResponseModel = T.decodeAnyModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
        }
        
        successCompletionBlock = { request in
            if (request.cacheResponseModel as? T) == nil {
                request.cacheResponseModel = T.decodeAnyModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
            success?(request.cacheResponseModel as? T ?? .init())
        }
        return self
    }
    
    // MARK: - Cache
    /// 是否使用已缓存响应
    @discardableResult
    open func useCacheResponse(_ useCacheResponse: Bool) -> Self {
        self.useCacheResponse = useCacheResponse
        return self
    }
    
    /// 预加载缓存句柄，必须主线程且在start之前调用生效
    @discardableResult
    open func preloadCache<T: HTTPRequest>(_ block: ((T) -> Void)?) -> Self {
        try? loadCacheResponse(isPreload: true, completion: { block?($0 as! T) })
        return self
    }
    
    /// 预加载指定缓存响应模型句柄，必须主线程且在start之前调用生效
    @discardableResult
    open func preloadCacheModel<T: AnyCodableModel>(of type: T.Type, designatedPath: String? = nil, success: ((T?) -> Void)?) -> Self {
        try? loadCacheResponse(isPreload: true, completion: { request in
            if (request.cacheResponseModel as? T) == nil {
                request.cacheResponseModel = T.decodeAnyModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
            success?(request.cacheResponseModel as? T)
        }, processor: { request in
            if (request.cacheResponseModel as? T) == nil {
                request.cacheResponseModel = T.decodeAnyModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
        })
        return self
    }
    
    /// 预加载指定缓存安全响应模型句柄，必须主线程且在start之前调用生效
    @discardableResult
    open func preloadSafeCacheModel<T: AnyCodableModel>(of type: T.Type, designatedPath: String? = nil, success: ((T) -> Void)?) -> Self {
        try? loadCacheResponse(isPreload: true, completion: { request in
            if (request.cacheResponseModel as? T) == nil {
                request.cacheResponseModel = T.decodeAnyModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
            success?(request.cacheResponseModel as? T ?? .init())
        }, processor: { request in
            if (request.cacheResponseModel as? T) == nil {
                request.cacheResponseModel = T.decodeAnyModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
        })
        return self
    }
    
    /// 加载本地缓存，返回是否成功
    open func loadCache() throws {
        guard cacheTimeInSeconds() >= 0 else {
            throw RequestError.cacheInvalidCacheTime
        }
        
        guard let cache = try? config.requestCache?.loadCache(for: self) else {
            throw RequestError.cacheInvalidCacheData
        }
        
        do {
            _cacheMetadata = try validateCache(cache.metadata)
        } catch {
            try? config.requestCache?.clearCache(for: self)
            throw error
        }
        
        _cacheData = cache.data
        _cacheString = String(data: cache.data, encoding: _cacheMetadata?.stringEncoding ?? .utf8)
        switch responseSerializerType() {
        case .JSON:
            _cacheJSON = _cacheData?.fw_jsonDecode
            guard _cacheJSON != nil else {
                throw RequestError.cacheInvalidCacheData
            }
        case .HTTP:
            break
        }
        
        #if DEBUG
        if config.debugLogEnabled {
            Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST CACHED===========\n%@%@ %@:\n%@", "💾 ", requestMethod().rawValue, requestUrl(), String.fw_safeString(responseJSONObject ?? responseString))
        }
        #endif
    }
    
    /// 保存指定数据到缓存文件
    @discardableResult
    open func saveCache(_ data: Data?) -> Bool {
        guard let data = data, let requestCache = config.requestCache else { return false }
        guard cacheTimeInSeconds() > 0, !isDataFromCache else { return false }
        
        let cacheMetadata = RequestCacheMetadata()
        cacheMetadata.version = cacheVersion()
        cacheMetadata.sensitiveDataString = String.fw_safeString(cacheSensitiveData())
        cacheMetadata.stringEncoding = RequestManager.shared.stringEncoding(for: self)
        cacheMetadata.creationDate = Date()
        cacheMetadata.appVersionString = UIApplication.fw_appVersion
        guard let metadata = Data.fw_archivedData(cacheMetadata) else { return false }
        
        do {
            try requestCache.saveCache((data: data, metadata: metadata), for: self)
            return true
        } catch {
            return false
        }
    }
    
    /// 缓存唯一Id，子类可重写
    open func cacheIdentifier() -> String {
        let requestUrl = requestUrl()
        let baseUrl: String
        if useCDN() {
            baseUrl = !cdnUrl().isEmpty ? cdnUrl() : config.cdnUrl
        } else {
            baseUrl = !self.baseUrl().isEmpty ? self.baseUrl() : config.baseUrl
        }
        let argument = cacheArgumentFilter(requestArgument())
        let requestInfo = String(format: "Method:%ld Host:%@ Url:%@ Argument:%@", requestMethod().rawValue, baseUrl, requestUrl, String.fw_safeString(argument))
        return requestInfo.fw_md5Encode
    }
    
    fileprivate func loadCacheResponse(isPreload: Bool, completion: Completion?, processor: Completion? = nil) throws {
        if isPreload {
            guard !isStarted, Thread.isMainThread else { return }
        }
        
        try loadCache()
        
        if isPreload {
            responseModelBlock = processor
            successCompletionBlock = completion
        }
        
        isDataFromCache = true
        DispatchQueue.fw_mainAsync {
            self.requestCompletePreprocessor()
            self.requestCompleteFilter()
            self.delegate?.requestFinished(self)
            self.successCompletionBlock?(self)
            self.clearCompletionBlock()
        }
    }
    
    private func startWithoutCache() {
        isStarted = true
        clearCacheVariables()
        RequestManager.shared.addRequest(self)
    }
    
    private func validateCache(_ metadata: Data) throws -> RequestCacheMetadata {
        guard let cacheMetadata = metadata.fw_unarchivedObject() as? RequestCacheMetadata else {
            throw RequestError.cacheInvalidMetadata
        }
        
        let metadataDuration = -(cacheMetadata.creationDate?.timeIntervalSinceNow ?? 0)
        if metadataDuration < 0 || metadataDuration > TimeInterval(cacheTimeInSeconds()) {
            throw RequestError.cacheExpired
        }
        
        let metadataVersion = cacheMetadata.version ?? 0
        if metadataVersion != cacheVersion() {
            throw RequestError.cacheVersionMismatch
        }
        
        let metadataSensitive = cacheMetadata.sensitiveDataString ?? ""
        let currentSensitive = String.fw_safeString(cacheSensitiveData())
        if metadataSensitive != currentSensitive {
            throw RequestError.cacheSensitiveDataMismatch
        }
        
        let metadataAppVersion = cacheMetadata.appVersionString ?? ""
        let currentAppVersion = UIApplication.fw_appVersion
        if metadataAppVersion != currentAppVersion {
            throw RequestError.cacheAppVersionMismatch
        }
        
        return cacheMetadata
    }
    
    private func clearCacheVariables() {
        _cacheData = nil
        _cacheJSON = nil
        _cacheString = nil
        _cacheMetadata = nil
        cacheResponseModel = nil
        responseModelBlock = nil
        isDataFromCache = false
    }
    
}

// MARK: - RequestMultipartFormData
/// 请求表单数据定义
public protocol RequestMultipartFormData: AnyObject {
    
    /// 添加表单数据，指定名称
    func append(_ formData: Data, name: String)
    
    /// 添加文件数据，指定fileName、mimeType
    func append(_ fileData: Data, name: String, fileName: String, mimeType: String)
    
    /// 添加文件URL，自动处理fileName、mimeType
    func append(_ fileURL: URL, name: String)
    
    /// 添加文件URL，指定fileName、mimeType
    func append(_ fileURL: URL, name: String, fileName: String, mimeType: String)
    
    /// 添加输入流，指定fileName、mimeType
    func append(_ inputStream: InputStream, length: UInt64, name: String, fileName: String, mimeType: String)
    
    /// 添加输入流，指定头信息
    func append(_ inputStream: InputStream, length: UInt64, headers: [String: String])
    
    /// 添加body数据，指定头信息
    func append(_ body: Data, headers: [String: String])
    
}

// MARK: - ResponseModelRequest
/// 响应模型请求协议
public protocol ResponseModelRequest {
    /// 关联响应模型数据类型，默认支持Any|AnyCodableModel，可扩展
    associatedtype ResponseModel: Any
    
    /// 当前响应模型，默认调用responseModelFilter
    var responseModel: ResponseModel? { get set }
    /// 解析响应模型方法
    func responseModelFilter() -> ResponseModel?
}

/// HTTPRequest Any响应模型请求协议默认实现
extension ResponseModelRequest where Self: HTTPRequest {
    
    /// 默认实现当前响应模型，解析成功时自动缓存
    public var responseModel: ResponseModel? {
        get {
            if cacheResponseModel == nil {
                cacheResponseModel = responseModelFilter()
            }
            return cacheResponseModel as? ResponseModel
        }
        set {
            cacheResponseModel = newValue
        }
    }
    
    /// 默认实现解析响应模型方法，返回responseJSONObject
    public func responseModelFilter() -> ResponseModel? {
        return responseJSONObject as? ResponseModel
    }
    
    /// 快捷设置模型响应成功句柄
    @discardableResult
    public func responseModel(_ success: ((ResponseModel?) -> Void)?) -> Self {
        successCompletionBlock = { request in
            success?((request as! Self).responseModel)
        }
        return self
    }
    
    /// 预加载缓存响应模型句柄，必须主线程且在start之前调用生效
    @discardableResult
    public func preloadCacheModel(_ success: ((ResponseModel?) -> Void)?) -> Self {
        try? loadCacheResponse(isPreload: true, completion: { request in
            success?((request as! Self).responseModel)
        })
        return self
    }
    
}

/// HTTPRequest AnyCodableModel响应模型请求协议默认实现
extension ResponseModelRequest where Self: HTTPRequest, ResponseModel: AnyCodableModel {
    
    /// 默认实现当前安全响应模型
    public var safeResponseModel: ResponseModel {
        return responseModel ?? .init()
    }
    
    /// 默认实现解析响应模型方法，调用decodeResponseModel，具体路径为nil
    public func responseModelFilter() -> ResponseModel? {
        return decodeResponseModel()
    }
    
    /// 默认实现解析响应数据为数据模型，支持具体路径
    public func decodeResponseModel(designatedPath: String? = nil) -> ResponseModel? {
        return ResponseModel.decodeAnyModel(from: responseJSONObject, designatedPath: designatedPath)
    }
    
    /// 快捷设置安全模型响应成功句柄
    @discardableResult
    public func safeResponseModel(_ success: ((ResponseModel) -> Void)?) -> Self {
        successCompletionBlock = { request in
            success?((request as! Self).safeResponseModel)
        }
        return self
    }
    
    /// 预加载缓存安全响应模型句柄，必须主线程且在start之前调用生效
    @discardableResult
    public func preloadSafeCacheModel(_ success: ((ResponseModel) -> Void)?) -> Self {
        try? loadCacheResponse(isPreload: true, completion: { request in
            success?((request as! Self).safeResponseModel)
        })
        return self
    }
    
}

// MARK: - RequestError
/// 请求错误协议，用于错误判断
public protocol RequestErrorProtocol {}

/// 嵌套错误协议，获取内部错误
public protocol UnderlyingErrorProtocol {
    var underlyingError: Error? { get }
}

/// 请求错误
public enum RequestError: Swift.Error, CustomNSError, RequestErrorProtocol {
    case unknown
    case cacheExpired
    case cacheVersionMismatch
    case cacheSensitiveDataMismatch
    case cacheAppVersionMismatch
    case cacheInvalidCacheTime
    case cacheInvalidMetadata
    case cacheInvalidCacheData
    case validationInvalidStatusCode(_ code: Int)
    case validationInvalidJSONFormat
    
    public static var errorDomain: String { "site.wuyong.error.request" }
    public var errorCode: Int {
        switch self {
        case .unknown:
            return 0
        case .cacheExpired:
            return -1
        case .cacheVersionMismatch:
            return -2
        case .cacheSensitiveDataMismatch:
            return -3
        case .cacheAppVersionMismatch:
            return -4
        case .cacheInvalidCacheTime:
            return -5
        case .cacheInvalidMetadata:
            return -6
        case .cacheInvalidCacheData:
            return -7
        case .validationInvalidStatusCode:
            return -8
        case .validationInvalidJSONFormat:
            return -9
        }
    }
    public var errorUserInfo: [String: Any] {
        switch self {
        case .unknown:
            return [NSLocalizedDescriptionKey: "Unknown error"]
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
        case let .validationInvalidStatusCode(code):
            return [NSLocalizedDescriptionKey: "Invalid status code (\(code))"]
        case .validationInvalidJSONFormat:
            return [NSLocalizedDescriptionKey: "Invalid JSON format"]
        }
    }
    
    /// 判断是否是网络请求错误，支持嵌套请求错误
    public static func isRequestError(_ error: Error?) -> Bool {
        guard let error = error else { return false }
        if error is RequestErrorProtocol { return true }
        if (error as NSError).fw_propertyBool(forName: "isRequestError") { return true }
        if (error as NSError).domain == NSURLErrorDomain { return true }
        if let underlyingError = error as? UnderlyingErrorProtocol {
            return isRequestError(underlyingError.underlyingError)
        }
        return false
    }
    
    /// 判断是否是网络连接错误，支持嵌套请求错误
    public static func isConnectionError(_ error: Error?) -> Bool {
        guard let error = error else { return false }
        if connectionErrorCodes.contains((error as NSError).code) { return true }
        if let underlyingError = error as? UnderlyingErrorProtocol {
            return isConnectionError(underlyingError.underlyingError)
        }
        return false
    }
    
    /// 判断是否是网络取消错误，支持嵌套请求错误
    public static func isCancelledError(_ error: Error?) -> Bool {
        guard let error = error else { return false }
        #if compiler(>=5.6.0) && canImport(_Concurrency)
        if error is CancellationError { return true }
        #endif
        if cancelledErrorCodes.contains((error as NSError).code) { return true }
        if let underlyingError = error as? UnderlyingErrorProtocol {
            return isCancelledError(underlyingError.underlyingError)
        }
        return false
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
