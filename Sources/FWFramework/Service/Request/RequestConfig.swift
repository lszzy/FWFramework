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
    
    /// 当前请求重试器，默认全局重试器
    open var requestRetrier: RequestRetrierProtocol = RequestRetrier.default
    
    /// 当前请求验证器，默认全局验证器
    open var requestValidator: RequestValidatorProtocol = RequestValidator.default
    
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
    /// 自定义显示网络错误方法，主线程优先调用，默认nil
    open var showRequestErrorBlock: ((HTTPRequest) -> Void)?
    
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

// MARK: - RequestRetrier
/// 请求重试器协议
public protocol RequestRetrierProtocol: AnyObject {
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
open class RequestRetrier: NSObject, RequestRetrierProtocol {
    public static let `default` = RequestRetrier()
    
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
    
    open func validateJSON(_ json: Any, with jsonValidator: Any) -> Bool {
        if let dict = json as? NSDictionary,
           let validator = jsonValidator as? NSDictionary {
            var result = true
            let enumerator = validator.keyEnumerator()
            while let key = enumerator.nextObject() as? String {
                let value = dict[key]
                let format = validator[key]
                if let value = value, let format = format,
                   (value is NSDictionary || value is NSArray) {
                    result = validateJSON(value, with: format)
                    if !result {
                        break
                    }
                } else if let object = value as? NSObject,
                          let validatorClass = format as? AnyClass {
                    if !object.isKind(of: validatorClass) && !(object is NSNull) {
                        result = false
                        break
                    }
                }
            }
            return result
        } else if let array = json as? NSArray,
                  let validatorArray = jsonValidator as? NSArray {
            if validatorArray.count > 0 {
                let validator = validatorArray[0]
                for item in array {
                    let result = validateJSON(item, with: validator)
                    if !result {
                        return false
                    }
                }
            }
            return true
        } else if let object = json as? NSObject,
                  let validatorClass = jsonValidator as? AnyClass {
            return object.isKind(of: validatorClass)
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
