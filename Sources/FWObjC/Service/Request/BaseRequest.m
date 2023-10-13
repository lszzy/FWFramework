//
//  BaseRequest.m
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

#import "BaseRequest.h"
#import "RequestManager.h"
#import "ObjC.h"
#import <objc/runtime.h>
#import <FWFramework/FWFramework-Swift.h>

#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_With_QoS_Available 1140.11
#else
#define NSFoundationVersionNumber_With_QoS_Available NSFoundationVersionNumber_iOS_8_0
#endif

NSString *const __FWRequestValidationErrorDomain = @"site.wuyong.error.request.validation";

NSString *const __FWRequestCacheErrorDomain = @"site.wuyong.error.request.cache";

static dispatch_queue_t __fw_request_cache_writing_queue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_With_QoS_Available) {
            attr = dispatch_queue_attr_make_with_qos_class(attr, QOS_CLASS_BACKGROUND, 0);
        }
        queue = dispatch_queue_create("site.wuyong.queue.request.cache", attr);
    });

    return queue;
}

@interface __FWCacheMetadata : NSObject<NSSecureCoding>

@property (nonatomic, assign) long long version;
@property (nonatomic, strong) NSString *sensitiveDataString;
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSString *appVersionString;

@end

@implementation __FWCacheMetadata

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.version) forKey:NSStringFromSelector(@selector(version))];
    [aCoder encodeObject:self.sensitiveDataString forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    [aCoder encodeObject:@(self.stringEncoding) forKey:NSStringFromSelector(@selector(stringEncoding))];
    [aCoder encodeObject:self.creationDate forKey:NSStringFromSelector(@selector(creationDate))];
    [aCoder encodeObject:self.appVersionString forKey:NSStringFromSelector(@selector(appVersionString))];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }

    self.version = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(version))] integerValue];
    self.sensitiveDataString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    self.stringEncoding = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(stringEncoding))] integerValue];
    self.creationDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(creationDate))];
    self.appVersionString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(appVersionString))];

    return self;
}

@end

@implementation __FWRequestAccessory

- (void)requestWillStart:(id)request {
    if (self.willStartBlock != nil) {
        self.willStartBlock(request);
        self.willStartBlock = nil;
    }
}

- (void)requestWillStop:(id)request {
    if (self.willStopBlock != nil) {
        self.willStopBlock(request);
        self.willStopBlock = nil;
    }
}

- (void)requestDidStop:(id)request {
    if (self.didStopBlock != nil) {
        self.didStopBlock(request);
        self.didStopBlock = nil;
    }
}

@end

@interface __FWBaseRequest ()

@property (nonatomic, strong) NSData *cacheData;
@property (nonatomic, strong) NSString *cacheString;
@property (nonatomic, strong) id cacheJSON;
@property (nonatomic, strong) NSXMLParser *cacheXML;

@property (nonatomic, strong) __FWCacheMetadata *cacheMetadata;
@property (nonatomic, assign) BOOL dataFromCache;

@property (nonatomic, assign) BOOL cancelled;

@end

@implementation __FWBaseRequest

#pragma mark - Request and Response Information

- (void)setError:(NSError *)error {
    _error = error;
    if (error != nil) [__FWNetworkUtils markRequestError:error];
}

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSInteger)responseStatusCode {
    return self.response.statusCode;
}

- (NSTimeInterval)responseServerTime {
    NSString *serverDate = self.response.allHeaderFields[@"Date"];
    return [NSDate __fw_formatServerDate:serverDate ?: @""];
}

- (NSDictionary *)responseHeaders {
    return self.response.allHeaderFields;
}

- (NSURLRequest *)currentRequest {
    return self.requestTask.currentRequest;
}

- (NSURLRequest *)originalRequest {
    return self.requestTask.originalRequest;
}

- (BOOL)isFinished {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCompleted && self.error == nil;
}

- (BOOL)isFailed {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCompleted && self.error != nil;
}

- (BOOL)isCancelled {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling || _cancelled;
}

- (BOOL)isExecuting {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}

- (NSString *)requestMethodString {
    switch ([self requestMethod]) {
        case __FWRequestMethodPOST:
            return @"POST";
        case __FWRequestMethodHEAD:
            return @"HEAD";
        case __FWRequestMethodPUT:
            return @"PUT";
        case __FWRequestMethodDELETE:
            return @"DELETE";
        case __FWRequestMethodPATCH:
            return @"PATCH";
        case __FWRequestMethodGET:
        default:
            return @"GET";
    }
}

#pragma mark - Request Configuration

- (void)setCompletionBlockWithSuccess:(__FWRequestCompletionBlock)success
                              failure:(__FWRequestCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
    self.uploadProgressBlock = nil;
}

- (void)addAccessory:(id<__FWRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

#pragma mark - Request Action

- (void)start {
    if (!self.useCacheResponse) {
        [self startWithoutCache];
        return;
    }

    // Do not cache download request.
    if (self.resumableDownloadPath) {
        [self startWithoutCache];
        return;
    }

    if (![self loadCacheWithError:nil]) {
        [self startWithoutCache];
        return;
    }

    _dataFromCache = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestCompletePreprocessor];
        [self requestCompleteFilter];
        __FWBaseRequest *strongSelf = self;
        [strongSelf.delegate requestFinished:strongSelf];
        if (strongSelf.successCompletionBlock) {
            strongSelf.successCompletionBlock(strongSelf);
        }
        [strongSelf clearCompletionBlock];
    });
}

- (void)startWithoutCache {
    [self clearCacheVariables];
    [self toggleAccessoriesWillStartCallBack];
    [[__FWRequestManager sharedManager] addRequest:self];
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    self.delegate = nil;
    [[__FWRequestManager sharedManager] cancelRequest:self];
    self.cancelled = YES;
    [self toggleAccessoriesDidStopCallBack];
}

- (void)startWithSuccess:(__FWRequestCompletionBlock)success
                                    failure:(__FWRequestCompletionBlock)failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)startWithCompletion:(__FWRequestCompletionBlock)completion {
    [self startWithSuccess:completion failure:completion];
}

- (void)startWithWillStart:(nullable __FWRequestCompletionBlock)willStart
                  willStop:(nullable __FWRequestCompletionBlock)willStop
                   success:(nullable __FWRequestCompletionBlock)success
                   failure:(nullable __FWRequestCompletionBlock)failure
                   didStop:(nullable __FWRequestCompletionBlock)didStop {
    __FWRequestAccessory *accessory = [__FWRequestAccessory new];
    accessory.willStartBlock = willStart;
    accessory.willStopBlock = willStop;
    accessory.didStopBlock = didStop;
    [self addAccessory:accessory];
    [self startWithSuccess:success failure:failure];
}

- (void)startSynchronouslyWithSuccess:(__FWRequestCompletionBlock)success failure:(__FWRequestCompletionBlock)failure {
    [self startSynchronouslyWithFilter:nil completion:^(__kindof __FWBaseRequest *request) {
        if (request.error == nil) {
            if (success) success(request);
        } else {
            if (failure) failure(request);
        }
    }];
}

- (void)startSynchronouslyWithFilter:(BOOL (^)(void))filter completion:(__FWRequestCompletionBlock)completion {
    [[__FWRequestManager sharedManager] synchronousRequest:self filter:filter completion:completion];
}

- (void)toggleAccessoriesWillStartCallBack {
    for (id<__FWRequestAccessory> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(requestWillStart:)]) {
            [accessory requestWillStart:self];
        }
    }
}

- (void)toggleAccessoriesWillStopCallBack {
    for (id<__FWRequestAccessory> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(requestWillStop:)]) {
            [accessory requestWillStop:self];
        }
    }
}

- (void)toggleAccessoriesDidStopCallBack {
    for (id<__FWRequestAccessory> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(requestDidStop:)]) {
            [accessory requestDidStop:self];
        }
    }
}

#pragma mark - Subclass Override

- (BOOL)responseMockValidator {
    if (__FWRequestConfig.sharedConfig.debugMockValidator) {
        return __FWRequestConfig.sharedConfig.debugMockValidator(self);
    }
    return [self responseStatusCode] == 404;
}

- (BOOL)responseMockProcessor {
    if (__FWRequestConfig.sharedConfig.debugMockProcessor) {
        return __FWRequestConfig.sharedConfig.debugMockProcessor(self);
    }
    return NO;
}

- (void)filterUrlRequest:(NSMutableURLRequest *)urlRequest {
}

- (BOOL)filterResponse:(NSError *__autoreleasing  _Nullable *)error {
    return YES;
}

- (void)requestCompletePreprocessor {
    NSData *responseData = _responseData;
    if (self.writeCacheAsynchronously) {
        __weak __typeof__(self) self_weak_ = self;
        dispatch_async(__fw_request_cache_writing_queue(), ^{
            __typeof__(self) self = self_weak_;
            [self saveResponseDataToCacheFile:responseData];
        });
    } else {
        [self saveResponseDataToCacheFile:responseData];
    }
}

- (void)requestCompleteFilter {
}

- (void)requestFailedPreprocessor {
}

- (void)requestFailedFilter {
}

- (NSString *)requestUrl {
    return @"";
}

- (NSString *)cdnUrl {
    return @"";
}

- (NSString *)baseUrl {
    return @"";
}

- (NSTimeInterval)requestTimeoutInterval {
    return 60;
}

- (NSURLRequestCachePolicy)requestCachePolicy {
    return -1;
}

- (id)requestArgument {
    return nil;
}

- (id)cacheFileNameFilter:(id)argument {
    return argument;
}

- (__FWRequestMethod)requestMethod {
    return __FWRequestMethodGET;
}

- (__FWRequestSerializerType)requestSerializerType {
    return __FWRequestSerializerTypeHTTP;
}

- (__FWResponseSerializerType)responseSerializerType {
    return __FWResponseSerializerTypeJSON;
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
    return nil;
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    return nil;
}

- (NSURLRequest *)buildCustomUrlRequest {
    return nil;
}

- (BOOL)useCDN {
    return NO;
}

- (BOOL)allowsCellularAccess {
    return YES;
}

- (id)jsonValidator {
    return nil;
}

- (BOOL)statusCodeValidator {
    NSInteger statusCode = [self responseStatusCode];
    return (statusCode >= 200 && statusCode <= 299);
}

- (NSInteger)requestRetryCount {
    return 0;
}

- (NSTimeInterval)requestRetryInterval {
    return 0;
}

- (NSTimeInterval)requestRetryTimeout {
    return 0;
}

- (BOOL)requestRetryValidator:(NSHTTPURLResponse *)response
               responseObject:(id)responseObject
                        error:(NSError *)error {
    NSInteger statusCode = response.statusCode;
    return error != nil || statusCode < 200 || statusCode > 299;
}

- (void)requestRetryProcessor:(NSHTTPURLResponse *)response
               responseObject:(id)responseObject
                        error:(NSError *)error
            completionHandler:(void (^)(BOOL))completionHandler {
    completionHandler(YES);
}

#pragma mark - Subclass Override

- (NSInteger)cacheTimeInSeconds {
    return -1;
}

- (long long)cacheVersion {
    return 0;
}

- (id)cacheSensitiveData {
    return nil;
}

- (BOOL)writeCacheAsynchronously {
    return YES;
}

#pragma mark -

- (BOOL)isDataFromCache {
    return _dataFromCache;
}

- (NSData *)responseData {
    if (_cacheData) {
        return _cacheData;
    }
    return _responseData;
}

- (NSString *)responseString {
    if (_cacheString) {
        return _cacheString;
    }
    return _responseString;
}

- (id)responseJSONObject {
    if (_cacheJSON) {
        return _cacheJSON;
    }
    return _responseJSONObject;
}

- (id)responseObject {
    if (_cacheJSON) {
        return _cacheJSON;
    }
    if (_cacheXML) {
        return _cacheXML;
    }
    if (_cacheData) {
        return _cacheData;
    }
    return _responseObject;
}

#pragma mark -

- (BOOL)loadCacheWithError:(NSError * _Nullable __autoreleasing *)error {
    // Make sure cache time in valid.
    if ([self cacheTimeInSeconds] < 0) {
        if (error) {
            *error = [NSError errorWithDomain:__FWRequestCacheErrorDomain code:__FWRequestCacheErrorInvalidCacheTime userInfo:@{ NSLocalizedDescriptionKey:@"Invalid cache time"}];
        }
        return NO;
    }

    // Try load metadata.
    if (![self loadCacheMetadata]) {
        if (error) {
            *error = [NSError errorWithDomain:__FWRequestCacheErrorDomain code:__FWRequestCacheErrorInvalidMetadata userInfo:@{ NSLocalizedDescriptionKey:@"Invalid metadata. Cache may not exist"}];
        }
        return NO;
    }

    // Check if cache is still valid.
    if (![self validateCacheWithError:error]) {
        return NO;
    }

    // Try load cache.
    if (![self loadCacheData]) {
        if (error) {
            *error = [NSError errorWithDomain:__FWRequestCacheErrorDomain code:__FWRequestCacheErrorInvalidCacheData userInfo:@{ NSLocalizedDescriptionKey:@"Invalid cache data"}];
        }
        return NO;
    }

    #ifdef DEBUG
    if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
        FWLogDebug(@"\n===========REQUEST CACHED===========\n%@%@ %@:\n%@", @"💾 ", [self requestMethodString], [self requestUrl], [NSString stringWithFormat:@"%@", self.responseJSONObject ?: (self.responseString ?: @"")]);
    }
    #endif
    return YES;
}

- (BOOL)validateCacheWithError:(NSError * _Nullable __autoreleasing *)error {
    // Date
    NSDate *creationDate = self.cacheMetadata.creationDate;
    NSTimeInterval duration = -[creationDate timeIntervalSinceNow];
    if (duration < 0 || duration > [self cacheTimeInSeconds]) {
        if (error) {
            *error = [NSError errorWithDomain:__FWRequestCacheErrorDomain code:__FWRequestCacheErrorExpired userInfo:@{ NSLocalizedDescriptionKey:@"Cache expired"}];
        }
        return NO;
    }
    // Version
    long long cacheVersionFileContent = self.cacheMetadata.version;
    if (cacheVersionFileContent != [self cacheVersion]) {
        if (error) {
            *error = [NSError errorWithDomain:__FWRequestCacheErrorDomain code:__FWRequestCacheErrorVersionMismatch userInfo:@{ NSLocalizedDescriptionKey:@"Cache version mismatch"}];
        }
        return NO;
    }
    // Sensitive data
    NSString *sensitiveDataString = self.cacheMetadata.sensitiveDataString;
    NSString *currentSensitiveDataString = ((NSObject *)[self cacheSensitiveData]).description;
    if (sensitiveDataString || currentSensitiveDataString) {
        // If one of the strings is nil, short-circuit evaluation will trigger
        if (sensitiveDataString.length != currentSensitiveDataString.length || ![sensitiveDataString isEqualToString:currentSensitiveDataString]) {
            if (error) {
                *error = [NSError errorWithDomain:__FWRequestCacheErrorDomain code:__FWRequestCacheErrorSensitiveDataMismatch userInfo:@{ NSLocalizedDescriptionKey:@"Cache sensitive data mismatch"}];
            }
            return NO;
        }
    }
    // App version
    NSString *appVersionString = self.cacheMetadata.appVersionString;
    NSString *currentAppVersionString = [__FWNetworkUtils appVersionString];
    if (appVersionString || currentAppVersionString) {
        if (appVersionString.length != currentAppVersionString.length || ![appVersionString isEqualToString:currentAppVersionString]) {
            if (error) {
                *error = [NSError errorWithDomain:__FWRequestCacheErrorDomain code:__FWRequestCacheErrorAppVersionMismatch userInfo:@{ NSLocalizedDescriptionKey:@"App version mismatch"}];
            }
            return NO;
        }
    }
    return YES;
}

- (BOOL)loadCacheMetadata {
    NSString *path = [self cacheMetadataFilePath];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        @try {
            _cacheMetadata = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            return YES;
        } @catch (NSException *exception) {
            if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
                FWLogDebug(@"Load cache metadata failed, reason = %@", exception.reason);
            }
            return NO;
        }
    }
    return NO;
}

- (BOOL)loadCacheData {
    NSString *path = [self cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        _cacheData = data;
        _cacheString = [[NSString alloc] initWithData:_cacheData encoding:self.cacheMetadata.stringEncoding];
        switch (self.responseSerializerType) {
            case __FWResponseSerializerTypeHTTP:
                // Do nothing.
                return YES;
            case __FWResponseSerializerTypeJSON:
                _cacheJSON = [NSJSONSerialization JSONObjectWithData:_cacheData options:(NSJSONReadingOptions)0 error:&error];
                
                // 兼容\uD800-\uDFFF引起JSON解码报错3840问题
                if (error && error.code == 3840) {
                    NSString *escapeString = [[NSString alloc] initWithData:_cacheData encoding:NSUTF8StringEncoding];
                    NSData *escapeData = [[self escapeJsonString:escapeString] dataUsingEncoding:NSUTF8StringEncoding];
                    if (escapeData && escapeData.length != _cacheData.length) {
                        error = nil;
                        _cacheJSON = [NSJSONSerialization JSONObjectWithData:escapeData options:(NSJSONReadingOptions)0 error:&error];
                    }
                }
                
                return error == nil;
            case __FWResponseSerializerTypeXMLParser:
                _cacheXML = [[NSXMLParser alloc] initWithData:_cacheData];
                return YES;
        }
    }
    return NO;
}

- (void)saveResponseDataToCacheFile:(NSData *)data {
    if ([self cacheTimeInSeconds] > 0 && ![self isDataFromCache]) {
        if (data != nil) {
            @try {
                // New data will always overwrite old data.
                [data writeToFile:[self cacheFilePath] atomically:YES];

                __FWCacheMetadata *metadata = [[__FWCacheMetadata alloc] init];
                metadata.version = [self cacheVersion];
                metadata.sensitiveDataString = ((NSObject *)[self cacheSensitiveData]).description;
                metadata.stringEncoding = [__FWNetworkUtils stringEncodingWithRequest:self];
                metadata.creationDate = [NSDate date];
                metadata.appVersionString = [__FWNetworkUtils appVersionString];
                [NSKeyedArchiver archiveRootObject:metadata toFile:[self cacheMetadataFilePath]];
            } @catch (NSException *exception) {
                if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
                    FWLogDebug(@"Save cache failed, reason = %@", exception.reason);
                }
            }
        }
    }
}

- (void)clearCacheVariables {
    _cacheData = nil;
    _cacheXML = nil;
    _cacheJSON = nil;
    _cacheString = nil;
    _cacheMetadata = nil;
    _dataFromCache = NO;
}

#pragma mark -

- (void)createDirectoryIfNeeded:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        [self createBaseDirectoryAtPath:path];
    } else {
        if (!isDir) {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            [self createBaseDirectoryAtPath:path];
        }
    }
}

- (void)createBaseDirectoryAtPath:(NSString *)path {
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
                                               attributes:nil error:&error];
    if (error) {
        if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
            FWLogDebug(@"create cache directory failed, error = %@", error);
        }
    } else {
        [__FWNetworkUtils addDoNotBackupAttribute:path];
    }
}

- (NSString *)cacheBasePath {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"LazyRequestCache"];

    // Filter cache base path
    NSArray<id<__FWCacheDirPathFilterProtocol>> *filters = [[__FWRequestConfig sharedConfig] cacheDirPathFilters];
    if (filters.count > 0) {
        for (id<__FWCacheDirPathFilterProtocol> filter in filters) {
            if ([filter respondsToSelector:@selector(filterCacheDirPath:withRequest:)]) {
                path = [filter filterCacheDirPath:path withRequest:self];
            }
        }
    }

    [self createDirectoryIfNeeded:path];
    return path;
}

- (NSString *)cacheFileName {
    NSString *requestUrl = [self requestUrl];
    NSString *baseUrl = [__FWRequestConfig sharedConfig].baseUrl;
    id argument = [self cacheFileNameFilter:[self requestArgument]];
    NSString *requestInfo = [NSString stringWithFormat:@"Method:%ld Host:%@ Url:%@ Argument:%@",
                             (long)[self requestMethod], baseUrl, requestUrl, argument];
    NSString *cacheFileName = [__FWNetworkUtils md5StringFromString:requestInfo];
    return cacheFileName;
}

- (NSString *)cacheFilePath {
    NSString *cacheFileName = [self cacheFileName];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheFileName];
    return path;
}

- (NSString *)cacheMetadataFilePath {
    NSString *cacheMetadataFileName = [NSString stringWithFormat:@"%@.metadata", [self cacheFileName]];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheMetadataFileName];
    return path;
}

- (NSString *)escapeJsonString:(NSString *)string {
    if (string.length < 1) return string;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"(\\\\UD[8-F][0-F][0-F])(\\\\UD[8-F][0-F][0-F])?" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    int count = (int)matches.count;
    if (count < 1) return string;
    
    // 倒序循环，避免replace越界
    for (int i = count - 1; i >= 0; i--) {
        NSRange range = [matches objectAtIndex:i].range;
        NSString *substr = [[string substringWithRange:range] uppercaseString];
        if (range.length == 12 && [substr characterAtIndex:3] <= 'B' && [substr characterAtIndex:9] > 'B') continue;
        string = [string stringByReplacingCharactersInRange:range withString:@""];
    }
    return string;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.currentRequest.URL, self.currentRequest.HTTPMethod, self.requestArgument];
}

@end
