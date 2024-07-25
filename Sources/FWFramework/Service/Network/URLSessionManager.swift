//
//  URLSessionManager.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

// MARK: - URLSessionManager
/// URLSession管理器
///
/// [AFNetworking](https://github.com/AFNetworking/AFNetworking)
open class URLSessionManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate, @unchecked Sendable {
    public static let networkingTaskDidResumeNotification = Notification.Name("site.wuyong.networking.task.resume")
    public static let networkingTaskDidCompleteNotification = Notification.Name("site.wuyong.networking.task.complete")
    public static let networkingTaskDidSuspendNotification = Notification.Name("site.wuyong.networking.task.suspend")
    public static let urlSessionDidInvalidateNotification = Notification.Name("site.wuyong.networking.session.invalidate")
    public static let urlSessionDownloadTaskDidMoveFileSuccessfullyNotification = Notification.Name("site.wuyong.networking.session.download.file-manager-succeed")
    public static let urlSessionDownloadTaskDidFailToMoveFileNotification = Notification.Name("site.wuyong.networking.session.download.file-manager-error")
    
    public static let networkingTaskDidCompleteResponseDataKey = "site.wuyong.networking.complete.finish.responsedata"
    public static let networkingTaskDidCompleteSerializedResponseKey = "site.wuyong.networking.task.complete.serializedresponse"
    public static let networkingTaskDidCompleteResponseSerializerKey = "site.wuyong.networking.task.complete.responseserializer"
    public static let networkingTaskDidCompleteAssetPathKey = "site.wuyong.networking.task.complete.assetpath"
    public static let networkingTaskDidCompleteErrorKey = "site.wuyong.networking.task.complete.error"
    public static let networkingTaskDidCompleteSessionTaskMetrics = "site.wuyong.networking.complete.sessiontaskmetrics"
    
    open private(set) lazy var session: URLSession = {
        return URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: self.operationQueue)
    }()
    open private(set) var operationQueue = OperationQueue()
    open var responseSerializer: HTTPResponseSerializer = JSONResponseSerializer()
    open var securityPolicy: SecurityPolicy = .default
    
    open var tasks: [URLSessionTask] {
        return tasks(for: "tasks")
    }
    open var dataTasks: [URLSessionDataTask] {
        return tasks(for: "dataTasks") as? [URLSessionDataTask] ?? []
    }
    open var uploadTasks: [URLSessionUploadTask] {
        return tasks(for: "uploadTasks") as? [URLSessionUploadTask] ?? []
    }
    open var downloadTasks: [URLSessionDownloadTask] {
        return tasks(for: "downloadTasks") as? [URLSessionDownloadTask] ?? []
    }
    
    open var completionQueue: DispatchQueue?
    open var completionGroup: DispatchGroup?
    
    open var sessionDidBecomeInvalid: ((_ session: URLSession, _ error: Error?) -> Void)?
    open var sessionDidReceiveAuthenticationChallenge: ((_ session: URLSession, _ challenge: URLAuthenticationChallenge, _ credential: inout URLCredential?) -> URLSession.AuthChallengeDisposition)?
    open var taskNeedNewBodyStream: ((_ session: URLSession, _ task: URLSessionTask) -> InputStream)?
    open var taskWillPerformHTTPRedirection: ((_ session: URLSession, _ task: URLSessionTask, _ response: URLResponse, _ request: URLRequest) -> URLRequest?)?
    open var authenticationChallengeHandler: ((_ session: URLSession, _ task: URLSessionTask, _ challenge: URLAuthenticationChallenge, _ completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Any?)?
    open var taskDidSendBodyData: ((_ session: URLSession, _ task: URLSessionTask, _ bytesSent: Int64, _ totalBytesSent: Int64, _ totalBytesExpectedToSend: Int64) -> Void)?
    open var taskDidComplete: ((_ session: URLSession, _ task: URLSessionTask, _ error: Error?) -> Void)?
    open var taskDidFinishCollectingMetrics: ((_ session: URLSession, _ task: URLSessionTask, _ metrics: URLSessionTaskMetrics?) -> Void)?
    open var dataTaskDidReceiveResponse: ((_ session: URLSession, _ task: URLSessionDataTask, _ response: URLResponse) -> URLSession.ResponseDisposition)?
    open var dataTaskDidBecomeDownloadTask: ((_ session: URLSession, _ dataTask: URLSessionDataTask, _ downloadTask: URLSessionDownloadTask) -> Void)?
    open var dataTaskDidReceiveData: ((_ session: URLSession, _ dataTask: URLSessionDataTask, _ data: Data) -> Void)?
    open var dataTaskWillCacheResponse: ((_ session: URLSession, _ dataTask: URLSessionDataTask, _ proposedResponse: CachedURLResponse) -> CachedURLResponse)?
    open var didFinishEventsForBackgroundURLSession: (@Sendable (_ session: URLSession) -> Void)?
    open var downloadTaskDidFinishDownloading: ((_ session: URLSession, _ downloadTask: URLSessionDownloadTask, _ location: URL) -> URL?)?
    open var downloadTaskDidWriteData: ((_ session: URLSession, _ downloadTask: URLSessionDownloadTask, _ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?
    open var downloadTaskDidResume: ((_ session: URLSession, _ downloadTask: URLSessionDownloadTask, _ fileOffset: Int64, _ expectedTotalBytes: Int64) -> Void)?
    
    private var sessionConfiguration: URLSessionConfiguration
    private var mutableTaskDelegates: [Int: URLSessionManagerTaskDelegate] = [:]
    private var lock = NSLock()
    private var taskDescriptionForSessionTasks: String {
        return String(format: "%p", self)
    }
    
    fileprivate static let urlSessionTaskDidResumeNotification = Notification.Name("site.wuyong.networking.nsurlsessiontask.resume")
    fileprivate static let urlSessionTaskDidSuspendNotification = Notification.Name("site.wuyong.networking.nsurlsessiontask.suspend")
    private static let urlSessionManagerLockName = "site.wuyong.networking.session.manager.lock"
    
    public convenience override init() {
        self.init(sessionConfiguration: nil)
    }
    
    public init(sessionConfiguration: URLSessionConfiguration?) {
        self.sessionConfiguration = sessionConfiguration ?? .default
        self.operationQueue.maxConcurrentOperationCount = 1
        self.lock.name = Self.urlSessionManagerLockName
        super.init()
        
        self.session.getTasksWithCompletionHandler { [weak self] dataTasks, uploadTasks, downloadTasks in
            for dataTask in dataTasks {
                self?.addDelegate(for: dataTask, uploadProgress: nil, downloadProgress: nil, completionHandler: nil)
            }
            
            for uploadTask in uploadTasks {
                self?.addDelegate(for: uploadTask, progress: nil, completionHandler: nil)
            }
            
            for downloadTask in downloadTasks {
                self?.addDelegate(for: downloadTask, progress: nil, destination: nil, completionHandler: nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open func invalidateSessionCancelingTasks(_ cancelPendingTasks: Bool, resetSession: Bool) {
        if cancelPendingTasks {
            self.session.invalidateAndCancel()
        } else {
            self.session.finishTasksAndInvalidate()
        }
        
        if resetSession {
            self.session = URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: self.operationQueue)
        }
    }
    
    open func dataTask(
        request: URLRequest,
        uploadProgress: ((Progress) -> Void)? = nil,
        downloadProgress: ((Progress) -> Void)? = nil,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionDataTask {
        let dataTask = session.dataTask(with: request)
        addDelegate(for: dataTask, uploadProgress: uploadProgress, downloadProgress: downloadProgress, completionHandler: completionHandler)
        return dataTask
    }
    
    open func uploadTask(
        request: URLRequest,
        fromFile fileURL: URL,
        progress: ((Progress) -> Void)? = nil,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionUploadTask {
        let uploadTask = session.uploadTask(with: request, fromFile: fileURL)
        addDelegate(for: uploadTask, progress: progress, completionHandler: completionHandler)
        return uploadTask
    }
    
    open func uploadTask(
        request: URLRequest,
        fromData bodyData: Data,
        progress: ((Progress) -> Void)? = nil,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionUploadTask {
        let uploadTask = session.uploadTask(with: request, from: bodyData)
        addDelegate(for: uploadTask, progress: progress, completionHandler: completionHandler)
        return uploadTask
    }
    
    open func uploadTask(
        streamedRequest: URLRequest,
        progress: ((Progress) -> Void)? = nil,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionUploadTask {
        let uploadTask = session.uploadTask(withStreamedRequest: streamedRequest)
        addDelegate(for: uploadTask, progress: progress, completionHandler: completionHandler)
        return uploadTask
    }
    
    open func downloadTask(
        request: URLRequest,
        progress: ((Progress) -> Void)? = nil,
        destination: ((_ targetPath: URL, _ response: URLResponse) -> URL)? = nil,
        completionHandler: ((_ response: URLResponse, _ filePath: URL?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionDownloadTask {
        let downloadTask = session.downloadTask(with: request)
        addDelegate(for: downloadTask, progress: progress, destination: destination, completionHandler: completionHandler)
        return downloadTask
    }
    
    open func downloadTask(
        resumeData: Data,
        progress: ((Progress) -> Void)? = nil,
        destination: ((_ targetPath: URL, _ response: URLResponse) -> URL)? = nil,
        completionHandler: ((_ response: URLResponse, _ filePath: URL?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionDownloadTask {
        let downloadTask = session.downloadTask(withResumeData: resumeData)
        addDelegate(for: downloadTask, progress: progress, destination: destination, completionHandler: completionHandler)
        return downloadTask
    }
    
    open func uploadProgress(for task: URLSessionTask) -> Progress? {
        return delegate(for: task)?.uploadProgress
    }
    
    open func downloadProgress(for task: URLSessionTask) -> Progress? {
        return delegate(for: task)?.downloadProgress
    }
    
    open func setUserInfo(_ userInfo: [AnyHashable: Any]?, for task: URLSessionTask) {
        task.fw.setPropertyCopy(userInfo, forName: "userInfo")
    }
    
    open func userInfo(for task: URLSessionTask) -> [AnyHashable: Any]? {
        return task.fw.property(forName: "userInfo") as? [AnyHashable: Any]
    }
    
    @objc private func taskDidResume(_ notification: Notification) {
        guard let task = notification.object as? URLSessionTask else { return }
        if task.taskDescription == taskDescriptionForSessionTasks {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: URLSessionManager.networkingTaskDidResumeNotification, object: task)
            }
        }
    }
    
    @objc private func taskDidSuspend(_ notification: Notification) {
        guard let task = notification.object as? URLSessionTask else { return }
        if task.taskDescription == taskDescriptionForSessionTasks {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: URLSessionManager.networkingTaskDidSuspendNotification, object: task)
            }
        }
    }
    
    private func delegate(for task: URLSessionTask) -> URLSessionManagerTaskDelegate? {
        var delegate: URLSessionManagerTaskDelegate?
        lock.lock()
        delegate = mutableTaskDelegates[task.taskIdentifier]
        lock.unlock()
        return delegate
    }
    
    private func setDelegate(_ delegate: URLSessionManagerTaskDelegate, for task: URLSessionTask) {
        lock.lock()
        mutableTaskDelegates[task.taskIdentifier] = delegate
        addNotificationObserver(for: task)
        lock.unlock()
    }
    
    private func addDelegate(
        for dataTask: URLSessionDataTask,
        uploadProgress: ((Progress) -> Void)?,
        downloadProgress: ((Progress) -> Void)?,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)?
    ) {
        let delegate = URLSessionManagerTaskDelegate(task: dataTask)
        delegate.manager = self
        delegate.completionHandler = completionHandler
        
        dataTask.taskDescription = taskDescriptionForSessionTasks
        self.setDelegate(delegate, for: dataTask)
        
        delegate.uploadProgressBlock = uploadProgress
        delegate.downloadProgressBlock = downloadProgress
    }
    
    private func addDelegate(
        for uploadTask: URLSessionUploadTask,
        progress: ((Progress) -> Void)?,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)?
    ) {
        let delegate = URLSessionManagerTaskDelegate(task: uploadTask)
        delegate.manager = self
        delegate.completionHandler = completionHandler
        
        uploadTask.taskDescription = taskDescriptionForSessionTasks
        self.setDelegate(delegate, for: uploadTask)
        
        delegate.uploadProgressBlock = progress
    }
    
    private func addDelegate(
        for downloadTask: URLSessionDownloadTask,
        progress: ((Progress) -> Void)?,
        destination: ((_ targetPath: URL, _ response: URLResponse) -> URL)?,
        completionHandler: ((_ response: URLResponse, _ filePath: URL?, _ error: Error?) -> Void)?
    ) {
        let delegate = URLSessionManagerTaskDelegate(task: downloadTask)
        delegate.manager = self
        delegate.completionHandler = completionHandler != nil ? { response, responseObject, error in
            completionHandler?(response, responseObject as? URL, error)
        } : nil
        
        if let destination = destination {
            delegate.downloadTaskDidFinishDownloading = { session, task, location in
                return destination(location, task.response ?? HTTPURLResponse())
            }
        }
        
        downloadTask.taskDescription = taskDescriptionForSessionTasks
        self.setDelegate(delegate, for: downloadTask)
        
        delegate.downloadProgressBlock = progress
    }
    
    private func removeDelegate(for task: URLSessionTask) {
        lock.lock()
        removeNotificationObserver(for: task)
        mutableTaskDelegates.removeValue(forKey: task.taskIdentifier)
        lock.unlock()
    }
    
    private func tasks(for keyPath: String) -> [URLSessionTask] {
        let sendableTasks = SendableObject<[URLSessionTask]>([])
        let semaphore = DispatchSemaphore(value: 0)
        session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            if keyPath == "dataTasks" {
                sendableTasks.object = dataTasks
            } else if keyPath == "uploadTasks" {
                sendableTasks.object = uploadTasks
            } else if keyPath == "downloadTasks" {
                sendableTasks.object = downloadTasks
            } else if keyPath == "tasks" {
                sendableTasks.object = dataTasks + uploadTasks + downloadTasks
            }
            
            semaphore.signal()
        }
        semaphore.wait()
        
        return sendableTasks.object
    }
    
    private func addNotificationObserver(for task: URLSessionTask) {
        NotificationCenter.default.addObserver(self, selector: #selector(taskDidResume(_:)), name: Self.urlSessionTaskDidResumeNotification, object: task)
        NotificationCenter.default.addObserver(self, selector: #selector(taskDidSuspend(_:)), name: Self.urlSessionTaskDidSuspendNotification, object: task)
    }
    
    private func removeNotificationObserver(for task: URLSessionTask) {
        NotificationCenter.default.removeObserver(self, name: Self.urlSessionTaskDidSuspendNotification, object: task)
        NotificationCenter.default.removeObserver(self, name: Self.urlSessionTaskDidResumeNotification, object: task)
    }
    
    // MARK: - URLSessionDelegate
    open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        sessionDidBecomeInvalid?(session, error)
        
        NotificationCenter.default.post(name: Self.urlSessionDidInvalidateNotification, object: session)
    }
    
    open func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        assert(sessionDidReceiveAuthenticationChallenge != nil, "`respondsToSelector:` implementation forces `URLSession:didReceiveChallenge:completionHandler:` to be called only if `self.sessionDidReceiveAuthenticationChallenge` is not nil")
        
        var credential: URLCredential?
        let disposition = sessionDidReceiveAuthenticationChallenge?(session, challenge, &credential)
        completionHandler(disposition ?? .performDefaultHandling, credential)
    }
    
    // MARK: - URLSessionTaskDelegate
    open func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        var redirectRequest: URLRequest? = request
        if taskWillPerformHTTPRedirection != nil {
            redirectRequest = taskWillPerformHTTPRedirection?(session, task, response, request)
        }
        completionHandler(redirectRequest)
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var evaluateServerTrust = false
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        if authenticationChallengeHandler != nil {
            let result = authenticationChallengeHandler!(session, task, challenge, completionHandler)
            if result == nil {
                return
            } else if let resultError = result as? Error {
                task.fw.setProperty(resultError, forName: "authenticationChallengeError")
                disposition = .cancelAuthenticationChallenge
            } else if let resultCredential = result as? URLCredential {
                credential = resultCredential
                disposition = .useCredential
            } else if let resultDisposition = result as? URLSession.AuthChallengeDisposition {
                disposition = resultDisposition
                assert(disposition == .performDefaultHandling || disposition == .cancelAuthenticationChallenge || disposition == .rejectProtectionSpace, "")
                evaluateServerTrust = disposition == .performDefaultHandling && challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
            } else {
                assert(false, "The return value from the authentication challenge handler must be nil, an Error, an URLCredential or an AuthChallengeDisposition.")
            }
        } else {
            evaluateServerTrust = challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
        }
        
        if evaluateServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust, securityPolicy.evaluateServerTrust(serverTrust, forDomain: challenge.protectionSpace.host) {
                disposition = .useCredential
                credential = URLCredential(trust: serverTrust)
            } else {
                task.fw.setProperty(serverTrustError(for: challenge.protectionSpace.serverTrust, url: task.currentRequest?.url), forName: "authenticationChallengeError")
                disposition = .cancelAuthenticationChallenge
            }
        }
        
        completionHandler(disposition, credential)
    }
    
    private func serverTrustError(for serverTrust: SecTrust?, url: URL?) -> Error {
        let CFNetworkBundle = Bundle(identifier: "com.apple.CFNetwork")
        let defaultValue = "The certificate for this server is invalid. You might be connecting to a server that is pretending to be “%@” which could put your confidential information at risk."
        let descriptionFormat = NSLocalizedString("Err-1202.w", tableName: nil, bundle: CFNetworkBundle ?? .main, value: defaultValue, comment: "")
        let localizedDescription = descriptionFormat.components(separatedBy: "%@").count <= 2 ? String.localizedStringWithFormat(descriptionFormat, url?.host ?? "") : descriptionFormat
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: localizedDescription
        ]

        if let serverTrust = serverTrust {
            userInfo[NSURLErrorFailingURLPeerTrustErrorKey] = serverTrust
        }

        if let url = url {
            userInfo[NSURLErrorFailingURLErrorKey] = url
            userInfo[NSURLErrorFailingURLStringErrorKey] = url.absoluteString
        }

        return NSError(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted, userInfo: userInfo)
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        var inputStream: InputStream?
        
        if taskNeedNewBodyStream != nil {
            inputStream = taskNeedNewBodyStream?(session, task)
        } else if let bodyStream = task.originalRequest?.httpBodyStream {
            inputStream = bodyStream.copy() as? InputStream
        }
        
        completionHandler(inputStream)
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        var totalUnitCount = totalBytesExpectedToSend
        if totalUnitCount == NSURLSessionTransferSizeUnknown {
            let contentLength = task.originalRequest?.value(forHTTPHeaderField: "Content-Length")
            if let contentLength = contentLength {
                totalUnitCount = Int64(contentLength) ?? .zero
            }
        }
        
        let delegate = delegate(for: task)
        delegate?.urlSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        
        taskDidSendBodyData?(session, task, bytesSent, totalBytesSent, totalUnitCount)
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let delegate = delegate(for: task)
        if delegate != nil {
            delegate?.urlSession(session, task: task, didCompleteWithError: error)
            
            removeDelegate(for: task)
        }
        
        taskDidComplete?(session, task, error)
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let delegate = delegate(for: task)
        delegate?.urlSession(session, task: task, didFinishCollecting: metrics)
        
        taskDidFinishCollectingMetrics?(session, task, metrics)
    }
    
    // MARK: - URLSessionDataDelegate
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        var disposition: URLSession.ResponseDisposition = .allow
        if dataTaskDidReceiveResponse != nil {
            disposition = dataTaskDidReceiveResponse!(session, dataTask, response)
        }
        completionHandler(disposition)
    }
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        let delegate = delegate(for: dataTask)
        if let delegate = delegate {
            removeDelegate(for: dataTask)
            setDelegate(delegate, for: downloadTask)
        }
        
        dataTaskDidBecomeDownloadTask?(session, dataTask, downloadTask)
    }
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let delegate = delegate(for: dataTask)
        delegate?.urlSession(session, dataTask: dataTask, didReceive: data)
        
        dataTaskDidReceiveData?(session, dataTask, data)
    }
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        var cachedResponse = proposedResponse
        if dataTaskWillCacheResponse != nil {
            cachedResponse = dataTaskWillCacheResponse!(session, dataTask, proposedResponse)
        }
        completionHandler(cachedResponse)
    }
    
    open func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let block = didFinishEventsForBackgroundURLSession {
            DispatchQueue.main.async {
                block(session)
            }
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let delegate = delegate(for: downloadTask)
        if downloadTaskDidFinishDownloading != nil {
            let fileURL = downloadTaskDidFinishDownloading!(session, downloadTask, location)
            if let fileURL = fileURL {
                delegate?.downloadFileURL = fileURL
                
                do {
                    try FileManager.default.moveItem(at: location, to: fileURL)
                    NotificationCenter.default.post(name: Self.urlSessionDownloadTaskDidMoveFileSuccessfullyNotification, object: downloadTask, userInfo: nil)
                } catch {
                    NotificationCenter.default.post(name: Self.urlSessionDownloadTaskDidFailToMoveFileNotification, object: downloadTask, userInfo: (error as NSError).userInfo)
                }
                
                return
            }
        }
        
        delegate?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }
    
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let delegate = delegate(for: downloadTask)
        delegate?.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        
        downloadTaskDidWriteData?(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        let delegate = delegate(for: downloadTask)
        delegate?.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
        
        downloadTaskDidResume?(session, downloadTask, fileOffset, expectedTotalBytes)
    }
    
    // MARK: - NSObject
    open override var description: String {
        return String(format: "<%@: %p, session: %@, operationQueue: %@>", NSStringFromClass(type(of: self)), self, self.session, self.operationQueue)
    }
    
    open override func responds(to selector: Selector!) -> Bool {
        if selector == #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:)) {
            return sessionDidReceiveAuthenticationChallenge != nil
        } else if selector == #selector(URLSessionTaskDelegate.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)) {
            return taskWillPerformHTTPRedirection != nil
        } else if selector == #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:)) {
            return dataTaskDidReceiveResponse != nil
        } else if selector == #selector(URLSessionDataDelegate.urlSession(_:dataTask:willCacheResponse:completionHandler:)) {
            return dataTaskWillCacheResponse != nil
        } else if selector == #selector(URLSessionDataDelegate.urlSessionDidFinishEvents(forBackgroundURLSession:)) {
            return didFinishEventsForBackgroundURLSession != nil
        }
        
        return type(of: self).instancesRespond(to: selector)
    }
}

// MARK: - URLSessionManagerTaskDelegate
fileprivate class URLSessionManagerTaskDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate, @unchecked Sendable {
    static let processingQueue = DispatchQueue(label: "site.wuyong.networking.session.manager.processing", attributes: .concurrent)
    static let completionGroup = DispatchGroup()
    
    weak var manager: URLSessionManager?
    private var mutableData: Data = Data()
    var uploadProgress = Progress(parent: nil, userInfo: nil)
    var downloadProgress = Progress(parent: nil, userInfo: nil)
    var downloadFileURL: URL?
    private var sessionTaskMetrics: URLSessionTaskMetrics?
    var downloadTaskDidFinishDownloading: ((_ session: URLSession, _ downloadTask: URLSessionDownloadTask, _ location: URL) -> URL?)?
    var uploadProgressBlock: ((Progress) -> Void)?
    var downloadProgressBlock: ((Progress) -> Void)?
    var completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)?
    
    init(task: URLSessionTask) {
        super.init()
        
        for progress in [uploadProgress, downloadProgress] {
            progress.totalUnitCount = NSURLSessionTransferSizeUnknown
            progress.isCancellable = true
            progress.cancellationHandler = { [weak task] in
                task?.cancel()
            }
            progress.isPausable = true
            progress.pausingHandler = { [weak task] in
                task?.suspend()
            }
            progress.resumingHandler = { [weak task] in
                task?.resume()
            }
            
            progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: nil)
        }
    }
    
    deinit {
        downloadProgress.removeObserver(self, forKeyPath: "fractionCompleted")
        uploadProgress.removeObserver(self, forKeyPath: "fractionCompleted")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let progress = object as? Progress {
            if progress == downloadProgress {
                downloadProgressBlock?(progress)
            } else if progress == uploadProgress {
                uploadProgressBlock?(progress)
            }
        }
    }
    
    // MARK: - URLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let error = (task.fw.property(forName: "authenticationChallengeError") as? Error) ?? error
        let manager = self.manager
        let sendableResponseObject = SendableObject<Any?>(nil)
        
        let sendableUserInfo = SendableObject<[AnyHashable: Any]>([:])
        sendableUserInfo.object[URLSessionManager.networkingTaskDidCompleteResponseSerializerKey] = manager?.responseSerializer
        
        let data = mutableData
        mutableData = Data()
        
        if let sessionTaskMetrics = sessionTaskMetrics {
            sendableUserInfo.object[URLSessionManager.networkingTaskDidCompleteSessionTaskMetrics] = sessionTaskMetrics
        }
        if let downloadFileURL = downloadFileURL {
            sendableUserInfo.object[URLSessionManager.networkingTaskDidCompleteAssetPathKey] = downloadFileURL
        } else {
            sendableUserInfo.object[URLSessionManager.networkingTaskDidCompleteResponseDataKey] = data
        }
        
        if let error = error {
            sendableUserInfo.object[URLSessionManager.networkingTaskDidCompleteErrorKey] = error
            
            let queue = manager?.completionQueue ?? .main
            let group = manager?.completionGroup ?? Self.completionGroup
            queue.async(group: group) {
                self.completionHandler?(task.response ?? HTTPURLResponse(), sendableResponseObject.object, error)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: URLSessionManager.networkingTaskDidCompleteNotification, object: task, userInfo: sendableUserInfo.object)
                }
            }
        } else {
            Self.processingQueue.async {
                let taskInfo = manager?.userInfo(for: task)
                if taskInfo != nil, let response = task.response {
                    manager?.responseSerializer.setUserInfo(taskInfo, for: response)
                }
                
                var serializationError: Error?
                do {
                    sendableResponseObject.object = try manager?.responseSerializer.responseObject(for: task.response, data: data)
                } catch let decodeError {
                    serializationError = decodeError
                }
                
                if self.downloadFileURL != nil {
                    sendableResponseObject.object = self.downloadFileURL
                }
                if sendableResponseObject.object != nil {
                    sendableUserInfo.object[URLSessionManager.networkingTaskDidCompleteSerializedResponseKey] = sendableResponseObject.object
                }
                if serializationError != nil {
                    sendableUserInfo.object[URLSessionManager.networkingTaskDidCompleteErrorKey] = serializationError
                }
                
                let queue = manager?.completionQueue ?? .main
                let group = manager?.completionGroup ?? Self.completionGroup
                let responseError = serializationError
                queue.async(group: group) {
                    self.completionHandler?(task.response ?? HTTPURLResponse(), sendableResponseObject.object, responseError)
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: URLSessionManager.networkingTaskDidCompleteNotification, object: task, userInfo: sendableUserInfo.object)
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        sessionTaskMetrics = metrics
    }
    
    // MARK: - URLSessionDataDelegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        downloadProgress.totalUnitCount = dataTask.countOfBytesExpectedToReceive
        downloadProgress.completedUnitCount = dataTask.countOfBytesReceived
        
        mutableData.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        uploadProgress.totalUnitCount = task.countOfBytesExpectedToSend
        uploadProgress.completedUnitCount = task.countOfBytesSent
    }
    
    // MARK: - URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        downloadProgress.totalUnitCount = totalBytesExpectedToWrite
        downloadProgress.completedUnitCount = totalBytesWritten
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        downloadProgress.totalUnitCount = expectedTotalBytes
        downloadProgress.completedUnitCount = fileOffset
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        downloadFileURL = nil
        
        if downloadTaskDidFinishDownloading != nil {
            downloadFileURL = downloadTaskDidFinishDownloading?(session, downloadTask, location)
            if let downloadFileURL = downloadFileURL {
                
                do {
                    try FileManager.default.moveItem(at: location, to: downloadFileURL)
                    NotificationCenter.default.post(name: URLSessionManager.urlSessionDownloadTaskDidMoveFileSuccessfullyNotification, object: downloadTask, userInfo: nil)
                } catch let fileManagerError {
                    NotificationCenter.default.post(name: URLSessionManager.urlSessionDownloadTaskDidFailToMoveFileNotification, object: downloadTask, userInfo: (fileManagerError as NSError).userInfo)
                }
            }
        }
    }
}

// MARK: - URLSessionTaskSwizzling
fileprivate class URLSessionTaskSwizzling: NSObject {
    static func swizzleURLSessionTask() {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        let localDataTask = session.dataTask(with: URLRequest(url: URL()))
        var originalResumeIMP: IMP?
        if let method = class_getInstanceMethod(self, #selector(af_resume)) {
            originalResumeIMP = method_getImplementation(method)
        }
        var currentClass: AnyClass? = type(of: localDataTask)
        
        while let classResumeMethod = class_getInstanceMethod(currentClass, NSSelectorFromString("resume")) {
            let superClass: AnyClass? = currentClass?.superclass()
            let classResumeIMP = method_getImplementation(classResumeMethod)
            let superclassResumeMethod = class_getInstanceMethod(superClass, NSSelectorFromString("resume"))
            let superclassResumeIMP = superclassResumeMethod != nil ? method_getImplementation(superclassResumeMethod!) : nil
            if classResumeIMP != superclassResumeIMP, originalResumeIMP != classResumeIMP {
                swizzleResumeAndSuspendMethod(for: currentClass)
            }
            currentClass = superClass
        }
        
        localDataTask.cancel()
        session.finishTasksAndInvalidate()
    }
    
    private static func swizzleResumeAndSuspendMethod(for theClass: AnyClass?) {
        let resumeMethod = class_getInstanceMethod(self, #selector(af_resume))
        let suspendMethod = class_getInstanceMethod(self, #selector(af_suspend))
        
        if let resumeMethod = resumeMethod, addMethod(for: theClass, selector: #selector(af_resume), method: resumeMethod) {
            swizzleSelector(for: theClass, originalSelector: NSSelectorFromString("resume"), swizzledSelector: #selector(af_resume))
        }
        if let suspendMethod = suspendMethod, addMethod(for: theClass, selector: #selector(af_suspend), method: suspendMethod) {
            swizzleSelector(for: theClass, originalSelector: NSSelectorFromString("suspend"), swizzledSelector: #selector(af_suspend))
        }
    }
    
    private static func swizzleSelector(for theClass: AnyClass?, originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(theClass, originalSelector)
        let swizzledMethod = class_getInstanceMethod(theClass, swizzledSelector)
        if let originalMethod = originalMethod,
           let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    private static func addMethod(for theClass: AnyClass?, selector: Selector, method: Method) -> Bool {
        return class_addMethod(theClass, selector, method_getImplementation(method), method_getTypeEncoding(method))
    }
    
    @objc dynamic var state: URLSessionTask.State {
        assert(false, "State method should never be called in the actual dummy class")
        return .canceling
    }
    
    @objc dynamic func af_resume() {
        assert(responds(to: #selector(getter: state)), "Does not respond to state")
        let state = self.state
        self.af_resume()
        
        if state != .running {
            NotificationCenter.default.post(name: URLSessionManager.urlSessionTaskDidResumeNotification, object: self)
        }
    }
    
    @objc dynamic func af_suspend() {
        assert(responds(to: #selector(getter: state)), "Does not respond to state")
        let state = self.state
        self.af_suspend()
        
        if state != .suspended {
            NotificationCenter.default.post(name: URLSessionManager.urlSessionTaskDidSuspendNotification, object: self)
        }
    }
}

// MARK: - FrameworkAutoloader+Network
extension FrameworkAutoloader {
    
    @objc static func loadService_Network() {
        URLSessionTaskSwizzling.swizzleURLSessionTask()
    }
    
}
