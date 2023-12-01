//
//  PlayerCache.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "PlayerCache.h"
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <CommonCrypto/CommonDigest.h>

#pragma mark - __FWPlayerCacheLoaderManager

static NSString *__FWPlayerCacheScheme = @"FWPlayerCache:";

@interface __FWPlayerCacheLoaderManager () <__FWPlayerCacheLoaderDelegate>

@property (nonatomic, strong) NSMutableDictionary<id<NSCoding>, __FWPlayerCacheLoader *> *loaders;

@end

@implementation __FWPlayerCacheLoaderManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _loaders = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)cleanCache {
    [self.loaders removeAllObjects];
}

- (void)cancelLoaders {
    [self.loaders enumerateKeysAndObjectsUsingBlock:^(id<NSCoding>  _Nonnull key, __FWPlayerCacheLoader * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
    [self.loaders removeAllObjects];
}

+ (NSURL *)assetURLWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }

    NSURL *assetURL = [NSURL URLWithString:[__FWPlayerCacheScheme stringByAppendingString:[url absoluteString]]];
    return assetURL;
}

- (AVURLAsset *)URLAssetWithURL:(NSURL *)url {
    NSURL *assetURL = [__FWPlayerCacheLoaderManager assetURLWithURL:url];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    [urlAsset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    return urlAsset;
}

- (AVPlayerItem *)playerItemWithURL:(NSURL *)url {
    NSURL *assetURL = [__FWPlayerCacheLoaderManager assetURLWithURL:url];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    [urlAsset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
    playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = YES;
    return playerItem;
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest  {
    NSURL *resourceURL = [loadingRequest.request URL];
    if ([resourceURL.absoluteString hasPrefix:__FWPlayerCacheScheme]) {
        __FWPlayerCacheLoader *loader = [self loaderForRequest:loadingRequest];
        if (!loader) {
            NSURL *originURL = nil;
            NSString *originStr = [resourceURL absoluteString];
            originStr = [originStr stringByReplacingOccurrencesOfString:__FWPlayerCacheScheme withString:@""];
            originURL = [NSURL URLWithString:originStr];
            loader = [[__FWPlayerCacheLoader alloc] initWithURL:originURL];
            loader.delegate = self;
            NSString *key = [self keyForResourceLoaderWithURL:resourceURL];
            self.loaders[key] = loader;
        }
        [loader addRequest:loadingRequest];
        return YES;
    }
    
    return NO;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    __FWPlayerCacheLoader *loader = [self loaderForRequest:loadingRequest];
    [loader removeRequest:loadingRequest];
}

#pragma mark - __FWPlayerCacheLoaderDelegate

- (void)resourceLoader:(__FWPlayerCacheLoader *)resourceLoader didFailWithError:(NSError *)error {
    [resourceLoader cancel];
    if ([self.delegate respondsToSelector:@selector(resourceLoaderManagerLoadURL:didFailWithError:)]) {
        [self.delegate resourceLoaderManagerLoadURL:resourceLoader.url didFailWithError:error];
    }
}

#pragma mark - Helper

- (NSString *)keyForResourceLoaderWithURL:(NSURL *)requestURL {
    if([[requestURL absoluteString] hasPrefix:__FWPlayerCacheScheme]){
        NSString *s = requestURL.absoluteString;
        return s;
    }
    return nil;
}

- (__FWPlayerCacheLoader *)loaderForRequest:(AVAssetResourceLoadingRequest *)request {
    NSString *requestKey = [self keyForResourceLoaderWithURL:request.request.URL];
    __FWPlayerCacheLoader *loader = self.loaders[requestKey];
    return loader;
}

@end

#pragma mark - __FWPlayerCacheLoader

@interface __FWPlayerCacheLoader () <__FWPlayerCacheRequestWorkerDelegate>

@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong) __FWPlayerCacheWorker *cacheWorker;
@property (nonatomic, strong) __FWPlayerCacheDownloader *mediaDownloader;
@property (nonatomic, strong) NSMutableArray<__FWPlayerCacheRequestWorker *> *pendingRequestWorkers;

@property (nonatomic, getter=isCancelled) BOOL cancelled;

@end

@implementation __FWPlayerCacheLoader


- (void)dealloc {
    [_mediaDownloader cancel];
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
        _cacheWorker = [[__FWPlayerCacheWorker alloc] initWithURL:url];
        _mediaDownloader = [[__FWPlayerCacheDownloader alloc] initWithURL:url cacheWorker:_cacheWorker];
        _pendingRequestWorkers = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Use - initWithURL: instead");
    return nil;
}

- (void)addRequest:(AVAssetResourceLoadingRequest *)request {
    if (self.pendingRequestWorkers.count > 0) {
        [self startNoCacheWorkerWithRequest:request];
    } else {
        [self startWorkerWithRequest:request];
    }
}

- (void)removeRequest:(AVAssetResourceLoadingRequest *)request {
    __block __FWPlayerCacheRequestWorker *requestWorker = nil;
    [self.pendingRequestWorkers enumerateObjectsUsingBlock:^(__FWPlayerCacheRequestWorker *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.request == request) {
            requestWorker = obj;
            *stop = YES;
        }
    }];
    if (requestWorker) {
        [requestWorker finish];
        [self.pendingRequestWorkers removeObject:requestWorker];
    }
}

- (void)cancel {
    [self.mediaDownloader cancel];
    [self.pendingRequestWorkers removeAllObjects];
    
    [[__FWPlayerCacheDownloaderStatus shared] removeURL:self.url];
}

#pragma mark - __FWPlayerCacheRequestWorkerDelegate

- (void)resourceLoadingRequestWorker:(__FWPlayerCacheRequestWorker *)requestWorker didCompleteWithError:(NSError *)error {
    [self removeRequest:requestWorker.request];
    if (error && [self.delegate respondsToSelector:@selector(resourceLoader:didFailWithError:)]) {
        [self.delegate resourceLoader:self didFailWithError:error];
    }
    if (self.pendingRequestWorkers.count == 0) {
        [[__FWPlayerCacheDownloaderStatus shared] removeURL:self.url];
    }
}

#pragma mark - Helper

- (void)startNoCacheWorkerWithRequest:(AVAssetResourceLoadingRequest *)request {
    [[__FWPlayerCacheDownloaderStatus shared] addURL:self.url];
    __FWPlayerCacheDownloader *mediaDownloader = [[__FWPlayerCacheDownloader alloc] initWithURL:self.url cacheWorker:self.cacheWorker];
    __FWPlayerCacheRequestWorker *requestWorker = [[__FWPlayerCacheRequestWorker alloc] initWithMediaDownloader:mediaDownloader
                                                                                             resourceLoadingRequest:request];
    [self.pendingRequestWorkers addObject:requestWorker];
    requestWorker.delegate = self;
    [requestWorker startWork];
}

- (void)startWorkerWithRequest:(AVAssetResourceLoadingRequest *)request {
    [[__FWPlayerCacheDownloaderStatus shared] addURL:self.url];
    __FWPlayerCacheRequestWorker *requestWorker = [[__FWPlayerCacheRequestWorker alloc] initWithMediaDownloader:self.mediaDownloader
                                                                                             resourceLoadingRequest:request];
    [self.pendingRequestWorkers addObject:requestWorker];
    requestWorker.delegate = self;
    [requestWorker startWork];
    
}

- (NSError *)loaderCancelledError {
    NSError *error = [[NSError alloc] initWithDomain:@"FWPlayerCache"
                                                code:-3
                                            userInfo:@{NSLocalizedDescriptionKey:@"Resource loader cancelled"}];
    return error;
}

@end

#pragma mark - __FWPlayerCacheDownloader

@protocol  __FWPlayerCacheSessionDelegateObjectDelegate <NSObject>

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler;
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler;
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error;

@end

static NSInteger kBufferSize = 10 * 1024;

@interface __FWPlayerCacheSessionDelegateObject : NSObject <NSURLSessionDelegate>

- (instancetype)initWithDelegate:(id<__FWPlayerCacheSessionDelegateObjectDelegate>)delegate;

@property (nonatomic, weak) id<__FWPlayerCacheSessionDelegateObjectDelegate> delegate;
@property (nonatomic, strong) NSMutableData *bufferData;

@end

@implementation __FWPlayerCacheSessionDelegateObject

- (instancetype)initWithDelegate:(id<__FWPlayerCacheSessionDelegateObjectDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _bufferData = [NSMutableData data];
    }
    return self;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    [self.delegate URLSession:session didReceiveChallenge:challenge completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [self.delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    @synchronized (self.bufferData) {
        [self.bufferData appendData:data];
        if (self.bufferData.length > kBufferSize) {
            NSRange chunkRange = NSMakeRange(0, self.bufferData.length);
            NSData *chunkData = [self.bufferData subdataWithRange:chunkRange];
            [self.bufferData replaceBytesInRange:chunkRange withBytes:NULL length:0];
            [self.delegate URLSession:session dataTask:dataTask didReceiveData:chunkData];
        }
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionDataTask *)task
didCompleteWithError:(nullable NSError *)error {
    @synchronized (self.bufferData) {
        if (self.bufferData.length > 0 && !error) {
            NSRange chunkRange = NSMakeRange(0, self.bufferData.length);
            NSData *chunkData = [self.bufferData subdataWithRange:chunkRange];
            [self.bufferData replaceBytesInRange:chunkRange withBytes:NULL length:0];
            [self.delegate URLSession:session dataTask:task didReceiveData:chunkData];
        }
    }
    [self.delegate URLSession:session task:task didCompleteWithError:error];
}

@end

#pragma mark - Class: __FWPlayerCacheActionWorker

@class __FWPlayerCacheActionWorker;

@protocol __FWPlayerCacheActionWorkerDelegate <NSObject>

- (void)actionWorker:(__FWPlayerCacheActionWorker *)actionWorker didReceiveResponse:(NSURLResponse *)response;
- (void)actionWorker:(__FWPlayerCacheActionWorker *)actionWorker didReceiveData:(NSData *)data isLocal:(BOOL)isLocal;
- (void)actionWorker:(__FWPlayerCacheActionWorker *)actionWorker didFinishWithError:(NSError *)error;

@end

@interface __FWPlayerCacheActionWorker : NSObject <__FWPlayerCacheSessionDelegateObjectDelegate>

@property (nonatomic, strong) NSMutableArray<__FWPlayerCacheAction *> *actions;
- (instancetype)initWithActions:(NSArray<__FWPlayerCacheAction *> *)actions url:(NSURL *)url cacheWorker:(__FWPlayerCacheWorker *)cacheWorker;

@property (nonatomic, assign) BOOL canSaveToCache;
@property (nonatomic, weak) id<__FWPlayerCacheActionWorkerDelegate> delegate;

- (void)start;
- (void)cancel;


@property (nonatomic, getter=isCancelled) BOOL cancelled;

@property (nonatomic, strong) __FWPlayerCacheWorker *cacheWorker;
@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) __FWPlayerCacheSessionDelegateObject *sessionDelegateObject;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic) NSInteger startOffset;

@end

@interface __FWPlayerCacheActionWorker ()

@property (nonatomic) NSTimeInterval notifyTime;

@end

@implementation __FWPlayerCacheActionWorker

- (void)dealloc {
    [self cancel];
}

- (instancetype)initWithActions:(NSArray<__FWPlayerCacheAction *> *)actions url:(NSURL *)url cacheWorker:(__FWPlayerCacheWorker *)cacheWorker {
    self = [super init];
    if (self) {
        _canSaveToCache = YES;
        _actions = [actions mutableCopy];
        _cacheWorker = cacheWorker;
        _url = url;
    }
    return self;
}

- (void)start {
    [self processActions];
}

- (void)cancel {
    if (_session) {
        [self.session invalidateAndCancel];
    }
    self.cancelled = YES;
}

- (__FWPlayerCacheSessionDelegateObject *)sessionDelegateObject {
    if (!_sessionDelegateObject) {
        _sessionDelegateObject = [[__FWPlayerCacheSessionDelegateObject alloc] initWithDelegate:self];
    }
    
    return _sessionDelegateObject;
}

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self.sessionDelegateObject delegateQueue:[__FWPlayerCacheSessionManager shared].downloadQueue];
        _session = session;
    }
    return _session;
}

- (void)processActions {
    if (self.isCancelled) {
        return;
    }
    
    __FWPlayerCacheAction *action = [self popFirstActionInList];
    if (!action) {
        return;
    }
    
    if (action.actionType == __FWPlayerCacheAtionTypeLocal) {
        NSError *error;
        NSData *data = [self.cacheWorker cachedDataForRange:action.range error:&error];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(actionWorker:didFinishWithError:)]) {
                [self.delegate actionWorker:self didFinishWithError:error];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(actionWorker:didReceiveData:isLocal:)]) {
                [self.delegate actionWorker:self didReceiveData:data isLocal:YES];
            }
            [self processActionsLater];
        }
    } else {
        long long fromOffset = action.range.location;
        long long endOffset = action.range.location + action.range.length - 1;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        NSString *range = [NSString stringWithFormat:@"bytes=%lld-%lld", fromOffset, endOffset];
        [request setValue:range forHTTPHeaderField:@"Range"];
        self.startOffset = action.range.location;
        self.task = [self.session dataTaskWithRequest:request];
        [self.task resume];
    }
}

- (void)processActionsLater {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(self) self = weakSelf;
        [self processActions];
    });
}

- (__FWPlayerCacheAction *)popFirstActionInList {
    @synchronized (self) {
        __FWPlayerCacheAction *action = [self.actions firstObject];
        if (action) {
            [self.actions removeObjectAtIndex:0];
            return action;
        }
    }
    if ([self.delegate respondsToSelector:@selector(actionWorker:didFinishWithError:)]) {
        [self.delegate actionWorker:self didFinishWithError:nil];
    }
    return nil;
}

- (void)notifyDownloadProgressWithFlush:(BOOL)flush finished:(BOOL)finished {
    double currentTime = CFAbsoluteTimeGetCurrent();
    double interval = [__FWPlayerCacheManager cacheUpdateNotifyInterval];
    if ((self.notifyTime < currentTime - interval) || flush) {
        self.notifyTime = currentTime;
        __FWPlayerCacheConfiguration *configuration = [self.cacheWorker.cacheConfiguration copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:__FWPlayerCacheManagerDidUpdateCacheNotification
                                                            object:self
                                                          userInfo:@{
                                                                     __FWPlayerCacheConfigurationKey: configuration,
                                                                     }];
            
        if (finished && configuration.progress >= 1.0) {
            [self notifyDownloadFinishedWithError:nil];
        }
    }
}

- (void)notifyDownloadFinishedWithError:(NSError *)error {
    __FWPlayerCacheConfiguration *configuration = [self.cacheWorker.cacheConfiguration copy];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:configuration forKey:__FWPlayerCacheConfigurationKey];
    [userInfo setValue:error forKey:__FWPlayerCacheFinishedErrorKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:__FWPlayerCacheManagerDidFinishCacheNotification
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark - __FWPlayerCacheSessionDelegateObjectDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential,card);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSString *mimeType = response.MIMEType;
    // Only download video/audio data
    if ([mimeType rangeOfString:@"video/"].location == NSNotFound &&
        [mimeType rangeOfString:@"audio/"].location == NSNotFound &&
        [mimeType rangeOfString:@"application"].location == NSNotFound) {
        completionHandler(NSURLSessionResponseCancel);
    } else {
        if ([self.delegate respondsToSelector:@selector(actionWorker:didReceiveResponse:)]) {
            [self.delegate actionWorker:self didReceiveResponse:response];
        }
        if (self.canSaveToCache) {
            [self.cacheWorker startWritting];
        }
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (self.isCancelled) {
        return;
    }
    
    if (self.canSaveToCache) {
        NSRange range = NSMakeRange(self.startOffset, data.length);
        NSError *error;
        [self.cacheWorker cacheData:data forRange:range error:&error];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(actionWorker:didFinishWithError:)]) {
                [self.delegate actionWorker:self didFinishWithError:error];
            }
            return;
        }
        [self.cacheWorker save];
    }
    
    self.startOffset += data.length;
    if ([self.delegate respondsToSelector:@selector(actionWorker:didReceiveData:isLocal:)]) {
        [self.delegate actionWorker:self didReceiveData:data isLocal:NO];
    }
    
    [self notifyDownloadProgressWithFlush:NO finished:NO];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (self.canSaveToCache) {
        [self.cacheWorker finishWritting];
        [self.cacheWorker save];
    }
    if (error) {
        if ([self.delegate respondsToSelector:@selector(actionWorker:didFinishWithError:)]) {
            [self.delegate actionWorker:self didFinishWithError:error];
        }
        [self notifyDownloadFinishedWithError:error];
    } else {
        [self notifyDownloadProgressWithFlush:YES finished:YES];
        [self processActions];
    }
}

@end

#pragma mark - Class: __FWPlayerCacheDownloaderStatus


@interface __FWPlayerCacheDownloaderStatus ()

@property (nonatomic, strong) NSMutableSet *downloadingURLS;

@end

@implementation __FWPlayerCacheDownloaderStatus

+ (instancetype)shared {
    static __FWPlayerCacheDownloaderStatus *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.downloadingURLS = [NSMutableSet set];
    });
    
    return instance;
}

- (void)addURL:(NSURL *)url {
    @synchronized (self.downloadingURLS) {
        [self.downloadingURLS addObject:url];
    }
}

- (void)removeURL:(NSURL *)url {
    @synchronized (self.downloadingURLS) {
        [self.downloadingURLS removeObject:url];
    }
}

- (BOOL)containsURL:(NSURL *)url {
    @synchronized (self.downloadingURLS) {
        return [self.downloadingURLS containsObject:url];
    }
}

- (NSSet *)urls {
    return [self.downloadingURLS copy];
}

@end

#pragma mark - Class: __FWPlayerCacheDownloader

@interface __FWPlayerCacheDownloader () <__FWPlayerCacheActionWorkerDelegate>

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURLSessionDataTask *task;

@property (nonatomic, strong) __FWPlayerCacheWorker *cacheWorker;
@property (nonatomic, strong) __FWPlayerCacheActionWorker *actionWorker;

@property (nonatomic) BOOL downloadToEnd;

@end

@implementation __FWPlayerCacheDownloader

- (void)dealloc {
    [[__FWPlayerCacheDownloaderStatus shared] removeURL:self.url];
}

- (instancetype)initWithURL:(NSURL *)url cacheWorker:(__FWPlayerCacheWorker *)cacheWorker {
    self = [super init];
    if (self) {
        _saveToCache = YES;
        _url = url;
        _cacheWorker = cacheWorker;
        _info = _cacheWorker.cacheConfiguration.contentInfo;
        [[__FWPlayerCacheDownloaderStatus shared] addURL:self.url];
    }
    return self;
}

- (void)downloadTaskFromOffset:(unsigned long long)fromOffset
                        length:(NSUInteger)length
                         toEnd:(BOOL)toEnd {
    // ---
    NSRange range = NSMakeRange((NSUInteger)fromOffset, length);
    
    if (toEnd) {
        range.length = (NSUInteger)self.cacheWorker.cacheConfiguration.contentInfo.contentLength - range.location;
    }
    
    NSArray *actions = [self.cacheWorker cachedDataActionsForRange:range];

    self.actionWorker = [[__FWPlayerCacheActionWorker alloc] initWithActions:actions url:self.url cacheWorker:self.cacheWorker];
    self.actionWorker.canSaveToCache = self.saveToCache;
    self.actionWorker.delegate = self;
    [self.actionWorker start];
}

- (void)downloadFromStartToEnd {
    // ---
    self.downloadToEnd = YES;
    NSRange range = NSMakeRange(0, 2);
    NSArray *actions = [self.cacheWorker cachedDataActionsForRange:range];

    self.actionWorker = [[__FWPlayerCacheActionWorker alloc] initWithActions:actions url:self.url cacheWorker:self.cacheWorker];
    self.actionWorker.canSaveToCache = self.saveToCache;
    self.actionWorker.delegate = self;
    [self.actionWorker start];
}

- (void)cancel {
    self.actionWorker.delegate = nil;
    [[__FWPlayerCacheDownloaderStatus shared] removeURL:self.url];
    [self.actionWorker cancel];
    self.actionWorker = nil;
}

#pragma mark - __FWPlayerCacheActionWorkerDelegate

- (void)actionWorker:(__FWPlayerCacheActionWorker *)actionWorker didReceiveResponse:(NSURLResponse *)response {
    if (!self.info) {
        __FWPlayerCacheContentInfo *info = [__FWPlayerCacheContentInfo new];
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)response;
            NSString *acceptRange = HTTPURLResponse.allHeaderFields[@"Accept-Ranges"];
            info.byteRangeAccessSupported = [acceptRange isEqualToString:@"bytes"];
            info.contentLength = [[[HTTPURLResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
        }
        NSString *mimeType = response.MIMEType;
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
        info.contentType = CFBridgingRelease(contentType);
        self.info = info;
        
        NSError *error;
        [self.cacheWorker setContentInfo:info error:&error];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(mediaDownloader:didFinishedWithError:)]) {
                [self.delegate mediaDownloader:self didFinishedWithError:error];
            }
            return;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(mediaDownloader:didReceiveResponse:)]) {
        [self.delegate mediaDownloader:self didReceiveResponse:response];
    }
}

- (void)actionWorker:(__FWPlayerCacheActionWorker *)actionWorker didReceiveData:(NSData *)data isLocal:(BOOL)isLocal {
    if ([self.delegate respondsToSelector:@selector(mediaDownloader:didReceiveData:)]) {
        [self.delegate mediaDownloader:self didReceiveData:data];
    }
}

- (void)actionWorker:(__FWPlayerCacheActionWorker *)actionWorker didFinishWithError:(NSError *)error {
    [[__FWPlayerCacheDownloaderStatus shared] removeURL:self.url];
    
    if (!error && self.downloadToEnd) {
        self.downloadToEnd = NO;
        [self downloadTaskFromOffset:2 length:(NSUInteger)(self.cacheWorker.cacheConfiguration.contentInfo.contentLength - 2) toEnd:YES];
    } else {
        if ([self.delegate respondsToSelector:@selector(mediaDownloader:didFinishedWithError:)]) {
            [self.delegate mediaDownloader:self didFinishedWithError:error];
        }
    }
}

@end

#pragma mark - __FWPlayerCacheRequestWorker

@interface __FWPlayerCacheRequestWorker () <__FWPlayerCacheDownloaderDelegate>

@property (nonatomic, strong, readwrite) AVAssetResourceLoadingRequest *request;
@property (nonatomic, strong) __FWPlayerCacheDownloader *mediaDownloader;

@end

@implementation __FWPlayerCacheRequestWorker

- (instancetype)initWithMediaDownloader:(__FWPlayerCacheDownloader *)mediaDownloader resourceLoadingRequest:(AVAssetResourceLoadingRequest *)request {
    self = [super init];
    if (self) {
        _mediaDownloader = mediaDownloader;
        _mediaDownloader.delegate = self;
        _request = request;
        
        [self fullfillContentInfo];
    }
    return self;
}

- (void)startWork {
    AVAssetResourceLoadingDataRequest *dataRequest = self.request.dataRequest;
    
    long long offset = dataRequest.requestedOffset;
    NSInteger length = dataRequest.requestedLength;
    if (dataRequest.currentOffset != 0) {
        offset = dataRequest.currentOffset;
    }
    
    BOOL toEnd = NO;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        if (dataRequest.requestsAllDataToEndOfResource) {
            toEnd = YES;
        }
    }
    [self.mediaDownloader downloadTaskFromOffset:offset length:length toEnd:toEnd];
}

- (void)cancel {
    [self.mediaDownloader cancel];
}

- (void)finish {
    if (!self.request.isFinished) {
        [self.mediaDownloader cancel];
        [self.request finishLoadingWithError:[self loaderCancelledError]];
    }
}

- (NSError *)loaderCancelledError{
    NSError *error = [[NSError alloc] initWithDomain:@"FWPlayerCache"
                                                code:-3
                                            userInfo:@{NSLocalizedDescriptionKey:@"Resource loader cancelled"}];
    return error;
}

- (void)fullfillContentInfo {
    AVAssetResourceLoadingContentInformationRequest *contentInformationRequest = self.request.contentInformationRequest;
    if (self.mediaDownloader.info && !contentInformationRequest.contentType) {
        // Fullfill content information
        contentInformationRequest.contentType = self.mediaDownloader.info.contentType;
        contentInformationRequest.contentLength = self.mediaDownloader.info.contentLength;
        contentInformationRequest.byteRangeAccessSupported = self.mediaDownloader.info.byteRangeAccessSupported;
    }
}

#pragma mark - __FWPlayerCacheDownloaderDelegate

- (void)mediaDownloader:(__FWPlayerCacheDownloader *)downloader didReceiveResponse:(NSURLResponse *)response {
    [self fullfillContentInfo];
}

- (void)mediaDownloader:(__FWPlayerCacheDownloader *)downloader didReceiveData:(NSData *)data {
    [self.request.dataRequest respondWithData:data];
}

- (void)mediaDownloader:(__FWPlayerCacheDownloader *)downloader didFinishedWithError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    
    if (!error) {
        [self.request finishLoading];
    } else {
        [self.request finishLoadingWithError:error];
    }
    
    [self.delegate resourceLoadingRequestWorker:self didCompleteWithError:error];
}

@end

#pragma mark - __FWPlayerCacheContentInfo

static NSString *kContentLengthKey = @"kContentLengthKey";
static NSString *kContentTypeKey = @"kContentTypeKey";
static NSString *kByteRangeAccessSupported = @"kByteRangeAccessSupported";

@implementation __FWPlayerCacheContentInfo

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@\ncontentLength: %lld\ncontentType: %@\nbyteRangeAccessSupported:%@", NSStringFromClass([self class]), self.contentLength, self.contentType, @(self.byteRangeAccessSupported)];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.contentLength) forKey:kContentLengthKey];
    [aCoder encodeObject:self.contentType forKey:kContentTypeKey];
    [aCoder encodeObject:@(self.byteRangeAccessSupported) forKey:kByteRangeAccessSupported];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _contentLength = [[aDecoder decodeObjectForKey:kContentLengthKey] longLongValue];
        _contentType = [aDecoder decodeObjectForKey:kContentTypeKey];
        _byteRangeAccessSupported = [[aDecoder decodeObjectForKey:kByteRangeAccessSupported] boolValue];
    }
    return self;
}

@end

#pragma mark - __FWPlayerCacheAction

@implementation __FWPlayerCacheAction

- (instancetype)initWithActionType:(__FWPlayerCacheAtionType)actionType range:(NSRange)range {
    self = [super init];
    if (self) {
        _actionType = actionType;
        _range = range;
    }
    return self;
}

- (BOOL)isEqual:(__FWPlayerCacheAction *)object {
    if (!NSEqualRanges(object.range, self.range)) {
        return NO;
    }
    
    if (object.actionType != self.actionType) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%@%@", NSStringFromRange(self.range), @(self.actionType)] hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"actionType %@, range: %@", @(self.actionType), NSStringFromRange(self.range)];
}

@end

#pragma mark - __FWPlayerCacheConfiguration

static NSString *kFileNameKey = @"kFileNameKey";
static NSString *kCacheFragmentsKey = @"kCacheFragmentsKey";
static NSString *kDownloadInfoKey = @"kDownloadInfoKey";
static NSString *kContentInfoKey = @"kContentInfoKey";
static NSString *kURLKey = @"kURLKey";

@interface __FWPlayerCacheConfiguration () <NSCoding>

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSArray<NSValue *> *internalCacheFragments;
@property (nonatomic, copy) NSArray *downloadInfo;

@end

@implementation __FWPlayerCacheConfiguration

+ (instancetype)configurationWithFilePath:(NSString *)filePath {
    filePath = [self configurationFilePathForFilePath:filePath];
    __FWPlayerCacheConfiguration *configuration;
    @try {
        configuration = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    } @catch (NSException *exception) {}
    
    if (!configuration) {
        configuration = [[__FWPlayerCacheConfiguration alloc] init];
        configuration.fileName = [filePath lastPathComponent];
    }
    configuration.filePath = filePath;
    
    return configuration;
}

+ (NSString *)configurationFilePathForFilePath:(NSString *)filePath {
    return [filePath stringByAppendingPathExtension:@"cache_cfg"];
}

- (NSArray<NSValue *> *)internalCacheFragments {
    if (!_internalCacheFragments) {
        _internalCacheFragments = [NSArray array];
    }
    return _internalCacheFragments;
}

- (NSArray *)downloadInfo {
    if (!_downloadInfo) {
        _downloadInfo = [NSArray array];
    }
    return _downloadInfo;
}

- (NSArray<NSValue *> *)cacheFragments {
    return [_internalCacheFragments copy];
}

- (float)progress {
    float progress = self.downloadedBytes / (float)self.contentInfo.contentLength;
    return progress;
}

- (long long)downloadedBytes {
    float bytes = 0;
    @synchronized (self.internalCacheFragments) {
        for (NSValue *range in self.internalCacheFragments) {
            bytes += range.rangeValue.length;
        }
    }
    return bytes;
}

- (float)downloadSpeed {
    long long bytes = 0;
    NSTimeInterval time = 0;
    @synchronized (self.downloadInfo) {
        for (NSArray *a in self.downloadInfo) {
            bytes += [[a firstObject] longLongValue];
            time += [[a lastObject] doubleValue];
        }
    }
    return bytes / 1024.0 / time;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.fileName forKey:kFileNameKey];
    [aCoder encodeObject:self.internalCacheFragments forKey:kCacheFragmentsKey];
    [aCoder encodeObject:self.downloadInfo forKey:kDownloadInfoKey];
    [aCoder encodeObject:self.contentInfo forKey:kContentInfoKey];
    [aCoder encodeObject:self.url forKey:kURLKey];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _fileName = [aDecoder decodeObjectForKey:kFileNameKey];
        _internalCacheFragments = [[aDecoder decodeObjectForKey:kCacheFragmentsKey] mutableCopy];
        if (!_internalCacheFragments) {
            _internalCacheFragments = [NSArray array];
        }
        _downloadInfo = [aDecoder decodeObjectForKey:kDownloadInfoKey];
        _contentInfo = [aDecoder decodeObjectForKey:kContentInfoKey];
        _url = [aDecoder decodeObjectForKey:kURLKey];
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    __FWPlayerCacheConfiguration *configuration = [[__FWPlayerCacheConfiguration allocWithZone:zone] init];
    configuration.fileName = self.fileName;
    configuration.filePath = self.filePath;
    configuration.internalCacheFragments = self.internalCacheFragments;
    configuration.downloadInfo = self.downloadInfo;
    configuration.url = self.url;
    configuration.contentInfo = self.contentInfo;
    
    return configuration;
}

#pragma mark - Update

- (void)save {
    if ([NSThread isMainThread]) {
        [self doDelaySaveAction];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self doDelaySaveAction];
        });
    }
}

- (void)doDelaySaveAction {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(archiveData) object:nil];
    [self performSelector:@selector(archiveData) withObject:nil afterDelay:1.0];
}

- (void)archiveData {
    @synchronized (self.internalCacheFragments) {
        @try {
            [NSKeyedArchiver archiveRootObject:self toFile:self.filePath];
        } @catch (NSException *exception) {}
    }
}

- (void)addCacheFragment:(NSRange)fragment {
    if (fragment.location == NSNotFound || fragment.length == 0) {
        return;
    }
    
    @synchronized (self.internalCacheFragments) {
        NSMutableArray *internalCacheFragments = [self.internalCacheFragments mutableCopy];
        
        NSValue *fragmentValue = [NSValue valueWithRange:fragment];
        NSInteger count = self.internalCacheFragments.count;
        if (count == 0) {
            [internalCacheFragments addObject:fragmentValue];
        } else {
            NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
            [internalCacheFragments enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSRange range = obj.rangeValue;
                if ((fragment.location + fragment.length) <= range.location) {
                    if (indexSet.count == 0) {
                        [indexSet addIndex:idx];
                    }
                    *stop = YES;
                } else if (fragment.location <= (range.location + range.length) && (fragment.location + fragment.length) > range.location) {
                    [indexSet addIndex:idx];
                } else if (fragment.location >= range.location + range.length) {
                    if (idx == count - 1) { // Append to last index
                        [indexSet addIndex:idx];
                    }
                }
            }];
            
            if (indexSet.count > 1) {
                NSRange firstRange = self.internalCacheFragments[indexSet.firstIndex].rangeValue;
                NSRange lastRange = self.internalCacheFragments[indexSet.lastIndex].rangeValue;
                NSInteger location = MIN(firstRange.location, fragment.location);
                NSInteger endOffset = MAX(lastRange.location + lastRange.length, fragment.location + fragment.length);
                NSRange combineRange = NSMakeRange(location, endOffset - location);
                [internalCacheFragments removeObjectsAtIndexes:indexSet];
                [internalCacheFragments insertObject:[NSValue valueWithRange:combineRange] atIndex:indexSet.firstIndex];
            } else if (indexSet.count == 1) {
                NSRange firstRange = self.internalCacheFragments[indexSet.firstIndex].rangeValue;
                
                NSRange expandFirstRange = NSMakeRange(firstRange.location, firstRange.length + 1);
                NSRange expandFragmentRange = NSMakeRange(fragment.location, fragment.length + 1);
                NSRange intersectionRange = NSIntersectionRange(expandFirstRange, expandFragmentRange);
                if (intersectionRange.length > 0) { // Should combine
                    NSInteger location = MIN(firstRange.location, fragment.location);
                    NSInteger endOffset = MAX(firstRange.location + firstRange.length, fragment.location + fragment.length);
                    NSRange combineRange = NSMakeRange(location, endOffset - location);
                    [internalCacheFragments removeObjectAtIndex:indexSet.firstIndex];
                    [internalCacheFragments insertObject:[NSValue valueWithRange:combineRange] atIndex:indexSet.firstIndex];
                } else {
                    if (firstRange.location > fragment.location) {
                        [internalCacheFragments insertObject:fragmentValue atIndex:[indexSet lastIndex]];
                    } else {
                        [internalCacheFragments insertObject:fragmentValue atIndex:[indexSet lastIndex] + 1];
                    }
                }
            }
        }
        
        self.internalCacheFragments = [internalCacheFragments copy];
    }
}

- (void)addDownloadedBytes:(long long)bytes spent:(NSTimeInterval)time {
    @synchronized (self.downloadInfo) {
        self.downloadInfo = [self.downloadInfo arrayByAddingObject:@[@(bytes), @(time)]];
    }
}

+ (BOOL)createAndSaveDownloadedConfigurationForURL:(NSURL *)url error:(NSError **)error {
    NSString *filePath = [__FWPlayerCacheManager cachedFilePathForURL:url];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary<NSFileAttributeKey, id> *attributes = [fileManager attributesOfItemAtPath:filePath error:error];
    if (!attributes) {
        return NO;
    }
    
    NSUInteger fileSize = (NSUInteger)attributes.fileSize;
    NSRange range = NSMakeRange(0, fileSize);
    
    __FWPlayerCacheConfiguration *configuration = [__FWPlayerCacheConfiguration configurationWithFilePath:filePath];
    configuration.url = url;
    
    __FWPlayerCacheContentInfo *contentInfo = [__FWPlayerCacheContentInfo new];
    
    NSString *fileExtension = [url pathExtension];
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        contentType = @"application/octet-stream";
    }
    contentInfo.contentType = contentType;
    
    contentInfo.contentLength = fileSize;
    contentInfo.byteRangeAccessSupported = YES;
    contentInfo.downloadedContentLength = fileSize;
    configuration.contentInfo = contentInfo;
    
    [configuration addCacheFragment:range];
    [configuration save];
    
    return YES;
}

@end

#pragma mark - __FWPlayerCacheManager

NSNotificationName __FWPlayerCacheManagerDidUpdateCacheNotification = @"FWPlayerCacheManagerDidUpdateCacheNotification";
NSNotificationName __FWPlayerCacheManagerDidFinishCacheNotification = @"FWPlayerCacheManagerDidFinishCacheNotification";

NSString *__FWPlayerCacheConfigurationKey = @"FWPlayerCacheConfigurationKey";
NSString *__FWPlayerCacheFinishedErrorKey = @"FWPlayerCacheFinishedErrorKey";

static NSString *kPlayerCacheDirectory = nil;
static NSTimeInterval kPlayerCacheNotifyInterval = 0.1;
static NSString *(^kPlayerFileNameRules)(NSURL *url);

@implementation __FWPlayerCacheManager

+ (void)setCacheDirectory:(NSString *)cacheDirectory {
    kPlayerCacheDirectory = cacheDirectory;
}

+ (NSString *)cacheDirectory {
    if (!kPlayerCacheDirectory) {
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        kPlayerCacheDirectory = [[cachePath stringByAppendingPathComponent:@"FWFramework"] stringByAppendingPathComponent:@"PlayerCache"];
    }
    return kPlayerCacheDirectory;
}

+ (void)setCacheUpdateNotifyInterval:(NSTimeInterval)interval {
    kPlayerCacheNotifyInterval = interval;
}

+ (NSTimeInterval)cacheUpdateNotifyInterval {
    return kPlayerCacheNotifyInterval;
}

+ (void)setFileNameRules:(NSString *(^)(NSURL *url))rules {
    kPlayerFileNameRules = rules;
}

+ (NSString *)cachedFilePathForURL:(NSURL *)url {
    NSString *pathComponent = nil;
    if (kPlayerFileNameRules) {
        pathComponent = kPlayerFileNameRules(url);
    } else {
        pathComponent = [self md5EncodeString:url.absoluteString];
        pathComponent = [pathComponent stringByAppendingPathExtension:url.pathExtension];
    }
    return [[self cacheDirectory] stringByAppendingPathComponent:pathComponent];
}

+ (NSString *)md5EncodeString:(NSString *)string {
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x", digest[i]];
    }
    return [NSString stringWithString:output];
}

+ (__FWPlayerCacheConfiguration *)cacheConfigurationForURL:(NSURL *)url {
    NSString *filePath = [self cachedFilePathForURL:url];
    __FWPlayerCacheConfiguration *configuration = [__FWPlayerCacheConfiguration configurationWithFilePath:filePath];
    return configuration;
}

+ (unsigned long long)calculateCachedSizeWithError:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheDirectory = [self cacheDirectory];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:cacheDirectory error:error];
    unsigned long long size = 0;
    if (files) {
        for (NSString *path in files) {
            NSString *filePath = [cacheDirectory stringByAppendingPathComponent:path];
            NSDictionary<NSFileAttributeKey, id> *attribute = [fileManager attributesOfItemAtPath:filePath error:error];
            if (!attribute) {
                size = -1;
                break;
            }
            
            size += [attribute fileSize];
        }
    }
    return size;
}

+ (void)cleanAllCacheWithError:(NSError **)error {
    // Find downloaing file
    NSMutableSet *downloadingFiles = [NSMutableSet set];
    [[[__FWPlayerCacheDownloaderStatus shared] urls] enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *file = [self cachedFilePathForURL:obj];
        [downloadingFiles addObject:file];
        NSString *configurationPath = [__FWPlayerCacheConfiguration configurationFilePathForFilePath:file];
        [downloadingFiles addObject:configurationPath];
    }];
    
    // Remove files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheDirectory = [self cacheDirectory];
    
    NSArray *files = [fileManager contentsOfDirectoryAtPath:cacheDirectory error:error];
    if (files) {
        for (NSString *path in files) {
            NSString *filePath = [cacheDirectory stringByAppendingPathComponent:path];
            if ([downloadingFiles containsObject:filePath]) {
                continue;
            }
            if (![fileManager removeItemAtPath:filePath error:error]) {
                break;
            }
        }
    }
}

+ (void)cleanCacheForURL:(NSURL *)url error:(NSError **)error {
    if ([[__FWPlayerCacheDownloaderStatus shared] containsURL:url]) {
        NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Clean cache for url `%@` can't be done, because it's downloading", nil), url];
        if (error) {
            *error = [NSError errorWithDomain:@"FWPlayerCache" code:2 userInfo:@{NSLocalizedDescriptionKey: description}];
        }
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [self cachedFilePathForURL:url];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        if (![fileManager removeItemAtPath:filePath error:error]) {
            return;
        }
    }
    
    NSString *configurationPath = [__FWPlayerCacheConfiguration configurationFilePathForFilePath:filePath];
    if ([fileManager fileExistsAtPath:configurationPath]) {
        if (![fileManager removeItemAtPath:configurationPath error:error]) {
            return;
        }
    }
}

+ (BOOL)addCacheFile:(NSString *)filePath forURL:(NSURL *)url error:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *cachePath = [__FWPlayerCacheManager cachedFilePathForURL:url];
    NSString *cacheFolder = [cachePath stringByDeletingLastPathComponent];
    if (![fileManager fileExistsAtPath:cacheFolder]) {
        if (![fileManager createDirectoryAtPath:cacheFolder
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:error]) {
            return NO;
        }
    }
    
    if (![fileManager copyItemAtPath:filePath toPath:cachePath error:error]) {
        return NO;
    }
    
    if (![__FWPlayerCacheConfiguration createAndSaveDownloadedConfigurationForURL:url error:error]) {
        [fileManager removeItemAtPath:cachePath error:nil]; // if remove failed, there is nothing we can do.
        return NO;
    }
    
    return YES;
}

@end

#pragma mark - __FWPlayerCacheSessionManager

@interface __FWPlayerCacheSessionManager ()

@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@end

@implementation __FWPlayerCacheSessionManager

+ (instancetype)shared {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.name = @"site.wuyong.queue.player.download";
        _downloadQueue = queue;
    }
    return self;
}

@end

#pragma mark - __FWPlayerCacheWorker

static NSInteger const kPackageLength = 512 * 1024; // 512 kb per package
static NSString *kPlayerCacheResponseKey = @"kPlayerCacheResponseKey";

@interface __FWPlayerCacheWorker ()

@property (nonatomic, strong) NSFileHandle *readFileHandle;
@property (nonatomic, strong) NSFileHandle *writeFileHandle;
@property (nonatomic, strong, readwrite) NSError *setupError;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) __FWPlayerCacheConfiguration *internalCacheConfiguration;

@property (nonatomic) long long currentOffset;

@property (nonatomic, strong) NSDate *startWriteDate;
@property (nonatomic) float writeBytes;
@property (nonatomic) BOOL writting;

@end

@implementation __FWPlayerCacheWorker

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self save];
    [_readFileHandle closeFile];
    [_writeFileHandle closeFile];
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        NSString *path = [__FWPlayerCacheManager cachedFilePathForURL:url];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        _filePath = path;
        NSError *error;
        NSString *cacheFolder = [path stringByDeletingLastPathComponent];
        if (![fileManager fileExistsAtPath:cacheFolder]) {
            [fileManager createDirectoryAtPath:cacheFolder
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error];
        }
        
        if (!error) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
            }
            NSURL *fileURL = [NSURL fileURLWithPath:path];
            _readFileHandle = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&error];
            if (!error) {
                _writeFileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
                _internalCacheConfiguration = [__FWPlayerCacheConfiguration configurationWithFilePath:path];
                _internalCacheConfiguration.url = url;
            }
        }
        
        _setupError = error;
    }
    return self;
}

- (__FWPlayerCacheConfiguration *)cacheConfiguration {
    return self.internalCacheConfiguration;
}

- (void)cacheData:(NSData *)data forRange:(NSRange)range error:(NSError **)error {
    @synchronized(self.writeFileHandle) {
        @try {
            [self.writeFileHandle seekToFileOffset:range.location];
            [self.writeFileHandle writeData:data];
            self.writeBytes += data.length;
            [self.internalCacheConfiguration addCacheFragment:range];
        } @catch (NSException *exception) {
            *error = [NSError errorWithDomain:exception.name code:123 userInfo:@{NSLocalizedDescriptionKey: exception.reason, @"exception": exception}];
        }
    }
}

- (NSData *)cachedDataForRange:(NSRange)range error:(NSError **)error {
    @synchronized(self.readFileHandle) {
        @try {
            [self.readFileHandle seekToFileOffset:range.location];
            NSData *data = [self.readFileHandle readDataOfLength:range.length]; // 空数据也会返回，所以如果 range 错误，会导致播放失效
            return data;
        } @catch (NSException *exception) {
            *error = [NSError errorWithDomain:exception.name code:123 userInfo:@{NSLocalizedDescriptionKey: exception.reason, @"exception": exception}];
        }
    }
    return nil;
}

- (NSArray<__FWPlayerCacheAction *> *)cachedDataActionsForRange:(NSRange)range {
    NSArray *cachedFragments = [self.internalCacheConfiguration cacheFragments];
    NSMutableArray *actions = [NSMutableArray array];
    
    if (range.location == NSNotFound) {
        return [actions copy];
    }
    NSInteger endOffset = range.location + range.length;
    // Delete header and footer not in range
    [cachedFragments enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange fragmentRange = obj.rangeValue;
        NSRange intersectionRange = NSIntersectionRange(range, fragmentRange);
        if (intersectionRange.length > 0) {
            NSInteger package = intersectionRange.length / kPackageLength;
            for (NSInteger i = 0; i <= package; i++) {
                __FWPlayerCacheAction *action = [__FWPlayerCacheAction new];
                action.actionType = __FWPlayerCacheAtionTypeLocal;
                
                NSInteger offset = i * kPackageLength;
                NSInteger offsetLocation = intersectionRange.location + offset;
                NSInteger maxLocation = intersectionRange.location + intersectionRange.length;
                NSInteger length = (offsetLocation + kPackageLength) > maxLocation ? (maxLocation - offsetLocation) : kPackageLength;
                action.range = NSMakeRange(offsetLocation, length);
                
                [actions addObject:action];
            }
        } else if (fragmentRange.location >= endOffset) {
            *stop = YES;
        }
    }];
    
    if (actions.count == 0) {
        __FWPlayerCacheAction *action = [__FWPlayerCacheAction new];
        action.actionType = __FWPlayerCacheAtionTypeRemote;
        action.range = range;
        [actions addObject:action];
    } else {
        // Add remote fragments
        NSMutableArray *localRemoteActions = [NSMutableArray array];
        [actions enumerateObjectsUsingBlock:^(__FWPlayerCacheAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange actionRange = obj.range;
            if (idx == 0) {
                if (range.location < actionRange.location) {
                    __FWPlayerCacheAction *action = [__FWPlayerCacheAction new];
                    action.actionType = __FWPlayerCacheAtionTypeRemote;
                    action.range = NSMakeRange(range.location, actionRange.location - range.location);
                    [localRemoteActions addObject:action];
                }
                [localRemoteActions addObject:obj];
            } else {
                __FWPlayerCacheAction *lastAction = [localRemoteActions lastObject];
                NSInteger lastOffset = lastAction.range.location + lastAction.range.length;
                if (actionRange.location > lastOffset) {
                    __FWPlayerCacheAction *action = [__FWPlayerCacheAction new];
                    action.actionType = __FWPlayerCacheAtionTypeRemote;
                    action.range = NSMakeRange(lastOffset, actionRange.location - lastOffset);
                    [localRemoteActions addObject:action];
                }
                [localRemoteActions addObject:obj];
            }
            
            if (idx == actions.count - 1) {
                NSInteger localEndOffset = actionRange.location + actionRange.length;
                if (endOffset > localEndOffset) {
                    __FWPlayerCacheAction *action = [__FWPlayerCacheAction new];
                    action.actionType = __FWPlayerCacheAtionTypeRemote;
                    action.range = NSMakeRange(localEndOffset, endOffset - localEndOffset);
                    [localRemoteActions addObject:action];
                }
            }
        }];
        
        actions = localRemoteActions;
    }
    
    return [actions copy];
}

- (void)setContentInfo:(__FWPlayerCacheContentInfo *)contentInfo error:(NSError **)error {
    self.internalCacheConfiguration.contentInfo = contentInfo;
    @try {
        [self.writeFileHandle truncateFileAtOffset:contentInfo.contentLength];
        [self.writeFileHandle synchronizeFile];
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:exception.name code:123 userInfo:@{NSLocalizedDescriptionKey: exception.reason, @"exception": exception}];
    }
}

- (void)save {
    @synchronized (self.writeFileHandle) {
        [self.writeFileHandle synchronizeFile];
        [self.internalCacheConfiguration save];
    }
}

- (void)startWritting {
    if (!self.writting) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    self.writting = YES;
    self.startWriteDate = [NSDate date];
    self.writeBytes = 0;
}

- (void)finishWritting {
    if (self.writting) {
        self.writting = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:self.startWriteDate];
        [self.internalCacheConfiguration addDownloadedBytes:self.writeBytes spent:time];
    }
}

#pragma mark - Notification

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self save];
}

@end
