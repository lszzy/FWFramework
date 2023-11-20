//
//  RequestManager.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

/// 请求管理器
open class RequestManager: NSObject {
    
    public static let shared = RequestManager()
    
    private var batchRequestArray: [BatchRequest] = []
    private var chainRequestArray: [ChainRequest] = []
    private var requestsRecord: [Int: HTTPRequest] = [:]
    private var lock = NSLock()
    private var synchronousQueue = DispatchQueue(label: "site.wuyong.queue.request.synchronous")
    private var synchronousSemaphore = DispatchSemaphore(value: 1)
    
    /// 添加请求并开始
    open func addRequest(_ request: HTTPRequest) {
        do {
            request.requestTask = try sessionTask(for: request)
            
            switch request.requestPriority {
            case .high:
                request.requestTask?.priority = URLSessionTask.highPriority
            case .low:
                request.requestTask?.priority = URLSessionTask.lowPriority
            default:
                request.requestTask?.priority = URLSessionTask.defaultPriority
            }
            
            addRequestToRecord(request)
            request.requestConfig.requestPlugin.resumeRequest(for: request)
            #if DEBUG
            if request.requestConfig.debugLogEnabled {
                Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST STARTED===========\n%@%@ %@:\n%@", "▶️ ", request.requestMethod().rawValue, request.requestUrl(), String.fw_safeString(request.requestArgument()))
            }
            #endif
        } catch {
            requestDidFail(request, error: error)
        }
    }
    
    /// 取消已经添加的请求
    open func cancelRequest(_ request: HTTPRequest) {
        if let downloadPath = request.resumableDownloadPath,
           let localUrl = incompleteDownloadTempPath(for: request, downloadPath: downloadPath) {
            let downloadTask = request.requestTask as? URLSessionDownloadTask
            downloadTask?.cancel(byProducingResumeData: { resumeData in
                try? resumeData?.write(to: localUrl, options: .atomic)
            })
        } else {
            request.requestConfig.requestPlugin.cancelRequest(for: request)
        }
        
        removeRequestFromRecord(request)
        request.clearCompletionBlock()
        #if DEBUG
        if request.requestConfig.debugLogEnabled {
            Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST CANCELLED===========\n%@%@ %@:\n%@", "⏹️ ", request.requestMethod().rawValue, request.requestUrl(), String.fw_safeString(request.requestArgument()))
        }
        #endif
    }
    
    /// 取消所有已添加的请求
    open func cancelAllRequests() {
        lock.lock()
        let allKeys = requestsRecord.keys
        lock.unlock()
        allKeys.forEach { key in
            lock.lock()
            let request = requestsRecord[key]
            lock.unlock()
            
            request?.stop()
        }
    }
    
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
        batchRequestArray.removeAll(where: { $0 == batchRequest })
    }
    
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
        chainRequestArray.removeAll(where: { $0 == chainRequest })
    }
    
    /// 当filter为nil或返回true时开始同步请求，完成后主线程回调
    open func synchronousRequest(_ request: HTTPRequest, filter: (() -> Bool)? = nil, completion: ((HTTPRequest) -> Void)?) {
        synchronousQueue.async { [weak self] in
            self?.synchronousSemaphore.wait()
            let filterResult = filter != nil ? filter!() : true
            if !filterResult {
                self?.synchronousSemaphore.signal()
                return
            }
            
            request.start { [weak self] request in
                completion?(request)
                self?.synchronousSemaphore.signal()
            }
        }
    }
    
    /// 当filter为nil或返回true时开始同步批量请求，完成后主线程回调
    open func synchronousBatchRequest(_ batchRequest: BatchRequest, filter: (() -> Bool)? = nil, completion: ((BatchRequest) -> Void)?) {
        synchronousQueue.async { [weak self] in
            self?.synchronousSemaphore.wait()
            let filterResult = filter != nil ? filter!() : true
            if !filterResult {
                self?.synchronousSemaphore.signal()
                return
            }
            
            batchRequest.start { [weak self] batchRequest in
                completion?(batchRequest)
                self?.synchronousSemaphore.signal()
            }
        }
    }
    
    /// 当filter为nil或返回true时开始同步队列请求，完成后主线程回调
    open func synchronousChainRequest(_ chainRequest: ChainRequest, filter: (() -> Bool)? = nil, completion: ((ChainRequest) -> Void)?) {
        synchronousQueue.async { [weak self] in
            self?.synchronousSemaphore.wait()
            let filterResult = filter != nil ? filter!() : true
            if !filterResult {
                self?.synchronousSemaphore.signal()
                return
            }
            
            chainRequest.start { [weak self] chainRequest in
                completion?(chainRequest)
                self?.synchronousSemaphore.signal()
            }
        }
    }
    
    /// 构建请求URL
    open func buildRequestUrl(_ request: HTTPRequest) -> String {
        var requestUrl = request.requestUrl()
        let tempUrl = URL.fw_url(string: requestUrl)
        if tempUrl != nil, tempUrl?.host != nil, tempUrl?.scheme != nil {
            return requestUrl
        }
        
        let filters = request.requestConfig.requestFilters
        for filter in filters {
            if let filterUrl = filter.filterUrl?(requestUrl, with: request) {
                requestUrl = filterUrl
            }
        }
        
        let baseUrl: String
        if request.useCDN() {
            baseUrl = request.cdnUrl().count > 0 ? request.cdnUrl() : request.requestConfig.cdnUrl
        } else {
            baseUrl = request.baseUrl().count > 0 ? request.baseUrl() : request.requestConfig.baseUrl
        }
        
        var url = URL.fw_url(string: baseUrl)
        if !baseUrl.isEmpty, !baseUrl.hasSuffix("/") {
            url = url?.appendingPathComponent("")
        }
        
        let resultUrl = URL.fw_url(string: requestUrl, relativeTo: url)
        return resultUrl?.absoluteString ?? ""
    }
    
    /// 获取响应编码
    open func stringEncoding(for request: HTTPRequest) -> String.Encoding {
        var stringEncoding = String.Encoding.utf8
        if let textEncoding = request.response?.textEncodingName {
            let encoding = CFStringConvertIANACharSetNameToEncoding(textEncoding as CFString)
            if encoding != kCFStringEncodingInvalidId {
                stringEncoding = String.Encoding(rawValue: UInt(encoding))
            }
        }
        return stringEncoding
    }
    
    /// 获取下载路径的临时路径
    open func incompleteDownloadTempPath(for request: HTTPRequest, downloadPath: String?) -> URL? {
        return nil
    }
    
    // MARK: - Private
    private func addRequestToRecord(_ request: HTTPRequest) {
        lock.lock()
        defer { lock.unlock() }
        requestsRecord[request.requestIdentifier] = request
    }
    
    private func removeRequestFromRecord(_ request: HTTPRequest) {
        lock.lock()
        defer { lock.unlock() }
        requestsRecord.removeValue(forKey: request.requestIdentifier)
        #if DEBUG
        if requestsRecord.count > 0 {
            if request.requestConfig.debugLogEnabled {
                Logger.debug(group: Logger.fw_moduleName, "Request queue size = %zd", requestsRecord.count)
            }
        }
        #endif
    }
    
    private func sessionTask(for request: HTTPRequest) throws -> URLSessionTask {
        if request.requestMethod() == .GET, request.resumableDownloadPath != nil {
            return try downloadTask(with: request, progress: request.resumableDownloadProgressBlock)
        } else {
            return try dataTask(with: request)
        }
    }
    
    private func dataTask(with request: HTTPRequest) throws -> URLSessionDataTask {
        throw RequestError.cacheExpired
    }
    
    private func downloadTask(with request: HTTPRequest, progress downloadProgressBlock: ((Progress) -> Void)?) throws -> URLSessionDownloadTask {
        throw RequestError.cacheExpired
    }
    
    private func validateResult(_ request: HTTPRequest) throws {
        
    }
    
    private func handleRequestResult(_ requestIdentifier: Int, response: URLResponse?, responseObject: Any?, error: Error?) {
        
    }
    
    private func requestDidSucceed(_ request: HTTPRequest) {
        
    }
    
    private func requestDidFail(_ request: HTTPRequest, error: Error) {
        
    }
    
}
