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
open class URLSessionManager: NSObject, NSCopying, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
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
    
    open private(set) var session: URLSession
    open private(set) var operationQueue = OperationQueue()
    open var responseSerializer: URLResponseSerialization = JSONResponseSerializer()
    open var securityPolicy: SecurityPolicy = .default()
    
    open private(set) var tasks: [URLSessionTask] = []
    open private(set) var dataTasks: [URLSessionDataTask] = []
    open private(set) var uploadTasks: [URLSessionUploadTask] = []
    open private(set) var downloadTasks: [URLSessionDownloadTask] = []
    
    open var completionQueue: DispatchQueue?
    open var completionGroup: DispatchGroup?
    
    open var sessionDidBecomeInvalid: ((_ session: URLSession, _ error: Error) -> Void)?
    open var sessionDidReceiveAuthenticationChallenge: ((_ session: URLSession, _ challenge: URLAuthenticationChallenge, _ credential: inout URLCredential?) -> URLSession.AuthChallengeDisposition)?
    open var taskNeedNewBodyStream: ((_ session: URLSession, _ task: URLSessionTask) -> InputStream)?
    open var taskWillPerformHTTPRedirection: ((_ session: URLSession, _ task: URLSessionTask, _ response: URLResponse, _ request: URLRequest) -> URLRequest?)?
    open var authenticationChallengeHandler: ((_ session: URLSession, _ task: URLSessionTask, _ challenge: URLAuthenticationChallenge, _ completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Any)?
    open var taskDidSendBodyData: ((_ session: URLSession, _ task: URLSessionTask, _ bytesSent: Int64, _ totalBytesSent: Int64, _ totalBytesExpectedToSend: Int64) -> Void)?
    open var taskDidComplete: ((_ session: URLSession, _ task: URLSessionTask, _ error: Error?) -> Void)?
    open var taskDidFinishCollectingMetrics: ((_ session: URLSession, _ task: URLSessionTask, _ metrics: URLSessionTaskMetrics?) -> Void)?
    open var dataTaskDidReceiveResponse: ((_ session: URLSession, _ task: URLSessionDataTask, _ response: URLResponse) -> URLSession.ResponseDisposition)?
    open var dataTaskDidBecomeDownloadTask: ((_ session: URLSession, _ dataTask: URLSessionDataTask, _ downloadTask: URLSessionDownloadTask) -> Void)?
    open var dataTaskDidReceiveData: ((_ session: URLSession, _ dataTask: URLSessionDataTask, _ data: Data) -> Void)?
    open var dataTaskWillCacheResponse: ((_ session: URLSession, _ dataTask: URLSessionDataTask, _ proposedResponse: CachedURLResponse) -> CachedURLResponse)?
    open var didFinishEventsForBackgroundURLSession: ((_ session: URLSession) -> Void)?
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
    
    public required init(sessionConfiguration: URLSessionConfiguration? = nil) {
        super.init()
        
        self.sessionConfiguration = sessionConfiguration ?? .default
        self.operationQueue.maxConcurrentOperationCount = 1
        self.lock.name = Self.urlSessionManagerLockName
        self.session = URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: self.operationQueue)
        
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
        
    }
    
    open func dataTask(
        request: URLRequest,
        uploadProgress: ((Progress) -> Void)? = nil,
        downloadProgress: ((Progress) -> Void)? = nil,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionDataTask {
        
    }
    
    open func uploadTask(
        request: URLRequest,
        fromFile fileURL: URL,
        progress: ((Progress) -> Void)? = nil,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionUploadTask {
        
    }
    
    open func uploadTask(
        request: URLRequest,
        fromData bodyData: Data?,
        progress: ((Progress) -> Void)? = nil,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionUploadTask {
        
    }
    
    open func uploadTask(
        streamedRequest: URLRequest,
        progress: ((Progress) -> Void)? = nil,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionUploadTask {
        
    }
    
    open func downloadTask(
        request: URLRequest,
        progress: ((Progress) -> Void)? = nil,
        destination: ((_ targetPath: URL, _ response: URLResponse) -> URL)? = nil,
        completionHandler: ((_ response: URLResponse, _ filePath: URL?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionDownloadTask {
        
    }
    
    open func downloadTask(
        resumeData: Data,
        progress: ((Progress) -> Void)? = nil,
        destination: ((_ targetPath: URL, _ response: URLResponse) -> URL)? = nil,
        completionHandler: ((_ response: URLResponse, _ filePath: URL?, _ error: Error?) -> Void)? = nil
    ) -> URLSessionDownloadTask {
        
    }
    
    open func uploadProgress(for task: URLSessionTask) -> Progress? {
        return delegate(for: task)?.uploadProgress
    }
    
    open func downloadProgress(for task: URLSessionTask) -> Progress? {
        return delegate(for: task)?.downloadProgress
    }
    
    open func setUserInfo(_ userInfo: [AnyHashable: Any]?, for task: URLSessionTask) {
        task.fw_setPropertyCopy(userInfo, forName: "userInfo")
    }
    
    open func userInfo(for task: URLSessionTask) -> [AnyHashable: Any]? {
        return task.fw_property(forName: "userInfo") as? [AnyHashable: Any]
    }
    
    @objc private func taskDidResume(_ notification: Notification) {
        
    }
    
    @objc private func taskDidSuspend(_ notification: Notification) {
        
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
        
    }
    
    private func addDelegate(
        for uploadTask: URLSessionUploadTask,
        progress: ((Progress) -> Void)?,
        completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)?
    ) {
        
    }
    
    private func addDelegate(
        for downloadTask: URLSessionDownloadTask,
        progress: ((Progress) -> Void)?,
        destination: ((_ targetPath: URL, _ response: URLResponse) -> URL)?,
        completionHandler: ((_ response: URLResponse, _ filePath: URL?, _ error: Error?) -> Void)?
    ) {
        
    }
    
    private func removeDelegate(for task: URLSessionTask) {
        
    }
    
    private func tasks(for keyPath: String) -> [URLSessionTask] {
        
    }
    
    private func addNotificationObserver(for task: URLSessionTask) {
        
    }
    
    private func removeNotificationObserver(for task: URLSessionTask) {
        
    }
    
    // MARK: - URLSessionDelegate
    
    // MARK: - URLSessionTaskDelegate
    
    // MARK: - URLSessionDataDelegate
    
    // MARK: - URLSessionDownloadDelegate
    
    // MARK: - NSObject
    open override var description: String {
        return String(format: "<%@: %p, session: %@, operationQueue: %@>", NSStringFromClass(self.classForCoder), self, self.session, self.operationQueue)
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
        
        return self.classForCoder.instancesRespond(to: selector)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return Self.init(sessionConfiguration: self.session.configuration)
    }
}

// MARK: - URLSessionManagerTaskDelegate
fileprivate class URLSessionManagerTaskDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    static let processingQueue = DispatchQueue(label: "site.wuyong.networking.session.manager.processing", attributes: .concurrent)
    static let completionGroup = DispatchGroup()
    
    weak var manager: URLSessionManager?
    private var mutableData: Data? = Data()
    var uploadProgress = Progress(parent: nil, userInfo: nil)
    var downloadProgress = Progress(parent: nil, userInfo: nil)
    private var downloadFileURL: URL?
    private var sessionTaskMetrics: URLSessionTaskMetrics?
    private var downloadTaskDidFinishDownloading: ((_ session: URLSession, _ downloadTask: URLSessionDownloadTask, _ location: URL) -> URL?)?
    private var uploadProgressBlock: ((Progress) -> Void)?
    private var downloadProgressBlock: ((Progress) -> Void)?
    private var completionHandler: ((_ response: URLResponse, _ responseObject: Any?, _ error: Error?) -> Void)?
    
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
        let error = (task.fw_property(forName: "authenticationChallengeError") as? Error) ?? error
        let manager = self.manager
        var responseObject: Any?
        
        var userInfo: [AnyHashable: Any] = [:]
        userInfo[URLSessionManager.networkingTaskDidCompleteResponseSerializerKey] = manager?.responseSerializer
        
        var data: Data?
        if mutableData != nil {
            data = mutableData
            mutableData = nil
        }
        
        if let sessionTaskMetrics = sessionTaskMetrics {
            userInfo[URLSessionManager.networkingTaskDidCompleteSessionTaskMetrics] = sessionTaskMetrics
        }
        if let downloadFileURL = downloadFileURL {
            userInfo[URLSessionManager.networkingTaskDidCompleteAssetPathKey] = downloadFileURL
        } else if let data = data {
            userInfo[URLSessionManager.networkingTaskDidCompleteResponseDataKey] = data
        }
        
        if let error = error {
            userInfo[URLSessionManager.networkingTaskDidCompleteErrorKey] = error
            
            let queue = manager?.completionQueue ?? .main
            let group = manager?.completionGroup ?? Self.completionGroup
            queue.async(group: group) {
                self.completionHandler?(task.response ?? HTTPURLResponse(), responseObject, error)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: URLSessionManager.networkingTaskDidCompleteNotification, object: task, userInfo: userInfo)
                }
            }
        } else {
            Self.processingQueue.async {
                let taskInfo = manager?.userInfo(for: task)
                if taskInfo != nil, task.response != nil, let responseSerializer = manager?.responseSerializer as? HTTPResponseSerializer {
                    responseSerializer.setUserInfo(taskInfo, for: task.response)
                }
                
                var serializationError: Error?
                responseObject = manager?.responseSerializer.responseObject(for: task.response, data: data, error: &serializationError)
                
                if self.downloadFileURL != nil {
                    responseObject = self.downloadFileURL
                }
                if responseObject != nil {
                    userInfo[URLSessionManager.networkingTaskDidCompleteSerializedResponseKey] = responseObject
                }
                if serializationError != nil {
                    userInfo[URLSessionManager.networkingTaskDidCompleteErrorKey] = serializationError
                }
                
                let queue = manager?.completionQueue ?? .main
                let group = manager?.completionGroup ?? Self.completionGroup
                queue.async(group: group) {
                    self.completionHandler?(task.response ?? HTTPURLResponse(), responseObject, serializationError)
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: URLSessionManager.networkingTaskDidCompleteNotification, object: task, userInfo: userInfo)
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
        
        mutableData?.append(data)
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
        let localDataTask = session.dataTask(with: URLRequest(url: NSURL() as URL))
        var originalResumeIMP: IMP?
        if let method = class_getInstanceMethod(self, #selector(af_resume)) {
            originalResumeIMP = method_getImplementation(method)
        }
        var currentClass: AnyClass? = localDataTask.classForCoder
        
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
    
    @objc var state: URLSessionTask.State {
        assert(false, "State method should never be called in the actual dummy class")
        return .canceling
    }
    
    @objc func af_resume() {
        assert(responds(to: #selector(getter: state)), "Does not respond to state")
        let state = self.state
        self.af_resume()
        
        if state != .running {
            NotificationCenter.default.post(name: URLSessionManager.urlSessionTaskDidResumeNotification, object: self)
        }
    }
    
    @objc func af_suspend() {
        assert(responds(to: #selector(getter: state)), "Does not respond to state")
        let state = self.state
        self.af_suspend()
        
        if state != .suspended {
            NotificationCenter.default.post(name: URLSessionManager.urlSessionTaskDidSuspendNotification, object: self)
        }
    }
}

// MARK: - FrameworkAutoloader+Network
@objc extension FrameworkAutoloader {
    
    static func loadService_Network() {
        URLSessionTaskSwizzling.swizzleURLSessionTask()
    }
    
}
