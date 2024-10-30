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
    func startDataTask(for request: HTTPRequest, completionHandler: (@Sendable (URLResponse, Any?, Error?) -> Void)?)

    /// 构建下载任务，支持断点续传，自动开始
    func startDownloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: (@Sendable (URLResponse, URL?, Error?) -> Void)?)

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
        try RequestPluginImpl.shared.buildUrlRequest(for: request)
    }

    /// 默认实现构建数据任务，自动开始
    public func startDataTask(for request: HTTPRequest, completionHandler: (@Sendable (URLResponse, Any?, Error?) -> Void)?) {
        RequestPluginImpl.shared.startDataTask(for: request, completionHandler: completionHandler)
    }

    /// 默认实现构建下载任务，支持断点续传自动开始
    public func startDownloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: (@Sendable (URLResponse, URL?, Error?) -> Void)?) {
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

// MARK: - RequestPluginImpl
/// 默认请求插件
open class RequestPluginImpl: NSObject, RequestPlugin, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = RequestPluginImpl()

    /// SessionConfiguration配置，默认nil
    open var sessionConfiguration: URLSessionConfiguration = .default
    /// 自定义安全策略，默认default
    open var securityPolicy: SecurityPolicy = .default
    /// SessionTaskMetrics配置句柄，默认nil
    open var collectingMetricsBlock: (@Sendable (_ session: URLSession, _ task: URLSessionTask, _ metrics: URLSessionTaskMetrics?) -> Void)?

    /// 是否移除响应JSON中的NSNull值，默认true
    open var removeNullValues = true
    /// 有效状态码范围，默认为(100-600)
    open var acceptableStatusCodes = IndexSet(integersIn: 100..<600)
    /// 有效的contentType列表，默认nil不修改
    open var acceptableContentTypes: Set<String>?

    private var completionQueue = DispatchQueue(label: "site.wuyong.queue.request.completion", attributes: .concurrent)

    /// 管理器，延迟加载前可配置
    open lazy var manager: HTTPSessionManager = {
        let result = HTTPSessionManager(sessionConfiguration: sessionConfiguration)
        result.securityPolicy = securityPolicy
        result.responseSerializer = httpResponseSerializer
        result.completionQueue = completionQueue
        result.taskDidFinishCollectingMetrics = collectingMetricsBlock
        return result
    }()

    /// HTTP响应序列化
    open lazy var httpResponseSerializer: HTTPResponseSerializer = {
        let result = HTTPResponseSerializer()
        result.acceptableStatusCodes = acceptableStatusCodes
        if let acceptableContentTypes {
            result.acceptableContentTypes = acceptableContentTypes
        }
        return result
    }()

    /// JSON响应序列化
    open lazy var jsonResponseSerializer: JSONResponseSerializer = {
        let result = JSONResponseSerializer()
        result.acceptableStatusCodes = acceptableStatusCodes
        if let acceptableContentTypes {
            result.acceptableContentTypes = acceptableContentTypes
        }
        result.removesKeysWithNullValues = removeNullValues
        return result
    }()

    // MARK: - RequestPlugin
    open func buildUrlRequest(for request: HTTPRequest) throws -> URLRequest {
        if let customUrlRequest = request.customUrlRequest() {
            return customUrlRequest
        }

        let requestUrl = RequestManager.shared.buildRequestUrl(for: request)
        let requestSerializer: HTTPRequestSerializer
        if request.requestSerializerType() == .JSON {
            requestSerializer = JSONRequestSerializer()
        } else {
            requestSerializer = HTTPRequestSerializer()
        }
        requestSerializer.timeoutInterval = request.requestTimeoutInterval()
        requestSerializer.allowsCellularAccess = request.allowsCellularAccess()
        if let cachePolicy = request.requestCachePolicy() {
            requestSerializer.cachePolicy = cachePolicy
        }

        if let headerFieldArray = request.requestAuthorizationHeaders(),
           !headerFieldArray.isEmpty {
            requestSerializer.setAuthorizationHeaderField(username: headerFieldArray.first ?? "", password: headerFieldArray.last ?? "")
        }
        if let headerFieldDictionary = request.requestHeaders(),
           !headerFieldDictionary.isEmpty {
            for (fieldKey, fieldValue) in headerFieldDictionary {
                requestSerializer.setValue(fieldValue, forHTTPHeaderField: fieldKey)
            }
        }

        var urlRequest: URLRequest
        if request.constructingBodyBlock != nil {
            urlRequest = try requestSerializer.multipartFormRequest(method: request.requestMethod().rawValue, urlString: requestUrl.absoluteString, parameters: request.requestArgument() as? [String: Any], constructingBody: { formData in
                if let requestFormData = formData as? RequestMultipartFormData {
                    request.constructingBodyBlock?(requestFormData)
                }
            })
        } else {
            urlRequest = try requestSerializer.request(method: request.requestMethod().rawValue, urlString: requestUrl.absoluteString, parameters: request.requestArgument())
        }

        RequestManager.shared.filterUrlRequest(&urlRequest, for: request)

        return urlRequest
    }

    open func startDataTask(for request: HTTPRequest, completionHandler: (@Sendable (URLResponse, Any?, Error?) -> Void)?) {
        let urlRequest: URLRequest
        do {
            urlRequest = try buildUrlRequest(for: request)
        } catch {
            completionHandler?(HTTPURLResponse(), nil, error)
            return
        }

        let dataTask = manager.dataTask(request: urlRequest, uploadProgress: request.uploadProgressBlock, downloadProgress: nil, completionHandler: { [weak self] response, responseObject, error in
            self?.handleResponse(for: request, response: response, responseObject: responseObject, error: error, completionHandler: completionHandler)
        })

        startRequestTask(dataTask, for: request)
    }

    open func startDownloadTask(for request: HTTPRequest, resumeData: Data?, destination: String, completionHandler: (@Sendable (URLResponse, URL?, Error?) -> Void)?) {
        let downloadTask: URLSessionDownloadTask
        if let resumeData {
            downloadTask = manager.downloadTask(resumeData: resumeData, progress: request.downloadProgressBlock, destination: { _, _ in
                URL(fileURLWithPath: destination, isDirectory: false)
            }, completionHandler: { [weak self] response, fileUrl, error in
                self?.handleResponse(for: request, response: response, responseObject: fileUrl, error: error, completionHandler: { response, responseObject, error in
                    completionHandler?(response, responseObject as? URL, error)
                })
            })
        } else {
            let urlRequest: URLRequest
            do {
                urlRequest = try buildUrlRequest(for: request)
            } catch {
                completionHandler?(HTTPURLResponse(), nil, error)
                return
            }

            downloadTask = manager.downloadTask(request: urlRequest, progress: request.downloadProgressBlock, destination: { _, _ in
                URL(fileURLWithPath: destination, isDirectory: false)
            }, completionHandler: { [weak self] response, fileUrl, error in
                self?.handleResponse(for: request, response: response, responseObject: fileUrl, error: error, completionHandler: { response, responseObject, error in
                    completionHandler?(response, responseObject as? URL, error)
                })
            })
        }

        startRequestTask(downloadTask, for: request)
    }

    open func suspendRequest(_ request: HTTPRequest) {
        request.requestTask?.suspend()
    }

    open func resumeRequest(_ request: HTTPRequest) {
        request.requestTask?.resume()
    }

    open func cancelRequest(_ request: HTTPRequest) {
        request.requestTask?.cancel()
    }

    // MARK: - Private
    private func startRequestTask(_ requestTask: URLSessionTask, for request: HTTPRequest) {
        switch request.requestPriority {
        case .high:
            requestTask.priority = URLSessionTask.highPriority
        case .low:
            requestTask.priority = URLSessionTask.lowPriority
        default:
            requestTask.priority = URLSessionTask.defaultPriority
        }

        request.requestTask = requestTask
        requestTask.resume()
    }

    private func handleResponse(for request: HTTPRequest, response: URLResponse, responseObject: Any?, error: Error?, completionHandler: (@Sendable (URLResponse, Any?, Error?) -> Void)?) {
        var serializationError: Error?
        request.responseObject = responseObject
        if let responseData = request.responseObject as? Data {
            request.responseData = responseData
            request.responseString = String(data: responseData, encoding: RequestManager.shared.stringEncoding(for: request))

            switch request.responseSerializerType() {
            case .JSON:
                do {
                    request.responseObject = try jsonResponseSerializer.responseObject(for: response, data: responseData)
                    request.responseJSONObject = request.responseObject
                } catch let decodeError {
                    serializationError = decodeError
                }
            default:
                break
            }
        }

        completionHandler?(response, request.responseObject, error ?? serializationError)
    }
}

// MARK: - StreamingMultipartFormData+RequestPluginImpl
extension StreamingMultipartFormData: RequestMultipartFormData {
    public func append(_ formData: Data, name: String) {
        appendPart(formData: formData, name: name)
    }

    public func append(_ fileData: Data, name: String, fileName: String, mimeType: String) {
        appendPart(fileData: fileData, name: name, fileName: fileName, mimeType: mimeType)
    }

    public func append(_ fileURL: URL, name: String) {
        try? appendPart(fileURL: fileURL, name: name)
    }

    public func append(_ fileURL: URL, name: String, fileName: String, mimeType: String) {
        try? appendPart(fileURL: fileURL, name: name, fileName: fileName, mimeType: mimeType)
    }

    public func append(_ inputStream: InputStream, length: UInt64, name: String, fileName: String, mimeType: String) {
        appendPart(inputStream: inputStream, length: length, name: name, fileName: fileName, mimeType: mimeType)
    }

    public func append(_ inputStream: InputStream, length: UInt64, headers: [String: String]) {
        appendPart(inputStream: inputStream, length: length, headers: headers)
    }

    public func append(_ body: Data, headers: [String: String]) {
        appendPart(headers: headers, body: body)
    }
}
