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
public enum RequestMethod: String, Sendable {
    case GET
    case POST
    case HEAD
    case PUT
    case DELETE
    case PATCH
    case TRACE
    case CONNECT
    case OPTIONS
    case QUERY
}

/// 请求序列化类型
public enum RequestSerializerType: Int, Sendable {
    case HTTP = 0
    case JSON
}

/// 响应序列化类型
public enum ResponseSerializerType: Int, Sendable {
    case HTTP = 0
    case JSON
}

/// 请求优先级
public enum RequestPriority: Int, Sendable {
    case `default` = 0
    case low = -4
    case high = 4
}

/// 请求代理
public protocol RequestDelegate: AnyObject {
    /// 请求完成
    @MainActor func requestFinished(_ request: HTTPRequest)
    /// 请求失败
    @MainActor func requestFailed(_ request: HTTPRequest)
}

extension RequestDelegate {
    /// 默认实现请求完成
    public func requestFinished(_ request: HTTPRequest) {}
    /// 默认实现请求失败
    public func requestFailed(_ request: HTTPRequest) {}
}

/// HTTP请求协议，主要用于处理方法中Self参数、错误处理等
public protocol HTTPRequestProtocol: AnyObject {
    /// 是否自动显示错误信息
    var autoShowError: Bool { get set }
    /// 当前网络错误
    var error: Error? { get }
    /// 显示网络错误，默认显示Toast提示
    func showError()
    /// 开始请求
    func start() -> Self
    /// 取消请求
    func cancel()
}

/// HTTP请求基类，支持缓存和重试机制，使用时继承即可
///
/// 注意事项：
/// 如果vc请求回调句柄中未使用weak self，会产生强引用，则self会在vc关闭且等待请求完成后才会释放
/// 如果vc请求回调句柄中使用了weak self，不会产生强引用，则self会在vc关闭时立即释放，不会等待请求完成
///
/// [YTKNetwork](https://github.com/yuantiku/YTKNetwork)
open class HTTPRequest: HTTPRequestProtocol, Equatable, CustomStringConvertible, @unchecked Sendable {
    /// 请求完成句柄
    public typealias Completion = @MainActor @Sendable (HTTPRequest) -> Void

    /// 请求构建器，可继承
    ///
    /// 继承HTTPRequest并重载Builder示例：
    /// ```swift
    /// class AppRequest: HTTPRequest {
    ///     class Builder: HTTPRequest.Builder {
    ///         override func build() -> AppRequest {
    ///             return AppRequest(builder: self)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// 使用AppRequest.Builder示例：
    /// ```swift
    /// let request = AppRequest.Builder()/*...*/.build()
    /// ```
    open class Builder {
        /// 只读属性
        public private(set) var baseUrl: String?
        public private(set) var requestUrl: String?
        public private(set) var cdnUrl: String?
        public private(set) var useCDN: Bool?
        public private(set) var allowsCellularAccess: Bool?
        public private(set) var requestTimeoutInterval: TimeInterval?
        public private(set) var requestCachePolicy: URLRequest.CachePolicy?
        public private(set) var requestMethod: RequestMethod?
        public private(set) var requestArgument: Any?
        public private(set) var constructingBodyBlock: (@Sendable (RequestMultipartFormData) -> Void)?
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
        public private(set) var statusCodeValidator: (@Sendable (_ request: HTTPRequest) -> Bool)?
        public private(set) var jsonValidator: Any?
        public private(set) var urlRequestFilter: (@Sendable (_ request: HTTPRequest, _ urlRequest: inout URLRequest) -> Void)?
        public private(set) var responseFilter: (@Sendable (_ request: HTTPRequest) throws -> Void)?
        public private(set) var responseMockValidator: (@Sendable (HTTPRequest) -> Bool)?
        public private(set) var responseMockProcessor: (@Sendable (HTTPRequest) -> Bool)?
        public private(set) var requestRetryCount: Int?
        public private(set) var requestRetryInterval: TimeInterval?
        public private(set) var requestRetryTimeout: TimeInterval?
        public private(set) var requestRetryValidator: (@Sendable (_ request: HTTPRequest, _ response: HTTPURLResponse, _ responseObject: Any?, _ error: Error?) -> Bool)?
        public private(set) var requestRetryProcessor: (@Sendable (_ request: HTTPRequest, _ response: HTTPURLResponse, _ responseObject: Any?, _ error: Error?, _ completionHandler: @escaping @Sendable (Bool) -> Void) -> Void)?
        public private(set) var requestCompletePreprocessor: (@Sendable (HTTPRequest) -> Void)?
        public private(set) var requestCompleteFilter: Completion?
        public private(set) var requestFailedPreprocessor: (@Sendable (HTTPRequest) -> Void)?
        public private(set) var requestFailedFilter: Completion?
        public private(set) var cacheTimeInSeconds: Int?
        public private(set) var cacheVersion: Int?
        public private(set) var cacheSensitiveData: Any?
        public private(set) var cacheArgumentFilter: (@Sendable (_ request: HTTPRequest, _ argument: Any?) -> Any?)?
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
            allowsCellularAccess = allows
            return self
        }

        /// 请求超时，默认60秒
        @discardableResult
        public func requestTimeoutInterval(_ interval: TimeInterval) -> Self {
            requestTimeoutInterval = interval
            return self
        }

        /// 自定义请求缓存策略，默认nil不处理
        @discardableResult
        public func requestCachePolicy(_ cachePolicy: URLRequest.CachePolicy?) -> Self {
            requestCachePolicy = cachePolicy
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
                if let dict = requestArgument as? [AnyHashable: Any] {
                    requestArgument = dict.merging(argumentDict, uniquingKeysWith: { $1 })
                } else {
                    requestArgument = argumentDict
                }
            } else {
                requestArgument = argument
            }
            return self
        }

        /// 添加单个参数
        @discardableResult
        public func requestArgument(_ name: String, value: Any?) -> Self {
            var dict = requestArgument as? [AnyHashable: Any] ?? [:]
            dict[name] = value
            requestArgument = dict
            return self
        }

        /// 自定义POST请求HTTP body数据
        @discardableResult
        public func constructingBodyBlock(_ block: (@Sendable (RequestMultipartFormData) -> Void)?) -> Self {
            constructingBodyBlock = block
            return self
        }

        /// 断点续传下载路径
        @discardableResult
        public func resumableDownloadPath(_ path: String?) -> Self {
            resumableDownloadPath = path
            return self
        }

        /// 请求序列化方式，默认HTTP
        @discardableResult
        public func requestSerializerType(_ serializerType: RequestSerializerType) -> Self {
            requestSerializerType = serializerType
            return self
        }

        /// 响应序列化方式，默认JSON
        @discardableResult
        public func responseSerializerType(_ serializerType: ResponseSerializerType) -> Self {
            responseSerializerType = serializerType
            return self
        }

        /// HTTP请求授权Header数组，示例：["Username", "Password"]
        @discardableResult
        public func requestAuthorizationHeaders(_ array: [String]?) -> Self {
            requestAuthorizationHeaders = array
            return self
        }

        /// 设置HTTP请求授权用户名和密码
        @discardableResult
        public func requestAuthorization(username: String?, password: String?) -> Self {
            if let username, let password {
                requestAuthorizationHeaders = [username, password]
            } else {
                requestAuthorizationHeaders = nil
            }
            return self
        }

        /// 批量添加请求Header
        @discardableResult
        public func requestHeaders(_ headers: [String: String]?) -> Self {
            guard let headers else { return self }
            if requestHeaders != nil {
                requestHeaders?.merge(headers, uniquingKeysWith: { $1 })
            } else {
                requestHeaders = headers
            }
            return self
        }

        /// 添加单个请求Header
        @discardableResult
        public func requestHeader(_ name: String, value: String?) -> Self {
            if requestHeaders == nil {
                requestHeaders = [:]
            }
            requestHeaders?[name] = value
            return self
        }

        /// 请求优先级，默认default
        @discardableResult
        public func requestPriority(_ priority: RequestPriority) -> Self {
            requestPriority = priority
            return self
        }

        /// 自定义用户信息
        @discardableResult
        public func requestUserInfo(_ userInfo: [AnyHashable: Any]?) -> Self {
            requestUserInfo = userInfo
            return self
        }

        /// JSON验证器，默认支持AnyValidator
        @discardableResult
        public func jsonValidator(_ validator: Any?) -> Self {
            jsonValidator = validator
            return self
        }

        /// 构建自定义URLRequest
        @discardableResult
        public func customUrlRequest(_ urlRequest: URLRequest?) -> Self {
            customUrlRequest = urlRequest
            return self
        }

        /// 设置是否是同步串行请求
        @discardableResult
        public func synchronously(_ synchronously: Bool) -> Self {
            isSynchronously = synchronously
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
        public func statusCodeValidator(_ validator: (@Sendable (_ request: HTTPRequest) -> Bool)?) -> Self {
            statusCodeValidator = validator
            return self
        }

        /// 请求发送前URLRequest过滤方法，默认不处理
        @discardableResult
        public func urlRequestFilter(_ filter: (@Sendable (_ request: HTTPRequest, _ urlRequest: inout URLRequest) -> Void)?) -> Self {
            urlRequestFilter = filter
            return self
        }

        /// 请求回调前Response过滤方法，默认成功不抛异常
        @discardableResult
        public func responseFilter(_ filter: (@Sendable (_ request: HTTPRequest) throws -> Void)?) -> Self {
            responseFilter = filter
            return self
        }

        /// 调试请求Mock验证器，默认判断404
        @discardableResult
        public func responseMockValidator(_ validator: (@Sendable (_ request: HTTPRequest) -> Bool)?) -> Self {
            responseMockValidator = validator
            return self
        }

        /// 调试请求Mock处理器，请求失败时且回调前在后台线程调用
        @discardableResult
        public func responseMockProcessor(_ block: (@Sendable (_ request: HTTPRequest) -> Bool)?) -> Self {
            responseMockProcessor = block
            return self
        }

        /// 请求完成预处理器，后台线程调用
        @discardableResult
        public func requestCompletePreprocessor(_ block: (@Sendable (HTTPRequest) -> Void)?) -> Self {
            requestCompletePreprocessor = block
            return self
        }

        /// 请求完成过滤器，主线程调用
        @discardableResult
        public func requestCompleteFilter(_ block: Completion?) -> Self {
            requestCompleteFilter = block
            return self
        }

        /// 请求失败预处理器，后台线程调用
        @discardableResult
        public func requestFailedPreprocessor(_ block: (@Sendable (HTTPRequest) -> Void)?) -> Self {
            requestFailedPreprocessor = block
            return self
        }

        /// 请求失败过滤器，主线程调用
        @discardableResult
        public func requestFailedFilter(_ block: Completion?) -> Self {
            requestFailedFilter = block
            return self
        }

        /// 请求重试次数，默认0
        @discardableResult
        public func requestRetryCount(_ count: Int) -> Self {
            requestRetryCount = count
            return self
        }

        /// 请求重试间隔，默认0
        @discardableResult
        public func requestRetryInterval(_ interval: TimeInterval) -> Self {
            requestRetryInterval = interval
            return self
        }

        /// 请求重试超时时间，默认0
        @discardableResult
        public func requestRetryTimeout(_ timeout: TimeInterval) -> Self {
            requestRetryTimeout = timeout
            return self
        }

        /// 请求重试验证方法，默认检查状态码和错误
        @discardableResult
        public func requestRetryValidator(_ validator: (@Sendable (_ request: HTTPRequest, _ response: HTTPURLResponse, _ responseObject: Any?, _ error: Error?) -> Bool)?) -> Self {
            requestRetryValidator = validator
            return self
        }

        /// 请求重试处理方法，回调处理状态，默认调用completionHandler(true)
        @discardableResult
        public func requestRetryProcessor(_ processor: (@Sendable (_ request: HTTPRequest, _ response: HTTPURLResponse, _ responseObject: Any?, _ error: Error?, _ completionHandler: @escaping @Sendable (Bool) -> Void) -> Void)?) -> Self {
            requestRetryProcessor = processor
            return self
        }

        /// 缓存有效期，默认-1不缓存
        @discardableResult
        public func cacheTimeInSeconds(_ seconds: Int) -> Self {
            cacheTimeInSeconds = seconds
            return self
        }

        /// 缓存版本号，默认0
        @discardableResult
        public func cacheVersion(_ version: Int) -> Self {
            cacheVersion = version
            return self
        }

        /// 缓存附加数据，变化时会更新缓存
        @discardableResult
        public func cacheSensitiveData(_ sensitiveData: Any?) -> Self {
            cacheSensitiveData = sensitiveData
            return self
        }

        /// 缓存文件名过滤器，参数为请求参数，默认返回argument
        @discardableResult
        public func cacheArgumentFilter(_ filter: (@Sendable (_ request: HTTPRequest, _ argument: Any?) -> Any?)?) -> Self {
            cacheArgumentFilter = filter
            return self
        }

        /// 是否异步写入缓存，默认true
        @discardableResult
        public func writeCacheAsynchronously(_ async: Bool) -> Self {
            writeCacheAsynchronously = async
            return self
        }

        /// 构建请求，子类可重写
        open func build() -> HTTPRequest {
            HTTPRequest(builder: self)
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
    open var requestCancelledBlock: (@Sendable (HTTPRequest) -> Void)?
    /// 自定义请求配件数组
    open var requestAccessories: [RequestAccessoryProtocol]?
    /// 自定义POST请求HTTP body数据
    open var constructingBodyBlock: (@Sendable (RequestMultipartFormData) -> Void)?
    /// 断点续传下载路径
    open var resumableDownloadPath: String?
    /// 断点续传进度句柄
    open var downloadProgressBlock: (@Sendable (Progress) -> Void)?
    /// 上传进度句柄
    open var uploadProgressBlock: (@Sendable (Progress) -> Void)?
    /// 请求优先级，默认default
    open var requestPriority: RequestPriority = .default
    /// 是否是同步串行请求，默认false为异步并发请求
    open var isSynchronously: Bool = false
    /// 自定义用户信息
    open var requestUserInfo: [AnyHashable: Any]?
    /// 是否预加载请求缓存模型(一般仅GET开启)，注意开启后当缓存存在时会调用成功句柄一次，默认false
    open var preloadCacheModel: Bool {
        get {
            if let preload = _preloadCacheModel { return preload }
            return config.preloadCacheFilter?(self) ?? false
        }
        set {
            _preloadCacheModel = newValue
        }
    }

    private var _preloadCacheModel: Bool?
    /// 判断缓存是否存在
    open var isResponseCached: Bool {
        do {
            try loadCache()
            return true
        } catch {
            return false
        }
    }

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
        (requestTask?.response as? HTTPURLResponse)?.allHeaderFields
    }

    /// 当前响应状态码
    open var responseStatusCode: Int {
        (requestTask?.response as? HTTPURLResponse)?.statusCode ?? 0
    }

    /// 当前响应服务器时间
    open var responseServerTime: TimeInterval {
        guard let serverDate = responseHeaders?["Date"] as? String else { return 0 }
        return Date.fw.formatServerDate(serverDate)
    }

    /// 请求开始时间
    open internal(set) var requestStartTime: TimeInterval = 0
    /// 请求总次数
    open internal(set) var requestTotalCount: Int = 0
    /// 请求总时长
    open internal(set) var requestTotalTime: TimeInterval = 0

    /// 请求是否已完成，requestTask必须完成且error为nil
    open var isFinished: Bool {
        guard let requestTask else { return false }
        return requestTask.state == .completed && error == nil
    }

    /// 请求是否已失败，error不为nil，不检查requestTask
    open var isFailed: Bool {
        error != nil
    }

    /// 请求是否已取消，含手动取消和requestTask取消
    open var isCancelled: Bool {
        if _isCancelled { return true }
        guard let requestTask else { return false }
        return requestTask.state == .canceling
    }

    /// 请求是否已开始，已开始之后再次调用start不会生效
    open private(set) var isStarted: Bool = false
    /// 请求是否已暂停，已开始之后才可暂停
    open private(set) var isSuspended: Bool = false
    /// 请求是否执行中，requestTask状态为running
    open var isExecuting: Bool {
        guard let requestTask else { return false }
        return requestTask.state == .running
    }

    /// 当前响应数据
    open var responseData: Data? {
        get { _responseData ?? _cacheData }
        set { _responseData = newValue }
    }

    private var _responseData: Data?

    /// 当前响应字符串
    open var responseString: String? {
        get { _responseString ?? _cacheString }
        set { _responseString = newValue }
    }

    private var _responseString: String?

    /// 当前响应对象
    open var responseObject: Any? {
        get { _responseObject ?? (_cacheJSON ?? _cacheData) }
        set { _responseObject = newValue }
    }

    private var _responseObject: Any?

    /// 当前响应JSON对象
    open var responseJSONObject: Any? {
        get { _responseJSONObject ?? _cacheJSON }
        set { _responseJSONObject = newValue }
    }

    private var _responseJSONObject: Any?

    /// 当前网络错误
    open var error: Error? {
        get {
            _error
        }
        set {
            let error = newValue as? NSError
            error?.fw.setPropertyBool(true, forName: "isRequestError")
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

    /// 请求构建器，从构建器初始化时才有值
    open private(set) var builder: Builder?

    /// 请求上下文控件，可自定义
    open var contextAccessory: RequestContextAccessory {
        get {
            if let accessory = _contextAccessory {
                return accessory
            }

            let accessory = config.contextAccessoryBlock?(self) ?? RequestContextAccessory()
            _contextAccessory = accessory
            return accessory
        }
        set {
            _contextAccessory = newValue
        }
    }

    private var _contextAccessory: RequestContextAccessory?

    fileprivate var _cacheResponseModel: Any?
    private var _responseModelBlock: (@Sendable (HTTPRequest) -> Void)?
    private var _preloadResponseModel: Bool?
    private var _isCancelled = false
    private var _cacheData: Data?
    private var _cacheString: String?
    private var _cacheJSON: Any?
    private var _cacheMetadata: RequestCacheMetadata?
    private var _cacheLoaded = false

    // MARK: - Lifecycle
    /// 初始化方法
    public init() {}

    /// 指定构建器并初始化
    public convenience init(builder: Builder) {
        self.init()

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
        builder?.baseUrl ?? ""
    }

    /// 请求URL地址，默认空，示例：/v1/user
    open func requestUrl() -> String {
        builder?.requestUrl ?? ""
    }

    /// 请求可选CDN地址，默认空
    open func cdnUrl() -> String {
        builder?.cdnUrl ?? ""
    }

    /// 是否使用CDN
    open func useCDN() -> Bool {
        builder?.useCDN ?? false
    }

    /// 是否允许蜂窝网络访问，默认true
    open func allowsCellularAccess() -> Bool {
        builder?.allowsCellularAccess ?? true
    }

    /// 请求超时，默认60秒
    open func requestTimeoutInterval() -> TimeInterval {
        builder?.requestTimeoutInterval ?? 60
    }

    /// 自定义请求缓存策略，默认nil不处理
    open func requestCachePolicy() -> URLRequest.CachePolicy? {
        builder?.requestCachePolicy
    }

    /// 请求方式，默认GET
    open func requestMethod() -> RequestMethod {
        builder?.requestMethod ?? .GET
    }

    /// 请求附加参数，建议[String: Any]?，默认nil
    open func requestArgument() -> Any? {
        builder?.requestArgument
    }

    /// 请求序列化方式，默认HTTP
    open func requestSerializerType() -> RequestSerializerType {
        builder?.requestSerializerType ?? .HTTP
    }

    /// 响应序列化方式，默认JSON
    open func responseSerializerType() -> ResponseSerializerType {
        builder?.responseSerializerType ?? .JSON
    }

    /// HTTP请求授权Header数组，示例：["UserName", "Password"]
    open func requestAuthorizationHeaders() -> [String]? {
        builder?.requestAuthorizationHeaders
    }

    /// 自定义请求Header字典
    open func requestHeaders() -> [String: String]? {
        builder?.requestHeaders
    }

    /// 请求发送前URLRequest过滤方法，默认不处理
    open func urlRequestFilter(_ urlRequest: inout URLRequest) {
        builder?.urlRequestFilter?(self, &urlRequest)
    }

    /// 构建自定义URLRequest
    open func customUrlRequest() -> URLRequest? {
        builder?.customUrlRequest
    }

    // MARK: - Override+Response
    /// JSON验证器，默认支持AnyValidator
    open func jsonValidator() -> Any? {
        builder?.jsonValidator
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
        if let preload = _preloadResponseModel { return preload }
        return config.preloadModelFilter?(self) ?? false
    }

    /// 请求完成预处理器，后台线程调用。默认写入请求缓存、预加载响应模型
    open func requestCompletePreprocessor() {
        let responseData = _responseData
        if responseData != nil {
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
                _responseModelBlock?(self)
            }
        }

        builder?.requestCompletePreprocessor?(self)
    }

    /// 请求完成过滤器，主线程调用，默认不处理
    @MainActor open func requestCompleteFilter() {
        builder?.requestCompleteFilter?(self)
    }

    /// 请求失败预处理器，后台线程调用，默认不处理
    open func requestFailedPreprocessor() {
        builder?.requestFailedPreprocessor?(self)
    }

    /// 请求失败过滤器，主线程调用，默认不处理
    @MainActor open func requestFailedFilter() {
        builder?.requestFailedFilter?(self)
    }

    // MARK: - Override+Retry
    /// 请求重试次数，默认0
    open func requestRetryCount() -> Int {
        builder?.requestRetryCount ?? 0
    }

    /// 请求重试间隔，默认0
    open func requestRetryInterval() -> TimeInterval {
        builder?.requestRetryInterval ?? 0
    }

    /// 请求重试超时时间，默认0
    open func requestRetryTimeout() -> TimeInterval {
        builder?.requestRetryTimeout ?? 0
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
    open func requestRetryProcessor(_ response: HTTPURLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping @Sendable (Bool) -> Void) {
        if let processor = builder?.requestRetryProcessor {
            processor(self, response, responseObject, error, completionHandler)
        } else {
            completionHandler(true)
        }
    }

    // MARK: - Override+Cache
    /// 缓存有效期，默认-1不缓存
    open func cacheTimeInSeconds() -> Int {
        builder?.cacheTimeInSeconds ?? -1
    }

    /// 缓存版本号，默认0
    open func cacheVersion() -> Int {
        builder?.cacheVersion ?? 0
    }

    /// 缓存敏感数据，变化时会更新缓存
    open func cacheSensitiveData() -> Any? {
        if let data = builder?.cacheSensitiveData {
            return data
        }
        return config.cacheSensitiveFilter?(self)
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
        builder?.writeCacheAsynchronously ?? true
    }

    // MARK: - Action
    /// 当前请求的上下文，支持UIViewController|UIView
    @discardableResult
    open func context(_ context: AnyObject?) -> Self {
        self.context = context
        return self
    }

    /// 开始请求，已开始后重复调用无效
    @discardableResult
    open func start() -> Self {
        guard !_isCancelled, !isStarted else { return self }

        if !preloadCacheModel || resumableDownloadPath != nil {
            startWithoutCache()
            return self
        }

        do {
            try loadCache()
        } catch {
            startWithoutCache()
            return self
        }

        #if DEBUG
        if config.debugLogEnabled {
            Logger.debug(group: Logger.fw.moduleName, "\n===========REQUEST CACHED===========\n%@%@ %@:\n%@", "💾 ", requestMethod().rawValue, requestUrl(), String.fw.safeString(responseJSONObject ?? responseString))
        }
        #endif

        isDataFromCache = true
        DispatchQueue.fw.mainAsync {
            self.requestCompletePreprocessor()
            self.requestCompleteFilter()
            self.delegate?.requestFinished(self)
            self.successCompletionBlock?(self)

            self.startWithoutCache()
        }
        return self
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

    /// 断点续传进度句柄
    @discardableResult
    open func downloadProgressBlock(_ block: (@Sendable (Progress) -> Void)?) -> Self {
        downloadProgressBlock = block
        return self
    }

    /// 上传进度句柄
    @discardableResult
    open func uploadProgressBlock(_ block: (@Sendable (Progress) -> Void)?) -> Self {
        uploadProgressBlock = block
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
        requestAccessories?.forEach { accessory in
            accessory.requestWillStart(self)
        }
    }

    func toggleAccessoriesWillStopCallBack() {
        contextAccessory.requestWillStop(self)
        requestAccessories?.forEach { accessory in
            accessory.requestWillStop(self)
        }
    }

    func toggleAccessoriesDidStopCallBack() {
        contextAccessory.requestDidStop(self)
        requestAccessories?.forEach { accessory in
            accessory.requestDidStop(self)
        }
    }

    // MARK: - Response
    /// 快捷设置响应失败句柄
    @discardableResult
    open func responseError(_ block: (@MainActor @Sendable (Error) -> Void)?) -> Self {
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
    open func responseModel<T: AnyModel>(of type: T.Type, designatedPath: String? = nil, success: (@MainActor @Sendable (T?) -> Void)?) -> Self {
        _responseModelBlock = { request in
            if (request._cacheResponseModel as? T) == nil {
                request._cacheResponseModel = T.decodeModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
        }

        successCompletionBlock = { request in
            if (request._cacheResponseModel as? T) == nil {
                request._cacheResponseModel = T.decodeModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
            success?(request._cacheResponseModel as? T)
        }
        return self
    }

    /// 快捷设置安全模型响应成功句柄，解析成功时自动缓存，支持后台预加载
    @discardableResult
    open func safeResponseModel<T: AnyModel>(of type: T.Type, designatedPath: String? = nil, success: (@MainActor @Sendable (T) -> Void)?) -> Self {
        responseModel(of: type, designatedPath: designatedPath, success: success != nil ? { @MainActor @Sendable responseModel in
            success?(responseModel ?? .init())
        } : nil)
    }

    // MARK: - Cache
    /// 是否预加载请求缓存模型(一般仅GET开启)，注意开启后当缓存存在时会调用成功句柄一次
    @discardableResult
    open func preloadCacheModel(_ preloadCacheModel: Bool) -> Self {
        self.preloadCacheModel = preloadCacheModel
        return self
    }

    /// 解析指定缓存响应模型句柄，必须在start之前调用生效
    @discardableResult
    open func responseCacheModel<T: AnyModel>(of type: T.Type, designatedPath: String? = nil, success: (@MainActor @Sendable (T?) -> Void)?) -> Self {
        try? loadCacheResponse(completion: { request in
            if (request._cacheResponseModel as? T) == nil {
                request._cacheResponseModel = T.decodeModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
            success?(request._cacheResponseModel as? T)
        }, processor: { request in
            if (request._cacheResponseModel as? T) == nil {
                request._cacheResponseModel = T.decodeModel(from: request.responseJSONObject, designatedPath: designatedPath)
            }
        })
        return self
    }

    /// 解析指定缓存安全响应模型句柄，必须在start之前调用生效
    @discardableResult
    open func responseSafeCacheModel<T: AnyModel>(of type: T.Type, designatedPath: String? = nil, success: (@MainActor @Sendable (T) -> Void)?) -> Self {
        responseCacheModel(of: type, designatedPath: designatedPath, success: success != nil ? { @MainActor @Sendable cacheModel in
            success?(cacheModel ?? .init())
        } : nil)
    }

    /// 加载本地缓存，返回是否成功
    open func loadCache() throws {
        guard !_cacheLoaded else { return }

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
            _cacheJSON = _cacheData?.fw.jsonDecode
            guard _cacheJSON != nil else {
                throw RequestError.cacheInvalidCacheData
            }
        case .HTTP:
            break
        }
        _cacheLoaded = true
    }

    /// 保存指定数据到缓存文件
    @discardableResult
    open func saveCache(_ data: Data?) -> Bool {
        guard let data, let requestCache = config.requestCache else { return false }
        guard cacheTimeInSeconds() > 0, !isDataFromCache else { return false }

        let cacheMetadata = RequestCacheMetadata()
        cacheMetadata.version = cacheVersion()
        cacheMetadata.sensitiveDataString = String.fw.safeString(cacheSensitiveData())
        cacheMetadata.stringEncoding = RequestManager.shared.stringEncoding(for: self)
        cacheMetadata.creationDate = Date()
        cacheMetadata.appVersionString = UIApplication.fw.appVersion
        guard let metadata = Data.fw.archivedData(cacheMetadata) else { return false }

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
        let requestInfo = String(format: "Method:%@ Host:%@ Url:%@ Argument:%@", requestMethod().rawValue, baseUrl, requestUrl, String.fw.safeString(argument))
        return requestInfo.fw.md5Encode
    }

    fileprivate func loadCacheResponse(completion: Completion?, processor: (@Sendable (HTTPRequest) -> Void)? = nil) throws {
        guard !isStarted else { return }

        try loadCache()

        #if DEBUG
        if config.debugLogEnabled {
            Logger.debug(group: Logger.fw.moduleName, "\n===========REQUEST PRELOADED===========\n%@%@ %@:\n%@", "💾 ", requestMethod().rawValue, requestUrl(), String.fw.safeString(responseJSONObject ?? responseString))
        }
        #endif

        _responseModelBlock = processor

        isDataFromCache = true
        DispatchQueue.fw.mainAsync {
            self.requestCompletePreprocessor()
            self.requestCompleteFilter()
            completion?(self)
        }
    }

    private func startWithoutCache() {
        isStarted = true
        clearCacheVariables()
        RequestManager.shared.addRequest(self)
    }

    private func validateCache(_ metadata: Data) throws -> RequestCacheMetadata {
        guard let cacheMetadata = metadata.fw.unarchivedObject() as? RequestCacheMetadata else {
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
        let currentSensitive = String.fw.safeString(cacheSensitiveData())
        if metadataSensitive != currentSensitive {
            throw RequestError.cacheSensitiveDataMismatch
        }

        let metadataAppVersion = cacheMetadata.appVersionString ?? ""
        let currentAppVersion = UIApplication.fw.appVersion
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
        _cacheLoaded = false
        _cacheResponseModel = nil
        _responseModelBlock = nil
        isDataFromCache = false
    }

    // MARK: - Equatable
    public static func ==(lhs: HTTPRequest, rhs: HTTPRequest) -> Bool {
        lhs.requestIdentifier == rhs.requestIdentifier
    }
}

// MARK: - HTTPRequestProtocol+HTTPRequest
extension HTTPRequestProtocol where Self: HTTPRequest {
    /// 开始请求并指定成功、失败句柄
    @discardableResult
    public func start(success: (@MainActor @Sendable (Self) -> Void)?, failure: (@MainActor @Sendable (Self) -> Void)?) -> Self {
        successCompletionBlock = success != nil ? { @MainActor @Sendable in success?($0 as! Self) } : nil
        failureCompletionBlock = failure != nil ? { @MainActor @Sendable in failure?($0 as! Self) } : nil
        return start()
    }

    /// 开始请求并指定完成句柄
    @discardableResult
    public func start(completion: (@MainActor @Sendable (Self) -> Void)?) -> Self {
        start(success: completion, failure: completion)
    }

    /// 请求取消句柄，不一定主线程调用
    @discardableResult
    public func requestCancelledBlock(_ block: (@Sendable (Self) -> Void)?) -> Self {
        requestCancelledBlock = block != nil ? { @Sendable in block?($0 as! Self) } : nil
        return self
    }

    /// 自定义响应完成句柄
    @discardableResult
    public func response(_ completion: (@MainActor @Sendable (Self) -> Void)?) -> Self {
        responseSuccess(completion).responseFailure(completion)
    }

    /// 自定义响应成功句柄
    @discardableResult
    public func responseSuccess(_ block: (@MainActor @Sendable (Self) -> Void)?) -> Self {
        successCompletionBlock = block != nil ? { @MainActor @Sendable in block?($0 as! Self) } : nil
        return self
    }

    /// 自定义响应失败句柄
    @discardableResult
    public func responseFailure(_ block: (@MainActor @Sendable (Self) -> Void)?) -> Self {
        failureCompletionBlock = block != nil ? { @MainActor @Sendable in block?($0 as! Self) } : nil
        return self
    }

    /// 解析缓存响应句柄，必须在start之前调用生效
    @discardableResult
    public func responseCache(_ block: (@MainActor @Sendable (Self) -> Void)?) -> Self {
        try? loadCacheResponse(completion: { block?($0 as! Self) })
        return self
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
    /// 关联响应模型数据类型，默认支持Any|AnyModel，可扩展
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
            if _cacheResponseModel == nil {
                _cacheResponseModel = responseModelFilter()
            }
            return _cacheResponseModel as? ResponseModel
        }
        set {
            _cacheResponseModel = newValue
        }
    }

    /// 默认实现解析响应模型方法，返回responseJSONObject
    public func responseModelFilter() -> ResponseModel? {
        responseJSONObject as? ResponseModel
    }

    /// 快捷设置模型响应成功句柄
    @discardableResult
    public func responseModel(_ success: (@MainActor @Sendable (ResponseModel?) -> Void)?) -> Self {
        successCompletionBlock = { request in
            success?((request as! Self).responseModel)
        }
        return self
    }

    /// 解析缓存响应模型句柄，必须在start之前调用生效
    @discardableResult
    public func responseCacheModel(_ success: (@MainActor @Sendable (ResponseModel?) -> Void)?) -> Self {
        try? loadCacheResponse(completion: { request in
            success?((request as! Self).responseModel)
        })
        return self
    }
}

/// HTTPRequest AnyModel响应模型请求协议默认实现
extension ResponseModelRequest where Self: HTTPRequest, ResponseModel: AnyModel {
    /// 默认实现当前安全响应模型
    public var safeResponseModel: ResponseModel {
        responseModel ?? .init()
    }

    /// 默认实现解析响应模型方法，调用decodeResponseModel，具体路径为nil
    public func responseModelFilter() -> ResponseModel? {
        decodeResponseModel()
    }

    /// 默认实现解析响应数据为数据模型，支持具体路径
    public func decodeResponseModel(designatedPath: String? = nil) -> ResponseModel? {
        ResponseModel.decodeModel(from: responseJSONObject, designatedPath: designatedPath)
    }

    /// 快捷设置安全模型响应成功句柄
    @discardableResult
    public func safeResponseModel(_ success: (@MainActor @Sendable (ResponseModel) -> Void)?) -> Self {
        successCompletionBlock = { request in
            success?((request as! Self).safeResponseModel)
        }
        return self
    }

    /// 解析缓存安全响应模型句柄，必须在start之前调用生效
    @discardableResult
    public func responseSafeCacheModel(_ success: (@MainActor @Sendable (ResponseModel) -> Void)?) -> Self {
        try? loadCacheResponse(completion: { request in
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
        guard let error else { return false }
        if error is RequestErrorProtocol { return true }
        if (error as NSError).fw.propertyBool(forName: "isRequestError") { return true }
        if (error as NSError).domain == NSURLErrorDomain { return true }
        if let underlyingError = error as? UnderlyingErrorProtocol {
            return isRequestError(underlyingError.underlyingError)
        }
        return false
    }

    /// 判断是否是网络连接错误，支持嵌套请求错误
    public static func isConnectionError(_ error: Error?) -> Bool {
        guard let error else { return false }
        if connectionErrorCodes.contains((error as NSError).code) { return true }
        if let underlyingError = error as? UnderlyingErrorProtocol {
            return isConnectionError(underlyingError.underlyingError)
        }
        return false
    }

    /// 判断是否是网络取消错误，支持嵌套请求错误
    public static func isCancelledError(_ error: Error?) -> Bool {
        guard let error else { return false }
        if error is CancellationError { return true }
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
        NSURLErrorRequestBodyStreamExhausted
    ]

    private static let cancelledErrorCodes: [Int] = [
        NSURLErrorCancelled,
        NSURLErrorUserCancelledAuthentication,
        NSUserCancelledError
    ]
}

// MARK: - Concurrency+HTTPRequest
extension HTTPRequestProtocol where Self: HTTPRequest {
    /// 异步获取完成响应，注意非Task取消也会触发(Continuation流程)
    public func response() async -> Self {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                requestCancelledBlock { request in
                    if !Task.isCancelled {
                        continuation.resume(returning: request)
                    }
                }
                .response { request in
                    continuation.resume(returning: request)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }

    /// 异步获取成功响应，注意非Task取消也会触发(Continuation流程)
    public func responseSuccess() async throws -> Self {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .responseSuccess { request in
                    continuation.resume(returning: request)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }

    /// 异步获取响应模型，注意非Task取消也会触发(Continuation流程)
    public func responseModel<T: AnyModel>(of type: T.Type, designatedPath: String? = nil) async throws -> T? where T: Sendable {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .responseModel(of: type, designatedPath: designatedPath) { responseModel in
                    continuation.resume(returning: responseModel)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }

    /// 异步获取安全响应模型，注意非Task取消也会触发(Continuation流程)
    public func safeResponseModel<T: AnyModel>(of type: T.Type, designatedPath: String? = nil) async throws -> T where T: Sendable {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .safeResponseModel(of: type, designatedPath: designatedPath) { responseModel in
                    continuation.resume(returning: responseModel)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }
}

extension ResponseModelRequest where Self: HTTPRequest {
    /// 异步获取模型响应，注意非Task取消也会触发(Continuation流程)
    public func responseModel() async throws -> ResponseModel? where ResponseModel: Sendable {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .responseModel { responseModel in
                    continuation.resume(returning: responseModel)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }
}

extension ResponseModelRequest where Self: HTTPRequest, ResponseModel: AnyModel {
    /// 异步获取安全模型响应，注意非Task取消也会触发(Continuation流程)
    public func safeResponseModel() async throws -> ResponseModel where ResponseModel: Sendable {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .safeResponseModel { responseModel in
                    continuation.resume(returning: responseModel)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }
}
