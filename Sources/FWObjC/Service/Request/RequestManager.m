//
//  RequestManager.m
//
//  Copyright (c) 2012-2016 FWNetwork https://github.com/yuantiku
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "RequestManager.h"
#import <pthread/pthread.h>
#import "HTTPSessionManager.h"
#import "ObjC.h"

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

#define kFWNetworkIncompleteDownloadFolderName @"Incomplete"

@interface __FWRequestManager ()

@property (strong, nonatomic) NSMutableArray<__FWBatchRequest *> *batchRequestArray;
@property (strong, nonatomic) NSMutableArray<__FWChainRequest *> *chainRequestArray;

@end

@implementation __FWRequestManager {
    __FWHTTPSessionManager *_manager;
    __FWRequestConfig *_config;
    __FWJSONResponseSerializer *_jsonResponseSerializer;
    __FWXMLParserResponseSerializer *_xmlParserResponseSerialzier;
    NSMutableDictionary<NSNumber *, __FWBaseRequest *> *_requestsRecord;

    dispatch_queue_t _processingQueue;
    pthread_mutex_t _lock;
    NSIndexSet *_allStatusCodes;
    dispatch_queue_t _synchronousQueue;
    dispatch_semaphore_t _synchronousSemaphore;
}

+ (__FWRequestManager *)sharedManager {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [__FWRequestConfig sharedConfig];
        _manager = [[__FWHTTPSessionManager alloc] initWithSessionConfiguration:_config.sessionConfiguration];
        _requestsRecord = [NSMutableDictionary dictionary];
        _processingQueue = dispatch_queue_create("site.wuyong.queue.request.processing", DISPATCH_QUEUE_CONCURRENT);
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        pthread_mutex_init(&_lock, NULL);
        _synchronousQueue = dispatch_queue_create("site.wuyong.queue.request.synchronous", DISPATCH_QUEUE_SERIAL);
        _synchronousSemaphore = dispatch_semaphore_create(1);
        _batchRequestArray = [NSMutableArray array];
        _chainRequestArray = [NSMutableArray array];

        _manager.securityPolicy = _config.securityPolicy;
        _manager.responseSerializer = [__FWHTTPResponseSerializer serializer];
        // Take over the status code validation
        _manager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
        _manager.completionQueue = _processingQueue;
        [_manager setTaskDidFinishCollectingMetricsBlock:_config.collectingMetricsBlock];
    }
    return self;
}

- (__FWHTTPResponseSerializer *)httpResponseSerializer {
    return _manager.responseSerializer;
}

- (__FWJSONResponseSerializer *)jsonResponseSerializer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _jsonResponseSerializer = [__FWJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableStatusCodes = _allStatusCodes;
        _jsonResponseSerializer.removesKeysWithNullValues = _config.removeNullValues;
    });
    return _jsonResponseSerializer;
}

- (__FWXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _xmlParserResponseSerialzier = [__FWXMLParserResponseSerializer serializer];
        _xmlParserResponseSerialzier.acceptableStatusCodes = _allStatusCodes;
    });
    return _xmlParserResponseSerialzier;
}

#pragma mark -

- (NSString *)buildRequestUrl:(__FWBaseRequest *)request {
    NSParameterAssert(request != nil);

    NSString *detailUrl = [request requestUrl];
    NSURL *temp = [NSURL URLWithString:detailUrl];
    if (!temp && [detailUrl length] > 0) {
        temp = [NSURL URLWithString:[detailUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    // If detailUrl is valid URL
    if (temp && temp.host && temp.scheme) {
        return detailUrl;
    }
    // Filter URL if needed
    NSArray *filters = [_config urlFilters];
    for (id<__FWUrlFilterProtocol> filter in filters) {
        if ([filter respondsToSelector:@selector(filterUrl:withRequest:)]) {
            detailUrl = [filter filterUrl:detailUrl withRequest:request];
        }
    }

    NSString *baseUrl;
    if ([request useCDN]) {
        if ([request cdnUrl].length > 0) {
            baseUrl = [request cdnUrl];
        } else {
            baseUrl = [_config cdnUrl];
        }
    } else {
        if ([request baseUrl].length > 0) {
            baseUrl = [request baseUrl];
        } else {
            baseUrl = [_config baseUrl];
        }
    }
    // URL slash compatibility
    NSURL *url = [NSURL URLWithString:baseUrl];
    if (!url && [baseUrl length] > 0) {
        url = [NSURL URLWithString:[baseUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }

    if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }

    NSURL *resultUrl = [NSURL URLWithString:detailUrl relativeToURL:url];
    if (!resultUrl && [detailUrl length] > 0) {
        resultUrl = [NSURL URLWithString:[detailUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] relativeToURL:url];
    }
    return resultUrl.absoluteString;
}

- (__FWHTTPRequestSerializer *)requestSerializerForRequest:(__FWBaseRequest *)request {
    __FWHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == __FWRequestSerializerTypeHTTP) {
        requestSerializer = [__FWHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == __FWRequestSerializerTypeJSON) {
        requestSerializer = [__FWJSONRequestSerializer serializer];
    }

    requestSerializer.timeoutInterval = [request requestTimeoutInterval];
    requestSerializer.allowsCellularAccess = [request allowsCellularAccess];
    NSURLRequestCachePolicy cachePolicy = [request requestCachePolicy];
    if (cachePolicy >= 0) {
        requestSerializer.cachePolicy = cachePolicy;
    }

    // If api needs server username and password
    NSArray<NSString *> *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil) {
        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
                                                          password:authorizationHeaderFieldArray.lastObject];
    }

    // If api needs to add custom value to HTTPHeaderField
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    return requestSerializer;
}

- (NSURLSessionTask *)sessionTaskForRequest:(__FWBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    if ([request requestMethod] == __FWRequestMethodGET && request.resumableDownloadPath) {
        return [self downloadTaskWithRequest:request progress:request.resumableDownloadProgressBlock error:error];
    }
    
    return [self dataTaskWithRequest:request error:error];
}

- (void)addRequest:(__FWBaseRequest *)request {
    NSParameterAssert(request != nil);

    NSError * __autoreleasing requestSerializationError = nil;
    request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    request.requestIdentifier = request.requestTask.taskIdentifier;
    if (requestSerializationError) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        return;
    }

    NSAssert(request.requestTask != nil, @"requestTask should not be nil");

    // Set request task priority
    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        switch (request.requestPriority) {
            case __FWRequestPriorityHigh:
                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case __FWRequestPriorityLow:
                request.requestTask.priority = NSURLSessionTaskPriorityLow;
                break;
            case __FWRequestPriorityDefault:
                /**!fall through*/
            default:
                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }

    // Retain request
    [self addRequestToRecord:request];
    [request.requestTask resume];
    #ifdef DEBUG
    if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
        FWLogDebug(@"\n===========REQUEST STARTED===========\n%@%@ %@:\n%@", @"▶️ ", [request requestMethodString], [request requestUrl], [NSString stringWithFormat:@"%@", [request requestArgument] ?: @""]);
    }
    #endif
}

- (void)cancelRequest:(__FWBaseRequest *)request {
    NSParameterAssert(request != nil);

    if (request.resumableDownloadPath && [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath] != nil) {
        NSURLSessionDownloadTask *requestTask = (NSURLSessionDownloadTask *)request.requestTask;
        [requestTask cancelByProducingResumeData:^(NSData *resumeData) {
            NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
            [resumeData writeToURL:localUrl atomically:YES];
        }];
    } else {
        [request.requestTask cancel];
    }

    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
    #ifdef DEBUG
    if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
        FWLogDebug(@"\n===========REQUEST CANCELLED===========\n%@%@ %@:\n%@", @"⏹️ ", [request requestMethodString], [request requestUrl], [NSString stringWithFormat:@"%@", [request requestArgument] ?: @""]);
    }
    #endif
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestsRecord allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            __FWBaseRequest *request = _requestsRecord[key];
            Unlock();
            // We are using non-recursive lock.
            // Do not lock `stop`, otherwise deadlock may occur.
            [request stop];
        }
    }
}

- (void)addBatchRequest:(__FWBatchRequest *)request {
    @synchronized(self) {
        [_batchRequestArray addObject:request];
    }
}

- (void)removeBatchRequest:(__FWBatchRequest *)request {
    @synchronized(self) {
        [_batchRequestArray removeObject:request];
    }
}

- (void)addChainRequest:(__FWChainRequest *)request {
    @synchronized(self) {
        [_chainRequestArray addObject:request];
    }
}

- (void)removeChainRequest:(__FWChainRequest *)request {
    @synchronized(self) {
        [_chainRequestArray removeObject:request];
    }
}

- (void)synchronousRequest:(__FWBaseRequest *)request filter:(BOOL (^)(void))filter completion:(__FWRequestCompletionBlock)completion {
    dispatch_async(_synchronousQueue, ^{
        dispatch_semaphore_wait(self->_synchronousSemaphore, DISPATCH_TIME_FOREVER);
        BOOL filterResult = filter != nil ? filter() : YES;
        if (!filterResult) {
            dispatch_semaphore_signal(self->_synchronousSemaphore);
            return;
        }
        
        [request startWithCompletion:^(__kindof __FWBaseRequest * _Nonnull request) {
            if (completion) completion(request);
            dispatch_semaphore_signal(self->_synchronousSemaphore);
        }];
    });
}

- (void)synchronousBatchRequest:(__FWBatchRequest *)batchRequest filter:(BOOL (^)(void))filter completion:(void (^)(__FWBatchRequest * _Nonnull))completion {
    dispatch_async(_synchronousQueue, ^{
        dispatch_semaphore_wait(self->_synchronousSemaphore, DISPATCH_TIME_FOREVER);
        BOOL filterResult = filter != nil ? filter() : YES;
        if (!filterResult) {
            dispatch_semaphore_signal(self->_synchronousSemaphore);
            return;
        }
        
        [batchRequest startWithCompletion:^(__FWBatchRequest * _Nonnull batchRequest) {
            if (completion) completion(batchRequest);
            dispatch_semaphore_signal(self->_synchronousSemaphore);
        }];
    });
}

- (void)synchronousChainRequest:(__FWChainRequest *)chainRequest filter:(BOOL (^)(void))filter completion:(nullable void (^)(__FWChainRequest * _Nonnull))completion {
    dispatch_async(_synchronousQueue, ^{
        dispatch_semaphore_wait(self->_synchronousSemaphore, DISPATCH_TIME_FOREVER);
        BOOL filterResult = filter != nil ? filter() : YES;
        if (!filterResult) {
            dispatch_semaphore_signal(self->_synchronousSemaphore);
            return;
        }
        
        [chainRequest startWithCompletion:^(__FWChainRequest * _Nonnull chainRequest) {
            if (completion) completion(chainRequest);
            dispatch_semaphore_signal(self->_synchronousSemaphore);
        }];
    });
}

- (BOOL)validateResult:(__FWBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [request statusCodeValidator];
    if (!result) {
        if (error) {
            NSString *desc = [NSString stringWithFormat:@"Invalid status code (%ld)", (long)[request responseStatusCode]];
            *error = [NSError errorWithDomain:__FWRequestValidationErrorDomain code:__FWRequestValidationErrorInvalidStatusCode userInfo:@{NSLocalizedDescriptionKey:desc}];
        }
        return result;
    }
    id json = [request responseJSONObject];
    id validator = [request jsonValidator];
    if (json && validator) {
        result = [__FWNetworkUtils validateJSON:json withValidator:validator];
        if (!result) {
            if (error) {
                *error = [NSError errorWithDomain:__FWRequestValidationErrorDomain code:__FWRequestValidationErrorInvalidJSONFormat userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
            }
            return result;
        }
    }
    return YES;
}

- (void)handleRequestResult:(NSUInteger)requestIdentifier response:(NSURLResponse *)response responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    __FWBaseRequest *request = _requestsRecord[@(requestIdentifier)];
    Unlock();

    // When the request is cancelled and removed from records, the underlying
    // AFNetworking failure callback will still kicks in, resulting in a nil `request`.
    //
    // Here we choose to completely ignore cancelled tasks. Neither success or failure
    // callback will be called.
    if (!request) {
        return;
    }

    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError = nil;

    NSError *requestError = nil;
    BOOL succeed = NO;

    request.requestTotalCount = [_manager requestTotalCountForResponse:response];
    request.requestTotalTime = [_manager requestTotalTimeForResponse:response];
    request.responseObject = responseObject;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[__FWNetworkUtils stringEncodingWithRequest:request]];

        switch (request.responseSerializerType) {
            case __FWResponseSerializerTypeHTTP:
                // Default serializer. Do nothing.
                break;
            case __FWResponseSerializerTypeJSON:
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:response data:request.responseData error:&serializationError];
                request.responseJSONObject = request.responseObject;
                break;
            case __FWResponseSerializerTypeXMLParser:
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:response data:request.responseData error:&serializationError];
                break;
        }
    }
    if (error) {
        succeed = NO;
        requestError = error;
    } else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    } else {
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }
    
    // Mock Response if needed when failed in debug mode
#ifdef DEBUG
    if (!succeed && _config.debugMockEnabled && [request responseMockValidator]) {
        succeed = [request responseMockProcessor];
        // Clear requestError when succeed
        if (succeed) {
            requestError = nil;
        }
    }
#endif
    
    // Filter Response with request when succeed
    if (succeed) {
        NSError * __autoreleasing responseError = nil;
        succeed = [request filterResponse:&responseError];
        requestError = responseError;
    }
    
    // Filter Response with filters if needed when succeed
    if (succeed) {
        NSArray *filters = [_config urlFilters];
        if (filters.count > 0) {
            NSError * __autoreleasing responseError = nil;
            for (id<__FWUrlFilterProtocol> filter in filters) {
                if ([filter respondsToSelector:@selector(filterResponse:withError:)]) {
                    succeed = [filter filterResponse:request withError:&responseError];
                    requestError = responseError;
                    // Do not execute next filter when failed
                    if (!succeed) {
                        break;
                    }
                }
            }
        }
    }

    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:requestError];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
        [request clearCompletionBlock];
    });
}

- (void)requestDidSucceedWithRequest:(__FWBaseRequest *)request {
    #ifdef DEBUG
    if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
        FWLogDebug(@"\n===========REQUEST SUCCEED===========\n%@%@ %@:\n%@", @"✅ ", [request requestMethodString], [request requestUrl], [NSString stringWithFormat:@"%@", request.responseJSONObject ?: (request.responseString ?: @"")]);
    }
    #endif
    
    @autoreleasepool {
        [request requestCompletePreprocessor];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [request toggleAccessoriesWillStopCallBack];
        [request requestCompleteFilter];

        if (request.delegate != nil) {
            [request.delegate requestFinished:request];
        }
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
        [request toggleAccessoriesDidStopCallBack];
    });
}

- (void)requestDidFailWithRequest:(__FWBaseRequest *)request error:(NSError *)error {
    request.error = error;
    #ifdef DEBUG
    if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
        FWLogDebug(@"\n===========REQUEST FAILED===========\n%@%@ %@:\n%@", @"❌ ", [request requestMethodString], [request requestUrl], [NSString stringWithFormat:@"%@", request.responseJSONObject ?: (request.error ?: @"")]);
    }
    #endif

    // Save incomplete download data.
    NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    NSURL *localUrl = nil;
    if (request.resumableDownloadPath) {
        localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
    }
    if (incompleteDownloadData && localUrl != nil) {
        [incompleteDownloadData writeToURL:localUrl atomically:YES];
    }

    // Load response from file and clean up if download task failed.
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:[__FWNetworkUtils stringEncodingWithRequest:request]];

            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }

    @autoreleasepool {
        [request requestFailedPreprocessor];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [request toggleAccessoriesWillStopCallBack];
        [request requestFailedFilter];

        if (request.delegate != nil) {
            [request.delegate requestFailed:request];
        }
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
        [request toggleAccessoriesDidStopCallBack];
    });
}

- (void)addRequestToRecord:(__FWBaseRequest *)request {
    Lock();
    _requestsRecord[@(request.requestIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(__FWBaseRequest *)request {
    Lock();
    [_requestsRecord removeObjectForKey:@(request.requestIdentifier)];
    #ifdef DEBUG
    if ([_requestsRecord count] > 0) {
        if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
            FWLogDebug(@"Request queue size = %zd", [_requestsRecord count]);
        }
    }
    #endif
    Unlock();
}

#pragma mark -

- (NSURLSessionDataTask *)dataTaskWithRequest:(__FWBaseRequest *)request
                                        error:(NSError * _Nullable __autoreleasing *)error {
    NSURLSessionDataTask *dataTask = [_manager dataTaskWithRequestBuilder:^NSURLRequest *{
        
        NSURLRequest *customUrlRequest = [request buildCustomUrlRequest];
        if (customUrlRequest) return customUrlRequest;
        
        __FWHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
        NSString *urlString = [self buildRequestUrl:request];

        NSMutableURLRequest *urlRequest = nil;
        if (request.constructingBodyBlock) {
            urlRequest = [requestSerializer multipartFormRequestWithMethod:request.requestMethodString URLString:urlString parameters:request.requestArgument constructingBodyWithBlock:request.constructingBodyBlock error:error];
        } else {
            urlRequest = [requestSerializer requestWithMethod:request.requestMethodString URLString:urlString parameters:request.requestArgument error:error];
        }
        
        // Filter URLRequest with request
        [request filterUrlRequest:urlRequest];
        
        // Filter URLRequest with filters if needed
        NSArray *filters = [[self config] urlFilters];
        for (id<__FWUrlFilterProtocol> filter in filters) {
            if ([filter respondsToSelector:@selector(filterUrlRequest:withRequest:)]) {
                [filter filterUrlRequest:urlRequest withRequest:request];
            }
        }
        
        return urlRequest;
    } retryCount:[request requestRetryCount] retryInterval:^NSTimeInterval(NSInteger requestCount) {
        
        return [request requestRetryInterval];
    } timeoutInterval:[request requestRetryTimeout] shouldRetry:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable _error, void (^ _Nonnull decisionHandler)(BOOL retry)) {
        
        request.requestTotalCount = [[self manager] requestTotalCountForResponse:response];
        request.requestTotalTime = [[self manager] requestTotalTimeForResponse:response];
        
        BOOL shouldRetry = [request requestRetryValidator:(NSHTTPURLResponse *)response responseObject:responseObject error:_error];
        if (!shouldRetry) {
            decisionHandler(NO);
            return;
        }
        
        [request requestRetryProcessor:(NSHTTPURLResponse *)response responseObject:responseObject error:_error completionHandler:^(BOOL success) {
            
            decisionHandler(success);
        }];
    } isCancelled:^BOOL(void){
        
        return request.isCancelled;
    } taskHandler:^(NSURLSessionDataTask *retryTask) {
        
        request.requestTask = retryTask;
    } uploadProgress:[request uploadProgressBlock] downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable _error) {
        
        [self handleRequestResult:request.requestIdentifier response:response responseObject:responseObject error:_error];
    }];

    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(__FWBaseRequest *)request
                                             progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                error:(NSError * _Nullable __autoreleasing *)error {
    // add parameters to URL;
    __FWHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:request.requestMethodString URLString:[self buildRequestUrl:request] parameters:request.requestArgument error:error];
    
    // Filter URLRequest with request
    [request filterUrlRequest:urlRequest];
    
    // Filter URLRequest with filters if needed
    NSArray *filters = [_config urlFilters];
    for (id<__FWUrlFilterProtocol> filter in filters) {
        if ([filter respondsToSelector:@selector(filterUrlRequest:withRequest:)]) {
            [filter filterUrlRequest:urlRequest withRequest:request];
        }
    }

    NSString *downloadPath = request.resumableDownloadPath;
    NSString *downloadTargetPath;
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    // If targetPath is a directory, use the file name we got from the urlRequest.
    // Make sure downloadTargetPath is always a file, not directory.
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }

    // AFN use `moveItemAtURL` to move downloaded file to target path,
    // this method aborts the move attempt if a file already exist at the path.
    // So we remove the exist file before we start the download task.
    // https://github.com/AFNetworking/AFNetworking/issues/3775
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }

    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:downloadPath];
    if (localUrl != nil) {
        BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:localUrl.path];
        NSData *data = [NSData dataWithContentsOfURL:localUrl];
        BOOL resumeDataIsValid = [__FWNetworkUtils validateResumeData:data];

        BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
        // Try to resume with resumeData.
        // Even though we try to validate the resumeData, this may still fail and raise excecption.
        if (canBeResumed) {
            @try {
                downloadTask = [_manager downloadTaskWithResumeData:data progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                    return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                    [self handleRequestResult:request.requestIdentifier response:response responseObject:filePath error:error];
                }];
                resumeSucceeded = YES;
            } @catch (NSException *exception) {
                if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
                    FWLogDebug(@"Resume download failed, reason = %@", exception.reason);
                }
                resumeSucceeded = NO;
            }
        }
    }
    if (!resumeSucceeded) {
        downloadTask = [_manager downloadTaskWithRequest:urlRequest progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [self handleRequestResult:request.requestIdentifier response:response responseObject:filePath error:error];
        }];
    }
    return downloadTask;
}

#pragma mark - Resumable Download

- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    NSString *cacheFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:kFWNetworkIncompleteDownloadFolderName];

    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:cacheFolder isDirectory:&isDirectory] && isDirectory) {
        return cacheFolder;
    }
    NSError *error = nil;
    if ([fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error] && error == nil) {
        return cacheFolder;
    }
    if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
        FWLogDebug(@"Failed to create cache directory at %@ with error: %@", cacheFolder, error != nil ? error.localizedDescription : @"unkown");
    }
    return nil;
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    if (downloadPath == nil || downloadPath.length == 0) {
        return nil;
    }
    NSString *tempPath = nil;
    NSString *md5URLString = [__FWNetworkUtils md5StringFromString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return tempPath == nil ? nil : [NSURL fileURLWithPath:tempPath];
}

#pragma mark - Testing

- (__FWRequestConfig *)config {
    return _config;
}

- (__FWHTTPSessionManager *)manager {
    return _manager;
}

- (void)resetURLSessionManager {
    _manager = [__FWHTTPSessionManager manager];
}

- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration {
    _manager = [[__FWHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
}

@end
