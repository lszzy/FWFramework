//
//  PlayerCache.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/25.
//

import Foundation
import AVFoundation

/*
// MARK: - PlayerCacheLoaderManager
public protocol PlayerCacheLoaderManagerDelegate: AnyObject {
    func resourceLoaderManagerLoadURL(_ url: URL, didFailWithError: Error)
}

/// 多媒体边下边播缓存管理器
///
/// [VIMediaCache](https://github.com/vitoziv/VIMediaCache)
open class PlayerCacheLoaderManager: NSObject, AVAssetResourceLoaderDelegate {
    open weak var delegate: PlayerCacheLoaderManagerDelegate?
    
    open func cleanCache() {
        
    }
    
    open func cancelLoaders() {
        
    }
    
    public static func assetURL(url: URL) -> URL {
        
    }
    
    open func urlAsset(url: URL) -> AVURLAsset {
        
    }
    
    open func playerItem(url: URL) -> AVPlayerItem {
        
    }
}

// MARK: - PlayerCacheLoader
public protocol PlayerCacheLoaderDelegate: AnyObject {
    func resourceLoader(_ resourceLoader: PlayerCacheLoader, didFailWithError: Error)
}

open class PlayerCacheLoader: NSObject {
    open private(set) var url: URL
    open weak var delegate: PlayerCacheLoaderDelegate?
    
    public init(url: URL) {
        self.url = url
        super.init()
    }
    
    open func addRequest(_ request: AVAssetResourceLoadingRequest) {
        
    }
    
    open func removeRequest(_ request: AVAssetResourceLoadingRequest) {
        
    }
    
    open func cancel() {
        
    }
}

// MARK: - PlayerCacheDownloader
open class PlayerCacheDownloaderStatus: NSObject {
    public static let shared = PlayerCacheDownloaderStatus()
    
    open var urls: Set<URL> {
        
    }
    
    open func addUrl(_ url: URL) {
        
    }
    
    open func removeUrl(_ url: URL) {
        
    }
    
    open func containsUrl(_ url: URL) -> Bool {
        
    }
}

@objc public protocol PlayerCacheDownloaderDelegate {
    @objc optional func mediaDownloader(_ downloader: PlayerCacheDownloader, didReceiveResponse: URLResponse)
    @objc optional func mediaDownloader(_ downloader: PlayerCacheDownloader, didReceiveData: Data)
    @objc optional func mediaDownloader(_ downloader: PlayerCacheDownloader, didFinishedWithError: Error)
}

open class PlayerCacheDownloader: NSObject {
    open private(set) var url: URL
    open weak var delegate: PlayerCacheDownloaderDelegate?
    open var info: PlayerCacheContentInfo
    open var saveToCache = false
    
    public init(url: URL, cacheWorker: PlayerCacheWorker) {
        
    }
    
    open func downloadTaskFrom(offset: UInt64, length: UInt, toEnd: Bool) {
        
    }
    
    open func downloadFromStartToEnd() {
        
    }
    
    open func cancel() {
        
        
    }
}

// MARK: - PlayerCacheRequestWorker
public protocol PlayerCacheRequestWorkerDelegate: AnyObject {
    func resourceLoadingRequestWorker(_ requestWorker: PlayerCacheRequestWorker, didCompleteWithError: Error)
}

open class PlayerCacheRequestWorker: NSObject {
    open weak var delegate: PlayerCacheRequestWorkerDelegate?
    open private(set) var request: AVAssetResourceLoadingRequest
    
    public init(mediaDownloader: PlayerCacheDownloader, resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        
    }
    
    open func startWork() {
        
    }
    
    open func cancel() {
        
    }
    
    open func finish() {
        
    }
}

// MARK: - PlayerCacheContentInfo
open class PlayerCacheContentInfo: NSObject {
    open var contentType: String = ""
    open var byteRangeAccessSupported = false
    open var contentLength: UInt64 = 0
    open var downloadedContentLength: UInt64 = 0
}

// MARK: - PlayerCacheAction
public enum PlayerCacheAtionType: Int {
    case local = 0
    case remote
}

open class PlayerCacheAction: NSObject {
    open var actionType: PlayerCacheAtionType
    open var range: NSRange
    
    public init(actionType: PlayerCacheAtionType, range: NSRange) {
        self.actionType = actionType
        self.range = range
        super.init()
    }
}

// MARK: - PlayerCacheConfiguration
open class PlayerCacheConfiguration: NSObject, NSCopying {
    open private(set) var filePath: String
    open var contentInfo: PlayerCacheContentInfo
    open var url: URL
    open var cacheFragments: [NSValue] {
        
    }
    open var progress: Float {
        
    }
    open var downloadedBytes: Int64 {
        
    }
    open var downloadSpeed: Float {
        
    }
    
    public static func configurationFilePath(for filePath: String) -> String {
        
    }
    
    public static func createAndSaveDownloadedConfiguration(for url: URL) throws {
        
    }
    
    public init(filePath: String) {
        
    }
    
    open func save() {
        
    }
    
    open func addCacheFragment(_ fragment: NSRange) {
        
    }
    
    open func addDownloadedBytes(bytes: Int64, spent time: TimeInterval) {
        
    }
}

// MARK: - PlayerCacheManager
open class PlayerCacheManager: NSObject {
    public static let playerCacheManagerDidUpdateNotification = Notification.Name("")
    public static let playerCacheManagerDidFinishNotification = Notification.Name("")
    public static let playerCacheConfigurationKey = ""
    public static let playerCacheFinishedErrorKey = ""
    
    public static var cacheDirectory: String = ""
    public static var cacheUpdateNotifyInterval: TimeInterval = 0
    
    public static func cachedFilePath(for url: URL) -> String {
        
    }
    
    public static func cacheConfiguration(for url: URL) -> PlayerCacheConfiguration {
        
    }
    
    public static func setFileNameRules(_ block: ((URL) -> String)?) {
        
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
open class PlayerCacheSessionManager: NSObject {
    public static let shared = PlayerCacheSessionManager()
    
    open private(set) var downloadQueue: OperationQueue
}

// MARK: - PlayerCacheWorker
open class PlayerCacheWorker: NSObject {
    open private(set) var cacheConfiguration: PlayerCacheConfiguration
    open private(set) var setupError: Error?
    
    public init(url: URL) {
        
    }
    
    open func cacheData(_ data: Data, for range: NSRange) throws {
        
    }
    
    open func cachedDataActions(for range: NSRange) -> [PlayerCacheAction] {
        
    }
    
    open func cachedData(for range: NSRange) throws -> Data {
        
    }
    
    open func setContentInfo(_ contentInfo: PlayerCacheContentInfo) throws {
        
    }
    
    open func save() {
        
    }
    
    open func startWritting() {
        
    }
    
    open func finishWritting() {
        
    }
}*/
