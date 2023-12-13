//
//  RequestConfig.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation
import UIKit

// MARK: - RequestFilter
/// 请求过滤器协议
public protocol RequestFilterProtocol: AnyObject {
    
    /// 请求URL过滤器，返回处理后的URL
    func filterUrl(_ originUrl: String, for request: HTTPRequest) -> String
    
    /// 请求URLRequest过滤器，处理后才发送请求
    func filterUrlRequest(_ urlRequest: inout URLRequest, for request: HTTPRequest)
    
    /// 请求Response过滤器，处理后才调用回调
    func filterResponse(for request: HTTPRequest) throws
    
}

extension RequestFilterProtocol {
    
    /// 默认实现请求URL过滤器，返回处理后的URL
    public func filterUrl(_ originUrl: String, for request: HTTPRequest) -> String {
        return originUrl
    }
    
    /// 默认实现请求URLRequest过滤器，处理后才发送请求
    public func filterUrlRequest(_ urlRequest: inout URLRequest, for request: HTTPRequest) {
    }
    
    /// 默认实现请求Response过滤器，处理后才调用回调
    public func filterResponse(for request: HTTPRequest) throws {
    }
    
}

// MARK: - RequestConfig
/// 请求配置类
open class RequestConfig {
    
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
    
    /// 当前请求缓存，默认文件缓存，可清空
    open var requestCache: RequestCacheProtocol? = RequestCache.default
    
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
    
    /// 是否后台预加载数据模型过滤句柄，默认nil
    open var preloadModelFilter: ((HTTPRequest) -> Bool)?
    /// 自定义请求上下文配件句柄，默认nil
    open var contextAccessoryBlock: ((HTTPRequest) -> RequestContextAccessory)?
    /// 自定义显示错误方法，主线程优先调用，默认nil
    open var showErrorBlock: HTTPRequest.Completion?
    /// 自定义显示加载方法，主线程优先调用，默认nil
    open var showLoadingBlock: HTTPRequest.Completion?
    /// 自定义隐藏加载方法，主线程优先调用，默认nil
    open var hideLoadingBlock: HTTPRequest.Completion?
    
    /// 初始化方法
    public init() {}
    
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
open class RequestAccessory: RequestAccessoryProtocol {
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
            
            DispatchQueue.fw_mainAsync {
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
        }
        self.willStopBlock = nil
        self.didStopBlock = { request in
            guard let request = request as? HTTPRequest else { return }
            
            DispatchQueue.fw_mainAsync {
                if request.autoShowLoading {
                    request.hideLoading()
                }
                if request.autoShowError, request.error != nil {
                    request.showError()
                }
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
            
            request.cancel()
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
        guard request.context != nil, !request.isCancelled else { return }
        
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
    /// 处理重试请求，处理完成回调是否需要重试
    func retryRequest(_ request: HTTPRequest, response: URLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping (Bool) -> Void)
}

/// 默认请求重试器，直接调用request的钩子方法
open class RequestRetrier: RequestRetrierProtocol {
    public static let `default` = RequestRetrier()
    
    /// 自定义重试过滤器，优先级最高且线程安全，必须回调completionHandler，可用于刷新授权等
    open var requestRetryFilter: ((_ request: HTTPRequest, _ response: URLResponse, _ responseObject: Any?, _ error: Error?, _ completionHandler: @escaping (Bool) -> Void) -> Void)?
    
    private lazy var filterQueue = DispatchQueue(label: "site.wuyong.queue.request.retrier.filter")
    private lazy var filterSemaphore = DispatchSemaphore(value: 1)
    
    open func retryRequest(_ request: HTTPRequest, response: URLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping (Bool) -> Void) {
        if request.isCancelled { return }
        
        guard let filter = requestRetryFilter else {
            retryProcess(request, response: response, responseObject: responseObject, error: error, completionHandler: completionHandler)
            return
        }
        
        filterQueue.async { [weak self] in
            self?.filterSemaphore.wait()
            filter(request, response, responseObject, error, { shouldRetry in
                self?.filterSemaphore.signal()
                
                if request.isCancelled { return }
                guard shouldRetry else {
                    completionHandler(false)
                    return
                }
                
                self?.retryProcess(request, response: response, responseObject: responseObject, error: error, completionHandler: completionHandler)
            })
        }
    }
    
    private func retryProcess(_ request: HTTPRequest, response: URLResponse, responseObject: Any?, error: Error?, completionHandler: @escaping (Bool) -> Void) {
        let retryCount = request.requestRetryCount()
        let remainCount = retryCount - (request.requestTotalCount - 1)
        var canRetry = retryCount < 0 || remainCount > 0
        var waitTime: TimeInterval = 0
        if canRetry {
            let timeoutInterval = request.requestRetryTimeout()
            waitTime = max(0, request.requestRetryInterval())
            canRetry = (timeoutInterval <= 0 || (Date().timeIntervalSince1970 - request.requestStartTime + waitTime) < timeoutInterval)
        }
        
        guard canRetry, let response = response as? HTTPURLResponse,
              request.requestRetryValidator(response, responseObject: responseObject, error: error) else {
            completionHandler(false)
            return
        }
        
        request.requestRetryProcessor(response, responseObject: responseObject, error: error) { shouldRetry in
            if request.isCancelled { return }
            
            if shouldRetry {
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    if request.isCancelled { return }
                    
                    completionHandler(true)
                }
            } else {
                completionHandler(false)
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
open class RequestValidator: RequestValidatorProtocol {
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

// MARK: - RequestCache
/// 请求缓存协议
public protocol RequestCacheProtocol: AnyObject {
    func loadCache(for request: HTTPRequest) throws -> (data: Data, metadata: Data)
    func saveCache(_ cache: (data: Data, metadata: Data), for request: HTTPRequest) throws
    func clearCache(for request: HTTPRequest) throws
}

/// 默认请求文件缓存
open class RequestCache: RequestCacheProtocol {
    public static let `default` = RequestCache()
    
    static let cacheQueue = DispatchQueue(label: "site.wuyong.queue.request.cache", qos: .background)
    
    /// 请求缓存路径过滤句柄，返回处理后的路径
    open var cacheFilePathFilter: ((_ request: HTTPRequest, _ filePath: String) -> String)?
    
    /// 请求缓存文件名过滤器，返回处理后的文件名
    open var cacheFileNameFilter: ((_ request: HTTPRequest, _ fileName: String) -> String)?
    
    /// 获取请求缓存基础路径
    open func cacheFilePath(for request: HTTPRequest) -> String {
        var filePath = FileManager.fw_pathCaches.fw_appendingPath(["FWFramework", "RequestCache"])
        if let filterPath = cacheFilePathFilter?(request, filePath) {
            filePath = filterPath
        }
        
        FileManager.fw_createDirectory(atPath: filePath)
        FileManager.fw_skipBackup(filePath)
        return filePath
    }
    
    /// 获取请求缓存文件名
    open func cacheFileName(for request: HTTPRequest) -> String {
        var fileName = request.cacheIdentifier()
        if let filterName = cacheFileNameFilter?(request, fileName) {
            fileName = filterName
        }
        return fileName
    }
    
    open func loadCache(for request: HTTPRequest) throws -> (data: Data, metadata: Data) {
        let filePath = cacheFilePath(for: request)
        let fileName = cacheFileName(for: request)
        let cacheFile = (filePath as NSString).appendingPathComponent(fileName)
        let metadataFile = cacheFile + ".metadata"
        
        let data = try Data(contentsOf: URL(fileURLWithPath: cacheFile))
        let metadata = try Data(Data(contentsOf: URL(fileURLWithPath: metadataFile)))
        return (data: data, metadata: metadata)
    }
    
    open func saveCache(_ cache: (data: Data, metadata: Data), for request: HTTPRequest) throws {
        let filePath = cacheFilePath(for: request)
        let fileName = cacheFileName(for: request)
        let cacheFile = (filePath as NSString).appendingPathComponent(fileName)
        let metadataFile = cacheFile + ".metadata"
        
        try cache.data.write(to: URL(fileURLWithPath: cacheFile), options: .atomic)
        try cache.metadata.write(to: URL(fileURLWithPath: metadataFile), options: .atomic)
    }
    
    open func clearCache(for request: HTTPRequest) throws {
        let filePath = cacheFilePath(for: request)
        let fileName = cacheFileName(for: request)
        let cacheFile = (filePath as NSString).appendingPathComponent(fileName)
        let metadataFile = cacheFile + ".metadata"
        
        try FileManager.default.removeItem(atPath: cacheFile)
        try FileManager.default.removeItem(atPath: metadataFile)
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
