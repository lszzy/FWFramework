//
//  RequestManager.h
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
#import "BaseRequest.h"
#import "BatchRequest.h"
#import "ChainRequest.h"
#import "RequestConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class __FWBaseRequest;
@class __FWBatchRequest;
@class __FWChainRequest;
@class __FWHTTPSessionManager;
@class __FWHTTPResponseSerializer;
@class __FWJSONResponseSerializer;
@class __FWXMLParserResponseSerializer;

///  __FWRequestManager is the underlying class that handles actual request generation,
///  serialization and response handling.
NS_SWIFT_NAME(RequestManager)
@interface __FWRequestManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared manager.
+ (__FWRequestManager *)sharedManager;

///  Add request to session and start it.
- (void)addRequest:(__FWBaseRequest *)request;

///  Cancel a request that was previously added.
- (void)cancelRequest:(__FWBaseRequest *)request;

///  Cancel all requests that were previously added.
- (void)cancelAllRequests;

///  Add a batch request.
- (void)addBatchRequest:(__FWBatchRequest *)request;

///  Remove a previously added batch request.
- (void)removeBatchRequest:(__FWBatchRequest *)request;

///  Add a chain request.
- (void)addChainRequest:(__FWChainRequest *)request;

///  Remove a previously added chain request.
- (void)removeChainRequest:(__FWChainRequest *)request;

/// Start request synchronously if condition is true or nil, and callback on main thread.
- (void)synchronousRequest:(__FWBaseRequest *)request completion:(nullable void (^)(__kindof __FWBaseRequest * _Nullable request))completion condition:(nullable BOOL (^)(void))condition;

/// Start batch request synchronously if condition is true or nil, and callback on main thread.
- (void)synchronousBatchRequest:(__FWBatchRequest *)batchRequest completion:(nullable void (^)(__FWBatchRequest * _Nullable batchRequest))completion condition:(nullable BOOL (^)(void))condition;

/// Start chain request synchronously if condition is true or nil, and callback on main thread.
- (void)synchronousChainRequest:(__FWChainRequest *)chainRequest completion:(nullable void (^)(__FWChainRequest * _Nullable chainRequest))completion condition:(nullable BOOL (^)(void))condition;

///  Return the constructed URL of request.
///
///  @param request The request to parse. Should not be nil.
///
///  @return The result URL.
- (NSString *)buildRequestUrl:(__FWBaseRequest *)request;

- (__FWHTTPSessionManager *)manager;
- (void)resetURLSessionManager;
- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSString *)incompleteDownloadTempCacheFolder;

- (__FWHTTPResponseSerializer *)httpResponseSerializer;
- (__FWJSONResponseSerializer *)jsonResponseSerializer;
- (__FWXMLParserResponseSerializer *)xmlParserResponseSerialzier;

@end

NS_ASSUME_NONNULL_END
