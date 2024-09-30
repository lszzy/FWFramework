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
    open var requestSerializer: HTTPRequestSerializer = .init()
    override open var securityPolicy: SecurityPolicy {
        get {
            super.securityPolicy
        }
        set {
            if newValue.pinningMode != .none && !(baseURL?.scheme == "https") {
                assertionFailure(String(format: "A security policy configured with `%@` can only be applied on a manager with a secure base URL (i.e. https)", "\(newValue.pinningMode.rawValue)"))
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

    override public convenience init(sessionConfiguration: URLSessionConfiguration?) {
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
        progress: (@Sendable (Progress) -> Void)? = nil,
        success: (@Sendable (_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: (@Sendable (_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "GET", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: nil, downloadProgress: progress, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }

    open func head(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        success: (@Sendable (_ task: URLSessionDataTask) -> Void)? = nil,
        failure: (@Sendable (_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "HEAD", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: nil, downloadProgress: nil, success: { task, _ in
            success?(task)
        }, failure: failure)
        dataTask?.resume()
        return dataTask
    }

    open func post(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        progress: (@Sendable (Progress) -> Void)? = nil,
        success: (@Sendable (_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: (@Sendable (_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "POST", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: progress, downloadProgress: nil, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }

    open func post(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        constructingBody block: (@Sendable (MultipartFormData) -> Void)?,
        progress: (@Sendable (Progress) -> Void)? = nil,
        success: (@Sendable (_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: (@Sendable (_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let url = URL.fw.url(string: urlString, relativeTo: baseURL)
        var request: URLRequest
        do {
            request = try requestSerializer.multipartFormRequest(method: "POST", urlString: url?.absoluteString ?? "", parameters: parameters as? [String: Any], constructingBody: block)
            headers?.forEach { field, value in
                request.setValue(value, forHTTPHeaderField: field)
            }
        } catch {
            if failure != nil {
                (completionQueue ?? .main).async {
                    failure?(nil, error)
                }
            }

            return nil
        }

        let sendableDataTask = SendableValue<URLSessionDataTask?>(nil)
        sendableDataTask.value = uploadTask(streamedRequest: request, progress: progress) { _, responseObject, error in
            if let error {
                failure?(sendableDataTask.value, error)
            } else if let dataTask = sendableDataTask.value {
                success?(dataTask, responseObject)
            }
        }
        sendableDataTask.value?.resume()
        return sendableDataTask.value
    }

    open func put(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        success: (@Sendable (_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: (@Sendable (_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "PUT", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: nil, downloadProgress: nil, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }

    open func patch(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        success: (@Sendable (_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: (@Sendable (_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let dataTask = dataTask(httpMethod: "PATCH", urlString: urlString, parameters: parameters, headers: headers, uploadProgress: nil, downloadProgress: nil, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }

    open func delete(
        urlString: String,
        parameters: Any? = nil,
        headers: [String: String]? = nil,
        success: (@Sendable (_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: (@Sendable (_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
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
        uploadProgress: (@Sendable (Progress) -> Void)? = nil,
        downloadProgress: (@Sendable (Progress) -> Void)? = nil,
        success: (@Sendable (_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)? = nil,
        failure: (@Sendable (_ task: URLSessionDataTask?, _ error: Error) -> Void)? = nil
    ) -> URLSessionDataTask? {
        let url = URL.fw.url(string: urlString, relativeTo: baseURL)
        var request: URLRequest
        do {
            request = try requestSerializer.request(method: httpMethod, urlString: url?.absoluteString ?? "", parameters: parameters)
            headers?.forEach { field, value in
                request.setValue(value, forHTTPHeaderField: field)
            }
        } catch {
            if failure != nil {
                (completionQueue ?? .main).async {
                    failure?(nil, error)
                }
            }

            return nil
        }

        let sendableDataTask = SendableValue<URLSessionDataTask?>(nil)
        sendableDataTask.value = dataTask(request: request, uploadProgress: uploadProgress, downloadProgress: downloadProgress, completionHandler: { _, responseObject, error in
            if let error {
                failure?(sendableDataTask.value, error)
            } else if let dataTask = sendableDataTask.value {
                success?(dataTask, responseObject)
            }
        })
        return sendableDataTask.value
    }

    override open var description: String {
        String(format: "<%@: %p, baseURL: %@, session: %@, operationQueue: %@>", NSStringFromClass(type(of: self)), self, baseURL?.absoluteString ?? "", session, operationQueue)
    }
}
