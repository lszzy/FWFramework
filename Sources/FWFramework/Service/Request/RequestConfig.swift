//
//  RequestConfig.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

// MARK: - RequestFilter
/// 请求过滤器协议
@objc public protocol RequestFilterProtocol {
    
    /// 请求URL过滤器，返回处理后的URL
    @objc optional func filterUrl(_ originUrl: String, with request: HTTPRequest) -> String
    
    /// 请求缓存路径过滤镜，返回处理后的路径
    @objc optional func filterCacheDirPath(_ originPath: String, with request: HTTPRequest) -> String
    
    /// 请求URLRequest过滤器，处理后才发送请求
    @objc optional func filterUrlRequest(_ urlRequest: NSMutableURLRequest, with request: HTTPRequest)
    
    /// 请求Response过滤器，处理后才调用回调
    func filterResponse(with request: HTTPRequest) throws
    
}

extension RequestFilterProtocol {
    
    /// 默认实现请求Response过滤器，处理后才调用回调
    public func filterResponse(with request: HTTPRequest) throws {
    }
    
}

// MARK: - RequestConfig
/// 请求配置类
open class RequestConfig: NSObject {
    
    public static let shared = RequestConfig()
    
    /// 自定义请求插件，未设置时自动从插件池加载
    open var requestPlugin: RequestPlugin! {
        get {
            if let requestPlugin = _requestPlugin {
                return requestPlugin
            } else if let requestPlugin = PluginManager.loadPlugin(RequestPlugin.self) {
                return requestPlugin
            }
            return RequestPluginImpl.shared
        }
        set {
            _requestPlugin = newValue
        }
    }
    private var _requestPlugin: RequestPlugin?
    
    /// 当前请求重试器，默认全局重试器，可清空
    open var requestRetrier: RequestRetrierProtocol? = RequestRetrier.default
    
    /// 当前请求验证器，默认全局验证器，可清空
    open var requestValidator: RequestValidatorProtocol? = RequestValidator.default
    
    /// 请求过滤器数组
    open private(set) var requestFilters: [RequestFilterProtocol] = []
    
    /// 请求基准地址
    open var baseUrl: String = ""
    /// 请求CDN地址
    open var cdnUrl: String = ""
    
    /// 是否启用调试
    open var debugLogEnabled: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()
    /// 是否启用调试Mock
    open var debugMockEnabled: Bool = false
    /// 调试Mock验证器，默认nil
    open var debugMockValidator: ((HTTPRequest) -> Bool)?
    /// 调试Mock处理器，默认nil
    open var debugMockProcessor: ((HTTPRequest) -> Bool)?
    
    /// 自定义请求上下文配件句柄，默认nil
    open var contextAccessoryBlock: ((HTTPRequest) -> RequestContextAccessory)?
    /// 自定义显示错误方法，主线程优先调用，默认nil
    open var showErrorBlock: ((HTTPRequest) -> Void)?
    /// 自定义显示加载方法，主线程优先调用，默认nil
    open var showLoadingBlock: ((HTTPRequest) -> Void)?
    /// 自定义隐藏加载方法，主线程优先调用，默认nil
    open var hideLoadingBlock: ((HTTPRequest) -> Void)?
    
    public override init() {
        super.init()
    }
    
    open override var description: String {
        return String(format: "<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass(self.classForCoder), self, baseUrl, cdnUrl)
    }
    
    /// 添加请求过滤器
    open func addRequestFilter(_ fileter: RequestFilterProtocol) {
        requestFilters.append(fileter)
    }
    
    /// 清空所有请求过滤器
    open func clearRequestFilters() {
        requestFilters.removeAll()
    }
    
}

// MARK: - RequestAccessory
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

/// 默认请求上下文配件，用于处理加载条和显示错误等
open class RequestContextAccessory: RequestAccessory {
    /// 是否自动初始化当前context控制器，默认true
    open var autoSetupContext: Bool = true
    /// 是否自动监听当前context控制器，当释放时自动停止请求，默认true
    open var autoObserveContext: Bool = true
    
    public override init() {
        super.init()
        
        self.willStartBlock = { [weak self] request in
            guard let request = request as? HTTPRequest else { return }
            
            if (request.autoShowLoading || request.autoShowError),
               self?.autoSetupContext == true, request.context == nil {
                self?.setupContext(for: request)
            }
            if request.context != nil, self?.autoObserveContext == true {
                self?.observeContext(for: request)
            }
            if request.autoShowLoading {
                request.showLoading()
            }
        }
        self.willStopBlock = nil
        self.didStopBlock = { request in
            guard let request = request as? HTTPRequest else { return }
            
            if request.autoShowLoading {
                request.hideLoading()
            }
            if request.autoShowError, request.error != nil {
                request.showError()
            }
        }
    }
    
    /// 初始化请求上下文，默认获取当前顶部控制器
    open func setupContext(for request: HTTPRequest) {
        guard request.context == nil else { return }
        
        request.context = UIWindow.fw_mainWindow?.fw_topViewController
    }
    
    /// 监听请求上下文，默认context控制器释放时自动停止请求
    open func observeContext(for request: HTTPRequest) {
        var viewController = request.context as? UIViewController
        if viewController == nil, let view = request.context as? UIView {
            viewController = view.fw_viewController
        }
        guard let viewController = viewController else { return }
        
        viewController.fw_observeLifecycleState { _, state in
            guard state == .didDeinit else { return }
            guard !request.isFinished, !request.isFailed, !request.isCancelled else { return }
            
            request.stop()
        }
    }
    
    /// 显示请求错误，优先调用config，默认显示Toast提示
    open func showError(for request: HTTPRequest) {
        guard request.context != nil, !request.isCancelled,
              let error = request.error else { return }
        
        if let block = request.config.showErrorBlock {
            block(request)
            return
        }
        
        DispatchQueue.fw_mainAsync {
            if let viewController = request.context as? UIViewController {
                viewController.fw_showMessage(error: error)
            } else if let view = request.context as? UIView {
                view.fw_showMessage(error: error)
            }
        }
    }
    
    /// 显示请求加载条，优先调用config
    open func showLoading(for request: HTTPRequest) {
        guard request.context != nil else { return }
        
        if let block = request.config.showLoadingBlock {
            block(request)
            return
        }
        
        DispatchQueue.fw_mainAsync {
            if let viewController = request.context as? UIViewController {
                viewController.fw_showLoading()
            } else if let view = request.context as? UIView {
                view.fw_showLoading()
            }
        }
    }
    
    /// 隐藏请求加载条，优先调用config
    open func hideLoading(for request: HTTPRequest) {
        guard request.context != nil else { return }
        
        if let block = request.config.hideLoadingBlock {
            block(request)
            return
        }
        
        DispatchQueue.fw_mainAsync {
            if let viewController = request.context as? UIViewController {
                viewController.fw_hideLoading()
            } else if let view = request.context as? UIView {
                view.fw_hideLoading()
            }
        }
    }
}

// MARK: - RequestRetrier
/// 请求重试器协议
public protocol RequestRetrierProtocol: AnyObject {
    /// 重试方式创建数据任务
    func retryDataTask(for request: HTTPRequest, completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)?) throws
}

/// 默认请求重试器，直接调用request的钩子方法
open class RequestRetrier: NSObject, RequestRetrierProtocol {
    public static let `default` = RequestRetrier()
    
    open func retryDataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) throws {
        let startTime = Date().timeIntervalSince1970
        let retryCount = request.requestRetryCount()
        try retryDataTask(for: request, retryCount: retryCount, remainCount: retryCount, startTime: startTime, shouldRetry: { response, responseObject, error, decisionHandler in
            guard let response = response as? HTTPURLResponse else {
                decisionHandler(false)
                return
            }
            
            let shouldRetry = request.requestRetryValidator(response, responseObject: responseObject, error: error)
            if !shouldRetry {
                decisionHandler(false)
                return
            }
            
            request.requestRetryProcessor(response, responseObject: responseObject, error: error) { success in
                decisionHandler(success)
            }
        }, completionHandler: completionHandler)
    }
    
    private func retryDataTask(
        for request: HTTPRequest,
        retryCount: Int,
        remainCount: Int,
        startTime: TimeInterval,
        shouldRetry: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?, _ decisionHandler: @escaping (Bool) -> Void) -> Void)?,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)?
    ) throws {
        let shouldRetry = shouldRetry ?? { response, responseObject, error, decisionHandler in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            decisionHandler(error != nil || statusCode < 200 || statusCode > 299)
        }
        
        let urlRequest = try RequestManager.shared.buildUrlRequest(request)
        request.config.requestPlugin.dataTask(for: request, urlRequest: urlRequest) { response, responseObject, error in
            if request.isCancelled { return }
            
            request.requestTotalCount = retryCount - remainCount + 1
            request.requestTotalTime = Date().timeIntervalSince1970 - startTime
            
            let canRetry = retryCount < 0 || remainCount > 0
            let waitTime: TimeInterval = canRetry ? max(0, request.requestRetryInterval()) : 0
            let timeoutInterval = request.requestRetryTimeout()
            if canRetry && (timeoutInterval <= 0 || (Date().timeIntervalSince1970 - startTime + waitTime) < timeoutInterval) {
                shouldRetry(response, responseObject, error, { retry in
                    if request.isCancelled { return }
                    
                    if retry {
                        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) { [weak self] in
                            if request.isCancelled { return }
                            
                            do {
                                try self?.retryDataTask(for: request, retryCount: retryCount, remainCount: remainCount - 1, startTime: startTime, shouldRetry: shouldRetry, completionHandler: completionHandler)
                                
                                request.config.requestPlugin.startRequest(for: request)
                            } catch let retryError {
                                completionHandler?(response, responseObject, error ?? retryError)
                            }
                        }
                    } else {
                        completionHandler?(response, responseObject, error)
                    }
                })
            } else {
                completionHandler?(response, responseObject, error)
            }
        }
    }
}

// MARK: - RequestValidator
/// 请求验证器协议
public protocol RequestValidatorProtocol: AnyObject {
    /// 验证响应结果，返回是否验证通过
    func validateResponse(for request: HTTPRequest) -> Bool
}

/// 默认请求验证器，调用jsonValidator验证responseJSONObject
open class RequestValidator: NSObject, RequestValidatorProtocol {
    public static let `default` = RequestValidator()
    
    open func validateResponse(for request: HTTPRequest) -> Bool {
        guard let json = request.responseJSONObject,
              let jsonValidator = request.jsonValidator() else {
            return true
        }
        
        return validateJSON(json, with: jsonValidator)
    }
    
    open func validateJSON(_ json: Any?, with jsonValidator: Any) -> Bool {
        if let dict = json as? [AnyHashable: Any],
           let validatorDict = jsonValidator as? [AnyHashable: Any] {
            var result = true
            for (key, validator) in validatorDict {
                let value = dict[key]
                result = validateJSON(value, with: validator)
                if !result {
                    break
                }
            }
            return result
        } else if let array = json as? [Any],
                  let validatorArray = jsonValidator as? [Any] {
            var result = true
            if validatorArray.count > 0 {
                let validator = validatorArray[0]
                for item in array {
                    result = validateJSON(item, with: validator)
                    if !result {
                        break
                    }
                }
            }
            return result
        } else if let anyValidator = jsonValidator as? AnyValidator {
            return anyValidator.validate(json)
        } else {
            return false
        }
    }
}

// MARK: - RequestCacheMetadata
/// 请求缓存Metadata
public class RequestCacheMetadata: NSObject, NSSecureCoding {
    public var version: Int?
    public var sensitiveDataString: String?
    public var stringEncoding: String.Encoding?
    public var creationDate: Date?
    public var appVersionString: String?
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    override init() { }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        self.version = aDecoder.decodeObject(forKey: "version") as? Int
        self.sensitiveDataString = aDecoder.decodeObject(forKey: "sensitiveDataString") as? String
        if let encode = aDecoder.decodeObject(forKey: "stringEncoding") as? UInt {
            self.stringEncoding = String.Encoding(rawValue: encode)
        }
        self.creationDate = aDecoder.decodeObject(forKey: "creationDate") as? Date
        self.appVersionString = aDecoder.decodeObject(forKey: "appVersionString") as? String
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.version, forKey: "version")
        aCoder.encode(self.sensitiveDataString, forKey: "sensitiveDataString")
        aCoder.encode(self.stringEncoding?.rawValue, forKey: "stringEncoding")
        aCoder.encode(self.creationDate, forKey: "creationDate")
        aCoder.encode(self.appVersionString, forKey: "appVersionString")
    }
}
