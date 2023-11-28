//
//  RequestPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

// MARK: - RequestPlugin
/// 请求插件协议
public protocol RequestPlugin: AnyObject {
    
    /// 构建数据任务，自动开始
    func startDataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?)
    
    /// 构建下载任务，支持断点续传，自动开始
    func startDownloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?)
    
    /// 取消请求
    func cancelRequest(_ request: HTTPRequest)
    
    /// 是否启用默认重试方案
    func shouldRetryRequest(_ request: HTTPRequest) -> Bool
    
}

extension RequestPlugin {
    
    /// 默认实现构建数据任务，自动开始
    public func startDataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        RequestPluginImpl.shared.startDataTask(for: request, completionHandler: completionHandler)
    }
    
    /// 默认实现构建下载任务，支持断点续传自动开始
    public func startDownloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) {
        RequestPluginImpl.shared.startDownloadTask(for: request, resumeData: resumeData, destination: destination, completionHandler: completionHandler)
    }
    
    /// 默认实现取消请求
    public func cancelRequest(_ request: HTTPRequest) {
        RequestPluginImpl.shared.cancelRequest(request)
    }
    
    /// 默认实现是否启用请求重试机制
    public func shouldRetryRequest(_ request: HTTPRequest) -> Bool {
        return RequestPluginImpl.shared.shouldRetryRequest(request)
    }
    
}
