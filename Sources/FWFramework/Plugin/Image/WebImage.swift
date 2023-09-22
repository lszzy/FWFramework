//
//  WebImage.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - AutoPurgingImageCache
/// 图片缓存协议
public protocol ImageCache {
    func addImage(_ image: UIImage, identifier: String)
    func removeImage(identifier: String) -> Bool
    func removeAllImages()
    func image(identifier: String) -> UIImage?
}

/// 图片请求缓存协议
public protocol ImageRequestCache: ImageCache {
    func shouldCacheImage(_ image: UIImage, for request: URLRequest, additionalIdentifier: String?) -> Bool
    func addImage(_ image: UIImage, for request: URLRequest, additionalIdentifier: String?)
    func removeImage(for request: URLRequest, additionalIdentifier: String?) -> Bool
    func image(for request: URLRequest, additionalIdentifier: String?) -> UIImage?
}

/// 内存自动清理图片缓存
open class AutoPurgingImageCache: NSObject, ImageRequestCache {
    open var memoryCapacity: UInt64 = 100 * 1024 * 1024
    open var preferredMemoryUsageAfterPurge: UInt64 = 60 * 1024 * 1024
    
    open var memoryUsage: UInt64 {
        var result: UInt64 = 0
        synchronizationQueue.sync {
            result = self.currentMemoryUsage
        }
        return result
    }
    
    private var cachedImages: [String: CachedImage] = [:]
    private var currentMemoryUsage: UInt64 = 0
    private var synchronizationQueue: DispatchQueue = DispatchQueue(label: "site.wuyong.queue.webimage.cache.\(UUID().uuidString)", attributes: .concurrent)
    
    public override init() {
        super.init()
        didInitialize()
    }
    
    public init(memoryCapacity: UInt64, preferredMemoryCapacity: UInt64) {
        super.init()
        self.memoryCapacity = memoryCapacity
        self.preferredMemoryUsageAfterPurge = preferredMemoryCapacity
        didInitialize()
    }
    
    private func didInitialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(removeAllImages), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open func addImage(_ image: UIImage, identifier: String) {
        synchronizationQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let cacheImage = CachedImage(image: image, identifier: identifier)
            
            if let previousCachedImage = self.cachedImages[identifier] {
                self.currentMemoryUsage -= previousCachedImage.totalBytes
            }
            
            self.cachedImages[identifier] = cacheImage
            self.currentMemoryUsage += cacheImage.totalBytes
        }
        
        synchronizationQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            if self.currentMemoryUsage > self.memoryCapacity {
                let bytesToPurge = self.currentMemoryUsage - self.preferredMemoryUsageAfterPurge
                var sortedImages = Array(self.cachedImages.values)
                sortedImages.sort { $0.lastAccessDate < $1.lastAccessDate }
                
                var bytesPurged: UInt64 = 0
                for cachedImage in sortedImages {
                    self.cachedImages.removeValue(forKey: cachedImage.identifier)
                    bytesPurged += cachedImage.totalBytes
                    if bytesPurged >= bytesToPurge {
                        break
                    }
                }
                self.currentMemoryUsage -= bytesPurged
            }
        }
    }
    
    @discardableResult
    open func removeImage(identifier: String) -> Bool {
        var removed = false
        synchronizationQueue.sync(flags: .barrier) {
            if let cachedImage = self.cachedImages[identifier] {
                self.cachedImages.removeValue(forKey: identifier)
                self.currentMemoryUsage -= cachedImage.totalBytes
                removed = true
            }
        }
        return removed
    }

    @objc open func removeAllImages() {
        synchronizationQueue.sync(flags: .barrier) {
            if !self.cachedImages.isEmpty {
                self.cachedImages.removeAll()
                self.currentMemoryUsage = 0
            }
        }
    }
    
    open func image(identifier: String) -> UIImage? {
        var image: UIImage?
        synchronizationQueue.sync {
            let cachedImage = self.cachedImages[identifier]
            image = cachedImage?.accessImage()
        }
        return image
    }

    open func addImage(_ image: UIImage, for request: URLRequest, additionalIdentifier: String? = nil) {
        let cacheKey = imageCacheKey(for: request, additionalIdentifier: additionalIdentifier)
        addImage(image, identifier: cacheKey)
    }

    @discardableResult
    open func removeImage(for request: URLRequest, additionalIdentifier: String? = nil) -> Bool {
        let cacheKey = imageCacheKey(for: request, additionalIdentifier: additionalIdentifier)
        return removeImage(identifier: cacheKey)
    }

    open func image(for request: URLRequest, additionalIdentifier: String? = nil) -> UIImage? {
        let cacheKey = imageCacheKey(for: request, additionalIdentifier: additionalIdentifier)
        return image(identifier: cacheKey)
    }

    open func shouldCacheImage(_ image: UIImage, for request: URLRequest, additionalIdentifier: String? = nil) -> Bool {
        return true
    }
    
    open func imageCacheKey(for request: URLRequest, additionalIdentifier: String? = nil) -> String {
        var key = request.url?.absoluteString ?? ""
        if let additionalIdentifier = additionalIdentifier {
            key += additionalIdentifier
        }
        return key
    }
}

fileprivate class CachedImage: NSObject {
    var image: UIImage
    var identifier: String
    
    var totalBytes: UInt64
    var lastAccessDate: Date
    var currentMemoryUsage: UInt64 = 0
    
    init(image: UIImage, identifier: String) {
        self.image = image
        self.identifier = identifier
        
        let imageSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let bytesPerPixel: CGFloat = 4.0
        let bytesPerSize = imageSize.width * imageSize.height
        self.totalBytes = UInt64(bytesPerPixel * bytesPerSize)
        self.lastAccessDate = Date()
        
        super.init()
    }
    
    func accessImage() -> UIImage {
        lastAccessDate = Date()
        return image
    }
    
    override var description: String {
        return "Identifier: \(identifier), lastAccessDate: \(lastAccessDate)"
    }
}

// MARK: - ImageDownloader
/// 图片下载优先顺序
public enum ImageDownloadPrioritization: Int {
    case FIFO
    case LIFO
}

/// 图片下载凭据
open class ImageDownloadReceipt: NSObject {
    public let task: URLSessionDataTask
    public let receiptID: UUID
    
    public init(receiptID: UUID, task: URLSessionDataTask) {
        self.receiptID = receiptID
        self.task = task
        super.init()
    }
}

fileprivate class ImageDownloaderResponseHandler: NSObject {
    var uuid: UUID
    var successBlock: ((URLRequest, HTTPURLResponse, UIImage) -> Void)?
    var failureBlock: ((URLRequest, HTTPURLResponse, Error) -> Void)?
    var progressBlock: ((Progress) -> Void)?
    
    init(
        uuid: UUID,
        successBlock: ((URLRequest, HTTPURLResponse, UIImage) -> Void)?,
        failureBlock: ((URLRequest, HTTPURLResponse, Error) -> Void)?,
        progressBlock: ((Progress) -> Void)?
    ) {
        self.uuid = uuid
        self.successBlock = successBlock
        self.failureBlock = failureBlock
        self.progressBlock = progressBlock
        
        super.init()
    }
    
    override var description: String {
        return "<ImageDownloaderResponseHandler>UUID: \(uuid.uuidString)"
    }
}

fileprivate class ImageDownloaderMergedTask: NSObject {
    var urlIdentifier: String
    var identifier: UUID
    var task: URLSessionDataTask
    var responseHandlers: [ImageDownloaderResponseHandler] = []
    
    init(urlIdentifier: String, identifier: UUID, task: URLSessionDataTask) {
        self.urlIdentifier = urlIdentifier
        self.identifier = identifier
        self.task = task
        
        super.init()
    }
    
    func addResponseHandler(_ handler: ImageDownloaderResponseHandler) {
        responseHandlers.append(handler)
    }
    
    func removeResponseHandler(_ handler: ImageDownloaderResponseHandler) {
        responseHandlers.removeAll { $0 == handler }
    }
}

/// 图片下载器，默认解码scale为1，同SDWebImage
open class ImageDownloader: NSObject {
    public static var shared = ImageDownloader()

    public static func defaultURLCache() -> URLCache {
        return URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 150 * 1024 * 1024,
            diskPath: "FWImageCache"
        )
    }

    public static func defaultURLSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.httpShouldSetCookies = true
        configuration.httpShouldUsePipelining = false
        
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.allowsCellularAccess = true
        configuration.timeoutIntervalForRequest = 60
        configuration.urlCache = defaultURLCache()
        return configuration
    }
    
    open var imageCache: ImageRequestCache?
    open var sessionManager: HTTPSessionManager
    open var downloadPrioritization: ImageDownloadPrioritization = .FIFO
    
    private var maximumActiveDownloads: Int = 4
    private var activeRequestCount: Int = 0
    private var queuedMergedTasks: [ImageDownloaderMergedTask] = []
    private var mergedTasks: [String: ImageDownloaderMergedTask] = [:]
    private var synchronizationQueue = DispatchQueue(label: "site.wuyong.queue.webimage.download.\(UUID().uuidString)")
    private var responseQueue = DispatchQueue(label: "site.wuyong.queue.webimage.response.\(UUID().uuidString)", attributes: .concurrent)

    public override convenience init() {
        let defaultConfiguration = Self.defaultURLSessionConfiguration()
        self.init(sessionConfiguration: defaultConfiguration)
    }

    public convenience init(sessionConfiguration: URLSessionConfiguration) {
        let sessionManager = HTTPSessionManager(sessionConfiguration: sessionConfiguration)
        let responseSerializer = ImageResponseSerializer()
        responseSerializer.imageScale = 1
        responseSerializer.shouldCacheResponseData = true
        sessionManager.responseSerializer = responseSerializer
        
        self.init(sessionManager: sessionManager, downloadPrioritization: .FIFO, maximumActiveDownloads: 4, imageCache: AutoPurgingImageCache())
    }

    public init(
        sessionManager: HTTPSessionManager,
        downloadPrioritization: ImageDownloadPrioritization,
        maximumActiveDownloads: Int,
        imageCache: ImageRequestCache?
    ) {
        self.sessionManager = sessionManager
        self.downloadPrioritization = downloadPrioritization
        self.maximumActiveDownloads = maximumActiveDownloads
        self.imageCache = imageCache
        
        super.init()
    }

    open func downloadImage(
        for url: Any?,
        receiptID: UUID = UUID(),
        options: WebImageOptions,
        context: [ImageCoderOptions: Any]?,
        success: ((URLRequest, HTTPURLResponse?, UIImage) -> Void)?,
        failure: ((URLRequest, HTTPURLResponse?, Error) -> Void)?,
        progress: ((Progress) -> Void)?
    ) -> ImageDownloadReceipt? {
        return nil
    }

    open func cancelTask(for imageDownloadReceipt: ImageDownloadReceipt) {
        
    }

    open func imageURL(for object: Any) -> URL? {
        return nil
    }

    open func imageOperationKey(for object: Any) -> String? {
        return nil
    }

    open func downloadImage(
        for object: Any,
        imageURL: Any?,
        options: WebImageOptions,
        context: [ImageCoderOptions: Any]?,
        placeholder: (() -> Void)?,
        completion: ((UIImage?, Bool, Error?) -> Void)?,
        progress: ((Double) -> Void)?
    ) {
        
    }

    open func cancelImageDownloadTask(_ object: Any) {
        
    }

    open func loadImageCache(for url: Any?) -> UIImage? {
        return nil
    }

    open func clearImageCaches(_ completion: (() -> Void)? = nil) {
        imageCache?.removeAllImages()
        sessionManager.session.configuration.urlCache?.removeAllCachedResponses()
        
        if completion != nil {
            if Thread.isMainThread {
                completion?()
            } else {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
    
    private func urlRequest(url: Any?, options: WebImageOptions = []) -> URLRequest? {
        var urlRequest: URLRequest?
        if let url = url as? URLRequest {
            urlRequest = url
        } else {
            var nsurl: URL?
            if let url = url as? URL {
                nsurl = url
            } else if let urlString = url as? String, !urlString.isEmpty {
                nsurl = URL(string: urlString)
                if nsurl == nil {
                    nsurl = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
                }
            }
            
            if let nsurl = nsurl {
                var request = URLRequest(url: nsurl)
                if options.contains(.ignoreCache) {
                    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                }
                request.addValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
                urlRequest = request
            }
        }
        return urlRequest
    }
}
