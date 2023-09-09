//
//  WebImage.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "WebImage.h"
#import "HTTPSessionManager.h"
#import <objc/runtime.h>
#import <FWFramework/FWFramework-Swift.h>

#pragma mark - __FWAutoPurgingImageCache

@interface __FWCachedImage : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) UInt64 totalBytes;
@property (nonatomic, strong) NSDate *lastAccessDate;
@property (nonatomic, assign) UInt64 currentMemoryUsage;

@end

@implementation __FWCachedImage

- (instancetype)initWithImage:(UIImage *)image identifier:(NSString *)identifier {
    if (self = [self init]) {
        self.image = image;
        self.identifier = identifier;

        CGSize imageSize = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
        CGFloat bytesPerPixel = 4.0;
        CGFloat bytesPerSize = imageSize.width * imageSize.height;
        self.totalBytes = (UInt64)bytesPerPixel * (UInt64)bytesPerSize;
        self.lastAccessDate = [NSDate date];
    }
    return self;
}

- (UIImage *)accessImage {
    self.lastAccessDate = [NSDate date];
    return self.image;
}

- (NSString *)description {
    NSString *descriptionString = [NSString stringWithFormat:@"Idenfitier: %@  lastAccessDate: %@ ", self.identifier, self.lastAccessDate];
    return descriptionString;

}

@end

@interface __FWAutoPurgingImageCache ()
@property (nonatomic, strong) NSMutableDictionary <NSString* , __FWCachedImage*> *cachedImages;
@property (nonatomic, assign) UInt64 currentMemoryUsage;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@end

@implementation __FWAutoPurgingImageCache

- (instancetype)init {
    return [self initWithMemoryCapacity:100 * 1024 * 1024 preferredMemoryCapacity:60 * 1024 * 1024];
}

- (instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity preferredMemoryCapacity:(UInt64)preferredMemoryCapacity {
    if (self = [super init]) {
        self.memoryCapacity = memoryCapacity;
        self.preferredMemoryUsageAfterPurge = preferredMemoryCapacity;
        self.cachedImages = [[NSMutableDictionary alloc] init];

        NSString *queueName = [NSString stringWithFormat:@"site.wuyong.queue.webimage.cache.%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(removeAllImages)
         name:UIApplicationDidReceiveMemoryWarningNotification
         object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UInt64)memoryUsage {
    __block UInt64 result = 0;
    dispatch_sync(self.synchronizationQueue, ^{
        result = self.currentMemoryUsage;
    });
    return result;
}

- (void)addImage:(UIImage *)image withIdentifier:(NSString *)identifier {
    dispatch_barrier_async(self.synchronizationQueue, ^{
        __FWCachedImage *cacheImage = [[__FWCachedImage alloc] initWithImage:image identifier:identifier];

        __FWCachedImage *previousCachedImage = self.cachedImages[identifier];
        if (previousCachedImage != nil) {
            self.currentMemoryUsage -= previousCachedImage.totalBytes;
        }

        self.cachedImages[identifier] = cacheImage;
        self.currentMemoryUsage += cacheImage.totalBytes;
    });

    dispatch_barrier_async(self.synchronizationQueue, ^{
        if (self.currentMemoryUsage > self.memoryCapacity) {
            UInt64 bytesToPurge = self.currentMemoryUsage - self.preferredMemoryUsageAfterPurge;
            NSMutableArray <__FWCachedImage*> *sortedImages = [NSMutableArray arrayWithArray:self.cachedImages.allValues];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastAccessDate"
                                                                           ascending:YES];
            [sortedImages sortUsingDescriptors:@[sortDescriptor]];

            UInt64 bytesPurged = 0;

            for (__FWCachedImage *cachedImage in sortedImages) {
                [self.cachedImages removeObjectForKey:cachedImage.identifier];
                bytesPurged += cachedImage.totalBytes;
                if (bytesPurged >= bytesToPurge) {
                    break;
                }
            }
            self.currentMemoryUsage -= bytesPurged;
        }
    });
}

- (BOOL)removeImageWithIdentifier:(NSString *)identifier {
    __block BOOL removed = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        __FWCachedImage *cachedImage = self.cachedImages[identifier];
        if (cachedImage != nil) {
            [self.cachedImages removeObjectForKey:identifier];
            self.currentMemoryUsage -= cachedImage.totalBytes;
            removed = YES;
        }
    });
    return removed;
}

- (BOOL)removeAllImages {
    __block BOOL removed = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        if (self.cachedImages.count > 0) {
            [self.cachedImages removeAllObjects];
            self.currentMemoryUsage = 0;
            removed = YES;
        }
    });
    return removed;
}

- (nullable UIImage *)imageWithIdentifier:(NSString *)identifier {
    __block UIImage *image = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        __FWCachedImage *cachedImage = self.cachedImages[identifier];
        image = [cachedImage accessImage];
    });
    return image;
}

- (void)addImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    [self addImage:image withIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (BOOL)removeImageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    return [self removeImageWithIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (nullable UIImage *)imageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    return [self imageWithIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (NSString *)imageCacheKeyFromURLRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)additionalIdentifier {
    NSString *key = request.URL.absoluteString;
    if (additionalIdentifier != nil) {
        key = [key stringByAppendingString:additionalIdentifier];
    }
    return key;
}

- (BOOL)shouldCacheImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier {
    return YES;
}

@end

#pragma mark - __FWImageDownloader

@interface __FWImageDownloaderResponseHandler : NSObject
@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, copy) void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, UIImage *);
@property (nonatomic, copy) void (^failureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *);
@property (nonatomic, copy) void (^progressBlock)(NSProgress *);
@end

@implementation __FWImageDownloaderResponseHandler

- (instancetype)initWithUUID:(NSUUID *)uuid
                     success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *responseObject))success
                     failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                    progress:(nullable void (^)(NSProgress *downloadProgress))progress {
    if (self = [self init]) {
        self.uuid = uuid;
        self.successBlock = success;
        self.failureBlock = failure;
        self.progressBlock = progress;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"<__FWImageDownloaderResponseHandler>UUID: %@", [self.uuid UUIDString]];
}

@end

@interface __FWImageDownloaderMergedTask : NSObject
@property (nonatomic, strong) NSString *URLIdentifier;
@property (nonatomic, strong) NSUUID *identifier;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSMutableArray <__FWImageDownloaderResponseHandler*> *responseHandlers;

@end

@implementation __FWImageDownloaderMergedTask

- (instancetype)initWithURLIdentifier:(NSString *)URLIdentifier identifier:(NSUUID *)identifier task:(NSURLSessionDataTask *)task {
    if (self = [self init]) {
        self.URLIdentifier = URLIdentifier;
        self.task = task;
        self.identifier = identifier;
        self.responseHandlers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addResponseHandler:(__FWImageDownloaderResponseHandler *)handler {
    [self.responseHandlers addObject:handler];
}

- (void)removeResponseHandler:(__FWImageDownloaderResponseHandler *)handler {
    [self.responseHandlers removeObject:handler];
}

@end

@implementation __FWImageDownloadReceipt

- (instancetype)initWithReceiptID:(NSUUID *)receiptID task:(NSURLSessionDataTask *)task {
    if (self = [self init]) {
        self.receiptID = receiptID;
        self.task = task;
    }
    return self;
}

@end

@interface __FWImageDownloader ()

@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@property (nonatomic, strong) dispatch_queue_t responseQueue;

@property (nonatomic, assign) NSInteger maximumActiveDownloads;
@property (nonatomic, assign) NSInteger activeRequestCount;

@property (nonatomic, strong) NSMutableArray *queuedMergedTasks;
@property (nonatomic, strong) NSMutableDictionary *mergedTasks;

@end

@implementation __FWImageDownloader

+ (NSURLCache *)defaultURLCache {
    NSUInteger memoryCapacity = 20 * 1024 * 1024; // 20MB
    NSUInteger diskCapacity = 150 * 1024 * 1024; // 150MB
    return [[NSURLCache alloc] initWithMemoryCapacity:memoryCapacity
                                         diskCapacity:diskCapacity
                                             diskPath:@"FWImageCache"];
}

+ (NSURLSessionConfiguration *)defaultURLSessionConfiguration {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

    //TODO set the default HTTP headers

    configuration.HTTPShouldSetCookies = YES;
    configuration.HTTPShouldUsePipelining = NO;

    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = 60.0;
    configuration.URLCache = [__FWImageDownloader defaultURLCache];

    return configuration;
}

- (instancetype)init {
    NSURLSessionConfiguration *defaultConfiguration = [self.class defaultURLSessionConfiguration];
    return [self initWithSessionConfiguration:defaultConfiguration];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    __FWHTTPSessionManager *sessionManager = [[__FWHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    __FWImageResponseSerializer *responseSerializer = [__FWImageResponseSerializer serializer];
    responseSerializer.imageScale = 1;
    responseSerializer.shouldCacheResponseData = YES;
    sessionManager.responseSerializer = responseSerializer;

    return [self initWithSessionManager:sessionManager
                 downloadPrioritization:__FWImageDownloadPrioritizationFIFO
                 maximumActiveDownloads:4
                             imageCache:[[__FWAutoPurgingImageCache alloc] init]];
}

- (instancetype)initWithSessionManager:(__FWHTTPSessionManager *)sessionManager
                downloadPrioritization:(__FWImageDownloadPrioritization)downloadPrioritization
                maximumActiveDownloads:(NSInteger)maximumActiveDownloads
                            imageCache:(id <__FWImageRequestCache>)imageCache {
    if (self = [super init]) {
        self.sessionManager = sessionManager;

        self.downloadPrioritization = downloadPrioritization;
        self.maximumActiveDownloads = maximumActiveDownloads;
        self.imageCache = imageCache;

        self.queuedMergedTasks = [[NSMutableArray alloc] init];
        self.mergedTasks = [[NSMutableDictionary alloc] init];
        self.activeRequestCount = 0;

        NSString *name = [NSString stringWithFormat:@"site.wuyong.queue.webimage.download.%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);

        name = [NSString stringWithFormat:@"site.wuyong.queue.webimage.response.%@", [[NSUUID UUID] UUIDString]];
        self.responseQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    }

    return self;
}

+ (__FWImageDownloader *)sharedDownloader
{
    return objc_getAssociatedObject([__FWImageDownloader class], @selector(sharedDownloader)) ?: [__FWImageDownloader defaultInstance];
}

+ (void)setSharedDownloader:(__FWImageDownloader *)sharedDownloader
{
    objc_setAssociatedObject([__FWImageDownloader class], @selector(sharedDownloader), sharedDownloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)defaultInstance {
    static __FWImageDownloader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (nullable __FWImageDownloadReceipt *)downloadImageForURL:(id)url
                                                 options:(__FWWebImageOptions)options
                                                 context:(NSDictionary<__FWImageCoderOptions,id> *)context
                                                 success:(void (^)(NSURLRequest * _Nonnull, NSHTTPURLResponse * _Nullable, UIImage * _Nonnull))success
                                                 failure:(void (^)(NSURLRequest * _Nonnull, NSHTTPURLResponse * _Nullable, NSError * _Nonnull))failure
                                                progress:(nullable void (^)(NSProgress * _Nonnull))progress {
    return [self downloadImageForURL:url withReceiptID:[NSUUID UUID] options:options context:context success:success failure:failure progress:progress];
}

- (nullable __FWImageDownloadReceipt *)downloadImageForURL:(id)url
                                           withReceiptID:(nonnull NSUUID *)receiptID
                                                 options:(__FWWebImageOptions)options
                                                 context:(nullable NSDictionary<__FWImageCoderOptions, id> *)context
                                                 success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                 failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                progress:(nullable void (^)(NSProgress * _Nonnull))progress {
    NSURLRequest *request = [self urlRequestWithURL:url options:options];
    __block NSURLSessionDataTask *task = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        NSString *URLIdentifier = request.URL.absoluteString;
        if (URLIdentifier.length == 0) {
            if (failure) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(request, nil, error);
                });
            }
            return;
        }

        // 1) Append the success and failure blocks to a pre-existing request if it already exists
        __FWImageDownloaderMergedTask *existingMergedTask = self.mergedTasks[URLIdentifier];
        if (existingMergedTask != nil) {
            __FWImageDownloaderResponseHandler *handler = [[__FWImageDownloaderResponseHandler alloc] initWithUUID:receiptID success:success failure:failure progress:progress];
            [existingMergedTask addResponseHandler:handler];
            task = existingMergedTask.task;
            return;
        }

        // 2) Attempt to load the image from the image cache if the cache policy allows it
        switch (request.cachePolicy) {
            case NSURLRequestUseProtocolCachePolicy:
            case NSURLRequestReturnCacheDataElseLoad:
            case NSURLRequestReturnCacheDataDontLoad: {
                if (!(options & __FWWebImageOptionRefreshCached) &&
                    !(options & __FWWebImageOptionIgnoreCache)) {
                    UIImage *cachedImage = [self.imageCache imageforRequest:request withAdditionalIdentifier:nil];
                    if (cachedImage != nil) {
                        if (success) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                success(request, nil, cachedImage);
                            });
                        }
                        return;
                    }
                }
                break;
            }
            default:
                break;
        }

        // 3) Create the request and set up authentication, validation and response serialization
        NSUUID *mergedTaskIdentifier = [NSUUID UUID];
        NSURLSessionDataTask *createdTask;
        __weak __typeof__(self) weakSelf = self;

        createdTask = [self.sessionManager
                       dataTaskWithRequest:request
                       uploadProgress:nil
                       downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
                           dispatch_async(self.responseQueue, ^{
                               __strong __typeof__(weakSelf) strongSelf = weakSelf;
                               __FWImageDownloaderMergedTask *mergedTask = [strongSelf safelyGetMergedTask:URLIdentifier];
                               if ([mergedTask.identifier isEqual:mergedTaskIdentifier]) {
                                   NSArray *responseHandlers = [strongSelf safelyGetResponseHandlers:URLIdentifier];
                                   for (__FWImageDownloaderResponseHandler *handler in responseHandlers) {
                                       if (handler.progressBlock) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               handler.progressBlock(downloadProgress);
                                           });
                                       }
                                   }
                               }
                           });
                       }
                       completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                           dispatch_async(self.responseQueue, ^{
                               __strong __typeof__(weakSelf) strongSelf = weakSelf;
                               __FWImageDownloaderMergedTask *mergedTask = [strongSelf safelyGetMergedTask:URLIdentifier];
                               if ([mergedTask.identifier isEqual:mergedTaskIdentifier]) {
                                   mergedTask = [strongSelf safelyRemoveMergedTaskWithURLIdentifier:URLIdentifier];
                                   if (error) {
                                       for (__FWImageDownloaderResponseHandler *handler in mergedTask.responseHandlers) {
                                           if (handler.failureBlock) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   handler.failureBlock(request, (NSHTTPURLResponse *)response, error);
                                               });
                                           }
                                       }
                                   } else {
                                       if ([strongSelf.imageCache shouldCacheImage:responseObject forRequest:request withAdditionalIdentifier:nil]) {
                                           [strongSelf.imageCache addImage:responseObject forRequest:request withAdditionalIdentifier:nil];
                                       }

                                       for (__FWImageDownloaderResponseHandler *handler in mergedTask.responseHandlers) {
                                           if (handler.successBlock) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   handler.successBlock(request, (NSHTTPURLResponse *)response, responseObject);
                                               });
                                           }
                                       }
                                       
                                   }
                               }
                               [strongSelf safelyDecrementActiveTaskCount];
                               [strongSelf safelyStartNextTaskIfNecessary];
                           });
                       }];
        
        // Store the context for use when the request completes
        if (context) [self.sessionManager setUserInfo:context forTask:createdTask];

        // 4) Store the response handler for use when the request completes
        __FWImageDownloaderResponseHandler *handler = [[__FWImageDownloaderResponseHandler alloc] initWithUUID:receiptID
                                                                                                   success:success
                                                                                                   failure:failure
                                                                                                  progress:progress];
        __FWImageDownloaderMergedTask *mergedTask = [[__FWImageDownloaderMergedTask alloc]
                                                   initWithURLIdentifier:URLIdentifier
                                                   identifier:mergedTaskIdentifier
                                                   task:createdTask];
        [mergedTask addResponseHandler:handler];
        self.mergedTasks[URLIdentifier] = mergedTask;

        // 5) Either start the request or enqueue it depending on the current active request count
        if ([self isActiveRequestCountBelowMaximumLimit]) {
            [self startMergedTask:mergedTask];
        } else {
            [self enqueueMergedTask:mergedTask];
        }

        task = mergedTask.task;
    });
    if (task) {
        return [[__FWImageDownloadReceipt alloc] initWithReceiptID:receiptID task:task];
    } else {
        return nil;
    }
}

- (void)cancelTaskForImageDownloadReceipt:(__FWImageDownloadReceipt *)imageDownloadReceipt {
    dispatch_sync(self.synchronizationQueue, ^{
        NSString *URLIdentifier = imageDownloadReceipt.task.originalRequest.URL.absoluteString;
        __FWImageDownloaderMergedTask *mergedTask = self.mergedTasks[URLIdentifier];
        NSUInteger index = [mergedTask.responseHandlers indexOfObjectPassingTest:^BOOL(__FWImageDownloaderResponseHandler * _Nonnull handler, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            return handler.uuid == imageDownloadReceipt.receiptID;
        }];

        if (index != NSNotFound) {
            __FWImageDownloaderResponseHandler *handler = mergedTask.responseHandlers[index];
            [mergedTask removeResponseHandler:handler];
            NSString *failureReason = [NSString stringWithFormat:@"ImageDownloader cancelled URL request: %@",imageDownloadReceipt.task.originalRequest.URL.absoluteString];
            NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey:failureReason};
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
            if (handler.failureBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler.failureBlock(imageDownloadReceipt.task.originalRequest, nil, error);
                });
            }
        }

        if (mergedTask.responseHandlers.count == 0) {
            [mergedTask.task cancel];
            [self removeMergedTaskWithURLIdentifier:URLIdentifier];
        }
    });
}

- (NSURLRequest *)urlRequestWithURL:(id)url options:(__FWWebImageOptions)options {
    NSURLRequest *urlRequest = nil;
    if ([url isKindOfClass:[NSURLRequest class]]) {
        urlRequest = url;
    } else {
        NSURL *nsurl = nil;
        if ([url isKindOfClass:[NSURL class]]) {
            nsurl = url;
        } else if ([url isKindOfClass:[NSString class]] && [url length] > 0) {
            nsurl = [NSURL URLWithString:url];
            if (!nsurl) {
                nsurl = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            }
        }
        
        if (nsurl != nil) {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
            if (!!(options & __FWWebImageOptionIgnoreCache)) {
                if (@available(iOS 13.0, *)) {
                    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
                } else {
                    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
                }
            }
            [request addValue:@"image/*,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
            urlRequest = request;
        }
    }
    return urlRequest;
}

- (__FWImageDownloaderMergedTask *)safelyRemoveMergedTaskWithURLIdentifier:(NSString *)URLIdentifier {
    __block __FWImageDownloaderMergedTask *mergedTask = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        mergedTask = [self removeMergedTaskWithURLIdentifier:URLIdentifier];
    });
    return mergedTask;
}

//This method should only be called from safely within the synchronizationQueue
- (__FWImageDownloaderMergedTask *)removeMergedTaskWithURLIdentifier:(NSString *)URLIdentifier {
    __FWImageDownloaderMergedTask *mergedTask = self.mergedTasks[URLIdentifier];
    [self.mergedTasks removeObjectForKey:URLIdentifier];
    return mergedTask;
}

- (void)safelyDecrementActiveTaskCount {
    dispatch_sync(self.synchronizationQueue, ^{
        if (self.activeRequestCount > 0) {
            self.activeRequestCount -= 1;
        }
    });
}

- (void)safelyStartNextTaskIfNecessary {
    dispatch_sync(self.synchronizationQueue, ^{
        if ([self isActiveRequestCountBelowMaximumLimit]) {
            while (self.queuedMergedTasks.count > 0) {
                __FWImageDownloaderMergedTask *mergedTask = [self dequeueMergedTask];
                if (mergedTask.task.state == NSURLSessionTaskStateSuspended) {
                    [self startMergedTask:mergedTask];
                    break;
                }
            }
        }
    });
}

- (void)startMergedTask:(__FWImageDownloaderMergedTask *)mergedTask {
    [mergedTask.task resume];
    ++self.activeRequestCount;
}

- (void)enqueueMergedTask:(__FWImageDownloaderMergedTask *)mergedTask {
    switch (self.downloadPrioritization) {
        case __FWImageDownloadPrioritizationFIFO:
            [self.queuedMergedTasks addObject:mergedTask];
            break;
        case __FWImageDownloadPrioritizationLIFO:
            [self.queuedMergedTasks insertObject:mergedTask atIndex:0];
            break;
    }
}

- (__FWImageDownloaderMergedTask *)dequeueMergedTask {
    __FWImageDownloaderMergedTask *mergedTask = nil;
    mergedTask = [self.queuedMergedTasks firstObject];
    [self.queuedMergedTasks removeObject:mergedTask];
    return mergedTask;
}

- (BOOL)isActiveRequestCountBelowMaximumLimit {
    return self.activeRequestCount < self.maximumActiveDownloads;
}

- (__FWImageDownloaderMergedTask *)safelyGetMergedTask:(NSString *)URLIdentifier {
    __block __FWImageDownloaderMergedTask *mergedTask;
    dispatch_sync(self.synchronizationQueue, ^(){
        mergedTask = self.mergedTasks[URLIdentifier];
    });
    return mergedTask;
}

- (NSArray *)safelyGetResponseHandlers:(NSString *)URLIdentifier {
    __block NSArray *responseHandlers;
    dispatch_sync(self.synchronizationQueue, ^(){
        __FWImageDownloaderMergedTask *mergedTask = self.mergedTasks[URLIdentifier];
        responseHandlers = [mergedTask.responseHandlers copy];
    });
    return responseHandlers;
}

- (__FWImageDownloadReceipt *)activeImageDownloadReceipt:(id)object
{
    if (!object) return nil;
    return (__FWImageDownloadReceipt *)objc_getAssociatedObject(object, @selector(activeImageDownloadReceipt:));
}

- (void)setActiveImageDownloadReceipt:(__FWImageDownloadReceipt *)receipt forObject:(id)object
{
    if (!object) return;
    objc_setAssociatedObject(object, @selector(activeImageDownloadReceipt:), receipt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)imageURLForObject:(id)object
{
    if (!object) return nil;
    return (NSURL *)objc_getAssociatedObject(object, @selector(imageURLForObject:));
}

- (void)setImageURL:(NSURL *)imageURL forObject:(id)object
{
    if (!object) return;
    objc_setAssociatedObject(object, @selector(imageURLForObject:), imageURL, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)imageOperationKeyForObject:(id)object
{
    if (!object) return nil;
    return (NSString *)objc_getAssociatedObject(object, @selector(imageOperationKeyForObject:));
}

- (void)setImageOperationKey:(NSString *)operationKey forObject:(id)object
{
    if (!object) return;
    objc_setAssociatedObject(object, @selector(imageOperationKeyForObject:), operationKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)downloadImageForObject:(id)object
                      imageURL:(id)url
                       options:(__FWWebImageOptions)options
                       context:(NSDictionary<__FWImageCoderOptions, id> *)context
                   placeholder:(void (^)(void))placeholder
                    completion:(void (^)(UIImage * _Nullable, BOOL, NSError * _Nullable))completion
                      progress:(void (^)(double))progress
{
    if (!object) return;
    NSURLRequest *urlRequest = [self urlRequestWithURL:url options:options];
    [self setImageOperationKey:NSStringFromClass([object class]) forObject:object];
    __FWImageDownloadReceipt *activeReceipt = [self activeImageDownloadReceipt:object];
    if (activeReceipt != nil) {
        [self cancelTaskForImageDownloadReceipt:activeReceipt];
        [self setActiveImageDownloadReceipt:nil forObject:object];
    }
    [self setImageURL:[urlRequest URL] forObject:object];
    
    if ([urlRequest URL] == nil) {
        if (placeholder) {
            placeholder();
        }
        if (completion) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
            completion(nil, NO, error);
        }
        return;
    }

    UIImage *cachedImage = nil;
    if (!(options & __FWWebImageOptionRefreshCached) &&
        !(options & __FWWebImageOptionIgnoreCache)) {
        id<__FWImageRequestCache> imageCache = self.imageCache;
        cachedImage = [imageCache imageforRequest:urlRequest withAdditionalIdentifier:nil];
    }
    if (cachedImage) {
        if (completion) {
            completion(cachedImage, YES, nil);
        }
        [self setActiveImageDownloadReceipt:nil forObject:object];
    } else {
        if (placeholder) {
            placeholder();
        }
        __weak __typeof(self)weakSelf = self;
        NSUUID *downloadID = [NSUUID UUID];
        __FWImageDownloadReceipt *receipt;
        receipt = [self
                   downloadImageForURL:urlRequest
                   withReceiptID:downloadID
                   options:options
                   context:context
                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([[strongSelf activeImageDownloadReceipt:object].receiptID isEqual:downloadID]) {
                           [__FWImageResponseSerializer clearCachedResponseDataForImage:responseObject];
                           if (completion) {
                               completion(responseObject, NO, nil);
                           }
                           [strongSelf setActiveImageDownloadReceipt:nil forObject:object];
                       }
                   }
                   failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                        if ([[strongSelf activeImageDownloadReceipt:object].receiptID isEqual:downloadID]) {
                            if (completion) {
                                completion(nil, NO, error);
                            }
                            [strongSelf setActiveImageDownloadReceipt:nil forObject:object];
                        }
                   }
                   progress:(progress ? ^(NSProgress * _Nonnull downloadProgress) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([[strongSelf activeImageDownloadReceipt:object].receiptID isEqual:downloadID]) {
                           progress(downloadProgress.fractionCompleted);
                       }
                   } : nil)];

        [self setActiveImageDownloadReceipt:receipt forObject:object];
    }
}

- (void)cancelImageDownloadTask:(id)object
{
    if (!object) return;
    __FWImageDownloadReceipt *receipt = [self activeImageDownloadReceipt:object];
    if (receipt != nil) {
        [self cancelTaskForImageDownloadReceipt:receipt];
        [self setActiveImageDownloadReceipt:nil forObject:object];
    }
    [self setImageOperationKey:nil forObject:object];
}

- (UIImage *)loadImageCacheForURL:(id)url
{
    NSURLRequest *urlRequest = [self urlRequestWithURL:url options:0];
    if ([urlRequest URL] == nil) return nil;

    id<__FWImageRequestCache> imageCache = self.imageCache;
    UIImage *cachedImage = [imageCache imageforRequest:urlRequest withAdditionalIdentifier:nil];
    if (cachedImage) return cachedImage;
    
    NSCachedURLResponse *cachedResponse = [self.sessionManager.session.configuration.URLCache cachedResponseForRequest:urlRequest];
    id responseObject = cachedResponse ? [self.sessionManager.responseSerializer responseObjectForResponse:cachedResponse.response data:cachedResponse.data error:nil] : nil;
    if ([responseObject isKindOfClass:[UIImage class]]) {
        return (UIImage *)responseObject;
    }
    return nil;
}

- (void)clearImageCaches:(void (^)(void))completion
{
    [self.imageCache removeAllImages];
    [self.sessionManager.session.configuration.URLCache removeAllCachedResponses];
    
    if (completion != nil) {
        if ([NSThread isMainThread]) {
            completion();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    }
}

@end
