/*!
 @header     FWNetworkManager.h
 @indexgroup FWFramework
 @brief      FWNetworkManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/7/18
 */

#import "FWURLRequestSerialization.h"
#import "FWURLResponseSerialization.h"
#import "FWSecurityPolicy.h"
#import "FWNetworkReachabilityManager.h"
#import "FWURLSessionManager.h"
#import "FWHTTPSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAutoPurgingImageCache

/**
 The `FWImageCache` protocol defines a set of APIs for adding, removing and fetching images from a cache synchronously.
 */
@protocol FWImageCache <NSObject>

/**
 Adds the image to the cache with the given identifier.

 @param image The image to cache.
 @param identifier The unique identifier for the image in the cache.
 */
- (void)addImage:(UIImage *)image withIdentifier:(NSString *)identifier;

/**
 Removes the image from the cache matching the given identifier.

 @param identifier The unique identifier for the image in the cache.

 @return A BOOL indicating whether or not the image was removed from the cache.
 */
- (BOOL)removeImageWithIdentifier:(NSString *)identifier;

/**
 Removes all images from the cache.

 @return A BOOL indicating whether or not all images were removed from the cache.
 */
- (BOOL)removeAllImages;

/**
 Returns the image in the cache associated with the given identifier.

 @param identifier The unique identifier for the image in the cache.

 @return An image for the matching identifier, or nil.
 */
- (nullable UIImage *)imageWithIdentifier:(NSString *)identifier;
@end


/**
 The `ImageRequestCache` protocol extends the `ImageCache` protocol by adding methods for adding, removing and fetching images from a cache given an `NSURLRequest` and additional identifier.
 */
@protocol FWImageRequestCache <FWImageCache>

/**
 Asks if the image should be cached using an identifier created from the request and additional identifier.
 
 @param image The image to be cached.
 @param request The unique URL request identifing the image asset.
 @param identifier The additional identifier to apply to the URL request to identify the image.
 
 @return A BOOL indicating whether or not the image should be added to the cache. YES will cache, NO will prevent caching.
 */
- (BOOL)shouldCacheImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

/**
 Adds the image to the cache using an identifier created from the request and additional identifier.

 @param image The image to cache.
 @param request The unique URL request identifing the image asset.
 @param identifier The additional identifier to apply to the URL request to identify the image.
 */
- (void)addImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

/**
 Removes the image from the cache using an identifier created from the request and additional identifier.

 @param request The unique URL request identifing the image asset.
 @param identifier The additional identifier to apply to the URL request to identify the image.
 
 @return A BOOL indicating whether or not all images were removed from the cache.
 */
- (BOOL)removeImageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

/**
 Returns the image from the cache associated with an identifier created from the request and additional identifier.

 @param request The unique URL request identifing the image asset.
 @param identifier The additional identifier to apply to the URL request to identify the image.

 @return An image for the matching request and identifier, or nil.
 */
- (nullable UIImage *)imageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

@end

/**
 The `AutoPurgingImageCache` in an in-memory image cache used to store images up to a given memory capacity. When the memory capacity is reached, the image cache is sorted by last access date, then the oldest image is continuously purged until the preferred memory usage after purge is met. Each time an image is accessed through the cache, the internal access date of the image is updated.
 */
@interface FWAutoPurgingImageCache : NSObject <FWImageRequestCache>

/**
 The total memory capacity of the cache in bytes.
 */
@property (nonatomic, assign) UInt64 memoryCapacity;

/**
 The preferred memory usage after purge in bytes. During a purge, images will be purged until the memory capacity drops below this limit.
 */
@property (nonatomic, assign) UInt64 preferredMemoryUsageAfterPurge;

/**
 The current total memory usage in bytes of all images stored within the cache.
 */
@property (nonatomic, assign, readonly) UInt64 memoryUsage;

/**
 Initialies the `AutoPurgingImageCache` instance with default values for memory capacity and preferred memory usage after purge limit. `memoryCapcity` defaults to `100 MB`. `preferredMemoryUsageAfterPurge` defaults to `60 MB`.

 @return The new `AutoPurgingImageCache` instance.
 */
- (instancetype)init;

/**
 Initialies the `AutoPurgingImageCache` instance with the given memory capacity and preferred memory usage
 after purge limit.

 @param memoryCapacity The total memory capacity of the cache in bytes.
 @param preferredMemoryCapacity The preferred memory usage after purge in bytes.

 @return The new `AutoPurgingImageCache` instance.
 */
- (instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity preferredMemoryCapacity:(UInt64)preferredMemoryCapacity;

@end

#pragma mark - FWImageDownloader

typedef NS_ENUM(NSInteger, FWImageDownloadPrioritization) {
    FWImageDownloadPrioritizationFIFO,
    FWImageDownloadPrioritizationLIFO
};

/**
 The `FWImageDownloadReceipt` is an object vended by the `FWImageDownloader` when starting a data task. It can be used to cancel active tasks running on the `FWImageDownloader` session. As a general rule, image data tasks should be cancelled using the `FWImageDownloadReceipt` instead of calling `cancel` directly on the `task` itself. The `FWImageDownloader` is optimized to handle duplicate task scenarios as well as pending versus active downloads.
 */
@interface FWImageDownloadReceipt : NSObject

/**
 The data task created by the `FWImageDownloader`.
*/
@property (nonatomic, strong) NSURLSessionDataTask *task;

/**
 The unique identifier for the success and failure blocks when duplicate requests are made.
 */
@property (nonatomic, strong) NSUUID *receiptID;
@end

/** The `FWImageDownloader` class is responsible for downloading images in parallel on a prioritized queue. Incoming downloads are added to the front or back of the queue depending on the download prioritization. Each downloaded image is cached in the underlying `NSURLCache` as well as the in-memory image cache. By default, any download request with a cached image equivalent in the image cache will automatically be served the cached image representation.
 */
@interface FWImageDownloader : NSObject

/**
 The image cache used to store all downloaded images in. `FWAutoPurgingImageCache` by default.
 */
@property (nonatomic, strong, nullable) id <FWImageRequestCache> imageCache;

/**
 The `FWHTTPSessionManager` used to download images. By default, this is configured with an `FWImageResponseSerializer`, and a shared `NSURLCache` for all image downloads.
 */
@property (nonatomic, strong) FWHTTPSessionManager *sessionManager;

/**
 Defines the order prioritization of incoming download requests being inserted into the queue. `FWImageDownloadPrioritizationFIFO` by default.
 */
@property (nonatomic, assign) FWImageDownloadPrioritization downloadPrioritization;

/**
 The shared default instance of `FWImageDownloader` initialized with default values.
 */
+ (instancetype)defaultInstance;

/**
 Creates a default `NSURLCache` with common usage parameter values.

 @returns The default `NSURLCache` instance.
 */
+ (NSURLCache *)defaultURLCache;

/**
 The default `NSURLSessionConfiguration` with common usage parameter values.
 */
+ (NSURLSessionConfiguration *)defaultURLSessionConfiguration;

/**
 Default initializer

 @return An instance of `FWImageDownloader` initialized with default values.
 */
- (instancetype)init;

/**
 Initializer with specific `URLSessionConfiguration`
 
 @param configuration The `NSURLSessionConfiguration` to be be used
 
 @return An instance of `FWImageDownloader` initialized with default values and custom `NSURLSessionConfiguration`
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/**
 Initializes the `FWImageDownloader` instance with the given session manager, download prioritization, maximum active download count and image cache.

 @param sessionManager The session manager to use to download images.
 @param downloadPrioritization The download prioritization of the download queue.
 @param maximumActiveDownloads  The maximum number of active downloads allowed at any given time. Recommend `4`.
 @param imageCache The image cache used to store all downloaded images in.

 @return The new `FWImageDownloader` instance.
 */
- (instancetype)initWithSessionManager:(FWHTTPSessionManager *)sessionManager
                downloadPrioritization:(FWImageDownloadPrioritization)downloadPrioritization
                maximumActiveDownloads:(NSInteger)maximumActiveDownloads
                            imageCache:(nullable id <FWImageRequestCache>)imageCache;

/**
 Creates a data task using the `sessionManager` instance for the specified URL request.

 If the same data task is already in the queue or currently being downloaded, the success and failure blocks are
 appended to the already existing task. Once the task completes, all success or failure blocks attached to the
 task are executed in the order they were added.

 @param request The URL request.
 @param success A block to be executed when the image data task finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the response parameter will be `nil`.
 @param failure A block object to be executed when the image data task finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.

 @return The image download receipt for the data task if available. `nil` if the image is stored in the cache.
 cache and the URL request cache policy allows the cache to be used.
 */
- (nullable FWImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)request
                                                        success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                        failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                        progress:(nullable void (^)(NSProgress *downloadProgress))progress;

/**
 Creates a data task using the `sessionManager` instance for the specified URL request.

 If the same data task is already in the queue or currently being downloaded, the success and failure blocks are
 appended to the already existing task. Once the task completes, all success or failure blocks attached to the
 task are executed in the order they were added.

 @param request The URL request.
 @param receiptID The identifier to use for the download receipt that will be created for this request. This must be a unique identifier that does not represent any other request.
 @param success A block to be executed when the image data task finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the response parameter will be `nil`.
 @param failure A block object to be executed when the image data task finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.

 @return The image download receipt for the data task if available. `nil` if the image is stored in the cache.
 cache and the URL request cache policy allows the cache to be used.
 */
- (nullable FWImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)request
                                                 withReceiptID:(NSUUID *)receiptID
                                                        success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                        failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                       progress:(nullable void (^)(NSProgress *downloadProgress))progress;

/**
 Cancels the data task in the receipt by removing the corresponding success and failure blocks and cancelling the data task if necessary.

 If the data task is pending in the queue, it will be cancelled if no other success and failure blocks are registered with the data task. If the data task is currently executing or is already completed, the success and failure blocks are removed and will not be called when the task finishes.

 @param imageDownloadReceipt The image download receipt to cancel.
 */
- (void)cancelTaskForImageDownloadReceipt:(FWImageDownloadReceipt *)imageDownloadReceipt;

@end

#pragma mark - UIImageView+FWNetwork

/**
 This category adds methods to the UIKit framework's `UIImageView` class. The methods in this category provide support for loading remote images asynchronously from a URL.
 */
@interface UIImageView (FWNetwork)

///------------------------------------
/// @name Accessing the Image Downloader
///------------------------------------

/**
 Set the shared image downloader used to download images.

 @param imageDownloader The shared image downloader used to download images.
 */
+ (void)fwSetSharedImageDownloader:(FWImageDownloader *)imageDownloader;

/**
 The shared image downloader used to download images.
 */
+ (FWImageDownloader *)fwSharedImageDownloader;

///--------------------
/// @name Setting Image
///--------------------

/**
 Asynchronously downloads an image from the specified URL, and sets it once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 By default, URL requests have a `Accept` header field value of "image / *", a cache policy of `NSURLCacheStorageAllowed` and a timeout interval of 30 seconds, and are set not handle cookies. To configure URL requests differently, use `setImageWithURLRequest:placeholderImage:success:failure:`

 @param url The URL used for the image request.
 */
- (void)fwSetImageWithURL:(id)url;

/**
 Asynchronously downloads an image from the specified URL, and sets it once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 By default, URL requests have a `Accept` header field value of "image / *", a cache policy of `NSURLCacheStorageAllowed` and a timeout interval of 30 seconds, and are set not handle cookies. To configure URL requests differently, use `setImageWithURLRequest:placeholderImage:success:failure:`

 @param url The URL used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the image view will not change its image until the image request finishes.
 */
- (void)fwSetImageWithURL:(id)url
         placeholderImage:(nullable UIImage *)placeholderImage;

/**
 Asynchronously downloads an image from the specified URL request, and sets it once the request is finished. Any previous image request for the receiver will be cancelled.
 
 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.
 
 If a completion block is specified, it is the responsibility of the block to set the image of the image view before returning. If no completion block is specified, the default behavior of setting the image with `self.fwImage = image` is applied.
 
 @param url The URL request used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes completely. If `nil`, the image view will not change its image until the image request finishes.
 @param completion A block to be executed when the image data task finishes. This block has no return value and takes two arguments: the image created from the response data of request, and the error object describing the network or parsing error that occurred. If the image was returned from cache, the error parameter will be `nil`.
 */
- (void)fwSetImageWithURL:(id)url
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion;

/**
 Asynchronously downloads an image from the specified URL request, and sets it once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 If a success block is specified, it is the responsibility of the block to set the image of the image view before returning. If no success block is specified, the default behavior of setting the image with `self.fwImage = image` is applied.

 @param urlRequest The URL request used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the image view will not change its image until the image request finishes.
 @param success A block to be executed when the image data task finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the response parameter will be `nil`.
 @param failure A block object to be executed when the image data task finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.
 @param progress A block object to be executed when the image data task executing. This block has no return value and takes one argument: the progress received from the server.
 */
- (void)fwSetImageWithURLRequest:(NSURLRequest *)urlRequest
                placeholderImage:(nullable UIImage *)placeholderImage
                         success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *image))success
                         failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                         progress:(nullable void (^)(NSProgress *downloadProgress))progress;

/**
 Cancels any executing image operation for the receiver, if one exists.
 */
- (void)fwCancelImageDownloadTask;

@end

#pragma mark - FWImagePlugin

/*!
 @brief 图片插件协议，应用可自定义图片实现
 */
@protocol FWImagePlugin <NSObject>

@optional

// imageView动画视图类插件方法，默认使用UIImageView
- (Class)fwImageViewAnimatedClass;

// imageView加载网络图片插件方法，默认使用框架网络库
- (void)fwImageView:(UIImageView *)imageView
        setImageUrl:(NSString *)imageUrl
        placeholder:(nullable UIImage *)placeholder
         completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
           progress:(nullable void (^)(float progress))progress;

@end

NS_ASSUME_NONNULL_END
