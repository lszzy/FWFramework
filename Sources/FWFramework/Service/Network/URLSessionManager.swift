//
//  URLSessionManager.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

/*
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
    open private(set) var operationQueue: OperationQueue
    open var responseSerializer: URLResponseSerialization
    open var securityPolicy: SecurityPolicy
    
    open private(set) var tasks: [URLSessionTask] = []
    open private(set) var dataTasks: [URLSessionDataTask] = []
    open private(set) var uploadTasks: [URLSessionUploadTask] = []
    open private(set) var downloadTasks: [URLSessionDownloadTask] = []
    
    open var completionQueue: DispatchQueue?
    open var completionGroup: DispatchGroup?
    
    public init(sessionConfiguration: URLSessionConfiguration? = nil) {
        
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
        
    }
    
    open func downloadProgress(for task: URLSessionTask) -> Progress? {
        
    }
    
    open func setUserInfo(_ userInfo: [AnyHashable: Any]?, for task: URLSessionTask) {
        
    }
    
    open func userInfo(for task: URLSessionTask) -> [AnyHashable: Any]? {
        
    }
    
    open func setSessionDidBecomeInvalidBlock(_ block: ((_ session: URLSession, _ error: Error) -> Void)?) {
        
    }
    
    open func setSessionDidReceiveAuthenticationChallengeBlock(_ block: ((_ session: URLSession, _ challenge: URLAuthenticationChallenge, _ credential: inout URLCredential?) -> URLSession.AuthChallengeDisposition)?) {
        
    }
    
    open func setTaskNeedNewBodyStreamBlock(_ block: ((_ session: URLSession, _ task: URLSessionTask) -> InputStream)?) {
        
    }
    
    open func setTaskWillPerformHTTPRedirectionBlock(_ block: ((_ session: URLSession, _ task: URLSessionTask, _ response: URLResponse, _ request: URLRequest) -> URLRequest?)?) {
        
    }
    
    open func setAuthenticationChallengeHandler(_ handler: ((_ session: URLSession, _ task: URLSessionTask, _ challenge: URLAuthenticationChallenge, _ completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Any)?) {
        
    }
    
    open func setTaskDidSendBodyDataBlock(_ block: ((_ session: URLSession, _ task: URLSessionTask, _ bytesSent: Int64, _ totalBytesSent: Int64, _ totalBytesExpectedToSend: Int64) -> Void)?) {
        
    }

    open func setTaskDidCompleteBlock(_ block: ((_ session: URLSession, _ task: URLSessionTask, _ error: Error?) -> Void)?) {
        
    }

    open func setTaskDidFinishCollectingMetricsBlock(_ block: ((_ session: URLSession, _ task: URLSessionTask, _ metrics: URLSessionTaskMetrics?) -> Void)?) {
        
    }

    open func setDataTaskDidReceiveResponseBlock(_ block: ((_ session: URLSession, _ task: URLSessionDataTask, _ response: URLResponse) -> URLSession.ResponseDisposition)?) {
        
    }

    open func setDataTaskDidBecomeDownloadTaskBlock(_ block: ((_ session: URLSession, _ dataTask: URLSessionDataTask, _ downloadTask: URLSessionDownloadTask) -> Void)?) {
        
    }

    open func setDataTaskDidReceiveDataBlock(_ block: ((_ session: URLSession, _ dataTask: URLSessionDataTask, _ data: Data) -> Void)?) {
        
    }

    open func setDataTaskWillCacheResponseBlock(_ block: ((_ session: URLSession, _ dataTask: URLSessionDataTask, _ proposedResponse: CachedURLResponse) -> CachedURLResponse)?) {
        
    }

    open func setDidFinishEventsForBackgroundURLSessionBlock(_ block: ((_ session: URLSession) -> Void)?) {
        
    }

    open func setDownloadTaskDidFinishDownloadingBlock(_ block: ((_ session: URLSession, _ downloadTask: URLSessionDownloadTask, _ location: URL) -> URL?)?) {
        
    }

    open func setDownloadTaskDidWriteDataBlock(_ block: ((_ session: URLSession, _ downloadTask: URLSessionDownloadTask, _ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?) {
        
    }

    open func setDownloadTaskDidResumeBlock(_ block: ((_ session: URLSession, _ downloadTask: URLSessionDownloadTask, _ fileOffset: Int64, _ expectedTotalBytes: Int64) -> Void)?) {
        
    }
}

fileprivate class URLSessionManagerTaskDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    static let processingQueue = DispatchQueue(label: "site.wuyong.networking.session.manager.processing", attributes: .concurrent)
    static let completionGroup = DispatchGroup()
    
    weak var manager: URLSessionManager?
    private var mutableData: Data? = Data()
    private var uploadProgress = Progress(parent: nil, userInfo: nil)
    private var downloadProgress = Progress(parent: nil, userInfo: nil)
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
}*/
