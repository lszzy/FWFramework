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
open class HTTPRequest: NSObject {
    
    /// 请求完成句柄
    public typealias Completion = (HTTPRequest) -> Void
    
    // MARK: - Accessor
    /// 自定义请求代理
    open weak var delegate: RequestDelegate?
    /// 自定义标签，默认0
    open var tag: Int = 0
    /// 当前请求的上下文，支持UIViewController|UIView
    open weak var context: AnyObject?
    /// 是否自动显示错误信息
    open var autoShowError = false
    /// 是否自动显示加载信息
    open var autoShowLoading = false
    /// 自定义成功回调句柄
    open var successCompletionBlock: Completion?
    /// 自定义失败回调句柄
    open var failureCompletionBlock: Completion?
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
    /// 自定义用户信息
    open var requestUserInfo: [AnyHashable: Any]?
    /// 是否使用已缓存响应
    open var useCacheResponse: Bool = false
    /// 是否是本地缓存数据
    open private(set) var isDataFromCache: Bool = false
    
    /// 当前请求唯一标志符，只初始化一次，重试时也不变
    open var requestIdentifier: Int = 0
    /// 当前请求适配器，根据插件不同而不同
    open var requestAdapter: Any?
    /// 自定义请求Task获取句柄，用于插件适配
    open var requestTaskBlock: ((HTTPRequest) -> URLSessionTask?)?
    
    /// 当前URLSessionTask，请求开始后可用
    open var requestTask: URLSessionTask? {
        get {
            if let block = requestTaskBlock {
                return block(self)
            }
            return _requestTask
        }
        set {
            _requestTask = newValue
        }
    }
    private var _requestTask: URLSessionTask?
    
    /// 当前响应
    open var response: HTTPURLResponse? {
        return requestTask?.response as? HTTPURLResponse
    }
    /// 当前响应Header
    open var responseHeaders: [AnyHashable: Any]? {
        return response?.allHeaderFields
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
    /// 请求总次数
    open internal(set) var requestTotalCount: Int = 0
    /// 请求总时长
    open internal(set) var requestTotalTime: TimeInterval = 0
    
    /// 请求是否已完成
    open var isFinished: Bool {
        guard let requestTask = requestTask else { return false }
        return requestTask.state == .completed && error == nil
    }
    /// 请求是否已失败
    open var isFailed: Bool {
        guard let requestTask = requestTask else { return false }
        return requestTask.state == .completed && error != nil
    }
    /// 请求是否已取消
    open var isCancelled: Bool {
        guard let requestTask = requestTask else { return false }
        return requestTask.state == .canceling || cancelled
    }
    /// 请求是否执行中
    open var isExecuting: Bool {
        guard let requestTask = requestTask else { return false }
        return requestTask.state == .running
    }
    
    /// 当前响应数据
    open var responseData: Data? {
        get {
            if cacheData != nil {
                return cacheData
            }
            return _responseData
        }
        set {
            _responseData = newValue
        }
    }
    private var _responseData: Data?
    
    /// 当前响应字符串
    open var responseString: String? {
        get {
            if cacheString != nil {
                return cacheString
            }
            return _responseString
        }
        set {
            _responseString = newValue
        }
    }
    private var _responseString: String?
    
    /// 当前响应对象
    open var responseObject: Any? {
        get {
            if cacheJSON != nil {
                return cacheJSON
            }
            if cacheData != nil {
                return cacheData
            }
            return _responseObject
        }
        set {
            _responseObject = newValue
        }
    }
    private var _responseObject: Any?
    
    /// 当前响应JSON对象
    open var responseJSONObject: Any? {
        get {
            if cacheJSON != nil {
                return cacheJSON
            }
            return _responseJSONObject
        }
        set {
            _responseJSONObject = newValue
        }
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
    
    private lazy var contextAccessory: RequestContextAccessory = {
        let result = config.contextAccessoryBlock?(self) ?? RequestContextAccessory()
        return result
    }()
    
    private static var cacheQueue = DispatchQueue(label: "site.wuyong.queue.request.cache", qos: .background)
    
    private var cacheData: Data?
    private var cacheString: String?
    private var cacheJSON: Any?
    private var cacheMetadata: RequestCacheMetadata?
    private var cancelled = false
    
    private var _baseUrl: String?
    private var _requestUrl: String?
    private var _cdnUrl: String?
    private var _useCDN: Bool?
    private var _allowsCellularAccess: Bool?
    private var _requestTimeoutInterval: TimeInterval?
    private var _requestCachePolicy: URLRequest.CachePolicy?
    private var _requestMethod: RequestMethod?
    private var _requestArgument: Any?
    private var _requestSerializerType: RequestSerializerType?
    private var _responseSerializerType: ResponseSerializerType?
    private var _requestAuthorizationHeaders: [String]?
    private var _requestHeaders: [String: String]?
    private var _customUrlRequest: URLRequest?
    private var _jsonValidator: Any?
    private var _requestRetryCount: Int?
    private var _requestRetryInterval: TimeInterval?
    private var _requestRetryTimeout: TimeInterval?
    private var _cacheTimeInSeconds: Int?
    private var _cacheVersion: Int?
    private var _cacheSensitiveData: Any?
    
    fileprivate var _responseModel: Any?
    
    // MARK: - Lifecycle
    public override init() {
        super.init()
    }
    
    /// 请求描述
    open override var description: String {
        return String(
            format: "<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }",
            NSStringFromClass(self.classForCoder),
            self,
            requestTask?.currentRequest?.url?.absoluteString ?? requestUrl(),
            requestTask?.currentRequest?.httpMethod ?? requestMethod().rawValue,
            String.fw_safeString(requestArgument())
        )
    }
    
    // MARK: - Request
    /// 请求基准URL，默认空，示例：https://www.wuyong.site
    open func baseUrl() -> String {
        return _baseUrl ?? ""
    }
    
    /// 请求基准URL，默认空，示例：https://www.wuyong.site
    @discardableResult
    open func baseUrl(_ baseUrl: String) -> Self {
        _baseUrl = baseUrl
        return self
    }
    
    /// 请求URL地址，默认空，示例：/v1/user
    @discardableResult
    open func requestUrl(_ requestUrl: String) -> Self {
        _requestUrl = requestUrl
        return self
    }
    
    /// 请求URL地址，默认空，示例：/v1/user
    open func requestUrl() -> String {
        return _requestUrl ?? ""
    }
    
    /// 请求可选CDN地址，默认空
    open func cdnUrl() -> String {
        return _cdnUrl ?? ""
    }
    
    /// 请求可选CDN地址，默认空
    @discardableResult
    open func cdnUrl(_ cdnUrl: String) -> Self {
        _cdnUrl = cdnUrl
        return self
    }
    
    /// 是否使用CDN
    @discardableResult
    open func useCDN(_ useCDN: Bool) -> Self {
        _useCDN = useCDN
        return self
    }
    
    /// 是否使用CDN
    open func useCDN() -> Bool {
        return _useCDN ?? false
    }
    
    /// 是否允许蜂窝网络访问，默认true
    open func allowsCellularAccess() -> Bool {
        return _allowsCellularAccess ?? true
    }
    
    /// 是否允许蜂窝网络访问，默认true
    @discardableResult
    open func allowsCellularAccess(_ allows: Bool) -> Self {
        _allowsCellularAccess = allows
        return self
    }
    
    /// 请求超时，默认60秒
    @discardableResult
    open func requestTimeoutInterval(_ interval: TimeInterval) -> Self {
        _requestTimeoutInterval = interval
        return self
    }
    
    /// 请求超时，默认60秒
    open func requestTimeoutInterval() -> TimeInterval {
        return _requestTimeoutInterval ?? 60
    }
    
    /// 自定义请求缓存策略，默认nil不处理
    open func requestCachePolicy() -> URLRequest.CachePolicy? {
        return _requestCachePolicy
    }
    
    /// 自定义请求缓存策略，默认nil不处理
    @discardableResult
    open func requestCachePolicy(_ cachePolicy: URLRequest.CachePolicy?) -> Self {
        _requestCachePolicy = cachePolicy
        return self
    }
    
    /// 请求方式，默认GET
    @discardableResult
    open func requestMethod(_ requestMethod: RequestMethod) -> Self {
        _requestMethod = requestMethod
        return self
    }
    
    /// 请求方式，默认GET
    open func requestMethod() -> RequestMethod {
        return _requestMethod ?? .GET
    }
    
    /// 请求附加参数，建议[String: Any]?，默认nil
    open func requestArgument() -> Any? {
        return _requestArgument
    }
    
    /// 请求附加参数，建议[String: Any]?，默认nil
    @discardableResult
    open func requestArgument(_ argument: Any?) -> Self {
        _requestArgument = argument
        return self
    }
    
    /// 请求序列化方式，默认HTTP
    @discardableResult
    open func requestSerializerType(_ serializerType: RequestSerializerType) -> Self {
        _requestSerializerType = serializerType
        return self
    }
    
    /// 请求序列化方式，默认HTTP
    open func requestSerializerType() -> RequestSerializerType {
        return _requestSerializerType ?? .HTTP
    }
    
    /// 响应序列化方式，默认JSON
    open func responseSerializerType() -> ResponseSerializerType {
        return _responseSerializerType ?? .JSON
    }
    
    /// 响应序列化方式，默认JSON
    @discardableResult
    open func responseSerializerType(_ serializerType: ResponseSerializerType) -> Self {
        _responseSerializerType = serializerType
        return self
    }
    
    /// HTTP请求授权Header数组，示例：["UserName", "Password"]
    open func requestAuthorizationHeaders() -> [String]? {
        return _requestAuthorizationHeaders
    }
    
    /// HTTP请求授权Header数组，示例：["UserName", "Password"]
    @discardableResult
    open func requestAuthorizationHeaders(_ array: [String]?) -> Self {
        _requestAuthorizationHeaders = array
        return self
    }
    
    /// 自定义请求Header字典
    open func requestHeaders() -> [String: String]? {
        return _requestHeaders
    }
    
    /// 自定义请求Header字典
    @discardableResult
    open func requestHeaders(_ headers: [String: String]?) -> Self {
        _requestHeaders = headers
        return self
    }
    
    /// 自定义POST请求HTTP body数据
    @discardableResult
    open func constructingBodyBlock(_ block: ((RequestMultipartFormData) -> Void)?) -> Self {
        self.constructingBodyBlock = block
        return self
    }
    
    /// 断点续传下载路径
    @discardableResult
    open func resumableDownloadPath(_ path: String?) -> Self {
        self.resumableDownloadPath = path
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
    
    /// 请求优先级，默认default
    @discardableResult
    open func requestPriority(_ priority: RequestPriority) -> Self {
        self.requestPriority = priority
        return self
    }
    
    /// 自定义用户信息
    @discardableResult
    open func requestUserInfo(_ userInfo: [AnyHashable: Any]?) -> Self {
        self.requestUserInfo = userInfo
        return self
    }
    
    /// 自定义标签，默认0
    @discardableResult
    open func tag(_ tag: Int) -> Self {
        self.tag = tag
        return self
    }
    
    /// JSON验证器，默认支持AnyValidator
    @discardableResult
    open func jsonValidator(_ validator: Any?) -> Self {
        _jsonValidator = validator
        return self
    }
    
    /// JSON验证器，默认支持AnyValidator
    open func jsonValidator() -> Any? {
        return _jsonValidator
    }
    
    /// 构建自定义URLRequest
    open func customUrlRequest() -> URLRequest? {
        return _customUrlRequest
    }
    
    /// 构建自定义URLRequest
    @discardableResult
    open func customUrlRequest(_ urlRequest: URLRequest?) -> Self {
        _customUrlRequest = urlRequest
        return self
    }
    
    /// 自定义成功回调句柄
    @discardableResult
    open func successCompletionBlock(_ block: Completion?) -> Self {
        self.successCompletionBlock = block
        return self
    }
    
    /// 自定义失败回调句柄
    @discardableResult
    open func failureCompletionBlock(_ block: Completion?) -> Self {
        self.failureCompletionBlock = block
        return self
    }
    
    /// 快捷设置模型响应成功句柄
    @discardableResult
    public func responseModel<T: AnyCodableModel>(of type: T.Type, designatedPath: String? = nil, success: ((T?) -> Void)?) -> Self {
        successCompletionBlock = { request in
            let responseModel = T.decodeAnyModel(from: request.responseJSONObject, designatedPath: designatedPath)
            success?(responseModel)
        }
        return self
    }
    
    /// 快捷设置安全模型响应成功句柄
    @discardableResult
    public func safeResponseModel<T: SafeCodableModel>(of type: T.Type, designatedPath: String? = nil, success: ((T) -> Void)?) -> Self {
        successCompletionBlock = { request in
            let responseModel = T.decodeSafeModel(from: request.responseJSONObject, designatedPath: designatedPath)
            success?(responseModel)
        }
        return self
    }
    
    /// 快捷设置响应失败句柄
    @discardableResult
    public func responseError(_ failure: ((Error) -> Void)?) -> Self {
        failureCompletionBlock = { request in
            failure?(request.error ?? RequestError.unknownError)
        }
        return self
    }
    
    // MARK: - Response
    /// 状态码验证器
    open func statusCodeValidator() -> Bool {
        let statusCode = responseStatusCode
        return statusCode >= 200 && statusCode <= 299
    }
    
    /// 调试请求Mock验证器，默认判断404
    open func responseMockValidator() -> Bool {
        if let validator = config.debugMockValidator {
            return validator(self)
        }
        return responseStatusCode == 404
    }
    
    /// 调试请求Mock处理器，请求失败时且回调前在后台线程调用
    open func responseMockProcessor() -> Bool {
        if let processor = config.debugMockProcessor {
            return processor(self)
        }
        return false
    }
    
    /// 请求发送前URLRequest过滤方法，默认不处理
    open func filterUrlRequest(_ urlRequest: inout URLRequest) {
    }
    
    /// 请求回调前Response过滤方法，默认成功不抛异常
    open func filterResponse() throws {
    }
    
    /// 请求完成预处理器，后台线程调用
    open func requestCompletePreprocessor() {
        let responseData = _responseData
        if writeCacheAsynchronously() {
            HTTPRequest.cacheQueue.async { [weak self] in
                self?.saveResponseData(responseData)
            }
        } else {
            saveResponseData(responseData)
        }
    }
    
    /// 请求完成过滤器，主线程调用
    open func requestCompleteFilter() {
    }
    
    /// 请求失败预处理器，后台线程调用
    open func requestFailedPreprocessor() {
    }
    
    /// 请求失败过滤器，主线程调用
    open func requestFailedFilter() {
    }
    
    // MARK: - Context
    /// 当前请求的上下文，支持UIViewController|UIView
    @discardableResult
    open func context(_ context: AnyObject?) -> Self {
        self.context = context
        return self
    }
    
    /// 是否自动显示错误信息
    @discardableResult
    open func autoShowError(_ autoShowError: Bool) -> Self {
        self.autoShowError = autoShowError
        return self
    }
    
    /// 是否自动显示加载信息
    @discardableResult
    open func autoShowLoading(_ autoShowLoading: Bool) -> Self {
        self.autoShowLoading = autoShowLoading
        return self
    }
    
    /// 显示网络错误，默认显示Toast提示
    open func showError() {
        contextAccessory.showError(for: self)
    }
    
    /// 显示加载条，默认显示加载插件
    open func showLoading() {
        contextAccessory.showLoading(for: self)
    }
    
    /// 隐藏加载条，默认隐藏加载插件
    open func hideLoading() {
        contextAccessory.hideLoading(for: self)
    }
    
    // MARK: - Retry
    /// 请求重试次数，默认0
    open func requestRetryCount() -> Int {
        return _requestRetryCount ?? 0
    }
    
    /// 请求重试次数，默认0
    @discardableResult
    open func requestRetryCount(_ count: Int) -> Self {
        _requestRetryCount = count
        return self
    }
    
    /// 请求重试间隔，默认0
    open func requestRetryInterval() -> TimeInterval {
        return _requestRetryInterval ?? 0
    }
    
    /// 请求重试间隔，默认0
    @discardableResult
    open func requestRetryInterval(_ interval: TimeInterval) -> Self {
        _requestRetryInterval = interval
        return self
    }
    
    /// 请求重试超时时间，默认0
    open func requestRetryTimeout() -> TimeInterval {
        return _requestRetryTimeout ?? 0
    }
    
    /// 请求重试超时时间，默认0
    @discardableResult
    open func requestRetryTimeout(_ timeout: TimeInterval) -> Self {
        _requestRetryTimeout = timeout
        return self
    }
    
    /// 请求重试验证方法，requestRetryCount大于0生效，默认检查状态码和错误
    open func requestRetryValidator(_ response: HTTPURLResponse, responseObject: Any?, error: Error?) -> Bool {
        if isCancelled { return false }
        let statusCode = response.statusCode
        return error != nil || statusCode < 200 || statusCode > 299
    }
    
    /// 请求重试处理方法，requestRetryValidator返回true生效，默认调用completionHandler(true)
    open func requestRetryProcessor(_ response: HTTPURLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    // MARK: - Action
    /// 开始并发请求
    @discardableResult
    open func start() -> Self {
        if !useCacheResponse {
            return startWithoutCache()
        }
        
        if let downloadPath = resumableDownloadPath, !downloadPath.isEmpty {
            return startWithoutCache()
        }
        
        do {
            try loadCache()
        } catch {
            return startWithoutCache()
        }
        
        isDataFromCache = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.requestCompletePreprocessor()
            self.requestCompleteFilter()
            self.delegate?.requestFinished(self)
            self.successCompletionBlock?(self)
            self.clearCompletionBlock()
        }
        return self
    }
    
    /// 开始请求，忽略本地缓存
    @discardableResult
    open func startWithoutCache() -> Self {
        clearCacheVariables()
        toggleAccessoriesWillStartCallBack()
        RequestManager.shared.addRequest(self)
        return self
    }
    
    /// 停止并发请求
    open func stop() {
        toggleAccessoriesWillStopCallBack()
        delegate = nil
        RequestManager.shared.cancelRequest(self)
        cancelled = true
        toggleAccessoriesDidStopCallBack()
    }
    
    /// 开始并发请求并指定成功、失败句柄
    @discardableResult
    open func start<T: HTTPRequest>(success: ((T) -> Void)?, failure: ((T) -> Void)?) -> Self {
        successCompletionBlock = success != nil ? { success?($0 as! T) } : nil
        failureCompletionBlock = failure != nil ? { failure?($0 as! T) } : nil
        return start()
    }
    
    /// 开始并发请求并指定完成句柄
    @discardableResult
    open func start<T: HTTPRequest>(completion: ((T) -> Void)?) -> Self {
        return start(success: completion, failure: completion)
    }
    
    /// 开始同步串行请求并指定成功、失败句柄
    @discardableResult
    open func startSynchronously<T: HTTPRequest>(success: ((T) -> Void)?, failure: ((T) -> Void)?) -> Self {
        return startSynchronously(filter: nil) { (request: T) in
            if request.error == nil {
                success?(request)
            } else {
                failure?(request)
            }
        }
    }
    
    /// 开始同步串行请求并指定过滤器和完成句柄
    @discardableResult
    open func startSynchronously<T: HTTPRequest>(filter: (() -> Bool)? = nil, completion: ((T) -> Void)?) -> Self {
        RequestManager.shared.synchronousRequest(self, filter: filter, completion: completion != nil ? { completion?($0 as! T) } : nil)
        return self
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
    
    /// 清理完成句柄
    open func clearCompletionBlock() {
        successCompletionBlock = nil
        failureCompletionBlock = nil
        uploadProgressBlock = nil
    }
    
    /// 切换配件将开始回调
    open func toggleAccessoriesWillStartCallBack() {
        contextAccessory.requestWillStart(self)
        requestAccessories?.forEach({ accessory in
            accessory.requestWillStart(self)
        })
    }
    
    /// 切换配件将结束回调
    open func toggleAccessoriesWillStopCallBack() {
        contextAccessory.requestWillStop(self)
        requestAccessories?.forEach({ accessory in
            accessory.requestWillStop(self)
        })
    }
    
    /// 切换配件已经结束回调
    open func toggleAccessoriesDidStopCallBack() {
        contextAccessory.requestDidStop(self)
        requestAccessories?.forEach({ accessory in
            accessory.requestDidStop(self)
        })
    }
    
    // MARK: - Cache
    /// 是否使用已缓存响应
    @discardableResult
    open func useCacheResponse(_ useCacheResponse: Bool) -> Self {
        self.useCacheResponse = useCacheResponse
        return self
    }
    
    /// 缓存有效期，默认-1不缓存
    open func cacheTimeInSeconds() -> Int {
        return _cacheTimeInSeconds ?? -1
    }
    
    /// 缓存有效期，默认-1不缓存
    @discardableResult
    open func cacheTimeInSeconds(_ seconds: Int) -> Self {
        _cacheTimeInSeconds = seconds
        return self
    }
    
    /// 缓存版本号，默认0
    open func cacheVersion() -> Int {
        return _cacheVersion ?? 0
    }
    
    /// 缓存版本号，默认0
    @discardableResult
    open func cacheVersion(_ version: Int) -> Self {
        _cacheVersion = version
        return self
    }
    
    /// 缓存附加数据，变化时会更新缓存
    open func cacheSensitiveData() -> Any? {
        return _cacheSensitiveData
    }
    
    /// 缓存附加数据，变化时会更新缓存
    @discardableResult
    open func cacheSensitiveData(_ sensitiveData: Any?) -> Self {
        _cacheSensitiveData = sensitiveData
        return self
    }
    
    /// 缓存文件名过滤器，参数为请求参数，默认返回argument
    open func filterCacheFileName(_ argument: Any?) -> Any? {
        return argument
    }
    
    /// 是否异步写入缓存，默认true
    open func writeCacheAsynchronously() -> Bool {
        return true
    }
    
    /// 加载本地缓存，返回是否成功
    open func loadCache() throws {
        if cacheTimeInSeconds() < 0 {
            throw RequestError.cacheInvalidCacheTime
        }
        
        if !loadCacheMetadata() {
            throw RequestError.cacheInvalidMetadata
        }
        
        try validateCache()
        
        if !loadCacheData() {
            throw RequestError.cacheInvalidCacheData
        }
        
        #if DEBUG
        if config.debugLogEnabled {
            Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST CACHED===========\n%@%@ %@:\n%@", "💾 ", requestMethod().rawValue, requestUrl(), String.fw_safeString(responseJSONObject ?? responseString))
        }
        #endif
    }
    
    /// 保存指定响应数据到缓存文件
    open func saveResponseData(_ data: Data?) {
        guard let data = data else { return }
        guard cacheTimeInSeconds() > 0, !isDataFromCache else { return }
        
        do {
            try data.write(to: URL(fileURLWithPath: cacheFilePath()), options: .atomic)
            
            let metadata = RequestCacheMetadata()
            metadata.version = cacheVersion()
            metadata.sensitiveDataString = String.fw_safeString(cacheSensitiveData())
            metadata.stringEncoding = RequestManager.shared.stringEncoding(for: self)
            metadata.creationDate = Date()
            metadata.appVersionString = UIApplication.fw_appVersion
            Data.fw_archiveObject(metadata, toFile: cacheMetadataFilePath())
        } catch {
            #if DEBUG
            if config.debugLogEnabled {
                Logger.debug(group: Logger.fw_moduleName, "Save cache failed, reason = %@", error.localizedDescription)
            }
            #endif
        }
    }
    
    /// 缓存基本路径
    open func cacheBasePath() -> String {
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
        var path = (libraryPath as NSString).appendingPathComponent("LazyRequestCache")
        
        if let filterPath = config.cacheDirPathFilter?(self, path) {
            path = filterPath
        }
        
        createCacheDirectory(path)
        return path
    }
    
    private func loadCacheMetadata() -> Bool {
        let path = cacheMetadataFilePath()
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) {
            if let metadata = Data.fw_unarchivedObject(withFile: path) as? RequestCacheMetadata {
                cacheMetadata = metadata
                return true
            } else {
                #if DEBUG
                if config.debugLogEnabled {
                    Logger.debug(group: Logger.fw_moduleName, "Load cache metadata failed")
                }
                #endif
                return false
            }
        }
        return false
    }
    
    private func validateCache() throws {
        let metadataDuration = -(cacheMetadata?.creationDate?.timeIntervalSinceNow ?? 0)
        if metadataDuration < 0 || metadataDuration > TimeInterval(cacheTimeInSeconds()) {
            throw RequestError.cacheExpired
        }
        
        let metadataVersion = cacheMetadata?.version ?? 0
        if metadataVersion != cacheVersion() {
            throw RequestError.cacheVersionMismatch
        }
        
        let metadataSensitive = cacheMetadata?.sensitiveDataString ?? ""
        let currentSensitive = String.fw_safeString(cacheSensitiveData())
        if metadataSensitive != currentSensitive {
            throw RequestError.cacheSensitiveDataMismatch
        }
        
        let metadataAppVersion = cacheMetadata?.appVersionString ?? ""
        let currentAppVersion = UIApplication.fw_appVersion
        if metadataAppVersion != currentAppVersion {
            throw RequestError.cacheAppVersionMismatch
        }
    }
    
    private func loadCacheData() -> Bool {
        let path = cacheFilePath()
        if FileManager.default.fileExists(atPath: path, isDirectory: nil),
           let data = NSData(contentsOfFile: path) as? Data {
            cacheData = data
            cacheString = String(data: data, encoding: cacheMetadata?.stringEncoding ?? .utf8)
            switch responseSerializerType() {
            case .HTTP:
                return true
            case .JSON:
                cacheJSON = cacheData?.fw_jsonDecode
                return cacheJSON != nil
            }
        }
        return false
    }
    
    private func clearCacheVariables() {
        cacheData = nil
        cacheJSON = nil
        cacheString = nil
        cacheMetadata = nil
        isDataFromCache = false
    }
    
    private func createCacheDirectory(_ path: String) {
        var isDir: ObjCBool = true
        if !FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            createBaseDirectory(path)
        } else {
            if !isDir.boolValue {
                try? FileManager.default.removeItem(atPath: path)
                createBaseDirectory(path)
            }
        }
    }
    
    private func createBaseDirectory(_ path: String) {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            FileManager.fw_skipBackup(path)
        } catch {
            #if DEBUG
            if config.debugLogEnabled {
                Logger.debug(group: Logger.fw_moduleName, "create cache directory failed, error = %@", error.localizedDescription)
            }
            #endif
        }
    }
    
    private func cacheFileName() -> String {
        let requestUrl = requestUrl()
        let baseUrl: String
        if useCDN() {
            baseUrl = !cdnUrl().isEmpty ? cdnUrl() : config.cdnUrl
        } else {
            baseUrl = !self.baseUrl().isEmpty ? self.baseUrl() : config.baseUrl
        }
        let argument = filterCacheFileName(requestArgument())
        let requestInfo = String(format: "Method:%ld Host:%@ Url:%@ Argument:%@", requestMethod().rawValue, baseUrl, requestUrl, String.fw_safeString(argument))
        return requestInfo.fw_md5Encode
    }
    
    private func cacheFilePath() -> String {
        let cacheFileName = cacheFileName()
        var path = cacheBasePath()
        path = (path as NSString).appendingPathComponent(cacheFileName)
        return path
    }
    
    private func cacheMetadataFilePath() -> String {
        let metadataFileName = "\(cacheFileName()).metadata"
        var path = cacheBasePath()
        path = (path as NSString).appendingPathComponent(metadataFileName)
        return path
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
            if _responseModel == nil {
                _responseModel = responseModelFilter()
            }
            return _responseModel as? ResponseModel
        }
        set {
            _responseModel = newValue
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
    
}

/// HTTPRequest AnyCodableModel响应模型请求协议默认实现
extension ResponseModelRequest where Self: HTTPRequest, ResponseModel: AnyCodableModel {
    
    /// 默认实现解析响应模型方法，调用decodeResponseModel，具体路径为nil
    public func responseModelFilter() -> ResponseModel? {
        return decodeResponseModel()
    }
    
    /// 默认实现解析响应数据为数据模型，支持具体路径
    public func decodeResponseModel(designatedPath: String? = nil) -> ResponseModel? {
        return ResponseModel.decodeAnyModel(from: responseJSONObject, designatedPath: designatedPath)
    }
    
}

/// HTTPRequest SafeCodableModel响应模型请求协议默认实现
extension ResponseModelRequest where Self: HTTPRequest, ResponseModel: SafeCodableModel {
    
    /// 默认实现当前安全响应模型
    public var safeResponseModel: ResponseModel {
        return responseModel ?? .init()
    }
    
    /// 快捷设置安全模型响应成功句柄
    @discardableResult
    public func safeResponseModel(_ success: ((ResponseModel) -> Void)?) -> Self {
        successCompletionBlock = { request in
            success?((request as! Self).safeResponseModel)
        }
        return self
    }
    
}

// MARK: - RequestError
/// 请求错误
public enum RequestError: Swift.Error, CustomNSError {
    case cacheExpired
    case cacheVersionMismatch
    case cacheSensitiveDataMismatch
    case cacheAppVersionMismatch
    case cacheInvalidCacheTime
    case cacheInvalidMetadata
    case cacheInvalidCacheData
    case validationInvalidStatusCode(_ code: Int)
    case validationInvalidJSONFormat
    case unknownError
    
    public static var errorDomain: String { "site.wuyong.error.request" }
    public var errorCode: Int {
        switch self {
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
        case .unknownError:
            return -10
        }
    }
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
        case let .validationInvalidStatusCode(code):
            return [NSLocalizedDescriptionKey: "Invalid status code (\(code))"]
        case .validationInvalidJSONFormat:
            return [NSLocalizedDescriptionKey: "Invalid JSON format"]
        case .unknownError:
            return [NSLocalizedDescriptionKey: "Unknown error"]
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
