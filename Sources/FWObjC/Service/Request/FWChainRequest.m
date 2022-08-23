//
//  FWChainRequest.m
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

#import "FWChainRequest.h"
#import "FWRequestAgent.h"
#import "FWNetworkPrivate.h"
#import "FWBaseRequest.h"

@interface FWChainRequest()<FWRequestDelegate>

@property (strong, nonatomic) NSMutableArray<FWBaseRequest *> *requestArray;
@property (strong, nonatomic) NSMutableArray<FWChainCallback> *requestCallbackArray;
@property (assign, nonatomic) NSUInteger nextRequestIndex;
@property (weak, nonatomic) FWBaseRequest *nextRequest;
@property (copy, nonatomic) FWChainCallback emptyCallback;

@end

@implementation FWChainRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        _nextRequestIndex = 0;
        _requestArray = [NSMutableArray array];
        _requestCallbackArray = [NSMutableArray array];
        _stoppedOnFailure = YES;
        _emptyCallback = ^(FWChainRequest *chainRequest, FWBaseRequest *baseRequest) { };
    }
    return self;
}

- (void)start {
    if (_nextRequestIndex > 0) {
        FWRequestLog(@"Error! Chain request has already started.");
        return;
    }

    _succeedRequest = nil;
    _failedRequest = nil;
    [[FWRequestAgent sharedAgent] addChainRequest:self];
    [self toggleAccessoriesWillStartCallBack];
    if (![self startNextRequest:nil]) {
        FWRequestLog(@"Error! Chain request array is empty.");
    }
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    _delegate = nil;
    [self clearRequest];
    [self toggleAccessoriesDidStopCallBack];
    [[FWRequestAgent sharedAgent] removeChainRequest:self];
}

- (void)startWithCompletionBlockWithSuccess:(void (^)(FWChainRequest *chainRequest))success
                                    failure:(void (^)(FWChainRequest *chainRequest))failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)startWithCompletion:(void (^)(FWChainRequest *))completion {
    [self startWithCompletionBlockWithSuccess:completion failure:completion];
}

- (void)setCompletionBlockWithSuccess:(void (^)(FWChainRequest *chainRequest))success
                              failure:(void (^)(FWChainRequest *chainRequest))failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (void)dealloc {
    [self clearRequest];
}

- (void)addRequest:(FWBaseRequest *)request callback:(FWChainCallback)callback {
    [_requestArray addObject:request];
    if (callback != nil) {
        [_requestCallbackArray addObject:callback];
    } else {
        [_requestCallbackArray addObject:_emptyCallback];
    }
}

- (NSArray<FWBaseRequest *> *)requestArray {
    return _requestArray;
}

- (BOOL)startNextRequest:(FWBaseRequest *)previousRequest {
    if (_nextRequestIndex >= [_requestArray count] && self.requestBuilder) {
        FWBaseRequest *baseRequest = self.requestBuilder(self, previousRequest);
        if (baseRequest) {
            [self addRequest:baseRequest callback:nil];
        }
    }
    
    if (_nextRequestIndex < [_requestArray count]) {
        FWBaseRequest *request = _requestArray[_nextRequestIndex];
        _nextRequestIndex++;
        request.delegate = self;
        [request clearCompletionBlock];
        if (_nextRequestIndex > 1 && self.requestInterval > 0) {
            _nextRequest = request;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.requestInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.nextRequest start];
            });
        } else {
            _nextRequest = nil;
            [request start];
        }
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Network Request Delegate

- (void)requestFinished:(FWBaseRequest *)request {
    _succeedRequest = request;
    _failedRequest = nil;
    
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    FWChainCallback chainCallback = _requestCallbackArray[currentRequestIndex];
    chainCallback(self, request);
    
    if (self.stoppedOnSuccess || ![self startNextRequest:request]) {
        [self requestCompleted];
    }
}

- (void)requestFailed:(FWBaseRequest *)request {
    _succeedRequest = nil;
    _failedRequest = request;
    
    if (self.stoppedOnFailure || ![self startNextRequest:request]) {
        [self requestCompleted];
    }
}

- (void)requestCompleted {
    [self toggleAccessoriesWillStopCallBack];
    
    if (!_failedRequest) {
        if ([_delegate respondsToSelector:@selector(chainRequestFinished:)]) {
            [_delegate chainRequestFinished:self];
        }
        if (_successCompletionBlock) {
            _successCompletionBlock(self);
        }
    } else {
        if ([_delegate respondsToSelector:@selector(chainRequestFailed:)]) {
            [_delegate chainRequestFailed:self];
        }
        if (_failureCompletionBlock) {
            _failureCompletionBlock(self);
        }
    }
    
    [self clearCompletionBlock];
    [self toggleAccessoriesDidStopCallBack];
    [[FWRequestAgent sharedAgent] removeChainRequest:self];
}

- (void)clearRequest {
    if (_nextRequestIndex > 0) {
        NSUInteger currentRequestIndex = _nextRequestIndex - 1;
        if (currentRequestIndex < [_requestArray count]) {
            FWBaseRequest *request = _requestArray[currentRequestIndex];
            [request stop];
        }
    }
    _nextRequest = nil;
    [_requestArray removeAllObjects];
    [_requestCallbackArray removeAllObjects];
    _requestBuilder = nil;
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
