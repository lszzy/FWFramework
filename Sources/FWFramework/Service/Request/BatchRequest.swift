//
//  BatchRequest.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

// MARK: - BatchRequest
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
open class BatchRequest: RequestDelegate {
    
    /// 批量请求完成句柄
    public typealias Completion = (BatchRequest) -> Void
    
    // MARK: - Accessor
    /// 当前请求数组
    open private(set) var requestArray: [HTTPRequest] = []
    /// 事件代理
    open weak var delegate: BatchRequestDelegate?
    /// 成功完成回调
    open var successCompletionBlock: Completion?
    /// 失败完成回调
    open var failureCompletionBlock: Completion?
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
    public init() {}
    
    public init(requestArray: [HTTPRequest]) {
        self.requestArray = requestArray
    }
    
    deinit {
        clearRequest()
    }
    
    // MARK: - Public
    /// 开始请求，仅能调用一次
    @discardableResult
    open func start() -> Self {
        guard finishedCount <= 0 else { return self }
        
        failedRequestArray.removeAll()
        BatchRequestManager.shared.addBatchRequest(self)
        toggleAccessoriesWillStartCallBack()
        for req in requestArray {
            req.autoShowLoading = false
            req.autoShowError = false
            req.delegate = self
            req.clearCompletionBlock()
            req.start()
        }
        return self
    }
    
    /// 取消请求
    open func cancel() {
        toggleAccessoriesWillStopCallBack()
        delegate = nil
        clearRequest()
        isCancelled = true
        toggleAccessoriesDidStopCallBack()
        BatchRequestManager.shared.removeBatchRequest(self)
    }
    
    /// 开始请求并指定成功、失败句柄
    @discardableResult
    open func start(success: Completion?, failure: Completion?) -> Self {
        successCompletionBlock = success
        failureCompletionBlock = failure
        return start()
    }
    
    /// 开始请求并指定完成句柄
    @discardableResult
    open func start(completion: Completion?) -> Self {
        return start(success: completion, failure: completion)
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
                req.cancel()
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
    private func toggleAccessoriesWillStartCallBack() {
        requestAccessories?.forEach({ accessory in
            accessory.requestWillStart(self)
        })
    }
    
    private func toggleAccessoriesWillStopCallBack() {
        requestAccessories?.forEach({ accessory in
            accessory.requestWillStop(self)
        })
    }
    
    private func toggleAccessoriesDidStopCallBack() {
        requestAccessories?.forEach({ accessory in
            accessory.requestDidStop(self)
        })
    }
    
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
        BatchRequestManager.shared.removeBatchRequest(self)
    }
    
    private func clearRequest() {
        for req in requestArray {
            req.cancel()
        }
        clearCompletionBlock()
    }
    
}

// MARK: - BatchRequestManager
/// 批量请求管理器
open class BatchRequestManager {
    
    public static let shared = BatchRequestManager()
    
    private var batchRequestArray: [BatchRequest] = []
    private var lock = NSLock()
    
    /// 添加批量请求
    open func addBatchRequest(_ batchRequest: BatchRequest) {
        lock.lock()
        defer { lock.unlock() }
        batchRequestArray.append(batchRequest)
    }
    
    /// 移除批量请求
    open func removeBatchRequest(_ batchRequest: BatchRequest) {
        lock.lock()
        defer { lock.unlock() }
        batchRequestArray.removeAll(where: { $0 === batchRequest })
    }
    
}
