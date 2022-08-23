//
//  FWBatchRequest.m
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

#import "FWBatchRequest.h"
#import "FWNetworkPrivate.h"
#import "FWRequestAgent.h"
#import "FWRequest.h"

@interface FWBatchRequest() <FWRequestDelegate>

@property (nonatomic) NSInteger finishedCount;
@property (nonatomic, strong) NSMutableArray<FWRequest *> *failedRequestArray;

@end

@implementation FWBatchRequest

- (instancetype)initWithRequestArray:(NSArray<FWRequest *> *)requestArray {
    self = [super init];
    if (self) {
        _requestArray = [requestArray copy];
        _failedRequestArray = [NSMutableArray array];
        _finishedCount = 0;
        _stoppedOnFailure = YES;
        for (FWRequest * req in _requestArray) {
            if (![req isKindOfClass:[FWRequest class]]) {
                FWRequestLog(@"Error, request item must be FWRequest instance.");
                return nil;
            }
        }
    }
    return self;
}

- (void)start {
    if (_finishedCount > 0) {
        FWRequestLog(@"Error! Batch request has already started.");
        return;
    }
    [_failedRequestArray removeAllObjects];
    [[FWRequestAgent sharedAgent] addBatchRequest:self];
    [self toggleAccessoriesWillStartCallBack];
    for (FWRequest * req in _requestArray) {
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
    [[FWRequestAgent sharedAgent] removeBatchRequest:self];
}

- (void)startWithCompletionBlockWithSuccess:(void (^)(FWBatchRequest *batchRequest))success
                                    failure:(void (^)(FWBatchRequest *batchRequest))failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)startWithCompletion:(void (^)(FWBatchRequest *))completion {
    [self startWithCompletionBlockWithSuccess:completion failure:completion];
}

- (void)setCompletionBlockWithSuccess:(void (^)(FWBatchRequest *batchRequest))success
                              failure:(void (^)(FWBatchRequest *batchRequest))failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (FWRequest *)failedRequest {
    return self.failedRequestArray.firstObject;
}

- (BOOL)isDataFromCache {
    BOOL result = YES;
    for (FWRequest *request in _requestArray) {
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

- (void)requestFinished:(FWRequest *)request {
    _finishedCount++;
    if (_finishedCount == _requestArray.count) {
        [self requestCompleted];
    }
}

- (void)requestFailed:(FWRequest *)request {
    [_failedRequestArray addObject:request];
    if (self.stoppedOnFailure) {
        for (FWRequest *req in _requestArray) {
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
    [[FWRequestAgent sharedAgent] removeBatchRequest:self];
}

- (void)clearRequest {
    for (FWRequest * req in _requestArray) {
        [req stop];
    }
    [self clearCompletionBlock];
}

#pragma mark - Request Accessoies

- (void)addAccessory:(id<FWRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

@end
