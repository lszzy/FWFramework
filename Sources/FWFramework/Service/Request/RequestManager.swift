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
        
    }
    
    /// 取消已经添加的请求
    open func cancelRequest(_ request: HTTPRequest) {
        
    }
    
    /// 取消所有已添加的请求
    open func cancelAllRequests() {
        
    }
    
    /// 添加批量请求
    open func addBatchRequest(_ batchRequest: BatchRequest) {
        
    }
    
    /// 移除批量请求
    open func removeBatchRequest(_ batchRequest: BatchRequest) {
        
    }
    
    /// 添加队列请求
    open func addChainRequest(_ chainRequest: ChainRequest) {
        
    }
    
    /// 移除队列请求
    open func removeChainRequest(_ chainRequest: ChainRequest) {
        
    }
    
    /// 当filter为nil或返回true时开始同步请求，完成后主线程回调
    open func synchronousRequest(_ request: HTTPRequest, filter: (() -> Bool)? = nil, completion: ((HTTPRequest) -> Void)?) {
        
    }
    
    /// 当filter为nil或返回true时开始同步批量请求，完成后主线程回调
    open func synchronousBatchRequest(_ batchRequest: BatchRequest, filter: (() -> Bool)? = nil, completion: ((BatchRequest) -> Void)?) {
        
    }
    
    /// 当filter为nil或返回true时开始同步队列请求，完成后主线程回调
    open func synchronousChainRequest(_ chainRequest: ChainRequest, filter: (() -> Bool)? = nil, completion: ((ChainRequest) -> Void)?) {
        
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
    
}
