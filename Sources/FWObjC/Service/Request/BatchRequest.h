//
//  BatchRequest.h
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

@class __FWBaseRequest;
@class __FWBatchRequest;
@protocol __FWRequestAccessory;

///  The __FWBatchRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of batch request finishes.
NS_SWIFT_NAME(BatchRequestDelegate)
@protocol __FWBatchRequestDelegate <NSObject>

@optional
///  Tell the delegate that the batch request has finished successfully/
///
///  @param batchRequest The corresponding batch request.
- (void)batchRequestFinished:(__FWBatchRequest *)batchRequest;

///  Tell the delegate that the batch request has failed.
///
///  @param batchRequest The corresponding batch request.
- (void)batchRequestFailed:(__FWBatchRequest *)batchRequest;

@end

///  __FWBatchRequest can be used to batch several __FWRequest. Note that when used inside __FWBatchRequest, a single
///  __FWBaseRequest will have its own callback and delegate cleared, in favor of the batch request callback.
NS_SWIFT_NAME(BatchRequest)
@interface __FWBatchRequest : NSObject

///  All the requests are stored in this array.
@property (nonatomic, strong, readonly) NSArray<__FWBaseRequest *> *requestArray;

///  The delegate object of the batch request. Default is nil.
@property (nonatomic, weak, nullable) id<__FWBatchRequestDelegate> delegate;

///  The success callback. Note this will be called only if all the requests are finished.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^successCompletionBlock)(__FWBatchRequest *);

///  The failure callback. Note this will be called if one of the requests fails.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(__FWBatchRequest *);

///  Tag can be used to identify batch request. Default value is 0.
@property (nonatomic) NSInteger tag;

///  This can be used to add several accessories object. Note if you use `addAccessory` to add accessory
///  this array will be automatically created. Default is nil.
@property (nonatomic, strong, nullable) NSMutableArray<id<__FWRequestAccessory>> *requestAccessories;

///  The first request that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly, nullable) __FWBaseRequest *failedRequest;

///  The requests that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly) NSArray<__FWBaseRequest *> *failedRequestArray;

///  When true, the batch request is stopped if one of the requests fails. Defaults to YES.
@property (nonatomic, assign) BOOL stoppedOnFailure;

///  Creates a `__FWBatchRequest` with a bunch of requests.
///
///  @param requestArray requests useds to create batch request.
///
- (instancetype)initWithRequestArray:(NSArray<__FWBaseRequest *> *)requestArray;

///  Set completion callbacks
- (void)setCompletionBlockWithSuccess:(nullable void (^)(__FWBatchRequest *batchRequest))success
                              failure:(nullable void (^)(__FWBatchRequest *batchRequest))failure;

///  Nil out both success and failure callback blocks.
- (void)clearCompletionBlock;

///  Convenience method to add request accessory. See also `requestAccessories`.
- (void)addAccessory:(id<__FWRequestAccessory>)accessory;

///  Append all the requests to queue.
- (void)start;

///  Stop all the requests of the batch request.
- (void)stop;

///  Convenience method to start the batch request with block callbacks.
- (void)startWithSuccess:(nullable void (^)(__FWBatchRequest *batchRequest))success
                 failure:(nullable void (^)(__FWBatchRequest *batchRequest))failure;

///  Convenience method to start the batch request with completion block.
- (void)startWithCompletion:(nullable void (^)(__FWBatchRequest *batchRequest))completion;

- (void)startWithWillStart:(nullable void (^)(__FWBatchRequest *batchRequest))willStart
                  willStop:(nullable void (^)(__FWBatchRequest *batchRequest))willStop
                   success:(nullable void (^)(__FWBatchRequest *batchRequest))success
                   failure:(nullable void (^)(__FWBatchRequest *batchRequest))failure
                   didStop:(nullable void (^)(__FWBatchRequest *batchRequest))didStop;

- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;

///  Whether all response data is from local cache.
- (BOOL)isDataFromCache;

@end

NS_ASSUME_NONNULL_END
