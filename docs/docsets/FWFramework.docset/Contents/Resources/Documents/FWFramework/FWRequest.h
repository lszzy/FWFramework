//
//  FWRequest.h
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

#import "FWBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const FWRequestCacheErrorDomain NS_SWIFT_NAME(RequestCacheErrorDomain);

typedef NS_ENUM(NSInteger, FWRequestCacheErrorCode) {
    FWRequestCacheErrorExpired = -1,
    FWRequestCacheErrorVersionMismatch = -2,
    FWRequestCacheErrorSensitiveDataMismatch = -3,
    FWRequestCacheErrorAppVersionMismatch = -4,
    FWRequestCacheErrorInvalidCacheTime = -5,
    FWRequestCacheErrorInvalidMetadata = -6,
    FWRequestCacheErrorInvalidCacheData = -7,
} NS_SWIFT_NAME(RequestCacheErrorCode);

///  FWRequest is the base class you should inherit to create your own request class.
///  Based on FWBaseRequest, FWRequest adds local caching feature. Note download
///  request will not be cached whatsoever, because download request may involve complicated
///  cache control policy controlled by `Cache-Control`, `Last-Modified`, etc.
///  https://github.com/yuantiku/YTKNetwork
NS_SWIFT_NAME(Request)
@interface FWRequest : FWBaseRequest

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

#pragma mark - Subclass Override

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

@end

NS_ASSUME_NONNULL_END
