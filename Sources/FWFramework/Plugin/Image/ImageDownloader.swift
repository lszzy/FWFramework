//
//  ImageDownloader.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import UIKit

// MARK: - ImageDownloader
/// 图片下载优先顺序
public enum ImageDownloadPrioritization: Int, Sendable {
    case FIFO
    case LIFO
}

/// 图片下载凭据
open class ImageDownloadReceipt: NSObject, @unchecked Sendable {
    public let task: URLSessionDataTask
    public let receiptID: UUID

    public init(receiptID: UUID, task: URLSessionDataTask) {
        self.receiptID = receiptID
        self.task = task
        super.init()
    }
}

/// 图片下载器，默认解码scale为1，同SDWebImage
///
/// [AFNetworking](https://github.com/AFNetworking/AFNetworking)
open class ImageDownloader: NSObject, @unchecked Sendable {
    // MARK: - Accessor
    public static let shared = ImageDownloader()

    public static func defaultURLCache() -> URLCache {
        URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 150 * 1024 * 1024,
            diskPath: "FWFramework/ImageCache"
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

    // MARK: - Lifecycle
    override public convenience init() {
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

    // MARK: - Public
    open func downloadImage(
        for url: Any?,
        receiptID: UUID = UUID(),
        options: WebImageOptions,
        context: [ImageCoderOptions: Any]?,
        success: (@MainActor @Sendable (URLRequest, HTTPURLResponse?, UIImage) -> Void)?,
        failure: (@MainActor @Sendable (URLRequest?, HTTPURLResponse?, Error) -> Void)?,
        progress: (@MainActor @Sendable (Progress) -> Void)?
    ) -> ImageDownloadReceipt? {
        let request = urlRequest(url: url, options: options)
        var task: URLSessionDataTask?
        synchronizationQueue.sync {
            let urlIdentifier = request?.url?.absoluteString ?? ""
            guard let request, !urlIdentifier.isEmpty else {
                if failure != nil {
                    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
                    DispatchQueue.main.async {
                        failure?(request, nil, error)
                    }
                }
                return
            }

            if let existingMergedTask = self.mergedTasks[urlIdentifier] {
                let handler = ImageDownloaderResponseHandler(uuid: receiptID, successBlock: success, failureBlock: failure, progressBlock: progress)
                existingMergedTask.addResponseHandler(handler)
                task = existingMergedTask.task
                return
            }

            switch request.cachePolicy {
            case .useProtocolCachePolicy, .returnCacheDataElseLoad, .returnCacheDataDontLoad:
                if !(options.contains(.refreshCached)) && !(options.contains(.ignoreCache)) {
                    if let cachedImage = self.imageCache?.image(for: request, additionalIdentifier: nil) {
                        if success != nil {
                            DispatchQueue.main.async {
                                success?(request, nil, cachedImage)
                            }
                        }
                        return
                    }
                }
            default:
                break
            }

            let mergedTaskIdentifier = UUID()
            var createdTask: URLSessionDataTask
            createdTask = self.sessionManager.dataTask(request: request, uploadProgress: nil, downloadProgress: { [weak self] downloadProgress in
                self?.responseQueue.async { [weak self] in
                    let mergedTask = self?.safelyGetMergedTask(urlIdentifier)
                    if mergedTask?.identifier == mergedTaskIdentifier {
                        let responseHandlers = self?.safelyGetResponseHandlers(urlIdentifier) ?? []
                        for handler in responseHandlers {
                            if handler.progressBlock != nil {
                                DispatchQueue.main.async {
                                    handler.progressBlock?(downloadProgress)
                                }
                            }
                        }
                    }
                }
            }, completionHandler: { [weak self] response, responseObject, error in
                let sendableResponseObject = SendableObject(responseObject)
                self?.responseQueue.async { [weak self] in
                    var mergedTask = self?.safelyGetMergedTask(urlIdentifier)
                    if mergedTask?.identifier == mergedTaskIdentifier {
                        mergedTask = self?.safelyRemoveMergedTask(urlIdentifier)
                        if let image = sendableResponseObject.object as? UIImage, error == nil {
                            if self?.imageCache?.shouldCacheImage(image, for: request, additionalIdentifier: nil) ?? false {
                                self?.imageCache?.addImage(image, for: request, additionalIdentifier: nil)
                            }

                            let responseHandlers = mergedTask?.responseHandlers ?? []
                            for handler in responseHandlers {
                                if handler.successBlock != nil {
                                    DispatchQueue.main.async {
                                        handler.successBlock?(request, response as? HTTPURLResponse, image)
                                    }
                                }
                            }
                        } else {
                            let error = error ?? NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
                            let responseHandlers = mergedTask?.responseHandlers ?? []
                            for handler in responseHandlers {
                                if handler.failureBlock != nil {
                                    DispatchQueue.main.async {
                                        handler.failureBlock?(request, response as? HTTPURLResponse, error)
                                    }
                                }
                            }
                        }
                    }
                    self?.safelyDecrementActiveTaskCount()
                    self?.safelyStartNextTaskIfNecessary()
                }
            })

            if context != nil {
                self.sessionManager.setUserInfo(context, for: createdTask)
            }

            let handler = ImageDownloaderResponseHandler(uuid: receiptID, successBlock: success, failureBlock: failure, progressBlock: progress)
            let mergedTask = ImageDownloaderMergedTask(urlIdentifier: urlIdentifier, identifier: mergedTaskIdentifier, task: createdTask)
            mergedTask.addResponseHandler(handler)
            self.mergedTasks[urlIdentifier] = mergedTask

            if self.isActiveRequestCountBelowMaximumLimit() {
                self.startMergedTask(mergedTask)
            } else {
                self.enqueueMergedTask(mergedTask)
            }

            task = mergedTask.task
        }
        guard let task else { return nil }
        return ImageDownloadReceipt(receiptID: receiptID, task: task)
    }

    open func cancelTask(for imageDownloadReceipt: ImageDownloadReceipt) {
        synchronizationQueue.sync {
            let urlIdentifier = imageDownloadReceipt.task.originalRequest?.url?.absoluteString ?? ""
            let mergedTask = self.mergedTasks[urlIdentifier]
            let handler = mergedTask?.responseHandlers.first(where: { $0.uuid == imageDownloadReceipt.receiptID
            })

            if let handler {
                mergedTask?.removeResponseHandler(handler)
                let failureReason = "ImageDownloader cancelled URL request: \(urlIdentifier)"
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [
                    NSLocalizedFailureReasonErrorKey: failureReason
                ])
                if handler.failureBlock != nil {
                    DispatchQueue.main.async {
                        handler.failureBlock?(imageDownloadReceipt.task.originalRequest, nil, error)
                    }
                }
            }

            if let mergedTask, mergedTask.responseHandlers.isEmpty {
                mergedTask.task.cancel()
                self.removeMergedTask(urlIdentifier)
            }
        }
    }

    open func imageURL(for object: Any) -> URL? {
        NSObject.fw.getAssociatedObject(object, key: "imageURL(for:)") as? URL
    }

    open func imageOperationKey(for object: Any) -> String? {
        NSObject.fw.getAssociatedObject(object, key: "imageOperationKey(for:)") as? String
    }

    open func downloadImage<T>(
        for object: T,
        imageURL: Any?,
        options: WebImageOptions,
        context: [ImageCoderOptions: Any]?,
        placeholder: (() -> Void)?,
        completion: (@MainActor @Sendable (UIImage?, Bool, Error?) -> Void)?,
        progress: (@MainActor @Sendable (Double) -> Void)?
    ) where T: Sendable {
        let urlRequest = urlRequest(url: imageURL, options: options)
        setImageOperationKey(String(describing: type(of: object)), for: object)
        if let activeReceipt = activeImageDownloadReceipt(for: object) {
            cancelTask(for: activeReceipt)
            setActiveImageDownloadReceipt(nil, for: object)
        }
        setImageURL(urlRequest?.url, for: object)

        guard let urlRequest, urlRequest.url != nil else {
            placeholder?()
            DispatchQueue.fw.mainAsync {
                completion?(nil, false, NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil))
            }
            return
        }

        var cachedImage: UIImage?
        if !(options.contains(.refreshCached)) && !(options.contains(.ignoreCache)) {
            cachedImage = imageCache?.image(for: urlRequest, additionalIdentifier: nil)
        }
        if let cachedImage {
            DispatchQueue.fw.mainAsync { [weak self] in
                completion?(cachedImage, true, nil)
                self?.setActiveImageDownloadReceipt(nil, for: object)
            }
        } else {
            placeholder?()
            let downloadID = UUID()
            let receipt = downloadImage(for: urlRequest, receiptID: downloadID, options: options, context: context, success: { [weak self] _, _, responseObject in
                if self?.activeImageDownloadReceipt(for: object)?.receiptID == downloadID {
                    ImageResponseSerializer.clearCachedResponseData(for: responseObject)
                    completion?(responseObject, false, nil)
                    self?.setActiveImageDownloadReceipt(nil, for: object)
                }
            }, failure: { [weak self] _, _, error in
                if self?.activeImageDownloadReceipt(for: object)?.receiptID == downloadID {
                    completion?(nil, false, error)
                    self?.setActiveImageDownloadReceipt(nil, for: object)
                }
            }, progress: progress != nil ? { @MainActor @Sendable [weak self] downloadProgress in
                if self?.activeImageDownloadReceipt(for: object)?.receiptID == downloadID {
                    progress?(downloadProgress.fractionCompleted)
                }
            } : nil)

            setActiveImageDownloadReceipt(receipt, for: object)
        }
    }

    open func cancelImageDownloadTask(_ object: Any) {
        if let receipt = activeImageDownloadReceipt(for: object) {
            cancelTask(for: receipt)
            setActiveImageDownloadReceipt(nil, for: object)
        }
        setImageOperationKey(nil, for: object)
    }

    open func loadImageCache(for url: Any?) -> UIImage? {
        guard let urlRequest = urlRequest(url: url) else {
            return nil
        }

        if let cachedImage = imageCache?.image(for: urlRequest, additionalIdentifier: nil) {
            return cachedImage
        }

        guard let cachedResponse = sessionManager.session.configuration.urlCache?.cachedResponse(for: urlRequest),
              let responseObject = try? sessionManager.responseSerializer.responseObject(for: cachedResponse.response, data: cachedResponse.data) else {
            return nil
        }

        return responseObject as? UIImage
    }

    open func clearImageCaches(_ completion: (@MainActor @Sendable () -> Void)? = nil) {
        imageCache?.removeAllImages()
        sessionManager.session.configuration.urlCache?.removeAllCachedResponses()

        if completion != nil {
            DispatchQueue.fw.mainAsync {
                completion?()
            }
        }
    }

    // MARK: - Private
    private func safelyRemoveMergedTask(_ urlIdentifier: String) -> ImageDownloaderMergedTask? {
        var mergedTask: ImageDownloaderMergedTask?
        synchronizationQueue.sync {
            mergedTask = self.removeMergedTask(urlIdentifier)
        }
        return mergedTask
    }

    @discardableResult
    private func removeMergedTask(_ urlIdentifier: String) -> ImageDownloaderMergedTask? {
        let mergedTask = mergedTasks[urlIdentifier]
        mergedTasks.removeValue(forKey: urlIdentifier)
        return mergedTask
    }

    private func safelyDecrementActiveTaskCount() {
        synchronizationQueue.sync {
            if self.activeRequestCount > 0 {
                self.activeRequestCount -= 1
            }
        }
    }

    private func safelyStartNextTaskIfNecessary() {
        synchronizationQueue.sync {
            if self.isActiveRequestCountBelowMaximumLimit() {
                while self.queuedMergedTasks.count > 0 {
                    if let mergedTask = self.dequeueMergedTask(),
                       mergedTask.task.state == .suspended {
                        self.startMergedTask(mergedTask)
                        break
                    }
                }
            }
        }
    }

    private func startMergedTask(_ mergedTask: ImageDownloaderMergedTask) {
        mergedTask.task.resume()
        activeRequestCount += 1
    }

    private func enqueueMergedTask(_ mergedTask: ImageDownloaderMergedTask) {
        switch downloadPrioritization {
        case .FIFO:
            queuedMergedTasks.append(mergedTask)
        case .LIFO:
            queuedMergedTasks.insert(mergedTask, at: 0)
        }
    }

    private func dequeueMergedTask() -> ImageDownloaderMergedTask? {
        guard queuedMergedTasks.count > 0 else { return nil }
        let mergedTask = queuedMergedTasks.removeFirst()
        return mergedTask
    }

    private func isActiveRequestCountBelowMaximumLimit() -> Bool {
        activeRequestCount < maximumActiveDownloads
    }

    private func safelyGetMergedTask(_ urlIdentifer: String) -> ImageDownloaderMergedTask? {
        var mergedTask: ImageDownloaderMergedTask?
        synchronizationQueue.sync {
            mergedTask = self.mergedTasks[urlIdentifer]
        }
        return mergedTask
    }

    private func safelyGetResponseHandlers(_ urlIdentifier: String) -> [ImageDownloaderResponseHandler] {
        var responseHandlers: [ImageDownloaderResponseHandler] = []
        synchronizationQueue.sync {
            let mergedTask = self.mergedTasks[urlIdentifier]
            responseHandlers = mergedTask?.responseHandlers ?? []
        }
        return responseHandlers
    }

    private func activeImageDownloadReceipt(for object: Any) -> ImageDownloadReceipt? {
        NSObject.fw.getAssociatedObject(object, key: "activeImageDownloadReceipt(for:)") as? ImageDownloadReceipt
    }

    private func setActiveImageDownloadReceipt(_ receipt: ImageDownloadReceipt?, for object: Any) {
        NSObject.fw.setAssociatedObject(object, key: "activeImageDownloadReceipt(for:)", value: receipt)
    }

    private func setImageURL(_ imageURL: URL?, for object: Any) {
        NSObject.fw.setAssociatedObject(object, key: "imageURL(for:)", value: imageURL, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    private func setImageOperationKey(_ operationKey: String?, for object: Any) {
        NSObject.fw.setAssociatedObject(object, key: "imageOperationKey(for:)", value: operationKey, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
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

            if let nsurl {
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

private class ImageDownloaderResponseHandler: NSObject, @unchecked Sendable {
    var uuid: UUID
    var successBlock: (@MainActor @Sendable (URLRequest, HTTPURLResponse?, UIImage) -> Void)?
    var failureBlock: (@MainActor @Sendable (URLRequest?, HTTPURLResponse?, Error) -> Void)?
    var progressBlock: (@MainActor @Sendable (Progress) -> Void)?

    init(
        uuid: UUID,
        successBlock: (@MainActor @Sendable (URLRequest, HTTPURLResponse?, UIImage) -> Void)?,
        failureBlock: (@MainActor @Sendable (URLRequest?, HTTPURLResponse?, Error) -> Void)?,
        progressBlock: (@MainActor @Sendable (Progress) -> Void)?
    ) {
        self.uuid = uuid
        self.successBlock = successBlock
        self.failureBlock = failureBlock
        self.progressBlock = progressBlock

        super.init()
    }

    override var description: String {
        "<ImageDownloaderResponseHandler>UUID: \(uuid.uuidString)"
    }
}

private class ImageDownloaderMergedTask: NSObject {
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
open class AutoPurgingImageCache: NSObject, ImageRequestCache, @unchecked Sendable {
    // MARK: - Accessor
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
    private var synchronizationQueue: DispatchQueue = .init(label: "site.wuyong.queue.webimage.cache.\(UUID().uuidString)", attributes: .concurrent)

    // MARK: - Lifecycle
    override public init() {
        super.init()
        didInitialize()
    }

    public init(memoryCapacity: UInt64, preferredMemoryCapacity: UInt64) {
        super.init()
        self.memoryCapacity = memoryCapacity
        preferredMemoryUsageAfterPurge = preferredMemoryCapacity
        didInitialize()
    }

    private func didInitialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(removeAllImages), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public
    open func addImage(_ image: UIImage, identifier: String) {
        synchronizationQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            let cacheImage = CachedImage(image: image, identifier: identifier)

            if let previousCachedImage = cachedImages[identifier] {
                currentMemoryUsage -= previousCachedImage.totalBytes
            }

            cachedImages[identifier] = cacheImage
            currentMemoryUsage += cacheImage.totalBytes
        }

        synchronizationQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            if currentMemoryUsage > memoryCapacity {
                let bytesToPurge = currentMemoryUsage - preferredMemoryUsageAfterPurge
                var sortedImages = Array(cachedImages.values)
                sortedImages.sort { $0.lastAccessDate < $1.lastAccessDate }

                var bytesPurged: UInt64 = 0
                for cachedImage in sortedImages {
                    cachedImages.removeValue(forKey: cachedImage.identifier)
                    bytesPurged += cachedImage.totalBytes
                    if bytesPurged >= bytesToPurge {
                        break
                    }
                }
                currentMemoryUsage -= bytesPurged
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
        true
    }

    open func imageCacheKey(for request: URLRequest, additionalIdentifier: String? = nil) -> String {
        var key = request.url?.absoluteString ?? ""
        if let additionalIdentifier {
            key += additionalIdentifier
        }
        return key
    }
}

private class CachedImage: NSObject {
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
        totalBytes = UInt64(bytesPerPixel * bytesPerSize)
        lastAccessDate = Date()

        super.init()
    }

    func accessImage() -> UIImage {
        lastAccessDate = Date()
        return image
    }

    override var description: String {
        "Identifier: \(identifier), lastAccessDate: \(lastAccessDate)"
    }
}
