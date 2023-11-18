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
    /// 自定义请求配置，未设置时使用全局配置
    open var requestConfig: RequestConfig! {
        get { _requestConfig ?? RequestConfig.shared }
        set { _requestConfig = newValue }
    }
    private var _requestConfig: RequestConfig?
    
    /// 自定义请求代理
    open weak var delegate: RequestDelegate?
    /// 自定义成功回调句柄
    open var successCompletionBlock: ((HTTPRequest) -> Void)?
    /// 自定义失败回调句柄
    open var failureCompletionBlock: ((HTTPRequest) -> Void)?
    /// 自定义请求配件数组
    open var requestAccessories: [RequestAccessoryProtocol] = []
    /// 自定义POST请求HTTP body数据
    open var constructingBodyBlock: ((RequestMultipartFormData) -> Void)?
    /// 断点续传下载路径
    open var resumableDownloadPath: String?
    /// 断点续传进度句柄
    open var resumableDownloadProgressBlock: ((Progress) -> Void)?
    /// 上传进度句柄
    open var uploadProgressBlock: ((Progress) -> Void)?
    /// 请求优先级，默认default
    open var requestPriority: RequestPriority = .default
    
    /// 当前URLSessionTask，请求开始后可用
    open var requestTask: URLSessionTask?
    /// 当前请求唯一标志符
    open var requestIdentifier: Int {
        return requestTask?.taskIdentifier ?? 0
    }
    /// 自定义标签，默认0
    open var tag: Int = 0
    /// 自定义用户信息
    open var requestUserInfo: [AnyHashable: Any]?
    /// 请求总次数
    open internal(set) var requestTotalCount: Int = 0
    /// 请求总时长
    open internal(set) var requestTotalTime: TimeInterval = 0
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
            if cacheXML != nil {
                return cacheXML
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
    
    private var cacheData: Data?
    private var cacheString: String?
    private var cacheJSON: Any?
    private var cacheXML: XMLParser?
    private var cacheMetadata: RequestCacheMetadata?
    private var dataFromCache = false
    private var cancelled = false
    
    // MARK: - Lifecycle
    public override init() {
        super.init()
    }
    
    open override var description: String {
        return String(format: "<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass(self.classForCoder), self, String.fw_safeString(currentRequest?.url), currentRequest?.httpMethod ?? "", String.fw_safeString(requestArgument()))
    }
    
    // MARK: - Override
    /// 请求基准URL，默认空，示例：https://www.wuyong.site
    open func baseUrl() -> String {
        return ""
    }
    
    /// 请求URL地址，默认空，示例：/v1/user
    open func requestUrl() -> String {
        return ""
    }
    
    /// 请求可选CDN地址，默认空
    open func cdnUrl() -> String {
        return ""
    }
    
    /// 是否使用CDN
    open func useCDN() -> Bool {
        return false
    }
    
    /// 是否允许蜂窝网络访问，默认true
    open func allowsCellularAccess() -> Bool {
        return true
    }
    
    /// 请求超时，默认60秒
    open func requestTimeoutInterval() -> TimeInterval {
        return 60
    }
    
    /// 自定义请求缓存策略，默认nil不处理
    open func requestCachePolicy() -> URLRequest.CachePolicy? {
        return nil
    }
    
    /// 请求方式，默认GET
    open func requestMethod() -> RequestMethod {
        return .GET
    }
    
    /// 请求附加参数，默认nil
    open func requestArgument() -> Any? {
        return nil
    }
    
    /// 请求序列化方式，默认HTTP
    open func requestSerializerType() -> RequestSerializerType {
        return .HTTP
    }
    
    /// 响应序列化方式，默认JSON
    open func responseSerializerType() -> ResponseSerializerType {
        return .JSON
    }
    
    /// HTTP请求授权Header数组，示例：["UserName", "Password"]
    open func requestAuthorizationHeaderFieldArray() -> [String]? {
        return nil
    }
    
    /// 自定义请求Header字典
    open func requestHeaderFieldValueDictionary() -> [String: String]? {
        return nil
    }
    
    /// 构建自定义URLRequest
    open func buildCustomUrlRequest() -> URLRequest? {
        return nil
    }
    
    /// JSON验证器
    open func jsonValidator() -> Any? {
        return nil
    }
    
    /// 状态码验证器
    open func statusCodeValidator() -> Bool {
        let statusCode = responseStatusCode
        return statusCode >= 200 && statusCode <= 299
    }
    
    /// 调试请求Mock验证器，默认判断404
    open func responseMockValidator() -> Bool {
        if let validator = requestConfig.debugMockValidator {
            return validator(self)
        }
        return responseStatusCode == 404
    }
    
    /// 调试请求Mock处理器，请求失败时且回调前在后台线程调用
    open func responseMockProcessor() -> Bool {
        if let processor = requestConfig.debugMockProcessor {
            return processor(self)
        }
        return false
    }
    
    /// 请求发送前URLRequest过滤方法，默认不处理
    open func filterUrlRequest(_ urlRequest: NSMutableURLRequest) {
    }
    
    /// 请求回调前Response过滤方法，默认成功不抛异常
    open func filterResponse() throws {
        
    }
    
    /// 请求完成预处理器，后台线程调用
    open func requestCompletePreprocessor() {
        
    }
    
    /// 请求完成过滤器，主线程调用
    open func requestCompleteFilter() {
    }
    
    /// 请求失败预处理器，后台线程调用
    open func requestFailedPreprocessor() {
    }
    
    /// 请求失败过滤器，主线程调用，默认处理autoShowError
    open func requestFailedFilter() {
        if autoShowError {
            showRequestError()
        }
    }
    
    // MARK: - Retry
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
        if isCancelled { return false }
        let statusCode = response.statusCode
        return error != nil || statusCode < 200 || statusCode > 299
    }
    
    /// 请求重试处理方法，requestRetryValidator返回true生效，默认调用completionHandler(true)
    open func requestRetryProcessor(_ response: HTTPURLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    // MARK: - Action
    /// 开始请求
    open func start() {
        
    }
    
    /// 停止请求
    open func stop() {
        
    }
    
    /// 开始请求并指定成功、失败句柄
    open func start(success: ((Self) -> Void)?, failure: ((Self) -> Void)?) {
        successCompletionBlock = success != nil ? { success?($0 as! Self) } : nil
        failureCompletionBlock = failure != nil ? { failure?($0 as! Self ) } : nil
        start()
    }
    
    /// 开始请求并指定完成句柄
    open func start(completion: ((Self) -> Void)?) {
        start(success: completion, failure: completion)
    }
    
    /// 开始同步请求并指定成功、失败句柄
    open func startSynchronously(success: ((Self) -> Void)?, failure: ((Self) -> Void)?) {
        
    }
    
    /// 开始同步请求并指定过滤器和完成句柄
    open func startSynchronously(filter: (() -> Bool)? = nil, completion: ((Self) -> Void)?) {
        
    }
    
    /// 添加请求配件
    open func addAccessory(_ accessory: RequestAccessoryProtocol) {
        requestAccessories.append(accessory)
    }
    
    /// 清理完成句柄
    open func clearCompletionBlock() {
        successCompletionBlock = nil
        failureCompletionBlock = nil
        uploadProgressBlock = nil
    }
    
    /// 切换配件将开始回调
    open func toggleAccessoriesWillStartCallBack() {
        for accessory in requestAccessories {
            accessory.requestWillStart(self)
        }
    }
    
    /// 切换配件将结束回调
    open func toggleAccessoriesWillStopCallBack() {
        for accessory in requestAccessories {
            accessory.requestWillStop(self)
        }
    }
    
    /// 切换配件已经结束回调
    open func toggleAccessoriesDidStopCallBack() {
        for accessory in requestAccessories {
            accessory.requestDidStop(self)
        }
    }
    
    // MARK: - Cache
    /// 缓存有效期，默认-1不缓存
    open func cacheTimeInSeconds() -> Int {
        return -1
    }
    
    /// 缓存版本号，默认0
    open func cacheVersion() -> Int {
        return 0
    }
    
    /// 缓存附加数据，变化时会更新缓存
    open func cacheSensitiveData() -> Any? {
        return nil
    }
    
    /// 是否异步写入缓存，默认true
    open func writeCacheAsynchronously() -> Bool {
        return true
    }
    
    /// 缓存基本路径
    open func cacheBasePath() -> String {
        return ""
    }
    
    /// 是否使用已缓存响应
    open var useCacheResponse: Bool = false
    
    /// 是否是本地缓存数据
    open var isDataFromCache: Bool {
        return dataFromCache
    }
    
    /// 加载本地缓存，返回是否成功
    open func loadCacheWithError(_ error: inout Error?) -> Bool {
        return false
    }
    
    /// 开始请求，忽略本地缓存
    open func startWithoutCache() {
        
    }
    
    /// 保存指定响应数据到缓存文件
    open func saveResponseDataToCacheFile(_ data: Data) {
        
    }
    
    /// 缓存文件名过滤器，参数为请求参数，默认返回argument
    open func filterCacheFileName(_ argument: Any?) -> Any? {
        return argument
    }
    
    // MARK: - Error
    /// 是否自动显示错误信息
    open var autoShowError = false
    
    /// 显示网络错误，默认显示Toast提示
    open func showRequestError() {
        guard let error = error else { return }
        
        if let block = requestConfig.showRequestErrorBlock {
            block(self)
        } else {
            if Thread.isMainThread {
                UIWindow.fw_showMessage(error: error)
            } else {
                DispatchQueue.main.async {
                    UIWindow.fw_showMessage(error: error)
                }
            }
        }
    }
    
}

// MARK: - RequestMultipartFormData
/// 请求表单数据协议
@objc public protocol RequestMultipartFormData {
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
