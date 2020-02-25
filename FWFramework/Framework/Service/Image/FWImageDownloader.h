// FWImageDownloader.h
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV 

#import <Foundation/Foundation.h>
#import "FWAutoPurgingImageCache.h"
#import "FWHTTPSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

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
@property (nonatomic, assign) FWImageDownloadPrioritization downloadPrioritizaton;

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

#endif

NS_ASSUME_NONNULL_END
