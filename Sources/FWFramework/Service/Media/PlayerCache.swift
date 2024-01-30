//
//  PlayerCache.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/25.
//

import Foundation
import AVFoundation
import MobileCoreServices

/*
// MARK: - PlayerCacheLoaderManager
public protocol PlayerCacheLoaderManagerDelegate: AnyObject {
    func resourceLoaderManagerLoadURL(_ url: URL, didFailWithError error: Error?)
}

/// 多媒体边下边播缓存管理器
///
/// [VIMediaCache](https://github.com/vitoziv/VIMediaCache)
public class PlayerCacheLoaderManager: NSObject, AVAssetResourceLoaderDelegate, PlayerCacheLoaderDelegate {
    public static let playerCacheScheme = "FWPlayerCache:"
    
    public weak var delegate: PlayerCacheLoaderManagerDelegate?
    
    private var loaders: [String: PlayerCacheLoader] = [:]
    
    public override init() {
        super.init()
    }
    
    public func cleanCache() {
        loaders.removeAll()
    }
    
    public func cancelLoaders() {
        loaders.forEach { (_, loader) in
            loader.cancel()
        }
        loaders.removeAll()
    }
    
    public static func assetURL(url: URL) -> URL {
        if url.isFileURL { return url }
        let urlString = playerCacheScheme + url.absoluteString
        return URL(string: urlString) ?? NSURL() as URL
    }
    
    public func urlAsset(url: URL) -> AVURLAsset {
        if url.isFileURL {
            return AVURLAsset(url: url)
        }
        
        let assetUrl = PlayerCacheLoaderManager.assetURL(url: url)
        let urlAsset = AVURLAsset(url: assetUrl)
        urlAsset.resourceLoader.setDelegate(self, queue: .main)
        return urlAsset
    }
    
    public func playerItem(url: URL) -> AVPlayerItem {
        if url.isFileURL {
            let urlAsset = AVURLAsset(url: url)
            return AVPlayerItem(asset: urlAsset)
        }
        
        let assetUrl = PlayerCacheLoaderManager.assetURL(url: url)
        let urlAsset = AVURLAsset(url: assetUrl)
        urlAsset.resourceLoader.setDelegate(self, queue: .main)
        let playerItem = AVPlayerItem(asset: urlAsset)
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        return playerItem
    }
    
    private func keyForResourceLoader(url: URL?) -> String? {
        if let url = url, url.absoluteString.hasPrefix(Self.playerCacheScheme) {
            return url.absoluteString
        }
        return nil
    }
    
    private func loader(for request: AVAssetResourceLoadingRequest) -> PlayerCacheLoader? {
        guard let requestKey = keyForResourceLoader(url: request.request.url) else { return nil }
        let loader = loaders[requestKey]
        return loader
    }
    
    // MARK: - AVAssetResourceLoaderDelegate
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        let resourceUrl = loadingRequest.request.url
        if let resourceUrl = resourceUrl, resourceUrl.absoluteString.hasPrefix(Self.playerCacheScheme) {
            if let loader = loader(for: loadingRequest) {
                loader.addRequest(loadingRequest)
            } else {
                let originStr = resourceUrl.absoluteString.replacingOccurrences(of: Self.playerCacheScheme, with: "")
                let originUrl = URL(string: originStr) ?? NSURL() as URL
                
                let loader = PlayerCacheLoader(url: originUrl)
                loader.delegate = self
                if let key = keyForResourceLoader(url: resourceUrl) {
                    loaders[key] = loader
                }
                loader.addRequest(loadingRequest)
            }
            return true
        }
        
        return false
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        let loader = loader(for: loadingRequest)
        loader?.removeRequest(loadingRequest)
    }
    
    // MARK: - PlayerCacheLoaderDelegate
    public func resourceLoader(_ resourceLoader: PlayerCacheLoader, didFailWithError error: Error?) {
        resourceLoader.cancel()
        delegate?.resourceLoaderManagerLoadURL(resourceLoader.url, didFailWithError: error)
    }
}

// MARK: - PlayerCacheLoader
public protocol PlayerCacheLoaderDelegate: AnyObject {
    func resourceLoader(_ resourceLoader: PlayerCacheLoader, didFailWithError error: Error?)
}

public class PlayerCacheLoader: NSObject, PlayerCacheRequestWorkerDelegate {
    public private(set) var url: URL
    public weak var delegate: PlayerCacheLoaderDelegate?
    
    private var cacheWorker: PlayerCacheWorker
    private var mediaDownloader: PlayerCacheDownloader
    private var pendingRequestWorkers: [PlayerCacheRequestWorker] = []
    private var isCancelled = false
    private var loaderCancelledError: Error {
        return NSError(domain: "FWPlayerCache", code: -3, userInfo: [NSLocalizedDescriptionKey: "Resource loader cancelled"])
    }
    
    public init(url: URL) {
        self.url = url
        self.cacheWorker = PlayerCacheWorker(url: url)
        self.mediaDownloader = PlayerCacheDownloader(url: url, cacheWorker: cacheWorker)
        super.init()
    }
    
    deinit {
        mediaDownloader.cancel()
    }
    
    public func addRequest(_ request: AVAssetResourceLoadingRequest) {
        if pendingRequestWorkers.count > 0 {
            startNoCacheWorker(request: request)
        } else {
            startWorker(request: request)
        }
    }
    
    public func removeRequest(_ request: AVAssetResourceLoadingRequest) {
        var requestWorker: PlayerCacheRequestWorker?
        for obj in pendingRequestWorkers {
            if obj.request == request {
                requestWorker = obj
                break
            }
        }
        
        if let requestWorker = requestWorker {
            requestWorker.finish()
            pendingRequestWorkers.removeAll { $0 == requestWorker }
        }
    }
    
    public func cancel() {
        mediaDownloader.cancel()
        pendingRequestWorkers.removeAll()
        
        PlayerCacheDownloaderStatus.shared.removeUrl(self.url)
    }
    
    private func startNoCacheWorker(request: AVAssetResourceLoadingRequest) {
        PlayerCacheDownloaderStatus.shared.addUrl(self.url)
        let mediaDownloader = PlayerCacheDownloader(url: self.url, cacheWorker: self.cacheWorker)
        let requestWorker = PlayerCacheRequestWorker(mediaDownloader: mediaDownloader, resourceLoadingRequest: request)
        pendingRequestWorkers.append(requestWorker)
        requestWorker.delegate = self
        requestWorker.startWork()
    }
    
    private func startWorker(request: AVAssetResourceLoadingRequest) {
        PlayerCacheDownloaderStatus.shared.addUrl(self.url)
        let requestWorker = PlayerCacheRequestWorker(mediaDownloader: self.mediaDownloader, resourceLoadingRequest: request)
        pendingRequestWorkers.append(requestWorker)
        requestWorker.delegate = self
        requestWorker.startWork()
    }
    
    // MARK: - PlayerCacheRequestWorkerDelegate
    public func resourceLoadingRequestWorker(_ requestWorker: PlayerCacheRequestWorker, didCompleteWithError error: Error?) {
        removeRequest(requestWorker.request)
        delegate?.resourceLoader(self, didFailWithError: error)
        if pendingRequestWorkers.count == 0 {
            PlayerCacheDownloaderStatus.shared.removeUrl(self.url)
        }
    }
}

// MARK: - PlayerCacheDownloader
public class PlayerCacheDownloaderStatus: NSObject {
    public static let shared = PlayerCacheDownloaderStatus()
    
    private var downloadingURLs: Set<URL> = []
    private var lock = NSLock()
    
    public override init() {
        super.init()
    }
    
    public var urls: Set<URL> {
        lock.lock()
        let urls = downloadingURLs
        lock.unlock()
        return urls
    }
    
    public func addUrl(_ url: URL) {
        lock.lock()
        defer { lock.unlock() }
        downloadingURLs.insert(url)
    }
    
    public func removeUrl(_ url: URL) {
        lock.lock()
        defer { lock.unlock() }
        downloadingURLs.remove(url)
    }
    
    public func containsUrl(_ url: URL) -> Bool {
        lock.lock()
        let contains = downloadingURLs.contains(url)
        lock.unlock()
        return contains
    }
}

@objc public protocol PlayerCacheDownloaderDelegate {
    @objc optional func mediaDownloader(_ downloader: PlayerCacheDownloader, didReceiveResponse response: URLResponse)
    @objc optional func mediaDownloader(_ downloader: PlayerCacheDownloader, didReceiveData data: Data)
    @objc optional func mediaDownloader(_ downloader: PlayerCacheDownloader, didFinishedWithError error: Error?)
}

public class PlayerCacheDownloader: NSObject, PlayerCacheActionWorkerDelegate {
    public private(set) var url: URL
    public weak var delegate: PlayerCacheDownloaderDelegate?
    public var info: PlayerCacheContentInfo?
    public var saveToCache = true
    
    private var task: URLSessionDataTask?
    private var cacheWorker: PlayerCacheWorker
    private var actionWorker: PlayerCacheActionWorker?
    private var downloadToEnd = false
    
    public init(url: URL, cacheWorker: PlayerCacheWorker) {
        self.url = url
        self.cacheWorker = cacheWorker
        self.info = cacheWorker.cacheConfiguration.contentInfo
        super.init()
        PlayerCacheDownloaderStatus.shared.addUrl(self.url)
    }
    
    deinit {
        PlayerCacheDownloaderStatus.shared.removeUrl(self.url)
    }
    
    public func downloadTaskFrom(offset: UInt64, length: UInt, toEnd: Bool) {
        var range = NSMakeRange(Int(offset), Int(length))
        if toEnd {
            range.length = Int(cacheWorker.cacheConfiguration.contentInfo?.contentLength ?? 0) - range.location
        }
        let actions = cacheWorker.cachedDataActions(for: range)
        
        actionWorker = PlayerCacheActionWorker(actions: actions, url: self.url, cacheWorker: self.cacheWorker)
        actionWorker?.canSaveToCache = saveToCache
        actionWorker?.delegate = self
        actionWorker?.start()
    }
    
    public func downloadFromStartToEnd() {
        downloadToEnd = true
        let range = NSMakeRange(0, 2)
        let actions = cacheWorker.cachedDataActions(for: range)
        
        actionWorker = PlayerCacheActionWorker(actions: actions, url: self.url, cacheWorker: self.cacheWorker)
        actionWorker?.canSaveToCache = saveToCache
        actionWorker?.delegate = self
        actionWorker?.start()
    }
    
    public func cancel() {
        actionWorker?.delegate = nil
        PlayerCacheDownloaderStatus.shared.removeUrl(self.url)
        actionWorker?.cancel()
        actionWorker = nil
    }
    
    // MARK: - PlayerCacheActionWorkerDelegate
    func actionWorker(_ actionWorker: PlayerCacheActionWorker, didReceiveResponse response: URLResponse) {
        if self.info == nil {
            let info = PlayerCacheContentInfo()
            if let response = response as? HTTPURLResponse {
                let acceptRange = response.allHeaderFields["Accept-Ranges"] as? String
                info.byteRangeAccessSupported = acceptRange == "bytes"
                let contentRange = response.allHeaderFields["Content-Range"] as? String ?? ""
                info.contentLength = UInt64(contentRange.components(separatedBy: "/").last ?? "") ?? 0
            }
            let mimeType = response.mimeType ?? ""
            let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeUnretainedValue()
            info.contentType = contentType as? String ?? ""
            self.info = info
            
            do {
                try cacheWorker.setContentInfo(info)
            } catch {
                delegate?.mediaDownloader?(self, didFinishedWithError: error)
                return
            }
        }
        
        delegate?.mediaDownloader?(self, didReceiveResponse: response)
    }
    
    func actionWorker(_ actionWorker: PlayerCacheActionWorker, didReceiveData data: Data, isLocal: Bool) {
        delegate?.mediaDownloader?(self, didReceiveData: data)
    }
    
    func actionWorker(_ actionWorker: PlayerCacheActionWorker, didFinishWithError error: Error?) {
        PlayerCacheDownloaderStatus.shared.removeUrl(self.url)
        
        if error == nil && downloadToEnd {
            downloadToEnd = false
            downloadTaskFrom(offset: 2, length: UInt((cacheWorker.cacheConfiguration.contentInfo?.contentLength ?? 0) - 2), toEnd: true)
        } else {
            delegate?.mediaDownloader?(self, didFinishedWithError: error)
        }
    }
}

fileprivate protocol PlayerCacheSessionDelegateObjectDelegate: AnyObject {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
}

fileprivate class PlayerCacheSessionDelegateObject: NSObject, URLSessionDataDelegate {
    private static let bufferSize: Int = 10 * 1024
    private weak var delegate: PlayerCacheSessionDelegateObjectDelegate?
    private var bufferData = Data()
    private var lock = NSLock()
    
    init(delegate: PlayerCacheSessionDelegateObjectDelegate?) {
        super.init()
        self.delegate = delegate
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate?.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        delegate?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        bufferData.append(data)
        if bufferData.count > Self.bufferSize {
            let chunkData = bufferData
            bufferData.removeAll()
            delegate?.urlSession(session, dataTask: dataTask, didReceive: chunkData)
        }
        lock.unlock()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        if bufferData.count > 0 && error == nil {
            let chunkData = bufferData
            bufferData.removeAll()
            if let dataTask = task as? URLSessionDataTask {
                delegate?.urlSession(session, dataTask: dataTask, didReceive: chunkData)
            }
        }
        lock.unlock()
        delegate?.urlSession(session, task: task, didCompleteWithError: error)
    }
}

protocol PlayerCacheActionWorkerDelegate: AnyObject {
    func actionWorker(_ actionWorker: PlayerCacheActionWorker, didReceiveResponse response: URLResponse)
    func actionWorker(_ actionWorker: PlayerCacheActionWorker, didReceiveData data: Data, isLocal: Bool)
    func actionWorker(_ actionWorker: PlayerCacheActionWorker, didFinishWithError error: Error?)
}

class PlayerCacheActionWorker: NSObject, PlayerCacheSessionDelegateObjectDelegate {
    private var actions: [PlayerCacheAction] = []
    var canSaveToCache = true
    weak var delegate: PlayerCacheActionWorkerDelegate?
    private var isCancelled = false
    private var url: URL
    private var cacheWorker: PlayerCacheWorker
    
    private lazy var session: URLSession = {
        let result = URLSession(configuration: .default, delegate: self.sessionDelegateObject, delegateQueue: PlayerCacheSessionManager.shared.downloadQueue)
        return result
    }()
    private lazy var sessionDelegateObject: PlayerCacheSessionDelegateObject = {
        let result = PlayerCacheSessionDelegateObject(delegate: self)
        return result
    }()
    private var task: URLSessionDataTask?
    private var startOffset: Int = 0
    private var notifyTime: TimeInterval = 0
    
    init(actions: [PlayerCacheAction], url: URL, cacheWorker: PlayerCacheWorker) {
        self.url = url
        self.cacheWorker = cacheWorker
        self.actions = actions
        super.init()
    }
    
    deinit {
        cancel()
    }
    
    func start() {
        processActions()
    }
    
    func cancel() {
        session.invalidateAndCancel()
        isCancelled = true
    }
    
    private func processActions() {
        if isCancelled { return }
        
        guard let action = popFirstActionInList() else { return }
        
        if action.actionType == .local {
            do {
                let data = try cacheWorker.cachedData(for: action.range)
                delegate?.actionWorker(self, didReceiveData: data ?? Data(), isLocal: true)
                processActionsLater()
            } catch {
                delegate?.actionWorker(self, didFinishWithError: error)
            }
        } else {
            let fromOffset = action.range.location
            let endOffset = action.range.location + action.range.length - 1
            var request = URLRequest(url: self.url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let range = String(format: "bytes=%lld-%lld", fromOffset, endOffset)
            request.setValue(range, forHTTPHeaderField: "Range")
            startOffset = action.range.location
            task = session.dataTask(with: request)
            task?.resume()
        }
    }
    
    private func processActionsLater() {
        DispatchQueue.global().async {
            self.processActions()
        }
    }
    
    private func popFirstActionInList() -> PlayerCacheAction? {
        objc_sync_enter(self)
        let action = self.actions.first
        if action != nil {
            self.actions.remove(at: 0)
        }
        objc_sync_exit(self)
        
        if let action = action {
            return action
        } else {
            delegate?.actionWorker(self, didFinishWithError: nil)
            return nil
        }
    }
    
    private func notifyDownloadProgress(flush: Bool, finished: Bool) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let interval = PlayerCacheManager.cacheUpdateNotifyInterval
        if notifyTime < (currentTime - interval) || flush {
            notifyTime = currentTime
            let configuration = cacheWorker.cacheConfiguration.copy() as! PlayerCacheConfiguration
            NotificationCenter.default.post(name: PlayerCacheManager.playerCacheManagerDidUpdateCacheNotification, object: self, userInfo: [PlayerCacheManager.playerCacheConfigurationKey: configuration])
            
            if finished && configuration.progress >= 1.0 {
                notifyDownloadFinished(error: nil)
            }
        }
    }
    
    private func notifyDownloadFinished(error: Error?) {
        let configuration = cacheWorker.cacheConfiguration.copy() as! PlayerCacheConfiguration
        var userInfo: [AnyHashable: Any] = [:]
        userInfo[PlayerCacheManager.playerCacheConfigurationKey] = configuration
        userInfo[PlayerCacheManager.playerCacheFinishedErrorKey] = error
        
        NotificationCenter.default.post(name: PlayerCacheManager.playerCacheManagerDidFinishCacheNotification, object: self, userInfo: userInfo)
    }
    
    // MARK: - PlayerCacheSessionDelegateObjectDelegate
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var credential: URLCredential?
        if let serverTrust = challenge.protectionSpace.serverTrust {
            credential = URLCredential(trust: serverTrust)
        }
        completionHandler(.useCredential, credential)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let mimeType = response.mimeType ?? ""
        if mimeType.range(of: "video/") == nil,
           mimeType.range(of: "audio/") == nil,
           mimeType.range(of: "application") == nil {
            completionHandler(.cancel)
        } else {
            delegate?.actionWorker(self, didReceiveResponse: response)
            if canSaveToCache {
                cacheWorker.startWritting()
            }
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if isCancelled { return }
        
        if canSaveToCache {
            let range = NSMakeRange(startOffset, data.count)
            do {
                try cacheWorker.cacheData(data, for: range)
                cacheWorker.save()
            } catch {
                delegate?.actionWorker(self, didFinishWithError: error)
                return
            }
        }
        
        startOffset += data.count
        delegate?.actionWorker(self, didReceiveData: data, isLocal: false)
        notifyDownloadProgress(flush: false, finished: false)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if canSaveToCache {
            cacheWorker.finishWritting()
            cacheWorker.save()
        }
        if error != nil {
            delegate?.actionWorker(self, didFinishWithError: error)
            notifyDownloadFinished(error: error)
        } else {
            notifyDownloadProgress(flush: true, finished: true)
            processActions()
        }
    }
}

// MARK: - PlayerCacheRequestWorker
public protocol PlayerCacheRequestWorkerDelegate: AnyObject {
    func resourceLoadingRequestWorker(_ requestWorker: PlayerCacheRequestWorker, didCompleteWithError error: Error?)
}

public class PlayerCacheRequestWorker: NSObject, PlayerCacheDownloaderDelegate {
    public weak var delegate: PlayerCacheRequestWorkerDelegate?
    public private(set) var request: AVAssetResourceLoadingRequest
    
    private var mediaDownloader: PlayerCacheDownloader
    private var loaderCancelledError: Error {
        return NSError(domain: "FWPlayerCache", code: -3, userInfo: [NSLocalizedDescriptionKey: "Resource loader cancelled"])
    }
    
    public init(mediaDownloader: PlayerCacheDownloader, resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        self.mediaDownloader = mediaDownloader
        self.request = resourceLoadingRequest
        super.init()
        
        self.mediaDownloader.delegate = self
        self.fullfillContentInfo()
    }
    
    public func startWork() {
        let dataRequest = request.dataRequest
        
        var offset = dataRequest?.requestedOffset ?? 0
        let length = dataRequest?.requestedLength ?? 0
        if let dataRequest = dataRequest, dataRequest.currentOffset != 0 {
            offset = dataRequest.currentOffset
        }
        
        var toEnd = false
        if dataRequest?.requestsAllDataToEndOfResource == true {
            toEnd = true
        }
        mediaDownloader.downloadTaskFrom(offset: UInt64(offset), length: UInt(length), toEnd: toEnd)
    }
    
    public func cancel() {
        mediaDownloader.cancel()
    }
    
    public func finish() {
        if !request.isFinished {
            mediaDownloader.cancel()
            request.finishLoading(with: loaderCancelledError)
        }
    }
    
    private func fullfillContentInfo() {
        let contentInformationRequest = request.contentInformationRequest
        if let info = mediaDownloader.info, contentInformationRequest?.contentType == nil {
            contentInformationRequest?.contentType = info.contentType
            contentInformationRequest?.contentLength = Int64(info.contentLength)
            contentInformationRequest?.isByteRangeAccessSupported = info.byteRangeAccessSupported
        }
    }
    
    // MARK: - PlayerCacheDownloaderDelegate
    public func mediaDownloader(_ downloader: PlayerCacheDownloader, didReceiveResponse response: URLResponse) {
        fullfillContentInfo()
    }
    
    public func mediaDownloader(_ downloader: PlayerCacheDownloader, didReceiveData data: Data) {
        request.dataRequest?.respond(with: data)
    }
    
    public func mediaDownloader(_ downloader: PlayerCacheDownloader, didFinishedWithError error: Error?) {
        if let error = error, (error as NSError).code == NSURLErrorCancelled { return }
        
        if error == nil {
            request.finishLoading()
        } else {
            request.finishLoading(with: error)
        }
        
        delegate?.resourceLoadingRequestWorker(self, didCompleteWithError: error)
    }
}

// MARK: - PlayerCacheContentInfo
public class PlayerCacheContentInfo: NSObject, NSCoding {
    public var contentType: String = ""
    public var byteRangeAccessSupported = false
    public var contentLength: UInt64 = 0
    public var downloadedContentLength: UInt64 = 0
    
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        contentLength = UInt64(coder.decodeInt64(forKey: "contentLength"))
        contentType = coder.decodeObject(forKey: "contentType") as? String ?? ""
        byteRangeAccessSupported = coder.decodeBool(forKey: "byteRangeAccessSupported")
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(Int64(contentLength), forKey: "contentLength")
        coder.encode(contentType, forKey: "contentType")
        coder.encode(byteRangeAccessSupported, forKey: "byteRangeAccessSupported")
    }
    
    public override var debugDescription: String {
        return String(format: "%@\ncontentLength: %lld\ncontentType: %@\nbyteRangeAccessSupported:%@", NSStringFromClass(self.classForCoder), contentLength, contentType, "\(byteRangeAccessSupported)")
    }
}

// MARK: - PlayerCacheAction
public enum PlayerCacheAtionType: Int {
    case local = 0
    case remote
}

public class PlayerCacheAction: NSObject {
    public var actionType: PlayerCacheAtionType
    public var range: NSRange
    
    public init(actionType: PlayerCacheAtionType, range: NSRange) {
        self.actionType = actionType
        self.range = range
        super.init()
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PlayerCacheAction else {
            return super.isEqual(object)
        }
        
        if object.range != range { return false }
        if object.actionType != actionType { return false }
        return true
    }
    
    public override var hash: Int {
        return String(format: "%@%@", NSStringFromRange(range), "\(actionType)").hash
    }
    
    public override var description: String {
        return String(format: "actionType %@, range: %@", "\(actionType)", NSStringFromRange(range))
    }
}

// MARK: - PlayerCacheConfiguration
public class PlayerCacheConfiguration: NSObject, NSCopying, NSCoding {
    public private(set) var filePath: String = ""
    public var contentInfo: PlayerCacheContentInfo?
    public var url: URL?
    
    public var cacheFragments: [NSValue] {
        var fragments = internalCacheFragments
        return fragments
    }
    public var progress: Float {
        guard let contentLength = contentInfo?.contentLength, contentLength > 0 else { return 0 }
        return Float(downloadedBytes) / Float(contentLength)
    }
    public var downloadedBytes: Int64 {
        var bytes: Int64 = 0
        objc_sync_enter(internalCacheFragments)
        for range in internalCacheFragments {
            bytes += Int64(range.rangeValue.length)
        }
        objc_sync_exit(internalCacheFragments)
        return bytes
    }
    public var downloadSpeed: Float {
        var bytes: Int64 = 0
        var time: TimeInterval = 0
        objc_sync_enter(downloadInfo)
        for info in downloadInfo {
            bytes += info.first?.int64Value ?? 0
            time += info.last?.doubleValue ?? 0
        }
        objc_sync_exit(downloadInfo)
        return time > 0 ? (Float(bytes) / 1024.0 / Float(time)) : 0
    }
    
    private var fileName = ""
    private var internalCacheFragments: [NSValue] = []
    private var downloadInfo: [[NSNumber]] = []
    
    public static func configuration(filePath: String) -> PlayerCacheConfiguration {
        let filePath = configurationFilePath(for: filePath)
        if let configuration = Data.fw_unarchivedObject(PlayerCacheConfiguration.self, withFile: filePath) {
            configuration.filePath = filePath
            return configuration
        } else {
            let configuration = PlayerCacheConfiguration()
            configuration.fileName = (filePath as NSString).lastPathComponent
            configuration.filePath = filePath
            return configuration
        }
    }
    
    public static func configurationFilePath(for filePath: String) -> String {
        return filePath.fw_appendingPathExtension("cache_cfg")
    }
    
    public static func createAndSaveDownloadedConfiguration(for url: URL) throws {
        
    }
    
    public required override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        fileName = coder.decodeObject(forKey: "fileName") as? String ?? ""
        internalCacheFragments = coder.decodeObject(forKey: "internalCacheFragments") as? [NSValue] ?? []
        downloadInfo = coder.decodeObject(forKey: "downloadInfo") as? [[NSNumber]] ?? []
        contentInfo = coder.decodeObject(forKey: "contentInfo") as? PlayerCacheContentInfo
        url = coder.decodeObject(forKey: "url") as? URL
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(fileName, forKey: "fileName")
        coder.encode(internalCacheFragments, forKey: "internalCacheFragments")
        coder.encode(downloadInfo, forKey: "downloadInfo")
        coder.encode(contentInfo, forKey: "contentInfo")
        coder.encode(url, forKey: "url")
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = Self.init()
        configuration.fileName = fileName
        configuration.filePath = filePath
        configuration.internalCacheFragments = internalCacheFragments
        configuration.downloadInfo = downloadInfo
        configuration.url = url
        configuration.contentInfo = contentInfo
        return configuration
    }
    
    public func save() {
        if Thread.isMainThread {
            doDelaySaveAction()
        } else {
            DispatchQueue.main.async {
                self.doDelaySaveAction()
            }
        }
    }
    
    public func addCacheFragment(_ fragment: NSRange) {
        if fragment.location == NSNotFound || fragment.length == 0 { return }
        objc_sync_enter(internalCacheFragments)
        defer { objc_sync_exit(internalCacheFragments) }
        
        var cacheFragments = internalCacheFragments
        let fragmentValue = NSValue(range: fragment)
        let count = self.internalCacheFragments.count
        if count == 0 {
            cacheFragments.append(fragmentValue)
        } else {
            var indexSet = IndexSet()
            for (idx, obj) in cacheFragments.enumerated() {
                let range = obj.rangeValue
                if fragment.location + fragment.length <= range.location {
                    if indexSet.count == 0 {
                        indexSet.insert(idx)
                    }
                    break
                } else if fragment.location <= (range.location + range.length) && (fragment.location + fragment.length) > range.location {
                    indexSet.insert(idx)
                } else if fragment.location >= (range.location + range.length) {
                    if idx == count - 1 {
                        indexSet.insert(idx)
                    }
                }
            }
            
            if indexSet.count > 1 {
                let firstRange = self.internalCacheFragments[indexSet.first ?? 0].rangeValue
                let lastRange = self.internalCacheFragments[indexSet.last ?? 0].rangeValue
                let location = min(firstRange.location, fragment.location)
                let endOffset = max(lastRange.location + lastRange.length, fragment.location + fragment.length)
                let combineRange = NSMakeRange(location, endOffset - location)
                cacheFragments.remove(atOffsets: indexSet)
                cacheFragments.insert(NSValue(range: combineRange), at: indexSet.first ?? 0)
            } else if indexSet.count == 1 {
                
            }
        }
        
        self.internalCacheFragments = cacheFragments
    }
    
    public func addDownloadedBytes(bytes: Int64, spent time: TimeInterval) {
        objc_sync_enter(downloadInfo)
        downloadInfo.append([NSNumber(value: bytes), NSNumber(value: time)])
        objc_sync_exit(downloadInfo)
    }
    
    private func doDelaySaveAction() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.archiveData), object: nil)
        perform(#selector(self.archiveData), with: nil, afterDelay: 1.0)
    }
    
    @objc private func archiveData() {
        objc_sync_enter(internalCacheFragments)
        Data.fw_archiveObject(self, toFile: filePath)
        objc_sync_exit(internalCacheFragments)
    }
}

// MARK: - PlayerCacheManager
public class PlayerCacheManager: NSObject {
    public static let playerCacheManagerDidUpdateCacheNotification = Notification.Name("FWPlayerCacheManagerDidUpdateCacheNotification")
    public static let playerCacheManagerDidFinishCacheNotification = Notification.Name("FWPlayerCacheManagerDidFinishCacheNotification")
    public static let playerCacheConfigurationKey = "FWPlayerCacheConfigurationKey"
    public static let playerCacheFinishedErrorKey = "FWPlayerCacheFinishedErrorKey"
    
    public static var cacheDirectory: String = {
        let result = FileManager.fw_pathCaches.fw_appendingPath(["FWFramework", "PlayerCache"])
        return result
    }()
    public static var cacheUpdateNotifyInterval: TimeInterval = 0.1
    private static var cacheFileNameRules: ((URL) -> String)?
    
    public static func cachedFilePath(for url: URL) -> String {
        var pathComponent: String = ""
        if let block = cacheFileNameRules {
            pathComponent = block(url)
        } else {
            pathComponent = url.absoluteString.fw_md5Encode.fw_appendingPathExtension(url.pathExtension)
        }
        return cacheDirectory.fw_appendingPath(pathComponent)
    }
    
    public static func cacheConfiguration(for url: URL) -> PlayerCacheConfiguration {
        let filePath = cachedFilePath(for: url)
        return PlayerCacheConfiguration.configuration(filePath: filePath)
    }
    
    public static func setFileNameRules(_ block: ((URL) -> String)?) {
        cacheFileNameRules = block
    }
    
    public static func calculateCachedSize() throws -> UInt64 {
        
    }
    
    public static func cleanAllCache() throws {
        
    }
    
    public static func cleanCache(for url: URL) throws {
        
    }
    
    public static func addCacheFile(_ filePath: String, for url: URL) throws {
        
    }
}

// MARK: - PlayerCacheSessionManager
public class PlayerCacheSessionManager: NSObject {
    public static let shared = PlayerCacheSessionManager()
    
    public private(set) var downloadQueue: OperationQueue = {
        let result = OperationQueue()
        result.name = "site.wuyong.queue.player.download"
        return result
    }()
    
    public override init() {
        super.init()
    }
}

// MARK: - PlayerCacheWorker
public class PlayerCacheWorker: NSObject {
    public private(set) var cacheConfiguration: PlayerCacheConfiguration
    public private(set) var setupError: Error?
    
    private var filePath: String
    private var readFileHandle: FileHandle?
    private var writeFileHandle: FileHandle?
    private var currentOffset: Int64 = 0
    private var startWriteDate: Date?
    private var writeBytes: Int = 0
    private var writting: Bool = false
    
    private static let packageLength: Int = 512 * 1024
    private static let playerCacheResponseKey = "PlayerCacheResponseKey"
    
    public init(url: URL) {
        let filePath = PlayerCacheManager.cachedFilePath(for: url)
        self.filePath = filePath
        
        let cacheFolder = (filePath as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: cacheFolder) {
            do {
                try FileManager.default.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true)
            } catch {
                self.setupError = error
            }
        }
        
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: nil)
        }
        let fileURL = URL(fileURLWithPath: filePath)
        do {
            self.readFileHandle = try FileHandle(forReadingFrom: fileURL)
            self.writeFileHandle = try FileHandle(forWritingTo: fileURL)
        } catch {
            self.setupError = error
        }
        
        self.cacheConfiguration = PlayerCacheConfiguration.configuration(filePath: filePath)
        self.cacheConfiguration.url = url
        
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.save()
        try? readFileHandle?.close()
        try? writeFileHandle?.close()
    }
    
    public func cacheData(_ data: Data, for range: NSRange) throws {
        guard let writeFileHandle = writeFileHandle else { return }
        
        var error: Error?
        objc_sync_enter(writeFileHandle)
        do {
            try writeFileHandle.seek(toOffset: UInt64(range.location))
            if #available(iOS 13.4, *) {
                try writeFileHandle.write(contentsOf: data)
            } else {
                var fileError: Error?
                ObjCBridge.tryCatch {
                    writeFileHandle.write(data)
                } exceptionHandler: { exception in
                    fileError = NSError(domain: exception.name.rawValue, code: 123, userInfo: [NSLocalizedDescriptionKey: exception.reason ?? "", "exception": exception])
                }
                if let fileError = fileError {
                    throw fileError
                }
            }
            writeBytes += data.count
            cacheConfiguration.addCacheFragment(range)
        } catch let fileError {
            error = fileError
        }
        objc_sync_exit(writeFileHandle)
        
        if let error = error {
            throw error
        }
    }
    
    public func cachedDataActions(for range: NSRange) -> [PlayerCacheAction] {
        
    }
    
    public func cachedData(for range: NSRange) throws -> Data? {
        guard let readFileHandle = readFileHandle else { return nil }
        objc_sync_enter(readFileHandle)
        defer { objc_sync_exit(readFileHandle) }
        try readFileHandle.seek(toOffset: UInt64(range.location))
        var data: Data?
        if #available(iOS 13.4, *) {
            data = try readFileHandle.read(upToCount: range.length)
        } else {
            var fileError: Error?
            ObjCBridge.tryCatch {
                data = readFileHandle.readData(ofLength: range.length)
            } exceptionHandler: { exception in
                fileError = NSError(domain: exception.name.rawValue, code: 123, userInfo: [NSLocalizedDescriptionKey: exception.reason ?? "", "exception": exception])
            }
            if let fileError = fileError {
                throw fileError
            }
        }
        return data
    }
    
    public func setContentInfo(_ contentInfo: PlayerCacheContentInfo) throws {
        cacheConfiguration.contentInfo = contentInfo
        try writeFileHandle?.truncate(atOffset: contentInfo.contentLength)
        try writeFileHandle?.synchronize()
    }
    
    public func save() {
        guard let writeFileHandle = writeFileHandle else { return }
        
        objc_sync_enter(writeFileHandle)
        try? writeFileHandle.synchronize()
        cacheConfiguration.save()
        objc_sync_exit(writeFileHandle)
    }
    
    public func startWritting() {
        if !writting {
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        writting = true
        startWriteDate = Date()
        writeBytes = 0
    }
    
    public func finishWritting() {
        if writting {
            writting = false
            NotificationCenter.default.removeObserver(self)
            let time = Date().timeIntervalSince(startWriteDate ?? Date())
            cacheConfiguration.addDownloadedBytes(bytes: Int64(writeBytes), spent: time)
        }
    }
    
    @objc private func applicationDidEnterBackground(_ notification: Notification) {
        self.save()
    }
}*/
