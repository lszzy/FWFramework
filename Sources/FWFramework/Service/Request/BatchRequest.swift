//
//  BatchRequest.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

/// 批量请求代理
public protocol BatchRequestDelegate: AnyObject {
    /// 批量请求完成
    func batchRequestFinished(_ batchRequest: BatchRequest)
    /// 批量请求失败
    func batchRequestFailed(_ batchRequest: BatchRequest)
}

extension BatchRequestDelegate {
    /// 默认实现批量请求完成
    public func batchRequestFinished(_ batchRequest: BatchRequest) {}
    /// 默认实现批量请求失败
    public func batchRequestFailed(_ batchRequest: BatchRequest) {}
}

/// 批量请求类
open class BatchRequest: NSObject {
    
    /// 当前请求数组
    open private(set) var requestArray: [HTTPRequest] = []
    /// 事件代理
    open weak var delegate: BatchRequestDelegate?
    /// 成功完成回调
    open var successCompletionBlock: ((BatchRequest) -> Void)?
    /// 失败完成回调
    open var failureCompletionBlock: ((BatchRequest) -> Void)?
    /// 请求标签，默认0
    open var tag: Int = 0
    /// 自定义请求配件数组
    open var requestAccessories: [RequestAccessoryProtocol]?
    /// 第一个导致批量请求失败的请求
    open private(set) var failedRequest: HTTPRequest?
    /// 已失败请求数组
    open private(set) var failedRequestArray: [HTTPRequest] = []
    /// 某个请求失败时，是否立即停止批量请求，默认true
    open var stoppedOnFailure = true
    
    /// 是否所有响应数据都来自本地缓存
    open var isDataFromCache: Bool {
        return false
    }
    
    /// 指定请求数组初始化
    public init(requestArray: [HTTPRequest]) {
        
    }
    
    /// 开始请求
    open func start() {
        
    }
    
    /// 停止请求
    open func stop() {
        
    }
    
    /// 开始请求并指定成功、失败句柄
    open func start(success: ((BatchRequest) -> Void)?, failure: ((BatchRequest) -> Void)?) {
        successCompletionBlock = success
        failureCompletionBlock = failure
        start()
    }
    
    /// 开始请求并指定完成句柄
    open func start(completion: ((BatchRequest) -> Void)?) {
        start(success: completion, failure: completion)
    }
    
    /// 开始同步请求并指定成功、失败句柄
    open func startSynchronously(success: ((BatchRequest) -> Void)?, failure: ((BatchRequest) -> Void)?) {
        
    }
    
    /// 开始同步请求并指定过滤器和完成句柄
    open func startSynchronously(filter: (() -> Bool)? = nil, completion: ((BatchRequest) -> Void)?) {
        
    }
    
    /// 添加请求配件
    open func addAccessory(_ accessory: RequestAccessoryProtocol) {
        if requestAccessories == nil {
            requestAccessories = []
        }
        requestAccessories?.append(accessory)
    }
    
    /// 清理完成句柄
    open func clearCompletionBlock() {
        successCompletionBlock = nil
        failureCompletionBlock = nil
    }
    
    /// 切换配件将开始回调
    open func toggleAccessoriesWillStartCallBack() {
        guard let requestAccessories = requestAccessories else { return }
        for accessory in requestAccessories {
            accessory.requestWillStart(self)
        }
    }
    
    /// 切换配件将结束回调
    open func toggleAccessoriesWillStopCallBack() {
        guard let requestAccessories = requestAccessories else { return }
        for accessory in requestAccessories {
            accessory.requestWillStop(self)
        }
    }
    
    /// 切换配件已经结束回调
    open func toggleAccessoriesDidStopCallBack() {
        guard let requestAccessories = requestAccessories else { return }
        for accessory in requestAccessories {
            accessory.requestDidStop(self)
        }
    }
    
}
