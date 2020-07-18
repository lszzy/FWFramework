/*!
 @header     FWRequestManager.m
 @indexgroup FWFramework
 @brief      FWRequestManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/7/18
 */

#import "FWRequestManager.h"
#import "FWPromise.h"

#pragma mark - FWRequest+FWPromise

@implementation FWBaseRequest (FWPromise)

- (FWPromise *)promise
{
    FWPromise *promise = [FWPromise promise];
    [self startWithCompletionBlockWithSuccess:^(__kindof FWBaseRequest *request) {
        [promise resolve:request];
    } failure:^(__kindof FWBaseRequest *request) {
        [promise reject:request.error];
    }];
    return promise;
}

- (FWCoroutineClosure)coroutine
{
    __weak __typeof__(self) self_weak_ = self;
    return ^(FWCoroutineCallback callback){
        __typeof__(self) self = self_weak_;
        [self startWithCompletionBlockWithSuccess:^(__kindof FWBaseRequest *request) {
            callback(request, nil);
        } failure:^(__kindof FWBaseRequest *request) {
            callback(nil, request.error);
        }];
    };
}

@end

@implementation FWBatchRequest (FWPromise)

- (FWPromise *)promise
{
    FWPromise *promise = [FWPromise promise];
    [self startWithCompletionBlockWithSuccess:^(FWBatchRequest *batchRequest) {
        [promise resolve:batchRequest];
    } failure:^(FWBatchRequest *batchRequest) {
        [promise reject:batchRequest.failedRequest.error];
    }];
    return promise;
}

- (FWCoroutineClosure)coroutine
{
    __weak __typeof__(self) self_weak_ = self;
    return ^(FWCoroutineCallback callback){
        __typeof__(self) self = self_weak_;
        [self startWithCompletionBlockWithSuccess:^(FWBatchRequest *batchRequest) {
            callback(batchRequest, nil);
        } failure:^(FWBatchRequest *batchRequest) {
            callback(nil, batchRequest.failedRequest.error);
        }];
    };
}

@end
