//
//  BaseRequest.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const __FWRequestValidationErrorDomain NS_SWIFT_NAME(RequestValidationErrorDomain);

FOUNDATION_EXPORT NSString *const __FWRequestCacheErrorDomain NS_SWIFT_NAME(RequestCacheErrorDomain);

typedef NS_ENUM(NSInteger, __FWRequestValidationErrorCode) {
    __FWRequestValidationErrorInvalidStatusCode = -8,
    __FWRequestValidationErrorInvalidJSONFormat = -9,
} NS_SWIFT_NAME(RequestValidationErrorCode);

typedef NS_ENUM(NSInteger, __FWRequestCacheErrorCode) {
    __FWRequestCacheErrorExpired = -1,
    __FWRequestCacheErrorVersionMismatch = -2,
    __FWRequestCacheErrorSensitiveDataMismatch = -3,
    __FWRequestCacheErrorAppVersionMismatch = -4,
    __FWRequestCacheErrorInvalidCacheTime = -5,
    __FWRequestCacheErrorInvalidMetadata = -6,
    __FWRequestCacheErrorInvalidCacheData = -7,
} NS_SWIFT_NAME(RequestCacheErrorCode);

///  HTTP Request method.
typedef NS_ENUM(NSInteger, __FWRequestMethod) {
    __FWRequestMethodGET = 0,
    __FWRequestMethodPOST,
    __FWRequestMethodHEAD,
    __FWRequestMethodPUT,
    __FWRequestMethodDELETE,
    __FWRequestMethodPATCH,
} NS_SWIFT_NAME(RequestMethod);

///  Request serializer type.
typedef NS_ENUM(NSInteger, __FWRequestSerializerType) {
    __FWRequestSerializerTypeHTTP = 0,
    __FWRequestSerializerTypeJSON,
} NS_SWIFT_NAME(RequestSerializerType);

///  Response serializer type, which determines response serialization process and
///  the type of `responseObject`.
typedef NS_ENUM(NSInteger, __FWResponseSerializerType) {
    /// NSData type
    __FWResponseSerializerTypeHTTP,
    /// JSON object type
    __FWResponseSerializerTypeJSON,
    /// NSXMLParser type
    __FWResponseSerializerTypeXMLParser,
} NS_SWIFT_NAME(ResponseSerializerType);

///  Request priority
typedef NS_ENUM(NSInteger, __FWRequestPriority) {
    __FWRequestPriorityLow = -4L,
    __FWRequestPriorityDefault = 0,
    __FWRequestPriorityHigh = 4,
} NS_SWIFT_NAME(RequestPriority);

@protocol __FWMultipartFormData;

typedef void (^__FWConstructingBlock)(id<__FWMultipartFormData> formData) NS_SWIFT_NAME(ConstructingBlock);
typedef void (^__FWURLSessionTaskProgressBlock)(NSProgress *) NS_SWIFT_NAME(URLSessionTaskProgressBlock);

@class __FWBaseRequest;

typedef void(^__FWRequestCompletionBlock)(__kindof __FWBaseRequest *request) NS_SWIFT_NAME(RequestCompletionBlock);

///  The __FWRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue.
NS_SWIFT_NAME(RequestDelegate)
@protocol __FWRequestDelegate <NSObject>

@optional
///  Tell the delegate that the request has finished successfully.
///
///  @param request The corresponding request.
- (void)requestFinished:(__kindof __FWBaseRequest *)request;

///  Tell the delegate that the request has failed.
///
///  @param request The corresponding request.
- (void)requestFailed:(__kindof __FWBaseRequest *)request;

@end

///  The __FWRequestAccessory protocol defines several optional methods that can be
///  used to track the status of a request. Objects that conforms this protocol
///  ("accessories") can perform additional configurations accordingly. All the
///  accessory methods will be called on the main queue.
NS_SWIFT_NAME(RequestAccessory)
@protocol __FWRequestAccessory <NSObject>

@optional

///  Inform the accessory that the request is about to start.
///
///  @param request The corresponding request.
- (void)requestWillStart:(id)request;

///  Inform the accessory that the request is about to stop. This method is called
///  before executing `requestFinished` and `successCompletionBlock`.
///
///  @param request The corresponding request.
- (void)requestWillStop:(id)request;

///  Inform the accessory that the request has already stoped. This method is called
///  after executing `requestFinished` and `successCompletionBlock`.
///
///  @param request The corresponding request.
- (void)requestDidStop:(id)request;

@end

NS_SWIFT_NAME(RequestAccessory)
@interface __FWRequestAccessory : NSObject <__FWRequestAccessory>

@property (nonatomic, copy, nullable) void (^willStartBlock)(id);
@property (nonatomic, copy, nullable) void (^willStopBlock)(id);
@property (nonatomic, copy, nullable) void (^didStopBlock)(id);

@end

///  __FWBaseRequest is the base class you should inherit to create your own request class. It provides many options
///  for constructing request, including local caching feature. Note download
///  request will not be cached whatsoever, because download request may involve complicated
///  cache control policy controlled by `Cache-Control`, `Last-Modified`, etc.
///  https://github.com/yuantiku/YTKNetwork
NS_SWIFT_NAME(BaseRequest)
@interface __FWBaseRequest : NSObject

#pragma mark - Request and Response Information
///=============================================================================
/// @name Request and Response Information
///=============================================================================

///  The underlying NSURLSessionTask.
///
///  @warning This value is actually nil and should not be accessed before the request starts.
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;

///  The request identifier, always equals the first requestTask.taskIdentifier.
@property (nonatomic, assign, readwrite) NSUInteger requestIdentifier;

///  Shortcut for `requestTask.currentRequest`.
@property (nonatomic, strong, readonly) NSURLRequest *currentRequest;

///  Shortcut for `requestTask.originalRequest`.
@property (nonatomic, strong, readonly) NSURLRequest *originalRequest;

///  Shortcut for `requestTask.response`.
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;

///  The response status code.
@property (nonatomic, readonly) NSInteger responseStatusCode;

///  The response header fields.
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseHeaders;

///  The raw data representation of response. Note this value can be nil if request failed.
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;

///  The string representation of response. Note this value can be nil if request failed.
@property (nonatomic, strong, readwrite, nullable) NSString *responseString;

///  This serialized response object. The actual type of this object is determined by
///  `__FWResponseSerializerType`. Note this value can be nil if request failed.
///
///  @note If `resumableDownloadPath` and DownloadTask is using, this value will
///              be the path to which file is successfully saved (NSURL), or nil if request failed.
@property (nonatomic, strong, readwrite, nullable) id responseObject;

///  If you use `__FWResponseSerializerTypeJSON`, this is a convenience (and sematic) getter
///  for the response object. Otherwise this value is nil.
@property (nonatomic, strong, readwrite, nullable) id responseJSONObject;

///  This error can be either serialization error or network error. If nothing wrong happens
///  this value will be nil.
@property (nonatomic, strong, readwrite, nullable) NSError *error;

///  Return finished state of request task.
@property (nonatomic, readonly, getter=isFinished) BOOL finished;

///  Return failed state of request task.
@property (nonatomic, readonly, getter=isFailed) BOOL failed;

///  Return cancelled state of request task.
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;

///  Executing state of request task.
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;

///  Total request count for request.
@property (nonatomic, readwrite) NSInteger requestTotalCount;

///  Total request time for request.
@property (nonatomic, readwrite) NSTimeInterval requestTotalTime;

///  The request method string for request.
@property (nonatomic, copy, readonly) NSString *requestMethodString;


#pragma mark - Request Configuration
///=============================================================================
/// @name Request Configuration
///=============================================================================

///  Tag can be used to identify request. Default value is 0.
@property (nonatomic) NSInteger tag;

///  The userInfo can be used to store additional info about the request. Default is nil.
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

///  The delegate object of the request. If you choose block style callback you can ignore this.
///  Default is nil.
@property (nonatomic, weak, nullable) id<__FWRequestDelegate> delegate;

///  The success callback. Note if this value is not nil and `requestFinished` delegate method is
///  also implemented, both will be executed but delegate method is first called. This block
///  will be called on the main queue.
@property (nonatomic, copy, nullable) __FWRequestCompletionBlock successCompletionBlock;

///  The failure callback. Note if this value is not nil and `requestFailed` delegate method is
///  also implemented, both will be executed but delegate method is first called. This block
///  will be called on the main queue.
@property (nonatomic, copy, nullable) __FWRequestCompletionBlock failureCompletionBlock;

///  This can be used to add several accessories object. Note if you use `addAccessory` to add accessory
///  this array will be automatically created. Default is nil.
@property (nonatomic, strong, nullable) NSMutableArray<id<__FWRequestAccessory>> *requestAccessories;

///  This can be use to construct HTTP body when needed in POST request. Default is nil.
@property (nonatomic, copy, nullable) __FWConstructingBlock constructingBodyBlock;

///  This value is used to perform resumable download request. Default is nil.
///
///  @note NSURLSessionDownloadTask is used when this value is not nil.
///              The exist file at the path will be removed before the request starts. If request succeed, file will
///              be saved to this path automatically, otherwise the response will be saved to `responseData`
///              and `responseString`. For this to work, server must support `Range` and response with
///              proper `Last-Modified` and/or `Etag`. See `NSURLSessionDownloadTask` for more detail.
@property (nonatomic, strong, nullable) NSString *resumableDownloadPath;

///  You can use this block to track the download progress. See also `resumableDownloadPath`.
@property (nonatomic, copy, nullable) __FWURLSessionTaskProgressBlock resumableDownloadProgressBlock;

///  You can use this block to track the upload progress.
@property (nonatomic, copy, nullable) __FWURLSessionTaskProgressBlock uploadProgressBlock;

///  The priority of the request. Default is `__FWRequestPriorityDefault`.
@property (nonatomic) __FWRequestPriority requestPriority;

///  Set completion callbacks
- (void)setCompletionBlockWithSuccess:(nullable __FWRequestCompletionBlock)success
                              failure:(nullable __FWRequestCompletionBlock)failure;

///  Nil out both success and failure callback blocks.
- (void)clearCompletionBlock;

///  Convenience method to add request accessory. See also `requestAccessories`.
- (void)addAccessory:(id<__FWRequestAccessory>)accessory;

#pragma mark - Request Action
///=============================================================================
/// @name Request Action
///=============================================================================

///  Append self to request queue and start the request.
- (void)start;

///  Remove self from request queue and cancel the request.
- (void)stop;

///  Convenience method to start the request with block callbacks.
- (void)startWithCompletionBlockWithSuccess:(nullable __FWRequestCompletionBlock)success
                                    failure:(nullable __FWRequestCompletionBlock)failure;

///  Convenience method to start the request with completion block.
- (void)startWithCompletion:(nullable __FWRequestCompletionBlock)completion;

- (void)startWithWillStart:(nullable __FWRequestCompletionBlock)willStart
                  willStop:(nullable __FWRequestCompletionBlock)willStop
                   success:(nullable __FWRequestCompletionBlock)success
                   failure:(nullable __FWRequestCompletionBlock)failure
                   didStop:(nullable __FWRequestCompletionBlock)didStop;

- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;

#pragma mark - Subclass Override
///=============================================================================
/// @name Subclass Override
///=============================================================================

///  This validator will be used to test whether to mock response in debug mode. Default is YES if 404.
- (BOOL)responseMockValidator;

///  Called on background thread after request failed but before callback in debug mode.
- (BOOL)responseMockProcessor;

///  Preprocess URLRequest before actually sending them.
- (void)filterUrlRequest:(NSMutableURLRequest *)urlRequest;

///  Postprocess request before actually run callback. Default is YES.
- (BOOL)filterResponse:(NSError * _Nullable __autoreleasing *)error;

///  Called on background thread after request succeeded but before switching to main thread. Note if
///  cache is loaded, this method WILL be called on the main thread, just like `requestCompleteFilter`.
- (void)requestCompletePreprocessor;

///  Called on the main thread after request succeeded.
- (void)requestCompleteFilter;

///  Called on background thread after request failed but before switching to main thread. See also
///  `requestCompletePreprocessor`.
- (void)requestFailedPreprocessor;

///  Called on the main thread when request failed.
- (void)requestFailedFilter;

///  The baseURL of request. This should only contain the host part of URL, e.g., http://www.example.com.
///  See also `requestUrl`
- (NSString *)baseUrl;

///  The URL path of request. This should only contain the path part of URL, e.g., /v1/user. See alse `baseUrl`.
///
///  @note This will be concated with `baseUrl` using [NSURL URLWithString:relativeToURL].
///              Because of this, it is recommended that the usage should stick to rules stated above.
///              Otherwise the result URL may not be correctly formed. See also `URLString:relativeToURL`
///              for more information.
///
///              Additionally, if `requestUrl` itself is a valid URL, it will be used as the result URL and
///              `baseUrl` will be ignored.
- (NSString *)requestUrl;

///  Optional CDN URL for request.
- (NSString *)cdnUrl;

///  Request timeout interval. Default is 60s.
///
///  @note When using `resumableDownloadPath`(NSURLSessionDownloadTask), the session seems to completely ignore
///              `timeoutInterval` property of `NSURLRequest`. One effective way to set timeout would be using
///              `timeoutIntervalForResource` of `NSURLSessionConfiguration`.
- (NSTimeInterval)requestTimeoutInterval;

///  Custom request cache policy. Default is -1, uses __FWHTTPRequestSerializer.cachePolicy.
- (NSURLRequestCachePolicy)requestCachePolicy;

///  Additional request argument.
- (nullable id)requestArgument;

///  Override this method to filter requests with certain arguments when caching.
- (id)cacheFileNameFilter:(id)argument;

///  HTTP request method.
- (__FWRequestMethod)requestMethod;

///  Request serializer type.
- (__FWRequestSerializerType)requestSerializerType;

///  Response serializer type. See also `responseObject`.
- (__FWResponseSerializerType)responseSerializerType;

///  Username and password used for HTTP authorization. Should be formed as @[@"Username", @"Password"].
- (nullable NSArray<NSString *> *)requestAuthorizationHeaderFieldArray;

///  Additional HTTP request header field.
- (nullable NSDictionary<NSString *, NSString *> *)requestHeaderFieldValueDictionary;

///  Use this to build custom request. If this method return non-nil value, `requestUrl`, `requestTimeoutInterval`,
///  `requestArgument`, `allowsCellularAccess`, `requestMethod` and `requestSerializerType` will all be ignored.
- (nullable NSURLRequest *)buildCustomUrlRequest;

///  Should use CDN when sending request.
- (BOOL)useCDN;

///  Whether the request is allowed to use the cellular radio (if present). Default is YES.
- (BOOL)allowsCellularAccess;

///  The validator will be used to test if `responseJSONObject` is correctly formed.
- (nullable id)jsonValidator;

///  This validator will be used to test if `responseStatusCode` is valid.
- (BOOL)statusCodeValidator;

///  Retry count for request. Default is 0.
- (NSInteger)requestRetryCount;

///  Retry interval for request. Default is 0.
- (NSTimeInterval)requestRetryInternval;

///  Retry timeout for request. Default is 0.
- (NSTimeInterval)requestRetryTimeout;

///  The validator will be used to test if request should retry, enabled when requestRetryCount > 0. Default to check statusCode and error.
- (BOOL)requestRetryValidator:(NSHTTPURLResponse *)response
               responseObject:(nullable id)responseObject
                        error:(nullable NSError *)error;

///  The processor will be called if requestRetryValidator return YES, completionHandler must be called with a bool value, which means retry request if success or stop request if failed. Default to YES.
- (void)requestRetryProcessor:(NSHTTPURLResponse *)response
               responseObject:(nullable id)responseObject
                        error:(nullable NSError *)error
            completionHandler:(void (^)(BOOL success))completionHandler;

#pragma mark - Cache

///  Whether to use cache as response or not. Default is NO.
///  If YES, which means caching will take effect with specific arguments.
///  Note that `cacheTimeInSeconds` default is -1. As a result cache data is not actually
///  used as response unless you return a positive value in `cacheTimeInSeconds`.
///
///  Also note that this option does not affect storing the response, which means response will always be saved even `useCacheResponse` is NO.
@property (nonatomic) BOOL useCacheResponse;

///  Whether data is from local cache.
- (BOOL)isDataFromCache;

///  Manually load cache from storage.
///
///  @param error If an error occurred causing cache loading failed, an error object will be passed, otherwise NULL.
///
///  @return Whether cache is successfully loaded.
- (BOOL)loadCacheWithError:(NSError * __autoreleasing *)error;

///  Start request without reading local cache even if it exists. Use this to update local cache.
- (void)startWithoutCache;

///  Save response data (probably from another request) to this request's cache location
- (void)saveResponseDataToCacheFile:(NSData *)data;

#pragma mark - Cache Subclass Override

///  The max time duration that cache can stay in disk until it's considered expired.
///  Default is -1, which means response is not actually saved as cache.
- (NSInteger)cacheTimeInSeconds;

///  Version can be used to identify and invalidate local cache. Default is 0.
- (long long)cacheVersion;

///  This can be used as additional identifier that tells the cache needs updating.
///
///  @note The `description` string of this object will be used as an identifier to verify whether cache
///              is invalid. Using `NSArray` or `NSDictionary` as return value type is recommended. However,
///              If you intend to use your custom class type, make sure that `description` is correctly implemented.
- (nullable id)cacheSensitiveData;

///  Whether cache is asynchronously written to storage. Default is YES.
- (BOOL)writeCacheAsynchronously;

- (NSString *)cacheBasePath;

@end

NS_ASSUME_NONNULL_END
