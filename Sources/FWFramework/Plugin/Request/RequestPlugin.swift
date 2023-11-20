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
    
    /// 构建URLRequest方法
    func urlRequest(for request: HTTPRequest) throws -> NSMutableURLRequest
    
    /// 开始数据请求，需设置requestTask
    func startDataRequest(_ request: HTTPRequest, urlRequest: URLRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?)
    
    /// 开始下载请求，支持断点续传，须设置requestTask
    func startDownloadRequest(_ request: HTTPRequest, urlRequest: URLRequest?, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?)
    
    /// 取消请求
    func cancelRequest(for request: HTTPRequest)
    
}

extension RequestPlugin {
    
    /// 默认实现构建URLRequest方法
    public func urlRequest(for request: HTTPRequest) throws -> NSMutableURLRequest {
        return try RequestPluginImpl.shared.urlRequest(for: request)
    }
    
    /// 默认实现开始数据请求，需设置requestTask
    public func startDataRequest(_ request: HTTPRequest, urlRequest: URLRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        RequestPluginImpl.shared.startDataRequest(request, urlRequest: urlRequest, completionHandler: completionHandler)
    }
    
    /// 默认实现开始下载请求，支持断点续传，须设置requestTask
    public func startDownloadRequest(_ request: HTTPRequest, urlRequest: URLRequest?, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) {
        RequestPluginImpl.shared.startDownloadRequest(request, urlRequest: urlRequest, resumeData: resumeData, destination: destination, completionHandler: completionHandler)
    }
    
    /// 默认实现取消请求
    public func cancelRequest(for request: HTTPRequest) {
        RequestPluginImpl.shared.cancelRequest(for: request)
    }
    
}
