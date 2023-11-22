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
open class BatchRequest: NSObject, RequestDelegate {
    
    // MARK: - Accessor
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
    open var failedRequest: HTTPRequest? {
        return failedRequestArray.first
    }
    /// 已失败请求数组
    open private(set) var failedRequestArray: [HTTPRequest] = []
    /// 当前网络错误
    open var error: Error? {
        return failedRequest?.error
    }
    /// 请求是否已取消
    open private(set) var isCancelled = false
    /// 某个请求失败时，是否立即停止批量请求，默认true
    open var stoppedOnFailure = true
    
    /// 是否所有响应数据都来自本地缓存
    open var isDataFromCache: Bool {
        var result = true
        for req in requestArray {
            if !req.isDataFromCache {
                result = false
                break
            }
        }
        return result
    }
    
    private var finishedCount: Int = 0
    
    // MARK: - Lifecycle
    /// 指定请求数组初始化
    public init(requestArray: [HTTPRequest]) {
        super.init()
        self.requestArray = requestArray
    }
    
    deinit {
        clearRequest()
    }
    
    // MARK: - Public
    /// 开始请求，仅能调用一次
    open func start() {
        guard finishedCount <= 0 else { return }
        
        failedRequestArray.removeAll()
        RequestManager.shared.addBatchRequest(self)
        toggleAccessoriesWillStartCallBack()
        for req in requestArray {
            req.autoShowLoading = false
            req.autoShowError = false
            req.delegate = self
            req.clearCompletionBlock()
            req.start()
        }
    }
    
    /// 停止请求
    open func stop() {
        toggleAccessoriesWillStopCallBack()
        delegate = nil
        clearRequest()
        isCancelled = true
        toggleAccessoriesDidStopCallBack()
        RequestManager.shared.removeBatchRequest(self)
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
        startSynchronously(filter: nil) { batchRequest in
            if batchRequest.failedRequest == nil {
                success?(batchRequest)
            } else {
                failure?(batchRequest)
            }
        }
    }
    
    /// 开始同步请求并指定过滤器和完成句柄
    open func startSynchronously(filter: (() -> Bool)? = nil, completion: ((BatchRequest) -> Void)?) {
        RequestManager.shared.synchronousBatchRequest(self, filter: filter, completion: completion)
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
        requestAccessories?.forEach({ accessory in
            accessory.requestWillStart(self)
        })
    }
    
    /// 切换配件将结束回调
    open func toggleAccessoriesWillStopCallBack() {
        requestAccessories?.forEach({ accessory in
            accessory.requestWillStop(self)
        })
    }
    
    /// 切换配件已经结束回调
    open func toggleAccessoriesDidStopCallBack() {
        requestAccessories?.forEach({ accessory in
            accessory.requestDidStop(self)
        })
    }
    
    open func requestFinished(_ request: HTTPRequest) {
        finishedCount += 1
        if finishedCount == requestArray.count {
            requestCompleted()
        }
    }
    
    open func requestFailed(_ request: HTTPRequest) {
        failedRequestArray.append(request)
        if stoppedOnFailure {
            for req in requestArray {
                req.stop()
            }
            requestCompleted()
            return
        }
        
        finishedCount += 1
        if finishedCount == requestArray.count {
            requestCompleted()
        }
    }
    
    // MARK: - Private
    private func requestCompleted() {
        toggleAccessoriesWillStopCallBack()
        
        if failedRequestArray.count < 1 {
            delegate?.batchRequestFinished(self)
            successCompletionBlock?(self)
        } else {
            delegate?.batchRequestFailed(self)
            failureCompletionBlock?(self)
        }
        
        clearCompletionBlock()
        toggleAccessoriesDidStopCallBack()
        RequestManager.shared.removeBatchRequest(self)
    }
    
    private func clearRequest() {
        for req in requestArray {
            req.stop()
        }
        clearCompletionBlock()
    }
    
}
