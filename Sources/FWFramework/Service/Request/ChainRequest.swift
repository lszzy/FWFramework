//
//  ChainRequest.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

/// 队列请求代理
public protocol ChainRequestDelegate: AnyObject {
    /// 队列请求完成
    func chainRequestFinished(_ chainRequest: ChainRequest)
    /// 队列请求失败
    func chainRequestFailed(_ chainRequest: ChainRequest)
}

extension ChainRequestDelegate {
    /// 默认实现队列请求完成
    public func chainRequestFinished(_ chainRequest: ChainRequest) {}
    /// 默认实现队列请求失败
    public func chainRequestFailed(_ chainRequest: ChainRequest) {}
}

/// 队列请求类
open class ChainRequest: NSObject, RequestDelegate {
    
    /// 回调句柄声明
    public typealias Callback = (ChainRequest, HTTPRequest) -> Void
    
    /// 当前请求数组
    open private(set) var requestArray: [HTTPRequest] = []
    /// 事件代理
    open weak var delegate: ChainRequestDelegate?
    /// 成功完成回调
    open var successCompletionBlock: ((ChainRequest) -> Void)?
    /// 失败完成回调
    open var failureCompletionBlock: ((ChainRequest) -> Void)?
    /// 请求标签，默认0
    open var tag: Int = 0
    /// 自定义请求配件数组
    open var requestAccessories: [RequestAccessoryProtocol]?
    /// 最后一个导致队列请求成功的请求
    open private(set) var succeedRequest: HTTPRequest?
    /// 最后一个导致队列请求失败的请求
    open private(set) var failedRequest: HTTPRequest?
    /// 请求间的时间间隔
    open var requestInterval: TimeInterval = 0
    /// 某个请求失败时，是否立即停止队列请求，默认true
    open var stoppedOnFailure = true
    /// 某个请求成功时，是否立即停止队列请求，默认false
    open var stoppedOnSuccess = false
    /// 请求构建句柄，所有请求完成后才会主线程调用
    open var requestBuilder: ((_ chainRequest: ChainRequest, _ previousRequest: HTTPRequest?) -> HTTPRequest?)?
    
    private var requestCallbackArray: [Callback] = []
    private var nextRequestIndex: Int = 0
    private weak var nextRequest: HTTPRequest?
    private let emptyCallback: Callback = { _, _ in }
    
    public override init() {
        super.init()
    }
    
    deinit {
        clearRequest()
    }
    
    /// 添加请求，可设置请求完成回调
    open func addRequest(_ request: HTTPRequest, callback: Callback? = nil) {
        requestArray.append(request)
        requestCallbackArray.append(callback ?? emptyCallback)
    }
    
    /// 开始请求，仅能调用一次
    open func start() {
        guard nextRequestIndex <= 0 else { return }
        
        succeedRequest = nil
        failedRequest = nil
        RequestManager.shared.addChainRequest(self)
        toggleAccessoriesWillStartCallBack()
        startNextRequest(nil)
    }
    
    /// 停止请求
    open func stop() {
        toggleAccessoriesWillStopCallBack()
        delegate = nil
        clearRequest()
        toggleAccessoriesDidStopCallBack()
        RequestManager.shared.removeChainRequest(self)
    }
    
    /// 开始请求并指定成功、失败句柄
    open func start(success: ((ChainRequest) -> Void)?, failure: ((ChainRequest) -> Void)?) {
        successCompletionBlock = success
        failureCompletionBlock = failure
        start()
    }
    
    /// 开始请求并指定完成句柄
    open func start(completion: ((ChainRequest) -> Void)?) {
        start(success: completion, failure: completion)
    }
    
    /// 开始同步请求并指定成功、失败句柄
    open func startSynchronously(success: ((ChainRequest) -> Void)?, failure: ((ChainRequest) -> Void)?) {
        startSynchronously(filter: nil) { chainRequest in
            if chainRequest.failedRequest == nil {
                success?(chainRequest)
            } else {
                failure?(chainRequest)
            }
        }
    }
    
    /// 开始同步请求并指定过滤器和完成句柄
    open func startSynchronously(filter: (() -> Bool)? = nil, completion: ((ChainRequest) -> Void)?) {
        RequestManager.shared.synchronousChainRequest(self, filter: filter, completion: completion)
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
    
    open func requestFailed(_ request: HTTPRequest) {
        succeedRequest = nil
        failedRequest = request
        
        if stoppedOnFailure || !startNextRequest(request) {
            requestCompleted()
        }
    }
    
    @discardableResult
    private func startNextRequest(_ previousRequest: HTTPRequest?) -> Bool {
        if nextRequestIndex >= requestArray.count, requestBuilder != nil {
            if let request = requestBuilder?(self, previousRequest) {
                addRequest(request, callback: nil)
            }
        }
        
        if nextRequestIndex < requestArray.count {
            let request = requestArray[nextRequestIndex]
            nextRequestIndex += 1
            request.delegate = self
            request.clearCompletionBlock()
            if nextRequestIndex > 1 && requestInterval > 0 {
                nextRequest = request
                DispatchQueue.main.asyncAfter(deadline: .now() + requestInterval) { [weak self] in
                    self?.nextRequest?.start()
                }
            } else {
                nextRequest = nil
                request.start()
            }
            return true
        }
        return false
    }
    
    private func requestCompleted() {
        toggleAccessoriesWillStopCallBack()
        
        if failedRequest == nil {
            delegate?.chainRequestFinished(self)
            successCompletionBlock?(self)
        } else {
            delegate?.chainRequestFailed(self)
            failureCompletionBlock?(self)
        }
        
        clearCompletionBlock()
        toggleAccessoriesDidStopCallBack()
        RequestManager.shared.removeChainRequest(self)
    }
    
    private func clearRequest() {
        if nextRequestIndex > 0 {
            let currentRequestIndex = nextRequestIndex - 1
            if currentRequestIndex < requestArray.count {
                let request = requestArray[currentRequestIndex]
                request.stop()
            }
        }
        
        nextRequest = nil
        requestArray.removeAll()
        requestCallbackArray.removeAll()
        requestBuilder = nil
        clearCompletionBlock()
    }
    
}
