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
    
    /// 构建请求URLRequest
    func buildUrlRequest(for request: HTTPRequest) throws -> URLRequest
    
    /// 构建数据任务，自动开始
    func startDataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?)
    
    /// 构建下载任务，支持断点续传，自动开始
    func startDownloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?)
    
    /// 暂停请求，开始后可调用
    func suspendRequest(_ request: HTTPRequest)
    
    /// 继续请求，暂停后可调用
    func resumeRequest(_ request: HTTPRequest)
    
    /// 取消请求
    func cancelRequest(_ request: HTTPRequest)
    
}

extension RequestPlugin {
    
    /// 默认实现构建请求URLRequest
    public func buildUrlRequest(for request: HTTPRequest) throws -> URLRequest {
        return try RequestPluginImpl.shared.buildUrlRequest(for: request)
    }
    
    /// 默认实现构建数据任务，自动开始
    public func startDataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        RequestPluginImpl.shared.startDataTask(for: request, completionHandler: completionHandler)
    }
    
    /// 默认实现构建下载任务，支持断点续传自动开始
    public func startDownloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) {
        RequestPluginImpl.shared.startDownloadTask(for: request, resumeData: resumeData, destination: destination, completionHandler: completionHandler)
    }
    
    /// 默认实现暂停请求，开始后可调用
    public func suspendRequest(_ request: HTTPRequest) {
        RequestPluginImpl.shared.suspendRequest(request)
    }
    
    /// 默认实现继续请求，暂停后可调用
    public func resumeRequest(_ request: HTTPRequest) {
        RequestPluginImpl.shared.resumeRequest(request)
    }
    
    /// 默认实现取消请求
    public func cancelRequest(_ request: HTTPRequest) {
        RequestPluginImpl.shared.cancelRequest(request)
    }
    
}
