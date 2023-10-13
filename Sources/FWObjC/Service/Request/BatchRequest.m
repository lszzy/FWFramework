//
//  BatchRequest.m
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

#import "BatchRequest.h"
#import "BaseRequest.h"
#import "RequestConfig.h"
#import "RequestManager.h"
#import "ObjC.h"

@interface __FWBatchRequest() <__FWRequestDelegate>

@property (nonatomic) NSInteger finishedCount;
@property (nonatomic, strong) NSMutableArray<__FWBaseRequest *> *failedRequestArray;

@end

@implementation __FWBatchRequest

- (instancetype)initWithRequestArray:(NSArray<__FWBaseRequest *> *)requestArray {
    self = [super init];
    if (self) {
        _requestArray = [requestArray copy];
        _failedRequestArray = [NSMutableArray array];
        _finishedCount = 0;
        _stoppedOnFailure = YES;
        for (__FWBaseRequest * req in _requestArray) {
            if (![req isKindOfClass:[__FWBaseRequest class]]) {
                if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
                    FWLogDebug(@"Error, request item must be __FWBaseRequest instance.");
                }
                return nil;
            }
        }
    }
    return self;
}

- (void)start {
    if (_finishedCount > 0) {
        if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
            FWLogDebug(@"Error! Batch request has already started.");
        }
        return;
    }
    [_failedRequestArray removeAllObjects];
    [[__FWRequestManager sharedManager] addBatchRequest:self];
    [self toggleAccessoriesWillStartCallBack];
    for (__FWBaseRequest * req in _requestArray) {
        req.delegate = self;
        [req clearCompletionBlock];
        [req start];
    }
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    _delegate = nil;
    [self clearRequest];
    [self toggleAccessoriesDidStopCallBack];
    [[__FWRequestManager sharedManager] removeBatchRequest:self];
}

- (void)startWithSuccess:(void (^)(__FWBatchRequest *batchRequest))success
                 failure:(void (^)(__FWBatchRequest *batchRequest))failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)startWithCompletion:(void (^)(__FWBatchRequest *))completion {
    [self startWithSuccess:completion failure:completion];
}

- (void)startWithWillStart:(nullable void (^)(__FWBatchRequest *batchRequest))willStart
                  willStop:(nullable void (^)(__FWBatchRequest *batchRequest))willStop
                   success:(nullable void (^)(__FWBatchRequest *batchRequest))success
                   failure:(nullable void (^)(__FWBatchRequest *batchRequest))failure
                   didStop:(nullable void (^)(__FWBatchRequest *batchRequest))didStop {
    __FWRequestAccessory *accessory = [__FWRequestAccessory new];
    accessory.willStartBlock = willStart;
    accessory.willStopBlock = willStop;
    accessory.didStopBlock = didStop;
    [self addAccessory:accessory];
    [self startWithSuccess:success failure:failure];
}

- (void)startSynchronouslyWithSuccess:(void (^)(__FWBatchRequest * _Nonnull))success failure:(void (^)(__FWBatchRequest * _Nonnull))failure {
    [self startSynchronouslyWithFilter:nil completion:^(__FWBatchRequest *batchRequest) {
        if (batchRequest.failedRequest == nil) {
            if (success) success(batchRequest);
        } else {
            if (failure) failure(batchRequest);
        }
    }];
}

- (void)startSynchronouslyWithFilter:(BOOL (^)(void))filter completion:(void (^)(__FWBatchRequest * _Nonnull))completion {
    [[__FWRequestManager sharedManager] synchronousBatchRequest:self filter:filter completion:completion];
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

- (void)setCompletionBlockWithSuccess:(void (^)(__FWBatchRequest *batchRequest))success
                              failure:(void (^)(__FWBatchRequest *batchRequest))failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (__FWBaseRequest *)failedRequest {
    return self.failedRequestArray.firstObject;
}

- (BOOL)isDataFromCache {
    BOOL result = YES;
    for (__FWBaseRequest *request in _requestArray) {
        if (!request.isDataFromCache) {
            result = NO;
        }
    }
    return result;
}

- (void)dealloc {
    [self clearRequest];
}

#pragma mark - Network Request Delegate

- (void)requestFinished:(__FWBaseRequest *)request {
    _finishedCount++;
    if (_finishedCount == _requestArray.count) {
        [self requestCompleted];
    }
}

- (void)requestFailed:(__FWBaseRequest *)request {
    [_failedRequestArray addObject:request];
    if (self.stoppedOnFailure) {
        for (__FWBaseRequest *req in _requestArray) {
            [req stop];
        }
        [self requestCompleted];
        return;
    }
    
    _finishedCount++;
    if (_finishedCount == _requestArray.count) {
        [self requestCompleted];
    }
}

- (void)requestCompleted {
    [self toggleAccessoriesWillStopCallBack];
    
    if (_failedRequestArray.count < 1) {
        if ([_delegate respondsToSelector:@selector(batchRequestFinished:)]) {
            [_delegate batchRequestFinished:self];
        }
        if (_successCompletionBlock) {
            _successCompletionBlock(self);
        }
    } else {
        if ([_delegate respondsToSelector:@selector(batchRequestFailed:)]) {
            [_delegate batchRequestFailed:self];
        }
        if (_failureCompletionBlock) {
            _failureCompletionBlock(self);
        }
    }
    
    [self clearCompletionBlock];
    [self toggleAccessoriesDidStopCallBack];
    [[__FWRequestManager sharedManager] removeBatchRequest:self];
}

- (void)clearRequest {
    for (__FWBaseRequest * req in _requestArray) {
        [req stop];
    }
    [self clearCompletionBlock];
}

#pragma mark - Request Accessoies

- (void)addAccessory:(id<__FWRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

@end
