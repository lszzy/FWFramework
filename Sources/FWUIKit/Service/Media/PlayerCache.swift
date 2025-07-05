//
//  PlayerCache.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/25.
//

import AVFoundation
import Foundation
import MobileCoreServices
import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

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

    override public init() {
        super.init()
    }

    public func cleanCache() {
        loaders.removeAll()
    }

    public func cancelLoaders() {
        for (_, loader) in loaders {
            loader.cancel()
        }
        loaders.removeAll()
    }

    public static func assetURL(url: URL) -> URL {
        if url.isFileURL { return url }
        let urlString = playerCacheScheme + url.absoluteString
        return URL(string: urlString) ?? URL()
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
        if let url, url.absoluteString.hasPrefix(Self.playerCacheScheme) {
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
        if let resourceUrl, resourceUrl.absoluteString.hasPrefix(Self.playerCacheScheme) {
            if let loader = loader(for: loadingRequest) {
                loader.addRequest(loadingRequest)
            } else {
                let originStr = resourceUrl.absoluteString.replacingOccurrences(of: Self.playerCacheScheme, with: "")
                let originUrl = URL(string: originStr) ?? URL()

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
        NSError(domain: "FWPlayerCache", code: -3, userInfo: [NSLocalizedDescriptionKey: "Resource loader cancelled"])
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

        if let requestWorker {
            requestWorker.finish()
            pendingRequestWorkers.removeAll { $0 == requestWorker }
        }
    }

    public func cancel() {
        mediaDownloader.cancel()
        pendingRequestWorkers.removeAll()

        PlayerCacheDownloaderStatus.shared.removeUrl(url)
    }

    private func startNoCacheWorker(request: AVAssetResourceLoadingRequest) {
        PlayerCacheDownloaderStatus.shared.addUrl(url)
        let mediaDownloader = PlayerCacheDownloader(url: url, cacheWorker: cacheWorker)
        let requestWorker = PlayerCacheRequestWorker(mediaDownloader: mediaDownloader, resourceLoadingRequest: request)
        pendingRequestWorkers.append(requestWorker)
        requestWorker.delegate = self
        requestWorker.startWork()
    }

    private func startWorker(request: AVAssetResourceLoadingRequest) {
        PlayerCacheDownloaderStatus.shared.addUrl(url)
        let requestWorker = PlayerCacheRequestWorker(mediaDownloader: mediaDownloader, resourceLoadingRequest: request)
        pendingRequestWorkers.append(requestWorker)
        requestWorker.delegate = self
        requestWorker.startWork()
    }

    // MARK: - PlayerCacheRequestWorkerDelegate
    public func resourceLoadingRequestWorker(_ requestWorker: PlayerCacheRequestWorker, didCompleteWithError error: Error?) {
        removeRequest(requestWorker.request)
        delegate?.resourceLoader(self, didFailWithError: error)
        if pendingRequestWorkers.count == 0 {
            PlayerCacheDownloaderStatus.shared.removeUrl(url)
        }
    }
}

// MARK: - PlayerCacheDownloader
public class PlayerCacheDownloaderStatus: NSObject, @unchecked Sendable {
    public static let shared = PlayerCacheDownloaderStatus()

    private var downloadingURLs: Set<URL> = []
    private var lock = NSLock()

    override public init() {
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

        actionWorker = PlayerCacheActionWorker(actions: actions, url: url, cacheWorker: cacheWorker)
        actionWorker?.canSaveToCache = saveToCache
        actionWorker?.delegate = self
        actionWorker?.start()
    }

    public func downloadFromStartToEnd() {
        downloadToEnd = true
        let range = NSMakeRange(0, 2)
        let actions = cacheWorker.cachedDataActions(for: range)

        actionWorker = PlayerCacheActionWorker(actions: actions, url: url, cacheWorker: cacheWorker)
        actionWorker?.canSaveToCache = saveToCache
        actionWorker?.delegate = self
        actionWorker?.start()
    }

    public func cancel() {
        actionWorker?.delegate = nil
        PlayerCacheDownloaderStatus.shared.removeUrl(url)
        actionWorker?.cancel()
        actionWorker = nil
    }

    // MARK: - PlayerCacheActionWorkerDelegate
    func actionWorker(_ actionWorker: PlayerCacheActionWorker, didReceiveResponse response: URLResponse) {
        if info == nil {
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
        PlayerCacheDownloaderStatus.shared.removeUrl(url)

        if error == nil && downloadToEnd {
            downloadToEnd = false
            downloadTaskFrom(offset: 2, length: UInt((cacheWorker.cacheConfiguration.contentInfo?.contentLength ?? 0) - 2), toEnd: true)
        } else {
            delegate?.mediaDownloader?(self, didFinishedWithError: error)
        }
    }
}

private protocol PlayerCacheSessionDelegateObjectDelegate: AnyObject {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
}

private class PlayerCacheSessionDelegateObject: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private static let bufferSize: Int = 10 * 1024
    private weak var delegate: PlayerCacheSessionDelegateObjectDelegate?
    private var bufferData = Data()
    private var lock = NSLock()

    init(delegate: PlayerCacheSessionDelegateObjectDelegate?) {
        super.init()
        self.delegate = delegate
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate?.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void) {
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

class PlayerCacheActionWorker: NSObject, PlayerCacheSessionDelegateObjectDelegate, @unchecked Sendable {
    private var actions: [PlayerCacheAction] = []
    var canSaveToCache = true
    weak var delegate: PlayerCacheActionWorkerDelegate?
    private var isCancelled = false
    private var url: URL
    private var cacheWorker: PlayerCacheWorker

    private var session: URLSession {
        if let result = _session {
            return result
        }
        let result = URLSession(configuration: .default, delegate: sessionDelegateObject, delegateQueue: PlayerCacheSessionManager.shared.downloadQueue)
        _session = result
        return result
    }

    private var _session: URLSession?
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
        _session?.invalidateAndCancel()
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
            var request = URLRequest(url: url)
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
        let action = actions.first
        if action != nil {
            actions.remove(at: 0)
        }
        objc_sync_exit(self)

        if let action {
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
        NSError(domain: "FWPlayerCache", code: -3, userInfo: [NSLocalizedDescriptionKey: "Resource loader cancelled"])
    }

    public init(mediaDownloader: PlayerCacheDownloader, resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        self.mediaDownloader = mediaDownloader
        self.request = resourceLoadingRequest
        super.init()

        self.mediaDownloader.delegate = self
        fullfillContentInfo()
    }

    public func startWork() {
        let dataRequest = request.dataRequest

        var offset = dataRequest?.requestedOffset ?? 0
        let length = dataRequest?.requestedLength ?? 0
        if let dataRequest, dataRequest.currentOffset != 0 {
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
        if let error, (error as NSError).code == NSURLErrorCancelled { return }

        if error == nil {
            request.finishLoading()
        } else {
            request.finishLoading(with: error)
        }

        delegate?.resourceLoadingRequestWorker(self, didCompleteWithError: error)
    }
}

// MARK: - PlayerCacheContentInfo
public class PlayerCacheContentInfo: NSObject, NSSecureCoding {
    public var contentType: String = ""
    public var byteRangeAccessSupported = false
    public var contentLength: UInt64 = 0
    public var downloadedContentLength: UInt64 = 0

    override public init() {
        super.init()
    }

    public static var supportsSecureCoding: Bool {
        true
    }

    public required init?(coder: NSCoder) {
        super.init()
        self.contentLength = UInt64(coder.decodeInt64(forKey: "contentLength"))
        self.contentType = coder.decodeObject(forKey: "contentType") as? String ?? ""
        self.byteRangeAccessSupported = coder.decodeBool(forKey: "byteRangeAccessSupported")
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int64(contentLength), forKey: "contentLength")
        coder.encode(contentType, forKey: "contentType")
        coder.encode(byteRangeAccessSupported, forKey: "byteRangeAccessSupported")
    }

    override public var debugDescription: String {
        String(format: "%@\ncontentLength: %lld\ncontentType: %@\nbyteRangeAccessSupported:%@", NSStringFromClass(type(of: self)), contentLength, contentType, "\(byteRangeAccessSupported)")
    }
}

// MARK: - PlayerCacheAction
public enum PlayerCacheAtionType: Int, Sendable {
    case local = 0
    case remote
}

public class PlayerCacheAction: NSObject {
    public var actionType: PlayerCacheAtionType = .local
    public var range: NSRange = .init()

    override public init() {
        super.init()
    }

    public convenience init(actionType: PlayerCacheAtionType, range: NSRange) {
        self.init()
        self.actionType = actionType
        self.range = range
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PlayerCacheAction else {
            return super.isEqual(object)
        }

        if object.range != range { return false }
        if object.actionType != actionType { return false }
        return true
    }

    override public var hash: Int {
        String(format: "%@%@", NSStringFromRange(range), "\(actionType)").hash
    }

    override public var description: String {
        String(format: "actionType %@, range: %@", "\(actionType)", NSStringFromRange(range))
    }
}

// MARK: - PlayerCacheConfiguration
public class PlayerCacheConfiguration: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public private(set) var filePath: String = ""
    public var contentInfo: PlayerCacheContentInfo?
    public var url: URL?

    public var cacheFragments: [NSValue] {
        let fragments = internalCacheFragments
        return fragments
    }

    public var progress: Float {
        guard let contentLength = contentInfo?.contentLength, contentLength > 0 else { return 0 }
        return Float(downloadedBytes) / Float(contentLength)
    }

    public var downloadedBytes: Int64 {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        var bytes: Int64 = 0
        for range in internalCacheFragments {
            bytes += Int64(range.rangeValue.length)
        }
        return bytes
    }

    public var downloadSpeed: Float {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        var bytes: Int64 = 0
        var time: TimeInterval = 0
        for info in downloadInfo {
            bytes += info.first?.int64Value ?? 0
            time += info.last?.doubleValue ?? 0
        }
        return time > 0 ? (Float(bytes) / 1024.0 / Float(time)) : 0
    }

    private var fileName = ""
    private var internalCacheFragments: [NSValue] = []
    private var downloadInfo: [[NSNumber]] = []

    public static func configuration(filePath: String) -> PlayerCacheConfiguration {
        let filePath = configurationFilePath(for: filePath)
        if let configuration = Data.fw.unarchivedObject(withFile: filePath, as: PlayerCacheConfiguration.self) {
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
        filePath.fw.appendingPathExtension("metadata")
    }

    public static func createAndSaveDownloadedConfiguration(for url: URL) throws {
        let filePath = PlayerCacheManager.cachedFilePath(for: url)
        let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
        let fileSize = attributes[.size] as? UInt64 ?? 0
        let range = NSRange(location: 0, length: Int(fileSize))

        let configuration = PlayerCacheConfiguration.configuration(filePath: filePath)
        configuration.url = url

        let contentInfo = PlayerCacheContentInfo()
        contentInfo.contentType = contentType(from: url.pathExtension)
        contentInfo.contentLength = fileSize
        contentInfo.byteRangeAccessSupported = true
        contentInfo.downloadedContentLength = fileSize
        configuration.contentInfo = contentInfo

        configuration.addCacheFragment(range)
        configuration.save()
    }

    private static func contentType(from fileExtension: String) -> String {
        if let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue(),
           let contentType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }
        return "application/octet-stream"
    }

    override public required init() {
        super.init()
    }

    public static var supportsSecureCoding: Bool {
        true
    }

    public required init?(coder: NSCoder) {
        super.init()
        self.fileName = coder.decodeObject(forKey: "fileName") as? String ?? ""
        self.internalCacheFragments = coder.decodeObject(forKey: "internalCacheFragments") as? [NSValue] ?? []
        self.downloadInfo = coder.decodeObject(forKey: "downloadInfo") as? [[NSNumber]] ?? []
        self.contentInfo = coder.decodeObject(forKey: "contentInfo") as? PlayerCacheContentInfo
        self.url = coder.decodeObject(forKey: "url") as? URL
    }

    public func encode(with coder: NSCoder) {
        coder.encode(fileName, forKey: "fileName")
        coder.encode(internalCacheFragments, forKey: "internalCacheFragments")
        coder.encode(downloadInfo, forKey: "downloadInfo")
        coder.encode(contentInfo, forKey: "contentInfo")
        coder.encode(url, forKey: "url")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = Self()
        configuration.fileName = fileName
        configuration.filePath = filePath
        configuration.internalCacheFragments = internalCacheFragments
        configuration.downloadInfo = downloadInfo
        configuration.url = url
        configuration.contentInfo = contentInfo
        return configuration
    }

    public func save() {
        DispatchQueue.fw.mainAsync {
            self.doDelaySaveAction()
        }
    }

    public func addCacheFragment(_ fragment: NSRange) {
        if fragment.location == NSNotFound || fragment.length == 0 { return }
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        var cacheFragments = internalCacheFragments
        let fragmentValue = NSValue(range: fragment)
        let count = internalCacheFragments.count
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
                let firstRange = internalCacheFragments[indexSet.first ?? 0].rangeValue
                let lastRange = internalCacheFragments[indexSet.last ?? 0].rangeValue
                let location = min(firstRange.location, fragment.location)
                let endOffset = max(lastRange.location + lastRange.length, fragment.location + fragment.length)
                let combineRange = NSMakeRange(location, endOffset - location)
                #if swift(>=5.9)
                cacheFragments.remove(atOffsets: indexSet)
                #else
                indexSet.forEach { cacheFragments.remove(at: $0) }
                #endif
                cacheFragments.insert(NSValue(range: combineRange), at: indexSet.first ?? 0)
            } else if indexSet.count == 1 {
                let firstRange = internalCacheFragments[indexSet.first ?? 0].rangeValue
                let expandFirstRange = NSMakeRange(firstRange.location, firstRange.length + 1)
                let expandFragmentRange = NSMakeRange(fragment.location, fragment.length + 1)
                let intersectionRange = NSIntersectionRange(expandFirstRange, expandFragmentRange)
                if intersectionRange.length > 0 {
                    let location = min(firstRange.location, fragment.location)
                    let endOffset = max(firstRange.location + firstRange.length, fragment.location + fragment.length)
                    let combineRange = NSMakeRange(location, endOffset - location)
                    cacheFragments.remove(at: indexSet.first ?? 0)
                    cacheFragments.insert(NSValue(range: combineRange), at: indexSet.first ?? 0)
                } else {
                    if firstRange.location > fragment.location {
                        cacheFragments.insert(fragmentValue, at: indexSet.last ?? 0)
                    } else {
                        cacheFragments.insert(fragmentValue, at: (indexSet.last ?? 0) + 1)
                    }
                }
            }
        }

        internalCacheFragments = cacheFragments
    }

    public func addDownloadedBytes(bytes: Int64, spent time: TimeInterval) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        downloadInfo.append([NSNumber(value: bytes), NSNumber(value: time)])
    }

    private func doDelaySaveAction() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(archiveData), object: nil)
        perform(#selector(archiveData), with: nil, afterDelay: 1.0)
    }

    @objc private func archiveData() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        Data.fw.archiveObject(self, toFile: filePath)
    }
}

// MARK: - PlayerCacheManager
public class PlayerCacheManager: NSObject, @unchecked Sendable {
    public static let playerCacheManagerDidUpdateCacheNotification = Notification.Name("FWPlayerCacheManagerDidUpdateCacheNotification")
    public static let playerCacheManagerDidFinishCacheNotification = Notification.Name("FWPlayerCacheManagerDidFinishCacheNotification")
    public static let playerCacheConfigurationKey = "FWPlayerCacheConfigurationKey"
    public static let playerCacheFinishedErrorKey = "FWPlayerCacheFinishedErrorKey"

    public static var cacheDirectory: String {
        get { shared.cacheDirectory }
        set { shared.cacheDirectory = newValue }
    }

    public static var cacheUpdateNotifyInterval: TimeInterval {
        get { shared.cacheUpdateNotifyInterval }
        set { shared.cacheUpdateNotifyInterval = newValue }
    }

    private static let shared = PlayerCacheManager()
    private var cacheDirectory: String = {
        let result = FileManager.fw.pathCaches.fw.appendingPath(["FWFramework", "PlayerCache"])
        return result
    }()

    private var cacheUpdateNotifyInterval: TimeInterval = 0.1
    private var cacheFileNameRules: (@Sendable (URL) -> String)?

    public static func cachedFilePath(for url: URL) -> String {
        var pathComponent = ""
        if let block = shared.cacheFileNameRules {
            pathComponent = block(url)
        } else {
            pathComponent = url.absoluteString.fw.md5Encode.fw.appendingPathExtension(url.pathExtension)
        }
        return cacheDirectory.fw.appendingPath(pathComponent)
    }

    public static func cacheConfiguration(for url: URL) -> PlayerCacheConfiguration {
        let filePath = cachedFilePath(for: url)
        return PlayerCacheConfiguration.configuration(filePath: filePath)
    }

    public static func setFileNameRules(_ block: (@Sendable (URL) -> String)?) {
        shared.cacheFileNameRules = block
    }

    public static func calculateCachedSize() throws -> UInt64 {
        let fileManager = FileManager.default
        let cacheDirectory = cacheDirectory
        let files = try fileManager.contentsOfDirectory(atPath: cacheDirectory)
        var size: UInt64 = 0
        for path in files {
            let filePath = (cacheDirectory as NSString).appendingPathComponent(path)
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            size += attributes[.size] as? UInt64 ?? 0
        }
        return size
    }

    public static func cleanAllCache() throws {
        var downloadingFiles = Set<String>()
        for url in PlayerCacheDownloaderStatus.shared.urls {
            let file = cachedFilePath(for: url)
            downloadingFiles.insert(file)
            let configurationPath = PlayerCacheConfiguration.configurationFilePath(for: file)
            downloadingFiles.insert(configurationPath)
        }

        let fileManager = FileManager.default
        let cacheDirectory = cacheDirectory
        let files = try fileManager.contentsOfDirectory(atPath: cacheDirectory)
        for path in files {
            let filePath = (cacheDirectory as NSString).appendingPathComponent(path)
            if downloadingFiles.contains(filePath) {
                continue
            }
            try fileManager.removeItem(atPath: filePath)
        }
    }

    public static func cleanCache(for url: URL) throws {
        if PlayerCacheDownloaderStatus.shared.containsUrl(url) {
            let description = "Clean cache for url `\(url)` can't be done, because it's downloading"
            throw NSError(domain: "FWPlayerCache", code: 2, userInfo: [NSLocalizedDescriptionKey: description])
        }

        let fileManager = FileManager.default
        let filePath = cachedFilePath(for: url)
        if fileManager.fileExists(atPath: filePath) {
            try fileManager.removeItem(atPath: filePath)
        }

        let configurationPath = PlayerCacheConfiguration.configurationFilePath(for: filePath)
        if fileManager.fileExists(atPath: configurationPath) {
            try fileManager.removeItem(atPath: configurationPath)
        }
    }

    public static func addCacheFile(_ filePath: String, for url: URL) throws {
        let fileManager = FileManager.default
        let cachePath = PlayerCacheManager.cachedFilePath(for: url)
        let cacheFolder = (cachePath as NSString).deletingLastPathComponent
        if !fileManager.fileExists(atPath: cacheFolder) {
            try fileManager.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true, attributes: nil)
        }

        try fileManager.copyItem(atPath: filePath, toPath: cachePath)

        do {
            try PlayerCacheConfiguration.createAndSaveDownloadedConfiguration(for: url)
        } catch {
            try? fileManager.removeItem(atPath: cachePath)
            throw error
        }
    }
}

// MARK: - PlayerCacheSessionManager
public class PlayerCacheSessionManager: NSObject, @unchecked Sendable {
    public static let shared = PlayerCacheSessionManager()

    public private(set) var downloadQueue: OperationQueue = {
        let result = OperationQueue()
        result.name = "site.wuyong.queue.player.download"
        return result
    }()

    override public init() {
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
        cacheConfiguration.url = url

        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.save()
        try? readFileHandle?.close()
        try? writeFileHandle?.close()
    }

    public func cacheData(_ data: Data, for range: NSRange) throws {
        guard let writeFileHandle else { return }
        objc_sync_enter(writeFileHandle)
        defer { objc_sync_exit(writeFileHandle) }

        var error: Error?
        do {
            try writeFileHandle.seek(toOffset: UInt64(range.location))
            if #available(iOS 13.4, *) {
                try writeFileHandle.write(contentsOf: data)
            } else {
                try ErrorManager.tryCatch { writeFileHandle.write(data) }
            }
            writeBytes += data.count
            cacheConfiguration.addCacheFragment(range)
        } catch let fileError {
            error = fileError
        }

        if let error {
            throw error
        }
    }

    public func cachedDataActions(for range: NSRange) -> [PlayerCacheAction] {
        let cachedFragments = cacheConfiguration.cacheFragments
        var actions = [PlayerCacheAction]()
        if range.location == NSNotFound {
            return actions
        }

        let endOffset = range.location + range.length
        for fragment in cachedFragments {
            let fragmentRange = fragment.rangeValue
            let intersectionRange = NSIntersectionRange(range, fragmentRange)
            if intersectionRange.length > 0 {
                let package = intersectionRange.length / Self.packageLength
                for i in 0...package {
                    let action = PlayerCacheAction()
                    action.actionType = .local

                    let offset = i * Self.packageLength
                    let offsetLocation = intersectionRange.location + offset
                    let maxLocation = intersectionRange.location + intersectionRange.length
                    let length = (offsetLocation + Self.packageLength) > maxLocation ? (maxLocation - offsetLocation) : Self.packageLength
                    action.range = NSRange(location: offsetLocation, length: length)

                    actions.append(action)
                }
            } else if fragmentRange.location >= endOffset {
                break
            }
        }

        if actions.isEmpty {
            let action = PlayerCacheAction()
            action.actionType = .remote
            action.range = range
            actions.append(action)
        } else {
            var localRemoteActions = [PlayerCacheAction]()
            for (idx, obj) in actions.enumerated() {
                let actionRange = obj.range
                if idx == 0 {
                    if range.location < actionRange.location {
                        let action = PlayerCacheAction()
                        action.actionType = .remote
                        action.range = NSRange(location: range.location, length: actionRange.location - range.location)
                        localRemoteActions.append(action)
                    }
                    localRemoteActions.append(obj)
                } else {
                    let lastAction = localRemoteActions.last ?? .init()
                    let lastOffset = lastAction.range.location + lastAction.range.length
                    if actionRange.location > lastOffset {
                        let action = PlayerCacheAction()
                        action.actionType = .remote
                        action.range = NSRange(location: lastOffset, length: actionRange.location - lastOffset)
                        localRemoteActions.append(action)
                    }
                    localRemoteActions.append(obj)
                }

                if idx == actions.count - 1 {
                    let localEndOffset = actionRange.location + actionRange.length
                    if endOffset > localEndOffset {
                        let action = PlayerCacheAction()
                        action.actionType = .remote
                        action.range = NSRange(location: localEndOffset, length: endOffset - localEndOffset)
                        localRemoteActions.append(action)
                    }
                }
            }

            actions = localRemoteActions
        }

        return actions
    }

    public func cachedData(for range: NSRange) throws -> Data? {
        guard let readFileHandle else { return nil }
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        try readFileHandle.seek(toOffset: UInt64(range.location))
        var data: Data?
        if #available(iOS 13.4, *) {
            data = try readFileHandle.read(upToCount: range.length)
        } else {
            try ErrorManager.tryCatch { data = readFileHandle.readData(ofLength: range.length) }
        }
        return data
    }

    public func setContentInfo(_ contentInfo: PlayerCacheContentInfo) throws {
        cacheConfiguration.contentInfo = contentInfo
        try writeFileHandle?.truncate(atOffset: contentInfo.contentLength)
        try writeFileHandle?.synchronize()
    }

    public func save() {
        guard let writeFileHandle else { return }
        objc_sync_enter(writeFileHandle)
        defer { objc_sync_exit(writeFileHandle) }

        try? writeFileHandle.synchronize()
        cacheConfiguration.save()
    }

    public func startWritting() {
        if !writting {
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
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
        save()
    }
}
