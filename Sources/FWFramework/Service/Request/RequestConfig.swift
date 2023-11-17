//
//  RequestConfig.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

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

// MARK: - RequestRetryer
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

// MARK: - RequestConfig
