/*!
 @header     FWPromise.m
 @indexgroup FWFramework
 @brief      FWPromise约定类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-07-18
 */

#import "FWPromise.h"
#import "FWMessage.h"

typedef NS_ENUM(NSInteger, FWPromiseState) {
    FWPromiseStatePending = 0,
    FWPromiseStateResolved,
    FWPromiseStateRejected,
};

@interface FWPromise ()

@property (nonatomic) id value;

@property (nonatomic) NSError *error;

@property (atomic, assign) FWPromiseState state;

@property (nonatomic, copy) void (^stateBlock)(FWPromise *object, FWPromiseState state);

@property (nonatomic, copy) FWPromiseBlock promiseBlock;

@property (nonatomic, copy) FWResolveBlock resolveBlock;

@property (nonatomic, copy) FWRejectBlock rejectBlock;

@property (nonatomic, copy) FWProgressBlock progressBlock;

@property (nonatomic, copy) FWRejectBlock catchBlock;

@property (nonatomic, copy) FWThenBlock thenBlock;

@property (nonatomic, copy) FWProgressBlock ratioBlock;

@property (nonatomic, strong) FWPromise *dependPromise;

@property (nonatomic, strong) id strongSelf;

@property (nonatomic, strong) id retryValue;

@property (nonatomic, assign) NSInteger retryCount;

@property (nonatomic, strong) NSMutableSet<FWPromise *> *promises;

@property (nonatomic, strong) NSMutableArray *values;

@end

@implementation FWPromise

+ (FWPromise *)promise:(FWPromiseBlock)block
{
    return [[FWPromise alloc] initWithBlock:block];
}

+ (FWPromise *)resolve:(id)value
{
    return [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        resolve(value);
    }];
}

+ (FWPromise *)reject:(NSError *)error
{
    return [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        reject(error);
    }];
}

- (instancetype)initWithBlock:(FWPromiseBlock)block
{
    self = [super init];
    if (self) {
        self.state = FWPromiseStatePending;
        self.strongSelf = self;
        
        __weak FWPromise *weakSelf = self;
        self.stateBlock = ^(FWPromise *object, FWPromiseState state) {
            __strong FWPromise *strongSelf = weakSelf;
            
            if (state == FWPromiseStateRejected) {
                if (strongSelf.catchBlock) {
                    strongSelf.catchBlock(object.error);
                    strongSelf.resolveBlock(nil);
                } else {
                    strongSelf.rejectBlock(object.error);
                }
            } else if (state == FWPromiseStateResolved) {
                strongSelf.retryValue = object.value;
                strongSelf.retryCount = 0;
                if (strongSelf.thenBlock) {
                    id value = strongSelf.thenBlock(object.value);
                    strongSelf.thenBlock = nil;
                    if (value && [value isKindOfClass:[NSError class]]) {
                        if (strongSelf.catchBlock) {
                            strongSelf.catchBlock(value);
                            strongSelf.resolveBlock(nil);
                        } else {
                            strongSelf.rejectBlock(value);
                        }
                    } else {
                        strongSelf.resolveBlock(value);
                    }
                } else {
                    strongSelf.resolveBlock(object.value);
                }
            }
        };
        
        self.resolveBlock = ^(id value) {
            __strong FWPromise *strongSelf = weakSelf;
            if (strongSelf.state != FWPromiseStatePending) {
                return;
            }
            
            if ([value isKindOfClass:[FWPromise class]]) {
                if (((FWPromise *)value).state == FWPromiseStatePending) {
                    strongSelf.dependPromise = value;
                }
                [value fwObserveProperty:@"state" target:strongSelf action:@selector(state:change:)];
            } else {
                strongSelf.value = value;
                strongSelf.state = FWPromiseStateResolved;
                strongSelf.strongSelf = nil;
            }
        };
        
        self.rejectBlock = ^(NSError *error) {
            __strong FWPromise *strongSelf = weakSelf;
            if (strongSelf.state != FWPromiseStatePending) {
                return;
            }
            
            strongSelf.error = error;
            strongSelf.state = FWPromiseStateRejected;
            strongSelf.strongSelf = nil;
        };
        
        self.promiseBlock = block;
        
        if (self.promiseBlock) {
            self.promiseBlock(self.resolveBlock, self.rejectBlock);
        }
    }
    return self;
}

- (void)dealloc
{
    self.state = self.state;
    self.dependPromise = nil;
}

- (void)state:(FWPromise *)object change:(NSDictionary *)change
{
    [object fwUnobserveProperty:@"state" target:self action:@selector(state:change:)];
    
    FWPromiseState state = [change[NSKeyValueChangeNewKey] integerValue];
    self.stateBlock(object, state);
}

- (void)resolve:(id)value
{
    self.resolveBlock(value);
}

- (void)reject:(NSError *)error
{
    self.rejectBlock(error);
}

- (void)progress:(double)ratio value:(id)value
{
    if (self.ratioBlock) {
        self.ratioBlock(ratio, value);
    }
}

- (FWPromise *(^)(FWThenBlock))then
{
    __weak FWPromise *weakSelf = self;
    return ^FWPromise *(FWThenBlock thenBlock) {
        __weak FWPromise *newPromise = nil;
        newPromise = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            __strong FWPromise *strongSelf = weakSelf;
            resolve(strongSelf);
        }];
        newPromise.thenBlock = thenBlock;
        return newPromise;
    };
}

- (FWPromise *(^)(FWRejectBlock))catch
{
    __weak FWPromise *weakSelf = self;
    return ^FWPromise *(FWRejectBlock catchBlock) {
        __weak FWPromise *newPromise = nil;
        newPromise = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            __strong FWPromise *strongSelf = weakSelf;
            resolve(strongSelf);
        }];
        newPromise.catchBlock = catchBlock;
        return newPromise;
    };
}

- (void (^)(dispatch_block_t))finally
{
    __weak FWPromise *weakSelf = self;
    return ^(dispatch_block_t runBlock) {
        __weak FWPromise *newPromise = nil;
        newPromise = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(weakSelf);
        }];
        newPromise.thenBlock = ^id(id value) {
            runBlock();
            return nil;
        };
        newPromise.catchBlock = ^(NSError *error) {
            runBlock();
        };
    };
}

- (FWPromise *(^)(FWProgressBlock))progress
{
    __weak FWPromise *weakSelf = self;
    return ^FWPromise *(FWProgressBlock ratioBlock){
        weakSelf.ratioBlock = ratioBlock;
        return weakSelf;
    };
}

+ (FWPromise *)progress:(FWProgressPromiseBlock)block
{
    FWPromise *promise = [[FWPromise alloc] initWithBlock:nil];
    __weak FWPromise *weakPromise = promise;
    promise.progressBlock = ^(double ratio, id value) {
        __strong FWPromise *strongPromise = weakPromise;
        if (strongPromise.state != FWPromiseStatePending) {
            return;
        }
        
        if (strongPromise.ratioBlock) {
            strongPromise.ratioBlock(ratio, value);
        }
    };
    
    promise.promiseBlock = ^(FWResolveBlock resolve, FWRejectBlock reject) {
        block(resolve, reject, weakPromise.progressBlock);
    };
    
    if (promise.promiseBlock) {
        promise.promiseBlock(promise.resolveBlock, promise.rejectBlock);
    }
    return promise;
}

+ (FWPromise *)timer:(NSTimeInterval)interval
{
    return [self promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            resolve(@(interval));
        });
    }];
}

- (FWPromise *(^)(NSTimeInterval))timeout
{
    __weak FWPromise *weakSelf = self;
    return ^FWPromise *(NSTimeInterval interval) {
        __weak FWPromise *newPromise = [FWPromise race:[NSArray arrayWithObjects:weakSelf, [FWPromise timer:interval], nil]];
        return newPromise;
    };
}

- (FWPromise *(^)(NSUInteger))retry
{
    __weak FWPromise *weakSelf = self;
    return ^FWPromise *(NSUInteger retryCount) {
        FWPromise *newPromise = nil;
        newPromise = [[FWPromise alloc] initWithBlock:^(FWResolveBlock resolve, FWRejectBlock reject) {
            __strong FWPromise *strongSelf = weakSelf;
            resolve(strongSelf);
        }];
        
        __weak FWPromise *weakPromise = newPromise;
        newPromise.stateBlock = ^(FWPromise *object, FWPromiseState state) {
            __strong FWPromise *strongPromise = weakPromise;
            
            if (state == FWPromiseStateRejected) {
                if (strongPromise.catchBlock) {
                    strongPromise.catchBlock(object.error);
                } else {
                    strongPromise.rejectBlock(object.error);
                }
            } else if (state == FWPromiseStateResolved) {
                strongPromise.retryValue = object.value;
                strongPromise.retryCount = 0;
                if (strongPromise.thenBlock) {
                    id value = strongPromise.thenBlock(object.value);
                    strongPromise.thenBlock = nil;
                    if (value && [value isKindOfClass:[NSError class]]) {
                        if (strongPromise.catchBlock) {
                            strongPromise.catchBlock(value);
                            strongPromise.resolveBlock(nil);
                        } else {
                            strongPromise.rejectBlock(value);
                        }
                    } else {
                        strongPromise.resolveBlock(value);
                    }
                } else {
                    strongPromise.resolveBlock(object.value);
                }
            }
        };
        
        BOOL thenBlock = NO;
        id block = weakSelf.promiseBlock;
        if (weakSelf.thenBlock != nil) {
            block = weakSelf.thenBlock;
            thenBlock = YES;
        }
        
        newPromise.catchBlock = ^(NSError *error){
            if (weakPromise.retryCount++ < retryCount){
                if (thenBlock) {
                    @autoreleasepool {
                        __weak FWPromise *retryPromise = nil;
                        retryPromise = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
                            id value = ((FWThenBlock)block)(weakSelf.retryValue);
                            if (value && [value isKindOfClass:[NSError class]]) {
                                reject(value);
                            } else {
                                resolve(value);
                            }
                        }];
                        weakPromise.resolveBlock(retryPromise);
                    }
                } else {
                    FWPromise *retryPromise = nil;
                    retryPromise = [FWPromise promise:block];
                    weakPromise.resolveBlock(retryPromise);
                }
            } else {
                weakPromise.rejectBlock(error);
            }
        };
        return newPromise;
    };
}

+ (FWPromise *)all:(NSArray<FWPromise *> *)promises
{
    FWPromise *promise = [[FWPromise alloc] initWithBlock:nil];
    promise.promises = [NSMutableSet set];
    promise.values = [NSMutableArray array];
    __weak FWPromise *weakPromise = promise;
    promise.stateBlock = ^(FWPromise *object, FWPromiseState state) {
        __strong FWPromise *strongPromise = weakPromise;
        
        [strongPromise.promises removeObject:object];
        if (state == FWPromiseStateRejected) {
            [strongPromise.promises enumerateObjectsUsingBlock:^(FWPromise *obj, BOOL *stop) {
                [obj fwUnobserveProperty:@"state" target:strongPromise action:@selector(state:change:)];
            }];
            strongPromise.rejectBlock(object.error);
        } else if (state == FWPromiseStateResolved) {
            [strongPromise.values addObject:object.value];
        }
        
        if (strongPromise.promises.count == 0) {
            strongPromise.resolveBlock(strongPromise.values);
        }
    };
    [promises enumerateObjectsUsingBlock:^(FWPromise *obj, NSUInteger idx, BOOL *stop) {
        [obj fwObserveProperty:@"state" target:promise action:@selector(state:change:)];
        if (obj.state == FWPromiseStatePending) {
            [promise.promises addObject:obj];
        }
    }];
    return promise;
}

+ (FWPromise *)race:(NSArray<FWPromise *> *)promises
{
    FWPromise *promise = [[FWPromise alloc] initWithBlock:nil];
    promise.promises = [NSMutableSet set];
    promise.values = [NSMutableArray array];
    __weak FWPromise *weakPromise = promise;
    promise.stateBlock = ^(FWPromise *object, FWPromiseState state) {
        __strong FWPromise *strongPromise = weakPromise;
        
        [strongPromise.promises removeObject:object];
        if (state == FWPromiseStateRejected) {
            [strongPromise.values addObject:object.error];
            if (strongPromise.promises.count == 0) {
                strongPromise.rejectBlock(object.error);
            }
        } else if (state == FWPromiseStateResolved) {
            [strongPromise.promises enumerateObjectsUsingBlock:^(FWPromise *obj, BOOL *stop) {
                [obj fwUnobserveProperty:@"state" target:strongPromise action:@selector(state:change:)];
            }];
            strongPromise.resolveBlock(object.value);
        }
    };
    [promises enumerateObjectsUsingBlock:^(FWPromise *obj, NSUInteger idx, BOOL *stop) {
        [obj fwObserveProperty:@"state" target:promise action:@selector(state:change:)];
        if (obj.state == FWPromiseStatePending) {
            [promise.promises addObject:obj];
        }
    }];
    return promise;
}

@end
