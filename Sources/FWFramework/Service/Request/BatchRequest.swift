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
    @MainActor func batchRequestFinished(_ batchRequest: BatchRequest)
    /// 批量请求失败
    @MainActor func batchRequestFailed(_ batchRequest: BatchRequest)
}

extension BatchRequestDelegate {
    /// 默认实现批量请求完成
    public func batchRequestFinished(_ batchRequest: BatchRequest) {}
    /// 默认实现批量请求失败
    public func batchRequestFailed(_ batchRequest: BatchRequest) {}
}

/// 批量请求类
open class BatchRequest: HTTPRequestProtocol, RequestDelegate, @unchecked Sendable {
    /// 批量请求完成句柄
    public typealias Completion = @MainActor @Sendable (BatchRequest) -> Void

    // MARK: - Accessor
    /// 当前请求数组
    open private(set) var requestArray: [HTTPRequest] = []
    /// 事件代理
    open weak var delegate: BatchRequestDelegate?
    /// 成功完成回调
    open var successCompletionBlock: Completion?
    /// 失败完成回调
    open var failureCompletionBlock: Completion?
    /// 请求结束回调，成功失败都会触发
    open var requestCompletedBlock: Completion?
    /// 请求取消回调，不一定主线程调用
    open var requestCancelledBlock: (@Sendable (BatchRequest) -> Void)?
    /// 请求标签，默认0
    open var tag: Int = 0
    /// 自定义请求配件数组
    open var requestAccessories: [RequestAccessoryProtocol]?
    /// 第一个导致批量请求失败的请求
    open var failedRequest: HTTPRequest? {
        failedRequestArray.first
    }

    /// 是否自动显示错误信息
    open var autoShowError: Bool {
        get { failedRequest?.autoShowError ?? false }
        set { failedRequest?.autoShowError = newValue }
    }

    /// 当前网络错误
    open var error: Error? {
        failedRequest?.error
    }

    /// 已失败请求数组
    open private(set) var failedRequestArray: [HTTPRequest] = []
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
    /// 添加单个请求，start之前调用
    @discardableResult
    open func addRequest(_ request: HTTPRequest) -> Self {
        requestArray.append(request)
        return self
    }

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
            req.preloadCacheModel = false
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
        requestCancelledBlock?(self)
        requestCancelledBlock = nil
        toggleAccessoriesDidStopCallBack()
        BatchRequestManager.shared.removeBatchRequest(self)
    }

    /// 开始请求并指定成功、失败、结束句柄
    @discardableResult
    open func start(
        success: Completion?,
        failure: Completion?,
        complete: Completion? = nil
    ) -> Self {
        successCompletionBlock = success
        failureCompletionBlock = failure
        if (complete != nil) { requestCompletedBlock = complete }
        return start()
    }

    /// 开始请求并指定完成句柄
    @discardableResult
    open func start(completion: Completion?) -> Self {
        start(success: completion, failure: completion)
    }
    
    /// 自定义请求结束句柄，成功失败都会触发
    @discardableResult
    open func requestCompleted(_ block: Completion?) -> Self {
        requestCompletedBlock = block
        return self
    }

    /// 请求取消句柄，不一定主线程调用
    @discardableResult
    open func requestCancelled(_ block: (@Sendable (BatchRequest) -> Void)?) -> Self {
        requestCancelledBlock = block
        return self
    }

    /// 自定义响应完成句柄
    @discardableResult
    open func response(_ completion: Completion?) -> Self {
        responseSuccess(completion).responseFailure(completion)
    }

    /// 自定义响应成功句柄
    @discardableResult
    open func responseSuccess(_ block: Completion?) -> Self {
        successCompletionBlock = block
        return self
    }

    /// 自定义响应失败句柄
    @discardableResult
    open func responseFailure(_ block: Completion?) -> Self {
        failureCompletionBlock = block
        return self
    }

    /// 快捷设置响应失败句柄
    @discardableResult
    open func responseError(_ block: (@MainActor @Sendable (Error) -> Void)?) -> Self {
        failureCompletionBlock = { request in
            block?(request.error ?? RequestError.unknown)
        }
        return self
    }

    /// 清理完成句柄
    open func clearCompletionBlock() {
        successCompletionBlock = nil
        failureCompletionBlock = nil
        requestCompletedBlock = nil
    }

    /// 显示网络错误，默认显示Toast提示
    open func showError() {
        failedRequest?.showError()
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

    /// 请求完成回调
    open func requestFinished(_ request: HTTPRequest) {
        finishedCount += 1
        if finishedCount == requestArray.count {
            requestCompleted()
        }
    }

    /// 请求失败回调
    open func requestFailed(_ request: HTTPRequest) {
        failedRequestArray.append(request)
        if stoppedOnFailure {
            for req in requestArray {
                if req != request { req.cancel() }
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
        requestAccessories?.forEach { accessory in
            accessory.requestWillStart(self)
        }
    }

    private func toggleAccessoriesWillStopCallBack() {
        requestAccessories?.forEach { accessory in
            accessory.requestWillStop(self)
        }
    }

    private func toggleAccessoriesDidStopCallBack() {
        requestAccessories?.forEach { accessory in
            accessory.requestDidStop(self)
        }
    }

    @MainActor private func requestCompleted() {
        toggleAccessoriesWillStopCallBack()

        if failedRequestArray.count < 1 {
            delegate?.batchRequestFinished(self)
            successCompletionBlock?(self)
            requestCompletedBlock?(self)
        } else {
            delegate?.batchRequestFailed(self)
            failureCompletionBlock?(self)
            requestCompletedBlock?(self)
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
open class BatchRequestManager: @unchecked Sendable {
    public static let shared = BatchRequestManager()

    private var batchRequestArray: [BatchRequest] = []
    private var lock = NSLock()

    public init() {}

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

// MARK: - Concurrency+BatchRequest
extension BatchRequest {
    /// 异步获取完成响应，注意非Task取消也会触发(Continuation流程)
    public func response() async -> BatchRequest {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                requestCancelled { request in
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
    public func responseSuccess() async throws -> BatchRequest {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelled { _ in
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
}
