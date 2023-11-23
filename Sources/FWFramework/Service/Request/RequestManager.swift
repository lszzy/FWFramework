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
    
    private var batchRequestArray: [BatchRequest] = []
    private var chainRequestArray: [ChainRequest] = []
    private var requestsRecord: [Int: HTTPRequest] = [:]
    private var lock = NSLock()
    private var synchronousQueue = DispatchQueue(label: "site.wuyong.queue.request.synchronous")
    private var synchronousSemaphore = DispatchSemaphore(value: 1)
    private var downloadFolderName = "Incomplete"
    
    /// 添加请求并开始
    open func addRequest(_ request: HTTPRequest) {
        do {
            try sessionTask(for: request)
            
            addRecord(for: request)
            request.config.requestPlugin.startRequest(for: request)
            #if DEBUG
            if request.config.debugLogEnabled {
                Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST STARTED===========\n%@%@ %@:\n%@", "▶️ ", request.requestMethod().rawValue, request.requestUrl(), String.fw_safeString(request.requestArgument()))
            }
            #endif
        } catch {
            requestDidFail(request, error: error)
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
            request.config.requestPlugin.cancelRequest(for: request)
        }
        
        removeRecord(for: request)
        request.clearCompletionBlock()
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
            
            request?.stop()
        }
    }
    
    /// 添加批量请求
    open func addBatchRequest(_ batchRequest: BatchRequest) {
        lock.lock()
        defer { lock.unlock() }
        batchRequestArray.append(batchRequest)
    }
    
    /// 移除批量请求
    open func removeBatchRequest(_ batchRequest: BatchRequest) {
        lock.lock()
        defer { lock.unlock() }
        batchRequestArray.removeAll(where: { $0 == batchRequest })
    }
    
    /// 添加队列请求
    open func addChainRequest(_ chainRequest: ChainRequest) {
        lock.lock()
        defer { lock.unlock() }
        chainRequestArray.append(chainRequest)
    }
    
    /// 移除队列请求
    open func removeChainRequest(_ chainRequest: ChainRequest) {
        lock.lock()
        defer { lock.unlock() }
        chainRequestArray.removeAll(where: { $0 == chainRequest })
    }
    
    /// 当filter为nil或返回true时开始同步请求，完成后主线程回调
    open func synchronousRequest(_ request: HTTPRequest, filter: (() -> Bool)? = nil, completion: ((HTTPRequest) -> Void)?) {
        synchronousQueue.async { [weak self] in
            self?.synchronousSemaphore.wait()
            let filterResult = filter != nil ? filter!() : true
            if !filterResult {
                self?.synchronousSemaphore.signal()
                return
            }
            
            request.start { [weak self] request in
                completion?(request)
                self?.synchronousSemaphore.signal()
            }
        }
    }
    
    /// 当filter为nil或返回true时开始同步批量请求，完成后主线程回调
    open func synchronousBatchRequest(_ batchRequest: BatchRequest, filter: (() -> Bool)? = nil, completion: ((BatchRequest) -> Void)?) {
        synchronousQueue.async { [weak self] in
            self?.synchronousSemaphore.wait()
            let filterResult = filter != nil ? filter!() : true
            if !filterResult {
                self?.synchronousSemaphore.signal()
                return
            }
            
            batchRequest.start { [weak self] batchRequest in
                completion?(batchRequest)
                self?.synchronousSemaphore.signal()
            }
        }
    }
    
    /// 当filter为nil或返回true时开始同步队列请求，完成后主线程回调
    open func synchronousChainRequest(_ chainRequest: ChainRequest, filter: (() -> Bool)? = nil, completion: ((ChainRequest) -> Void)?) {
        synchronousQueue.async { [weak self] in
            self?.synchronousSemaphore.wait()
            let filterResult = filter != nil ? filter!() : true
            if !filterResult {
                self?.synchronousSemaphore.signal()
                return
            }
            
            chainRequest.start { [weak self] chainRequest in
                completion?(chainRequest)
                self?.synchronousSemaphore.signal()
            }
        }
    }
    
    /// 构建请求URL
    open func buildRequestUrl(_ request: HTTPRequest) -> String {
        var requestUrl = request.requestUrl()
        let tempUrl = URL.fw_url(string: requestUrl)
        if tempUrl != nil, tempUrl?.host != nil, tempUrl?.scheme != nil {
            return requestUrl
        }
        
        let filters = request.config.requestFilters
        for filter in filters {
            if let filterUrl = filter.filterUrl?(requestUrl, with: request) {
                requestUrl = filterUrl
            }
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
        
        let resultUrl = URL.fw_url(string: requestUrl, relativeTo: url)
        return resultUrl?.absoluteString ?? ""
    }
    
    /// 构建请求URLRequest
    open func buildUrlRequest(_ request: HTTPRequest) throws -> URLRequest {
        if let customUrlRequest = request.buildCustomUrlRequest() {
            return customUrlRequest
        }
        
        let urlRequest = try request.config.requestPlugin.urlRequest(for: request)
        
        request.filterUrlRequest(urlRequest)
        
        let filters = request.config.requestFilters
        for filter in filters {
            filter.filterUrlRequest?(urlRequest, with: request)
        }
        
        if request.requestSerializerType() == .JSON,
           urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if request.responseSerializerType() == .JSON,
           urlRequest.value(forHTTPHeaderField: "Accept") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        
        return urlRequest as URLRequest
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
                #if DEBUG
                if request.config.debugLogEnabled {
                    Logger.debug(group: Logger.fw_moduleName, "Failed to create cache directory at %@ with error: %@", cacheFolder, error.localizedDescription)
                }
                #endif
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
    
    private func removeRecord(for request: HTTPRequest) {
        lock.lock()
        defer { lock.unlock() }
        requestsRecord.removeValue(forKey: request.requestIdentifier)
        #if DEBUG
        if requestsRecord.count > 0 {
            if request.config.debugLogEnabled {
                Logger.debug(group: Logger.fw_moduleName, "Request queue size = %zd", requestsRecord.count)
            }
        }
        #endif
    }
    
    private func sessionTask(for request: HTTPRequest) throws {
        if request.requestMethod() == .GET, request.resumableDownloadPath != nil {
            try downloadTask(for: request)
        } else {
            try dataTask(for: request)
        }
        guard let requestTask = request.requestTask else { return }
        
        request.requestIdentifier = requestTask.taskIdentifier
        switch request.requestPriority {
        case .high:
            requestTask.priority = URLSessionTask.highPriority
        case .low:
            requestTask.priority = URLSessionTask.lowPriority
        default:
            requestTask.priority = URLSessionTask.defaultPriority
        }
    }
    
    private func dataTask(for request: HTTPRequest) throws {
        let retryRequest = request.config.requestPlugin.retryRequest(for: request)
        if retryRequest, let requestRetrier = request.config.requestRetrier {
            try requestRetrier.retryDataTask(for: request) { [weak self] response, responseObject, error in
                self?.handleResponse(request.requestIdentifier, response: response, responseObject: responseObject, error: error)
            }
        } else {
            let startTime = Date().timeIntervalSince1970
            let urlRequest = try RequestManager.shared.buildUrlRequest(request)
            request.config.requestPlugin.dataTask(for: request, urlRequest: urlRequest) { [weak self] response, responseObject, error in
                request.requestTotalCount = 1
                request.requestTotalTime = Date().timeIntervalSince1970 - startTime
                
                self?.handleResponse(request.requestIdentifier, response: response, responseObject: responseObject, error: error)
            }
        }
    }
    
    private func downloadTask(for request: HTTPRequest) throws {
        let urlRequest = try buildUrlRequest(request)
        
        let downloadPath = request.resumableDownloadPath ?? ""
        var downloadTargetPath: String = ""
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: downloadPath, isDirectory: &isDirectory) {
            isDirectory = false
        }
        if isDirectory.boolValue {
            let fileName = urlRequest.url?.lastPathComponent ?? ""
            downloadTargetPath = NSString.path(withComponents: [downloadPath, fileName])
        } else {
            downloadTargetPath = downloadPath
        }
        
        if FileManager.default.fileExists(atPath: downloadTargetPath) {
            try? FileManager.default.removeItem(atPath: downloadTargetPath)
        }
        
        var resumeSucceed = false
        if let localUrl = incompleteDownloadTempPath(for: request, downloadPath: downloadPath) {
            let resumeDataFileExists = FileManager.default.fileExists(atPath: localUrl.path)
            let data = try? Data(contentsOf: localUrl)
            let resumeDataIsValid = validateResumeData(data)
            
            if resumeDataFileExists && resumeDataIsValid {
                request.config.requestPlugin.downloadTask(for: request, urlRequest: nil, resumeData: data, destination: downloadTargetPath) { [weak self] response, filePath, error in
                    self?.handleResponse(request.requestIdentifier, response: response, responseObject: filePath, error: error)
                }
                resumeSucceed = request.requestTask != nil
            }
        }
        if !resumeSucceed {
            request.config.requestPlugin.downloadTask(for: request, urlRequest: urlRequest as URLRequest, resumeData: nil, destination: downloadTargetPath) { [weak self] response, filePath, error in
                self?.handleResponse(request.requestIdentifier, response: response, responseObject: filePath, error: error)
            }
        }
    }
    
    private func handleResponse(_ requestIdentifier: Int, response: URLResponse?, responseObject: Any?, error: Error?) {
        lock.lock()
        let request = requestsRecord[requestIdentifier]
        lock.unlock()
        guard let request = request else { return }
        
        var serializationError: Error?
        do {
            try request.config.requestPlugin.urlResponse(for: request, response: response, responseObject: responseObject)
        } catch let responseError {
            serializationError = responseError
        }
        
        var requestError: Error?
        var succeed = true
        if error != nil {
            succeed = false
            requestError = error
        } else if serializationError != nil {
            succeed = false
            requestError = serializationError
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
                try request.filterResponse()
            } catch let responseError {
                succeed = false
                requestError = responseError
            }
        }
        
        if succeed {
            let filters = request.config.requestFilters
            for filter in filters {
                do {
                    try filter.filterResponse(with: request)
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
            requestDidFail(request, error: requestError ?? RequestError.validationInvalidJSONFormat)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.removeRecord(for: request)
            request.clearCompletionBlock()
        }
    }
    
    private func validateResponse(_ request: HTTPRequest) throws {
        if !request.statusCodeValidator() {
            throw RequestError.validationInvalidStatusCode
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
            Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST SUCCEED===========\n%@%@ %@:\n%@", "✅ ", request.requestMethod().rawValue, request.requestUrl(), String.fw_safeString(request.responseJSONObject ?? request.responseString))
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
        }
    }
    
    private func requestDidFail(_ request: HTTPRequest, error: Error) {
        request.error = error
        #if DEBUG
        if request.config.debugLogEnabled {
            Logger.debug(group: Logger.fw_moduleName, "\n===========REQUEST FAILED===========\n%@%@ %@:\n%@", "❌ ", request.requestMethod().rawValue, request.requestUrl(), String.fw_safeString(request.responseJSONObject ?? request.error))
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
        }
    }
    
}
