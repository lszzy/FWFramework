//
//  NetworkManager.h
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
#import "Request.h"
#import "BatchRequest.h"
#import "ChainRequest.h"
#import "RequestManager.h"
#import "NetworkConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class FWBaseRequest;
@class __FWHTTPSessionManager;
@class __FWHTTPResponseSerializer;
@class __FWJSONResponseSerializer;
@class __FWXMLParserResponseSerializer;

///  FWNetworkManager is the underlying class that handles actual request generation,
///  serialization and response handling.
NS_SWIFT_NAME(NetworkManager)
@interface FWNetworkManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared manager.
+ (FWNetworkManager *)sharedManager;

///  Add request to session and start it.
- (void)addRequest:(FWBaseRequest *)request;

///  Cancel a request that was previously added.
- (void)cancelRequest:(FWBaseRequest *)request;

///  Cancel all requests that were previously added.
- (void)cancelAllRequests;

///  Return the constructed URL of request.
///
///  @param request The request to parse. Should not be nil.
///
///  @return The result URL.
- (NSString *)buildRequestUrl:(FWBaseRequest *)request;

- (__FWHTTPSessionManager *)manager;
- (void)resetURLSessionManager;
- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSString *)incompleteDownloadTempCacheFolder;

- (__FWHTTPResponseSerializer *)httpResponseSerializer;
- (__FWJSONResponseSerializer *)jsonResponseSerializer;
- (__FWXMLParserResponseSerializer *)xmlParserResponseSerialzier;

@end

NS_ASSUME_NONNULL_END
