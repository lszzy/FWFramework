//
//  FWNetworkConfig.h
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

@class FWBaseRequest;
@class FWSecurityPolicy;

///  FWUrlFilterProtocol can be used to append common parameters to requests before sending them.
NS_SWIFT_NAME(UrlFilterProtocol)
@protocol FWUrlFilterProtocol <NSObject>

@optional

///  Preprocess request URL before actually sending them.
///
///  @param originUrl request's origin URL, which is returned by `requestUrl`
///  @param request   request itself
///
///  @return A new url which will be used as a new `requestUrl`
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(FWBaseRequest *)request;

///  Preprocess URLRequest before actually sending them.
///
///  @param urlRequest request's URLRequest
///  @param request   request itself
///
- (void)filterUrlRequest:(NSMutableURLRequest *)urlRequest withRequest:(FWBaseRequest *)request;

///  Postprocess request before actually run callback.
///
///  @param request   request itself
///  @param error   result error
///
- (BOOL)filterResponse:(FWBaseRequest *)request withError:(NSError * _Nullable __autoreleasing *)error;

@end

///  FWCacheDirPathFilterProtocol can be used to append common path components when caching response results
NS_SWIFT_NAME(CacheDirPathFilterProtocol)
@protocol FWCacheDirPathFilterProtocol <NSObject>

@optional

///  Preprocess cache path before actually saving them.
///
///  @param originPath original base cache path, which is generated in `FWRequest` class.
///  @param request    request itself
///
///  @return A new path which will be used as base path when caching.
- (NSString *)filterCacheDirPath:(NSString *)originPath withRequest:(FWBaseRequest *)request;
@end

///  FWNetworkConfig stored global network-related configurations, which will be used in `FWNetworkAgent`
///  to form and filter requests, as well as caching response.
NS_SWIFT_NAME(NetworkConfig)
@interface FWNetworkConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Return a shared config object.
+ (FWNetworkConfig *)sharedConfig;

///  Request base URL, such as "http://www.yuantiku.com". Default is empty string.
@property (nonatomic, strong) NSString *baseUrl;
///  Request CDN URL. Default is empty string.
@property (nonatomic, strong) NSString *cdnUrl;
///  URL filters. See also `FWUrlFilterProtocol`.
@property (nonatomic, strong, readonly) NSArray<id<FWUrlFilterProtocol>> *urlFilters;
///  Cache path filters. See also `FWCacheDirPathFilterProtocol`.
@property (nonatomic, strong, readonly) NSArray<id<FWCacheDirPathFilterProtocol>> *cacheDirPathFilters;
///  Security policy will be used by AFNetworking. See also `FWSecurityPolicy`.
@property (nonatomic, strong) FWSecurityPolicy *securityPolicy;
///  Whether to remove NSNull values from response JSON. Defaults to YES.
@property (nonatomic, assign) BOOL removeNullValues;
///  Whether to log debug info. Default is NO;
@property (nonatomic) BOOL debugLogEnabled;
///  Whether to enable mock response when failed in debug mode. Default is NO.
@property (nonatomic, assign) BOOL debugMockEnabled;
///  SessionConfiguration will be used to initialize FWHTTPSessionManager. Default is nil.
@property (nonatomic, strong, nullable) NSURLSessionConfiguration *sessionConfiguration;
///  NSURLSessionTaskMetrics
@property (nonatomic, copy, nullable) void (^collectingMetricsBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLSessionTaskMetrics * _Nullable metrics);

///  Add a new URL filter.
- (void)addUrlFilter:(id<FWUrlFilterProtocol>)filter;
///  Remove all URL filters.
- (void)clearUrlFilter;
///  Add a new cache path filter
- (void)addCacheDirPathFilter:(id<FWCacheDirPathFilterProtocol>)filter;
///  Clear all cache path filters.
- (void)clearCacheDirPathFilter;

@end

NS_ASSUME_NONNULL_END
