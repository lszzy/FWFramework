//
//  RequestManager.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

/// 请求管理器
open class RequestManager {
    
    public static let shared = RequestManager()
    
    private var requestsRecord: [String: HTTPRequest] = [:]
    private var downloadFolderName = "Incomplete"
    private var lock = NSLock()
    private var syncQueue = DispatchQueue(label: "site.wuyong.queue.request.synchronous")
    private var syncSemaphore = DispatchSemaphore(value: 1)
    
    public init() {}
    
    /// 添加请求并开始
    open func addRequest(_ request: HTTPRequest) {
        addRecord(for: request)
        
        if request.isSynchronously {
            syncQueue.async { [weak self] in
                self?.syncSemaphore.wait()
                
                self?.startRequest(request)
            }
        } else {
            startRequest(request)
        }
    }
    
    /// 取消已经添加的请求
    open func cancelRequest(_ request: HTTPRequest) {
        if let downloadPath = request.resumableDownloadPath,
           let localUrl = incompleteDownloadTempPath(for: request, downloadPath: downloadPath) {
            let downloadTask = request.requestTask as? URLSessionDownloadTask
            downloadTask?.cancel(byProducingResumeData: { resumeData in
                try? resumeData?.write(to: localUrl, options: .atomic)
            })
        } else {
            request.config.requestPlugin.cancelRequest(request)
        }
        
        finishRequest(request)
        
        #if DEBUG
        if request.config.debugLogEnabled {
            Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST CANCELLED===========\n%@%@ %@:\n%@", "⏹️ ", request.requestMethod().rawValue, request.requestUrl(), String.fw_safeString(request.requestArgument()))
        }
        #endif
    }
    
    /// 取消所有已添加的请求
    open func cancelAllRequests() {
        lock.lock()
        let allKeys = requestsRecord.keys
        lock.unlock()
        allKeys.forEach { key in
            lock.lock()
            let request = requestsRecord[key]
            lock.unlock()
            
            request?.cancel()
        }
    }
    
    /// 构建请求URL
    open func buildRequestUrl(for request: HTTPRequest) -> URL {
        var requestUrl = request.requestUrl()
        if let url = URL.fw_url(string: requestUrl), url.host != nil, url.scheme != nil {
            return url
        }
        
        let filters = request.config.requestFilters
        for filter in filters {
            requestUrl = filter.filterUrl(requestUrl, for: request)
        }
        
        let baseUrl: String
        if request.useCDN() {
            baseUrl = request.cdnUrl().count > 0 ? request.cdnUrl() : request.config.cdnUrl
        } else {
            baseUrl = request.baseUrl().count > 0 ? request.baseUrl() : request.config.baseUrl
        }
        
        var url = URL.fw_url(string: baseUrl)
        if !baseUrl.isEmpty, !baseUrl.hasSuffix("/") {
            url = url?.appendingPathComponent("")
        }
        return URL.fw_url(string: requestUrl, relativeTo: url) ?? URL()
    }
    
    /// 过滤URL请求
    open func filterUrlRequest(_ urlRequest: inout URLRequest, for request: HTTPRequest) {
        request.urlRequestFilter(&urlRequest)
        
        let filters = request.config.requestFilters
        for filter in filters {
            filter.filterUrlRequest(&urlRequest, for: request)
        }
        
        if request.requestSerializerType() == .JSON,
           urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if request.responseSerializerType() == .JSON,
           urlRequest.value(forHTTPHeaderField: "Accept") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        }
    }
    
    /// 获取响应编码
    open func stringEncoding(for request: HTTPRequest) -> String.Encoding {
        var stringEncoding = String.Encoding.utf8
        if let textEncoding = request.requestTask?.response?.textEncodingName {
            let encoding = CFStringConvertIANACharSetNameToEncoding(textEncoding as CFString)
            if encoding != kCFStringEncodingInvalidId {
                stringEncoding = String.Encoding(rawValue: UInt(encoding))
            }
        }
        return stringEncoding
    }
    
    /// 获取下载路径的临时路径
    open func incompleteDownloadTempPath(for request: HTTPRequest, downloadPath: String?) -> URL? {
        guard let downloadPath = downloadPath, !downloadPath.isEmpty else {
            return nil
        }
        
        var tempPath: String?
        let cacheFolder = (NSTemporaryDirectory() as NSString).appendingPathComponent(downloadFolderName)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: cacheFolder, isDirectory: &isDirectory), isDirectory.boolValue {
            tempPath = cacheFolder
        } else {
            do {
                try FileManager.default.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true)
                tempPath = cacheFolder
            } catch {
                tempPath = nil
            }
        }
        guard var tempPath = tempPath else {
            return nil
        }
        
        tempPath = (tempPath as NSString).appendingPathComponent(downloadPath.fw_md5Encode)
        return URL(fileURLWithPath: tempPath)
    }
    
    // MARK: - Private
    private func addRecord(for request: HTTPRequest) {
        lock.lock()
        defer { lock.unlock() }
        requestsRecord[request.requestIdentifier] = request
    }
    
    private func removeRecord(for request: HTTPRequest) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let removed = requestsRecord.removeValue(forKey: request.requestIdentifier)
        return removed != nil
    }
    
    private func startRequest(_ request: HTTPRequest) {
        #if DEBUG
        if request.config.debugLogEnabled {
            Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST STARTED===========\n%@%@ %@:\n%@", "▶️ ", request.requestMethod().rawValue, request.requestUrl(), String.fw_safeString(request.requestArgument()))
        }
        #endif
        
        request.toggleAccessoriesWillStartCallBack()
        
        request.requestStartTime = Date().timeIntervalSince1970
        retrySessionTask(for: request) { [weak self] response, responseObject, error in
            self?.handleResponse(with: request.requestIdentifier, response: response, responseObject: responseObject, error: error)
        }
    }
    
    private func finishRequest(_ request: HTTPRequest) {
        let isRemoved = removeRecord(for: request)
        request.clearCompletionBlock()
        
        if request.isSynchronously, isRemoved {
            syncSemaphore.signal()
        }
    }
    
    private func retrySessionTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        startSessionTask(for: request) { [weak self] response, responseObject, error in
            request.requestTotalCount += 1
            request.requestTotalTime = Date().timeIntervalSince1970 - request.requestStartTime
            
            if let requestRetrier = request.config.requestRetrier {
                requestRetrier.retryRequest(request, response: response, responseObject: responseObject, error: error) { shouldRetry in
                    if shouldRetry {
                        self?.retrySessionTask(for: request, completionHandler: completionHandler)
                    } else {
                        completionHandler?(response, responseObject, error)
                    }
                }
            } else {
                completionHandler?(response, responseObject, error)
            }
        }
    }
    
    private func startSessionTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        if request.requestMethod() == .GET, request.resumableDownloadPath != nil {
            startDownloadTask(for: request, completionHandler: completionHandler)
        } else {
            startDataTask(for: request, completionHandler: completionHandler)
        }
    }
    
    private func startDataTask(for request: HTTPRequest, completionHandler: ((URLResponse, Any?, Error?) -> Void)?) {
        request.config.requestPlugin.startDataTask(for: request, completionHandler: completionHandler)
    }
    
    private func startDownloadTask(for request: HTTPRequest, completionHandler: ((URLResponse, URL?, Error?) -> Void)?) {
        let downloadPath = request.resumableDownloadPath ?? ""
        var downloadTargetPath: String = ""
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: downloadPath, isDirectory: &isDirectory) {
            isDirectory = false
        }
        if isDirectory.boolValue {
            let requestUrl = buildRequestUrl(for: request)
            let fileName = requestUrl.lastPathComponent
            downloadTargetPath = NSString.path(withComponents: [downloadPath, fileName])
        } else {
            downloadTargetPath = downloadPath
        }
        
        if FileManager.default.fileExists(atPath: downloadTargetPath) {
            try? FileManager.default.removeItem(atPath: downloadTargetPath)
        }
        
        var resumeData: Data?
        if let localUrl = incompleteDownloadTempPath(for: request, downloadPath: downloadPath) {
            let resumeDataFileExists = FileManager.default.fileExists(atPath: localUrl.path)
            let data = try? Data(contentsOf: localUrl)
            let resumeDataIsValid = validateResumeData(data)
            
            if resumeDataFileExists && resumeDataIsValid {
                resumeData = data
            }
        }
        
        request.config.requestPlugin.startDownloadTask(for: request, resumeData: resumeData, destination: downloadTargetPath, completionHandler: completionHandler)
    }
    
    private func handleResponse(with requestIdentifier: String, response: URLResponse, responseObject: Any?, error: Error?) {
        lock.lock()
        let request = requestsRecord[requestIdentifier]
        lock.unlock()
        guard let request = request else { return }
        
        var requestError: Error?
        var succeed = true
        if error != nil {
            succeed = false
            requestError = error
        } else {
            do {
                try validateResponse(request)
            } catch let validationError {
                succeed = false
                requestError = validationError
            }
        }
        
        #if DEBUG
        if !succeed, request.config.debugMockEnabled, request.responseMockValidator() {
            succeed = request.responseMockProcessor()
            if succeed {
                requestError = nil
            }
        }
        #endif
        
        if succeed {
            do {
                try request.responseFilter()
            } catch let responseError {
                succeed = false
                requestError = responseError
            }
        }
        
        if succeed {
            let filters = request.config.requestFilters
            for filter in filters {
                do {
                    try filter.filterResponse(for: request)
                } catch let responseError {
                    succeed = false
                    requestError = responseError
                }
                if !succeed {
                    break
                }
            }
        }
        
        if succeed {
            requestDidSucceed(request)
        } else {
            requestDidFail(request, error: requestError ?? RequestError.unknown)
        }
    }
    
    private func validateResponse(_ request: HTTPRequest) throws {
        if !request.statusCodeValidator() {
            throw RequestError.validationInvalidStatusCode(request.responseStatusCode)
        }
        
        if let requestValidator = request.config.requestValidator,
           !requestValidator.validateResponse(for: request) {
            throw RequestError.validationInvalidJSONFormat
        }
    }
    
    private func validateResumeData(_ data: Data?) -> Bool {
        guard let data = data, data.count > 0 else { return false }
        
        let resumeDictionary = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [AnyHashable: Any]
        if let resumeDictionary = resumeDictionary, !resumeDictionary.isEmpty {
            return true
        }
        return false
    }
    
    private func requestDidSucceed(_ request: HTTPRequest) {
        #if DEBUG
        if request.config.debugLogEnabled {
            Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST SUCCEED===========\n%@%@%@ %@:\n%@", "✅ ", request.requestMethod().rawValue, request.requestTotalCount > 1 ? " \(request.requestTotalCount)x" : "", request.requestUrl(), String.fw_safeString(request.responseJSONObject ?? request.responseString))
        }
        #endif
        
        autoreleasepool {
            request.requestCompletePreprocessor()
        }
        DispatchQueue.main.async {
            request.toggleAccessoriesWillStopCallBack()
            request.requestCompleteFilter()
            request.delegate?.requestFinished(request)
            request.successCompletionBlock?(request)
            request.toggleAccessoriesDidStopCallBack()
            
            self.finishRequest(request)
        }
    }
    
    private func requestDidFail(_ request: HTTPRequest, error: Error) {
        request.error = error
        #if DEBUG
        if request.config.debugLogEnabled {
            Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST FAILED===========\n%@%@%@ %@:\n%@", "❌ ", request.requestMethod().rawValue, request.requestTotalCount > 1 ? " \(request.requestTotalCount)x" : "", request.requestUrl(), String.fw_safeString(request.responseJSONObject ?? request.error))
        }
        #endif
        
        let incompleteDownloadData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        if incompleteDownloadData != nil,
           let downloadPath = request.resumableDownloadPath,
           let localUrl = incompleteDownloadTempPath(for: request, downloadPath: downloadPath) {
            try? incompleteDownloadData?.write(to: localUrl, options: .atomic)
        }
        
        if let url = request.responseObject as? URL {
            if url.isFileURL && FileManager.default.fileExists(atPath: url.path) {
                request.responseData = try? Data(contentsOf: url)
                request.responseString = request.responseData != nil ? String(data: request.responseData!, encoding: stringEncoding(for: request)) : nil
                
                try? FileManager.default.removeItem(at: url)
            }
            request.responseObject = nil
        }
        
        autoreleasepool {
            request.requestFailedPreprocessor()
        }
        DispatchQueue.main.async {
            request.toggleAccessoriesWillStopCallBack()
            request.requestFailedFilter()
            request.delegate?.requestFailed(request)
            request.failureCompletionBlock?(request)
            request.toggleAccessoriesDidStopCallBack()
            
            self.finishRequest(request)
        }
    }
    
}
