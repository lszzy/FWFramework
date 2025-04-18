//
//  ChainRequest.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

// MARK: - ChainRequest
/// 队列请求代理
public protocol ChainRequestDelegate: AnyObject {
    /// 队列请求完成
    @MainActor func chainRequestFinished(_ chainRequest: ChainRequest)
    /// 队列请求失败
    @MainActor func chainRequestFailed(_ chainRequest: ChainRequest)
}

extension ChainRequestDelegate {
    /// 默认实现队列请求完成
    public func chainRequestFinished(_ chainRequest: ChainRequest) {}
    /// 默认实现队列请求失败
    public func chainRequestFailed(_ chainRequest: ChainRequest) {}
}

/// 队列请求类
open class ChainRequest: HTTPRequestProtocol, RequestDelegate, @unchecked Sendable {
    /// 队列请求完成句柄
    public typealias Completion = @MainActor @Sendable (ChainRequest) -> Void
    /// 回调处理句柄声明
    public typealias CallbackHandler = @Sendable (ChainRequest, HTTPRequest) -> Void

    // MARK: - Accessor
    /// 当前请求数组
    open private(set) var requestArray: [HTTPRequest] = []
    /// 事件代理
    open weak var delegate: ChainRequestDelegate?
    /// 成功完成回调
    open var successCompletionBlock: Completion?
    /// 失败完成回调
    open var failureCompletionBlock: Completion?
    /// 请求结束回调，成功失败都会触发
    open var requestCompletedBlock: Completion?
    /// 请求取消回调，不一定主线程调用
    open var requestCancelledBlock: (@Sendable (ChainRequest) -> Void)?
    /// 请求标签，默认0
    open var tag: Int = 0
    /// 自定义请求配件数组
    open var requestAccessories: [RequestAccessoryProtocol]?
    /// 最后一个导致队列请求成功的请求
    open private(set) var succeedRequest: HTTPRequest?
    /// 最后一个导致队列请求失败的请求
    open private(set) var failedRequest: HTTPRequest?
    /// 是否自动显示错误信息
    open var autoShowError: Bool {
        get { failedRequest?.autoShowError ?? false }
        set { failedRequest?.autoShowError = newValue }
    }

    /// 当前网络错误
    open var error: Error? {
        failedRequest?.error
    }

    /// 请求是否已取消
    open private(set) var isCancelled = false
    /// 请求间的时间间隔
    open var requestInterval: TimeInterval = 0
    /// 某个请求失败时，是否立即停止队列请求，默认true
    open var stoppedOnFailure = true
    /// 某个请求成功时，是否立即停止队列请求，默认false
    open var stoppedOnSuccess = false
    /// 请求构建句柄，所有请求完成后才会主线程调用
    open var requestBuilder: (@Sendable (_ chainRequest: ChainRequest, _ previousRequest: HTTPRequest?) -> HTTPRequest?)?

    private var requestCallbackArray: [CallbackHandler] = []
    private var nextRequestIndex: Int = 0
    private weak var nextRequest: HTTPRequest?
    private let emptyCallback: CallbackHandler = { _, _ in }

    // MARK: - Lifecycle
    public init() {}

    deinit {
        clearRequest()
    }

    // MARK: - Public
    /// 添加请求，可设置请求完成回调
    @discardableResult
    open func addRequest(_ request: HTTPRequest, callback: CallbackHandler? = nil) -> Self {
        requestArray.append(request)
        requestCallbackArray.append(callback ?? emptyCallback)
        return self
    }

    /// 开始请求，仅能调用一次
    @discardableResult
    open func start() -> Self {
        guard nextRequestIndex <= 0 else { return self }

        succeedRequest = nil
        failedRequest = nil
        ChainRequestManager.shared.addChainRequest(self)
        startNextRequest(nil)
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
        ChainRequestManager.shared.removeChainRequest(self)
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
        if complete != nil { requestCompletedBlock = complete }
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
    open func requestCancelled(_ block: (@Sendable (ChainRequest) -> Void)?) -> Self {
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
        succeedRequest = request
        failedRequest = nil

        let currentRequestIndex = nextRequestIndex - 1
        let chainCallback = requestCallbackArray[currentRequestIndex]
        chainCallback(self, request)

        if stoppedOnSuccess || !startNextRequest(request) {
            requestCompleted()
        }
    }

    /// 请求失败回调
    open func requestFailed(_ request: HTTPRequest) {
        succeedRequest = nil
        failedRequest = request

        if stoppedOnFailure || !startNextRequest(request) {
            requestCompleted()
        }
    }

    // MARK: - Private
    @discardableResult
    private func startNextRequest(_ previousRequest: HTTPRequest?) -> Bool {
        if nextRequestIndex >= requestArray.count, requestBuilder != nil {
            if let request = requestBuilder?(self, previousRequest) {
                addRequest(request, callback: nil)
            }
        }

        if previousRequest == nil {
            toggleAccessoriesWillStartCallBack()
        }

        if nextRequestIndex < requestArray.count {
            let request = requestArray[nextRequestIndex]
            nextRequestIndex += 1
            request.autoShowLoading = false
            request.autoShowError = false
            request.preloadCacheModel = false
            request.delegate = self
            request.clearCompletionBlock()
            if nextRequestIndex > 1 && requestInterval > 0 {
                nextRequest = request
                DispatchQueue.main.asyncAfter(deadline: .now() + requestInterval) {
                    self.nextRequest?.start()
                }
            } else {
                nextRequest = nil
                request.start()
            }
            return true
        }
        return false
    }

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

        if failedRequest == nil {
            delegate?.chainRequestFinished(self)
            successCompletionBlock?(self)
            requestCompletedBlock?(self)
        } else {
            delegate?.chainRequestFailed(self)
            failureCompletionBlock?(self)
            requestCompletedBlock?(self)
        }

        clearCompletionBlock()
        toggleAccessoriesDidStopCallBack()
        ChainRequestManager.shared.removeChainRequest(self)
    }

    private func clearRequest() {
        if nextRequestIndex > 0 {
            let currentRequestIndex = nextRequestIndex - 1
            if currentRequestIndex < requestArray.count {
                let request = requestArray[currentRequestIndex]
                request.cancel()
            }
        }

        nextRequest = nil
        requestArray.removeAll()
        requestCallbackArray.removeAll()
        requestBuilder = nil
        clearCompletionBlock()
    }
}

// MARK: - ChainRequestManager
/// 队列请求管理器
open class ChainRequestManager: @unchecked Sendable {
    public static let shared = ChainRequestManager()

    private var chainRequestArray: [ChainRequest] = []
    private var lock = NSLock()

    public init() {}

    /// 添加队列请求
    open func addChainRequest(_ chainRequest: ChainRequest) {
        lock.lock()
        defer { lock.unlock() }
        chainRequestArray.append(chainRequest)
    }

    /// 移除队列请求
    open func removeChainRequest(_ chainRequest: ChainRequest) {
        lock.lock()
        defer { lock.unlock() }
        chainRequestArray.removeAll(where: { $0 === chainRequest })
    }
}

// MARK: - Concurrency+ChainRequest
extension ChainRequest {
    /// 异步获取完成响应，注意非Task取消也会触发(Continuation流程)
    public func response() async -> ChainRequest {
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
    public func responseSuccess() async throws -> ChainRequest {
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
