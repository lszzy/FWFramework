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
        return ""
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
