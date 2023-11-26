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
    
    /// 构建请求响应
    func urlResponse(for request: HTTPRequest, response: URLResponse?, responseObject: Any?) throws
    
    /// 请求重试，返回是否启用默认重试方案
    func retryRequest(for request: HTTPRequest) -> Bool
    
    /// 构建数据任务，需设置requestTask
    func dataTask(for request: HTTPRequest, urlRequest: URLRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?)
    
    /// 构建下载任务，支持断点续传，须设置requestTask
    func downloadTask(for request: HTTPRequest, urlRequest: URLRequest?, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?)
    
    /// 开始请求
    func startRequest(for request: HTTPRequest)
    
    /// 取消请求
    func cancelRequest(for request: HTTPRequest)
    
}

extension RequestPlugin {
    
    /// 默认实现构建URLRequest方法
    public func urlRequest(for request: HTTPRequest) throws -> NSMutableURLRequest {
        return try RequestPluginImpl.shared.urlRequest(for: request)
    }
    
    /// 默认实现构建请求响应
    public func urlResponse(for request: HTTPRequest, response: URLResponse?, responseObject: Any?) throws {
        try RequestPluginImpl.shared.urlResponse(for: request, response: response, responseObject: responseObject)
    }
    
    /// 默认实现是否启用请求重试机制
    public func retryRequest(for request: HTTPRequest) -> Bool {
        return RequestPluginImpl.shared.retryRequest(for: request)
    }
    
    /// 默认实现构建数据任务，需设置requestTask
    public func dataTask(for request: HTTPRequest, urlRequest: URLRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        RequestPluginImpl.shared.dataTask(for: request, urlRequest: urlRequest, completionHandler: completionHandler)
    }
    
    /// 默认实现构建下载任务，支持断点续传，须设置requestTask
    public func downloadTask(for request: HTTPRequest, urlRequest: URLRequest?, resumeData: Data?, destination: String, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) {
        RequestPluginImpl.shared.downloadTask(for: request, urlRequest: urlRequest, resumeData: resumeData, destination: destination, completionHandler: completionHandler)
    }
    
    /// 默认实现开始请求
    public func startRequest(for request: HTTPRequest) {
        RequestPluginImpl.shared.startRequest(for: request)
    }
    
    /// 默认实现取消请求
    public func cancelRequest(for request: HTTPRequest) {
        RequestPluginImpl.shared.cancelRequest(for: request)
    }
    
}
