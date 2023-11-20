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
    
    /// 继续请求
    func resumeRequest(for request: HTTPRequest)
    
    /// 取消请求
    func cancelRequest(for request: HTTPRequest)
    
}

extension RequestPlugin {
    
    /// 默认实现构建URLRequest方法
    public func urlRequest(for request: HTTPRequest) throws -> NSMutableURLRequest {
        return try RequestPluginImpl.shared.urlRequest(for: request)
    }
    
    /// 默认实现继续请求
    public func resumeRequest(for request: HTTPRequest) {
        RequestPluginImpl.shared.resumeRequest(for: request)
    }
    
    /// 默认实现取消请求
    public func cancelRequest(for request: HTTPRequest) {
        RequestPluginImpl.shared.cancelRequest(for: request)
    }
    
}
