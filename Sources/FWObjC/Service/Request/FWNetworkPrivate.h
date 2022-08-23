//
//  FWNetworkPrivate.h
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
#import "FWRequest.h"
#import "FWBatchRequest.h"
#import "FWChainRequest.h"
#import "FWRequestAgent.h"
#import "FWNetworkAgent.h"
#import "FWNetworkConfig.h"
#import "FWRequestAccessory.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void FWRequestLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2) NS_REFINED_FOR_SWIFT;

@class FWHTTPSessionManager;
@class FWHTTPResponseSerializer;
@class FWJSONResponseSerializer;
@class FWXMLParserResponseSerializer;

NS_SWIFT_NAME(NetworkUtils)
@interface FWNetworkUtils : NSObject

+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;

+ (void)addDoNotBackupAttribute:(NSString *)path;

+ (NSString *)md5StringFromString:(NSString *)string;

+ (NSString *)appVersionString;

+ (NSStringEncoding)stringEncodingWithRequest:(FWBaseRequest *)request;

+ (BOOL)validateResumeData:(NSData *)data;

+ (BOOL)isRequestError:(nullable NSError *)error;

@end

@interface FWRequest (Getter)

- (NSString *)cacheBasePath;

@end

@interface FWBaseRequest (Setter)

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, assign, readwrite) NSUInteger requestIdentifier;
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;
@property (nonatomic, strong, readwrite, nullable) id responseJSONObject;
@property (nonatomic, strong, readwrite, nullable) id responseObject;
@property (nonatomic, strong, readwrite, nullable) NSString *responseString;
@property (nonatomic, strong, readwrite, nullable) NSError *error;
@property (nonatomic, readwrite) NSInteger requestTotalCount;
@property (nonatomic, readwrite) NSTimeInterval requestTotalTime;

@end

@interface FWBaseRequest (RequestAccessory)

- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;

@end

@interface FWBatchRequest (RequestAccessory)

- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;

@end

@interface FWChainRequest (RequestAccessory)

- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;

@end

@interface FWNetworkAgent (Private)

- (FWHTTPSessionManager *)manager;
- (void)resetURLSessionManager;
- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSString *)incompleteDownloadTempCacheFolder;

- (FWHTTPResponseSerializer *)httpResponseSerializer;
- (FWJSONResponseSerializer *)jsonResponseSerializer;
- (FWXMLParserResponseSerializer *)xmlParserResponseSerialzier;

@end

NS_ASSUME_NONNULL_END
