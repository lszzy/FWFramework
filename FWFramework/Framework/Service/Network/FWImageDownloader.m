// FWImageDownloader.m
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

#import "FWImageDownloader.h"
#import "FWHTTPSessionManager.h"

@interface FWImageDownloaderResponseHandler : NSObject
@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, copy) void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, UIImage *);
@property (nonatomic, copy) void (^failureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *);
@end

@implementation FWImageDownloaderResponseHandler

- (instancetype)initWithUUID:(NSUUID *)uuid
                     success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *responseObject))success
                     failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure {
    if (self = [self init]) {
        self.uuid = uuid;
        self.successBlock = success;
        self.failureBlock = failure;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"<FWImageDownloaderResponseHandler>UUID: %@", [self.uuid UUIDString]];
}

@end

@interface FWImageDownloaderMergedTask : NSObject
@property (nonatomic, strong) NSString *URLIdentifier;
@property (nonatomic, strong) NSUUID *identifier;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSMutableArray <FWImageDownloaderResponseHandler*> *responseHandlers;

@end

@implementation FWImageDownloaderMergedTask

- (instancetype)initWithURLIdentifier:(NSString *)URLIdentifier identifier:(NSUUID *)identifier task:(NSURLSessionDataTask *)task {
    if (self = [self init]) {
        self.URLIdentifier = URLIdentifier;
        self.task = task;
        self.identifier = identifier;
        self.responseHandlers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addResponseHandler:(FWImageDownloaderResponseHandler *)handler {
    [self.responseHandlers addObject:handler];
}

- (void)removeResponseHandler:(FWImageDownloaderResponseHandler *)handler {
    [self.responseHandlers removeObject:handler];
}

@end

@implementation FWImageDownloadReceipt

- (instancetype)initWithReceiptID:(NSUUID *)receiptID task:(NSURLSessionDataTask *)task {
    if (self = [self init]) {
        self.receiptID = receiptID;
        self.task = task;
    }
    return self;
}

@end

@interface FWImageDownloader ()

@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@property (nonatomic, strong) dispatch_queue_t responseQueue;

@property (nonatomic, assign) NSInteger maximumActiveDownloads;
@property (nonatomic, assign) NSInteger activeRequestCount;

@property (nonatomic, strong) NSMutableArray *queuedMergedTasks;
@property (nonatomic, strong) NSMutableDictionary *mergedTasks;

@end

@implementation FWImageDownloader

+ (NSURLCache *)defaultURLCache {
    
    // It's been discovered that a crash will occur on certain versions
    // of iOS if you customize the cache.
    //
    // More info can be found here: https://devforums.apple.com/message/1102182#1102182
    //
    // When iOS 7 support is dropped, this should be modified to use
    // NSProcessInfo methods instead.
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.2" options:NSNumericSearch] == NSOrderedAscending) {
        return [NSURLCache sharedURLCache];
    }
    return [[NSURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024
                                         diskCapacity:150 * 1024 * 1024
                                             diskPath:@"site.wuyong.imagedownloader"];
}

+ (NSURLSessionConfiguration *)defaultURLSessionConfiguration {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

    //TODO set the default HTTP headers

    configuration.HTTPShouldSetCookies = YES;
    configuration.HTTPShouldUsePipelining = NO;

    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = 60.0;
    configuration.URLCache = [FWImageDownloader defaultURLCache];

    return configuration;
}

- (instancetype)init {
    NSURLSessionConfiguration *defaultConfiguration = [self.class defaultURLSessionConfiguration];
    return [self initWithSessionConfiguration:defaultConfiguration];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    FWHTTPSessionManager *sessionManager = [[FWHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    sessionManager.responseSerializer = [FWImageResponseSerializer serializer];

    return [self initWithSessionManager:sessionManager
                 downloadPrioritization:FWImageDownloadPrioritizationFIFO
                 maximumActiveDownloads:4
                             imageCache:[[FWAutoPurgingImageCache alloc] init]];
}

- (instancetype)initWithSessionManager:(FWHTTPSessionManager *)sessionManager
                downloadPrioritization:(FWImageDownloadPrioritization)downloadPrioritization
                maximumActiveDownloads:(NSInteger)maximumActiveDownloads
                            imageCache:(id <FWImageRequestCache>)imageCache {
    if (self = [super init]) {
        self.sessionManager = sessionManager;

        self.downloadPrioritizaton = downloadPrioritization;
        self.maximumActiveDownloads = maximumActiveDownloads;
        self.imageCache = imageCache;

        self.queuedMergedTasks = [[NSMutableArray alloc] init];
        self.mergedTasks = [[NSMutableDictionary alloc] init];
        self.activeRequestCount = 0;

        NSString *name = [NSString stringWithFormat:@"site.wuyong.imagedownloader.synchronizationqueue-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);

        name = [NSString stringWithFormat:@"site.wuyong.imagedownloader.responsequeue-%@", [[NSUUID UUID] UUIDString]];
        self.responseQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    }

    return self;
}

+ (instancetype)defaultInstance {
    static FWImageDownloader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (nullable FWImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)request
                                                        success:(void (^)(NSURLRequest * _Nonnull, NSHTTPURLResponse * _Nullable, UIImage * _Nonnull))success
                                                        failure:(void (^)(NSURLRequest * _Nonnull, NSHTTPURLResponse * _Nullable, NSError * _Nonnull))failure {
    return [self downloadImageForURLRequest:request withReceiptID:[NSUUID UUID] success:success failure:failure];
}

- (nullable FWImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)request
                                                  withReceiptID:(nonnull NSUUID *)receiptID
                                                        success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                        failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure {
    __block NSURLSessionDataTask *task = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        NSString *URLIdentifier = request.URL.absoluteString;
        if (URLIdentifier == nil) {
            if (failure) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(request, nil, error);
                });
            }
            return;
        }

        // 1) Append the success and failure blocks to a pre-existing request if it already exists
        FWImageDownloaderMergedTask *existingMergedTask = self.mergedTasks[URLIdentifier];
        if (existingMergedTask != nil) {
            FWImageDownloaderResponseHandler *handler = [[FWImageDownloaderResponseHandler alloc] initWithUUID:receiptID success:success failure:failure];
            [existingMergedTask addResponseHandler:handler];
            task = existingMergedTask.task;
            return;
        }

        // 2) Attempt to load the image from the image cache if the cache policy allows it
        switch (request.cachePolicy) {
            case NSURLRequestUseProtocolCachePolicy:
            case NSURLRequestReturnCacheDataElseLoad:
            case NSURLRequestReturnCacheDataDontLoad: {
                UIImage *cachedImage = [self.imageCache imageforRequest:request withAdditionalIdentifier:nil];
                if (cachedImage != nil) {
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            success(request, nil, cachedImage);
                        });
                    }
                    return;
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
                       downloadProgress:nil
                       completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                           dispatch_async(self.responseQueue, ^{
                               __strong __typeof__(weakSelf) strongSelf = weakSelf;
                               FWImageDownloaderMergedTask *mergedTask = [strongSelf safelyGetMergedTask:URLIdentifier];
                               if ([mergedTask.identifier isEqual:mergedTaskIdentifier]) {
                                   mergedTask = [strongSelf safelyRemoveMergedTaskWithURLIdentifier:URLIdentifier];
                                   if (error) {
                                       for (FWImageDownloaderResponseHandler *handler in mergedTask.responseHandlers) {
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

                                       for (FWImageDownloaderResponseHandler *handler in mergedTask.responseHandlers) {
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

        // 4) Store the response handler for use when the request completes
        FWImageDownloaderResponseHandler *handler = [[FWImageDownloaderResponseHandler alloc] initWithUUID:receiptID
                                                                                                   success:success
                                                                                                   failure:failure];
        FWImageDownloaderMergedTask *mergedTask = [[FWImageDownloaderMergedTask alloc]
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
        return [[FWImageDownloadReceipt alloc] initWithReceiptID:receiptID task:task];
    } else {
        return nil;
    }
}

- (void)cancelTaskForImageDownloadReceipt:(FWImageDownloadReceipt *)imageDownloadReceipt {
    dispatch_sync(self.synchronizationQueue, ^{
        NSString *URLIdentifier = imageDownloadReceipt.task.originalRequest.URL.absoluteString;
        FWImageDownloaderMergedTask *mergedTask = self.mergedTasks[URLIdentifier];
        NSUInteger index = [mergedTask.responseHandlers indexOfObjectPassingTest:^BOOL(FWImageDownloaderResponseHandler * _Nonnull handler, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            return handler.uuid == imageDownloadReceipt.receiptID;
        }];

        if (index != NSNotFound) {
            FWImageDownloaderResponseHandler *handler = mergedTask.responseHandlers[index];
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

        if (mergedTask.responseHandlers.count == 0 && mergedTask.task.state == NSURLSessionTaskStateSuspended) {
            [mergedTask.task cancel];
            [self removeMergedTaskWithURLIdentifier:URLIdentifier];
        }
    });
}

- (FWImageDownloaderMergedTask *)safelyRemoveMergedTaskWithURLIdentifier:(NSString *)URLIdentifier {
    __block FWImageDownloaderMergedTask *mergedTask = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        mergedTask = [self removeMergedTaskWithURLIdentifier:URLIdentifier];
    });
    return mergedTask;
}

//This method should only be called from safely within the synchronizationQueue
- (FWImageDownloaderMergedTask *)removeMergedTaskWithURLIdentifier:(NSString *)URLIdentifier {
    FWImageDownloaderMergedTask *mergedTask = self.mergedTasks[URLIdentifier];
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
                FWImageDownloaderMergedTask *mergedTask = [self dequeueMergedTask];
                if (mergedTask.task.state == NSURLSessionTaskStateSuspended) {
                    [self startMergedTask:mergedTask];
                    break;
                }
            }
        }
    });
}

- (void)startMergedTask:(FWImageDownloaderMergedTask *)mergedTask {
    [mergedTask.task resume];
    ++self.activeRequestCount;
}

- (void)enqueueMergedTask:(FWImageDownloaderMergedTask *)mergedTask {
    switch (self.downloadPrioritizaton) {
        case FWImageDownloadPrioritizationFIFO:
            [self.queuedMergedTasks addObject:mergedTask];
            break;
        case FWImageDownloadPrioritizationLIFO:
            [self.queuedMergedTasks insertObject:mergedTask atIndex:0];
            break;
    }
}

- (FWImageDownloaderMergedTask *)dequeueMergedTask {
    FWImageDownloaderMergedTask *mergedTask = nil;
    mergedTask = [self.queuedMergedTasks firstObject];
    [self.queuedMergedTasks removeObject:mergedTask];
    return mergedTask;
}

- (BOOL)isActiveRequestCountBelowMaximumLimit {
    return self.activeRequestCount < self.maximumActiveDownloads;
}

- (FWImageDownloaderMergedTask *)safelyGetMergedTask:(NSString *)URLIdentifier {
    __block FWImageDownloaderMergedTask *mergedTask;
    dispatch_sync(self.synchronizationQueue, ^(){
        mergedTask = self.mergedTasks[URLIdentifier];
    });
    return mergedTask;
}

@end

#endif
