//
//  ChainRequest.m
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

#import "ChainRequest.h"
#import "RequestConfig.h"
#import "BaseRequest.h"
#import "RequestManager.h"
#import "ObjC.h"

@interface __FWChainRequest()<__FWRequestDelegate>

@property (strong, nonatomic) NSMutableArray<__FWBaseRequest *> *requestArray;
@property (strong, nonatomic) NSMutableArray<__FWChainCallback> *requestCallbackArray;
@property (assign, nonatomic) NSUInteger nextRequestIndex;
@property (weak, nonatomic) __FWBaseRequest *nextRequest;
@property (copy, nonatomic) __FWChainCallback emptyCallback;

@end

@implementation __FWChainRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        _nextRequestIndex = 0;
        _requestArray = [NSMutableArray array];
        _requestCallbackArray = [NSMutableArray array];
        _stoppedOnFailure = YES;
        _emptyCallback = ^(__FWChainRequest *chainRequest, __FWBaseRequest *baseRequest) { };
    }
    return self;
}

- (void)start {
    if (_nextRequestIndex > 0) {
        if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
            FWLogDebug(@"Error! Chain request has already started.");
        }
        return;
    }

    _succeedRequest = nil;
    _failedRequest = nil;
    [[__FWRequestManager sharedManager] addChainRequest:self];
    [self toggleAccessoriesWillStartCallBack];
    if (![self startNextRequest:nil]) {
        if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
            FWLogDebug(@"Error! Chain request array is empty.");
        }
    }
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    _delegate = nil;
    [self clearRequest];
    [self toggleAccessoriesDidStopCallBack];
    [[__FWRequestManager sharedManager] removeChainRequest:self];
}

- (void)startWithSuccess:(void (^)(__FWChainRequest *chainRequest))success
                 failure:(void (^)(__FWChainRequest *chainRequest))failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)startWithCompletion:(void (^)(__FWChainRequest *))completion {
    [self startWithSuccess:completion failure:completion];
}

- (void)startWithWillStart:(nullable void (^)(__FWChainRequest *chainRequest))willStart
                  willStop:(nullable void (^)(__FWChainRequest *chainRequest))willStop
                   success:(nullable void (^)(__FWChainRequest *chainRequest))success
                   failure:(nullable void (^)(__FWChainRequest *chainRequest))failure
                   didStop:(nullable void (^)(__FWChainRequest *chainRequest))didStop {
    __FWRequestAccessory *accessory = [__FWRequestAccessory new];
    accessory.willStartBlock = willStart;
    accessory.willStopBlock = willStop;
    accessory.didStopBlock = didStop;
    [self addAccessory:accessory];
    [self startWithSuccess:success failure:failure];
}

- (void)startSynchronouslyWithSuccess:(void (^)(__FWChainRequest * _Nonnull))success failure:(void (^)(__FWChainRequest * _Nonnull))failure {
    [self startSynchronouslyWithFilter:nil completion:^(__FWChainRequest *chainRequest) {
        if (chainRequest.failedRequest == nil) {
            if (success) success(chainRequest);
        } else {
            if (failure) failure(chainRequest);
        }
    }];
}

- (void)startSynchronouslyWithFilter:(BOOL (^)(void))filter completion:(void (^)(__FWChainRequest * _Nonnull))completion {
    [[__FWRequestManager sharedManager] synchronousChainRequest:self filter:filter completion:completion];
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

- (void)setCompletionBlockWithSuccess:(void (^)(__FWChainRequest *chainRequest))success
                              failure:(void (^)(__FWChainRequest *chainRequest))failure {
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

- (void)addRequest:(__FWBaseRequest *)request callback:(__FWChainCallback)callback {
    [_requestArray addObject:request];
    if (callback != nil) {
        [_requestCallbackArray addObject:callback];
    } else {
        [_requestCallbackArray addObject:_emptyCallback];
    }
}

- (NSArray<__FWBaseRequest *> *)requestArray {
    return _requestArray;
}

- (BOOL)startNextRequest:(__FWBaseRequest *)previousRequest {
    if (_nextRequestIndex >= [_requestArray count] && self.requestBuilder) {
        __FWBaseRequest *baseRequest = self.requestBuilder(self, previousRequest);
        if (baseRequest) {
            [self addRequest:baseRequest callback:nil];
        }
    }
    
    if (_nextRequestIndex < [_requestArray count]) {
        __FWBaseRequest *request = _requestArray[_nextRequestIndex];
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

- (void)requestFinished:(__FWBaseRequest *)request {
    _succeedRequest = request;
    _failedRequest = nil;
    
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    __FWChainCallback chainCallback = _requestCallbackArray[currentRequestIndex];
    chainCallback(self, request);
    
    if (self.stoppedOnSuccess || ![self startNextRequest:request]) {
        [self requestCompleted];
    }
}

- (void)requestFailed:(__FWBaseRequest *)request {
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
    [[__FWRequestManager sharedManager] removeChainRequest:self];
}

- (void)clearRequest {
    if (_nextRequestIndex > 0) {
        NSUInteger currentRequestIndex = _nextRequestIndex - 1;
        if (currentRequestIndex < [_requestArray count]) {
            __FWBaseRequest *request = _requestArray[currentRequestIndex];
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

- (void)addAccessory:(id<__FWRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

@end
