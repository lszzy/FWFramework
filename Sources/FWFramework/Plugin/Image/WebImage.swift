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
    func removeAllImages() -> Bool
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

    @objc open func removeAllImages() -> Bool {
        var removed = false
        synchronizationQueue.sync(flags: .barrier) {
            if !self.cachedImages.isEmpty {
                self.cachedImages.removeAll()
                self.currentMemoryUsage = 0
                removed = true
            }
        }
        return removed
    }
    
    open func image(identifier: String) -> UIImage? {
        var image: UIImage?
        synchronizationQueue.sync {
            let cachedImage = self.cachedImages[identifier]
            image = cachedImage?.accessImage()
        }
        return image
    }

    open func addImage(_ image: UIImage, for request: URLRequest, additionalIdentifier: String?) {
        let cacheKey = imageCacheKey(for: request, additionalIdentifier: additionalIdentifier)
        addImage(image, identifier: cacheKey)
    }

    open func removeImage(for request: URLRequest, additionalIdentifier: String?) -> Bool {
        let cacheKey = imageCacheKey(for: request, additionalIdentifier: additionalIdentifier)
        return removeImage(identifier: cacheKey)
    }

    open func image(for request: URLRequest, additionalIdentifier: String?) -> UIImage? {
        let cacheKey = imageCacheKey(for: request, additionalIdentifier: additionalIdentifier)
        return image(identifier: cacheKey)
    }

    open func shouldCacheImage(_ image: UIImage, for request: URLRequest, additionalIdentifier: String?) -> Bool {
        return true
    }
    
    open func imageCacheKey(for request: URLRequest, additionalIdentifier: String?) -> String {
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
