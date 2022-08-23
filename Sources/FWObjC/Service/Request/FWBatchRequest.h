//
//  FWBatchRequest.h
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

@class FWRequest;
@class FWBatchRequest;
@protocol FWRequestAccessory;

///  The FWBatchRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of batch request finishes.
NS_SWIFT_NAME(BatchRequestDelegate)
@protocol FWBatchRequestDelegate <NSObject>

@optional
///  Tell the delegate that the batch request has finished successfully/
///
///  @param batchRequest The corresponding batch request.
- (void)batchRequestFinished:(FWBatchRequest *)batchRequest;

///  Tell the delegate that the batch request has failed.
///
///  @param batchRequest The corresponding batch request.
- (void)batchRequestFailed:(FWBatchRequest *)batchRequest;

@end

///  FWBatchRequest can be used to batch several FWRequest. Note that when used inside FWBatchRequest, a single
///  FWRequest will have its own callback and delegate cleared, in favor of the batch request callback.
NS_SWIFT_NAME(BatchRequest)
@interface FWBatchRequest : NSObject

///  All the requests are stored in this array.
@property (nonatomic, strong, readonly) NSArray<FWRequest *> *requestArray;

///  The delegate object of the batch request. Default is nil.
@property (nonatomic, weak, nullable) id<FWBatchRequestDelegate> delegate;

///  The success callback. Note this will be called only if all the requests are finished.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^successCompletionBlock)(FWBatchRequest *);

///  The failure callback. Note this will be called if one of the requests fails.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(FWBatchRequest *);

///  Tag can be used to identify batch request. Default value is 0.
@property (nonatomic) NSInteger tag;

///  This can be used to add several accessories object. Note if you use `addAccessory` to add accessory
///  this array will be automatically created. Default is nil.
@property (nonatomic, strong, nullable) NSMutableArray<id<FWRequestAccessory>> *requestAccessories;

///  The first request that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly, nullable) FWRequest *failedRequest;

///  The requests that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly) NSArray<FWRequest *> *failedRequestArray;

///  When true, the batch request is stopped if one of the requests fails. Defaults to YES.
@property (nonatomic, assign) BOOL stoppedOnFailure;

///  Creates a `FWBatchRequest` with a bunch of requests.
///
///  @param requestArray requests useds to create batch request.
///
- (instancetype)initWithRequestArray:(NSArray<FWRequest *> *)requestArray;

///  Set completion callbacks
- (void)setCompletionBlockWithSuccess:(nullable void (^)(FWBatchRequest *batchRequest))success
                              failure:(nullable void (^)(FWBatchRequest *batchRequest))failure;

///  Nil out both success and failure callback blocks.
- (void)clearCompletionBlock;

///  Convenience method to add request accessory. See also `requestAccessories`.
- (void)addAccessory:(id<FWRequestAccessory>)accessory;

///  Append all the requests to queue.
- (void)start;

///  Stop all the requests of the batch request.
- (void)stop;

///  Convenience method to start the batch request with block callbacks.
- (void)startWithCompletionBlockWithSuccess:(nullable void (^)(FWBatchRequest *batchRequest))success
                                    failure:(nullable void (^)(FWBatchRequest *batchRequest))failure;

///  Convenience method to start the batch request with completion block.
- (void)startWithCompletion:(nullable void (^)(FWBatchRequest *batchRequest))completion;

///  Whether all response data is from local cache.
- (BOOL)isDataFromCache;

@end

NS_ASSUME_NONNULL_END
