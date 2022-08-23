//
//  FWChainRequest.h
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

@class FWChainRequest;
@class FWBaseRequest;
@protocol FWRequestAccessory;

///  The FWChainRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of chain request finishes.
NS_SWIFT_NAME(ChainRequestDelegate)
@protocol FWChainRequestDelegate <NSObject>

@optional
///  Tell the delegate that the chain request has finished successfully.
///
///  @param chainRequest The corresponding chain request.
- (void)chainRequestFinished:(FWChainRequest *)chainRequest;

///  Tell the delegate that the chain request has failed.
///
///  @param chainRequest The corresponding chain request.
- (void)chainRequestFailed:(FWChainRequest *)chainRequest;

@end

/// The chain callback called when one request finished
typedef void (^FWChainCallback)(FWChainRequest *chainRequest, FWBaseRequest *baseRequest) NS_SWIFT_NAME(ChainCallback);

///  FWChainRequest can be used to chain several FWRequest so that one will only starts after another finishes.
///  Note that when used inside FWChainRequest, a single FWRequest will have its own callback and delegate
///  cleared, in favor of the chain request callback.
NS_SWIFT_NAME(ChainRequest)
@interface FWChainRequest : NSObject

///  All the requests are stored in this array.
@property (nonatomic, strong, readonly) NSArray<FWBaseRequest *> *requestArray;

///  The delegate object of the chain request. Default is nil.
@property (nonatomic, weak, nullable) id<FWChainRequestDelegate> delegate;

///  The success callback. Note this will be called only if all the requests are finished.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^successCompletionBlock)(FWChainRequest *);

///  The failure callback. Note this will be called if one of the requests fails.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(FWChainRequest *);

///  Tag can be used to identify chain request. Default value is 0.
@property (nonatomic) NSInteger tag;

///  This can be used to add several accessories object. Note if you use `addAccessory` to add accessory
///  this array will be automatically created. Default is nil.
@property (nonatomic, strong, nullable) NSMutableArray<id<FWRequestAccessory>> *requestAccessories;

///  The last request that succeed (and causing the chain request to finish).
@property (nonatomic, strong, readonly, nullable) FWBaseRequest *succeedRequest;

///  The last request that failed (and causing the chain request to fail).
@property (nonatomic, strong, readonly, nullable) FWBaseRequest *failedRequest;

///  The request interval to start next chain request. Defaults to 0.
@property (nonatomic, assign) NSTimeInterval requestInterval;

///  When true, the chain request is stopped if one of the requests fails. Defaults to YES.
@property (nonatomic, assign) BOOL stoppedOnFailure;

///  When true, the chain request is stopped if one of the requests succeed. Defaults to NO.
@property (nonatomic, assign) BOOL stoppedOnSuccess;

///  Set completion callbacks
- (void)setCompletionBlockWithSuccess:(nullable void (^)(FWChainRequest *chainRequest))success
                              failure:(nullable void (^)(FWChainRequest *chainRequest))failure;

///  Nil out both success and failure callback blocks.
- (void)clearCompletionBlock;

///  Convenience method to add request accessory. See also `requestAccessories`.
- (void)addAccessory:(id<FWRequestAccessory>)accessory;

///  Start the chain request, adding first request in the chain to request queue.
- (void)start;

///  Stop the chain request. Remaining request in chain will be cancelled.
- (void)stop;

///  Convenience method to start the chain request with block callbacks.
- (void)startWithCompletionBlockWithSuccess:(nullable void (^)(FWChainRequest *chainRequest))success
                                    failure:(nullable void (^)(FWChainRequest *chainRequest))failure;

///  Convenience method to start the chain request with completion block.
- (void)startWithCompletion:(nullable void (^)(FWChainRequest *chainRequest))completion;

///  Add request to request chain.
///
///  @param request  The request to be chained.
///  @param callback The finish callback
- (void)addRequest:(FWBaseRequest *)request callback:(nullable FWChainCallback)callback;

///  The request builder for the chain. Note this will be called if all of the requests finished.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) FWBaseRequest * _Nullable (^requestBuilder)(FWChainRequest *chainRequest, FWBaseRequest * _Nullable previousRequest);

@end

NS_ASSUME_NONNULL_END
