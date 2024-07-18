//
//  HTTPSessionManager.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

/// HTTPSession管理器
///
/// [AFNetworking](https://github.com/AFNetworking/AFNetworking)
open class HTTPSessionManager: URLSessionManager, @unchecked Sendable {
    open private(set) var baseURL: URL?
    open var requestSerializer: HTTPRequestSerializer = HTTPRequestSerializer()
    open override var securityPolicy: SecurityPolicy {
        get {
            return super.securityPolicy
        }
        set {
            if newValue.pinningMode != .none && !(baseURL?.scheme == "https") {
                assert(false, String(format: "A security policy configured with `%@` can only be applied on a manager with a secure base URL (i.e. https)", "\(newValue.pinningMode.rawValue)"))
            }
            super.securityPolicy = newValue
        }
    }
    
    public convenience init() {
        self.init(baseURL: nil, sessionConfiguration: nil)
    }
    
    public convenience init(baseURL: URL?) {
        self.init(baseURL: baseURL, sessionConfiguration: nil)
    }
    
    public convenience override init(sessionConfiguration: URLSessionConfiguration?) {
        self.init(baseURL: nil, sessionConfiguration: sessionConfiguration)
    }
    
    public init(baseURL: URL?, sessionConfiguration: URLSessionConfiguration?) {
        super.init(sessionConfiguration: sessionConfiguration)
        
        if let url = baseURL, url.path.count > 0, !url.absoluteString.hasSuffix("/") {
            self.baseURL = url.appendingPathComponent("")
        } else {
            self.baseURL = baseURL
        }
    }
    
    open func get(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        progress: ((Progress) -> Void)? = nil,
        success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: ((_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "GET", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: nil, downloadProgress: progress, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    open func head(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        success: ((_ task: URLSessionDataTask) -> Void)? = nil,
        failure: ((_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "HEAD", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: nil, downloadProgress: nil, success: { task, responseObject in
            success?(task)
        }, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    open func post(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        progress: ((Progress) -> Void)? = nil,
        success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: ((_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "POST", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: progress, downloadProgress: nil, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    open func post(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        constructingBody block: ((MultipartFormData) -> Void)?,
        progress: ((Progress) -> Void)? = nil,
        success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: (@Sendable (_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let url = URL.fw.url(string: urlString, relativeTo: baseURL)
        var request: URLRequest
        do {
            request = try requestSerializer.multipartFormRequest(method: "POST", urlString: url?.absoluteString ?? "", parameters: parameters as? [String: Any], constructingBody: block)
            headers?.forEach({ (field, value) in
                request.setValue(value, forHTTPHeaderField: field)
            })
        } catch {
            if failure != nil {
                (self.completionQueue ?? .main).async {
                    failure?(nil, error)
                }
            }
            
            return nil
        }
        
        var dataTask: URLSessionDataTask?
        dataTask = uploadTask(streamedRequest: request, progress: progress) { response, responseObject, error in
            if let error = error {
                failure?(dataTask, error)
            } else if let dataTask = dataTask {
                success?(dataTask, responseObject)
            }
        }
        dataTask?.resume()
        return dataTask
    }
    
    open func put(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: ((_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "PUT", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: nil, downloadProgress: nil, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    open func patch(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: ((_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "PATCH", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: nil, downloadProgress: nil, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    open func delete(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: ((_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "DELETE", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: nil, downloadProgress: nil, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    open func dataTask(
        httpMethod: String,
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        uploadProgress: ((Progress) -> Void)? = nil,
        downloadProgress: ((Progress) -> Void)? = nil,
        success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: ((_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let url = URL.fw.url(string: urlString, relativeTo: baseURL)
        var request: URLRequest
        do {
            request = try requestSerializer.request(method: httpMethod, urlString: url?.absoluteString ?? "", parameters: parameters)
            headers?.forEach({ (field, value) in
                request.setValue(value, forHTTPHeaderField: field)
            })
        } catch {
            if failure != nil {
                (self.completionQueue ?? .main).async {
                    failure?(nil, error)
                }
            }
            
            return nil
        }
        
        var dataTask: URLSessionDataTask?
        dataTask = self.dataTask(request: request, uploadProgress: uploadProgress, downloadProgress: downloadProgress, completionHandler: { response, responseObject, error in
            if let error = error {
                failure?(dataTask, error)
            } else if let dataTask = dataTask {
                success?(dataTask, responseObject)
            }
        })
        return dataTask
    }
    
    open override var description: String {
        return String(format: "<%@: %p, baseURL: %@, session: %@, operationQueue: %@>", NSStringFromClass(type(of: self)), self, baseURL?.absoluteString ?? "", session, operationQueue)
    }
}
