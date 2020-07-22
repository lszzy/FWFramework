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

#pragma mark - FWPromise

typedef NS_ENUM(NSInteger, FWPromiseState) {
    FWPromiseStatePending = 0,
    FWPromiseStateResolved,
    FWPromiseStateRejected,
};

@interface FWPromise ()

@property (nonatomic, strong) id value;

@property (nonatomic, strong) id error;

@property (atomic, assign) FWPromiseState state;

@property (nonatomic, copy) void (^stateBlock)(FWPromise *object, FWPromiseState state);

@property (nonatomic, copy) FWPromiseBlock promiseBlock;

@property (nonatomic, copy) FWResolveBlock resolveBlock;

@property (nonatomic, copy) FWRejectBlock rejectBlock;

@property (nonatomic, copy) FWProgressBlock progressBlock;

@property (nonatomic, copy) FWRejectBlock catchBlock;

@property (nonatomic, copy) FWThenBlock thenBlock;

@property (nonatomic, copy) FWProgressBlock percentBlock;

@property (nonatomic, strong) FWPromise *dependPromise;

@property (nonatomic, strong) id strongSelf;

@property (nonatomic, strong) id retryValue;

@property (nonatomic, assign) NSInteger retryCount;

@property (nonatomic, strong) NSMutableSet<FWPromise *> *promises;

@property (nonatomic, strong) NSMutableArray *values;

@end

@implementation FWPromise

+ (FWPromise *)promise
{
    return [[FWPromise alloc] init];
}

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

+ (FWPromise *)reject:(id)error
{
    return [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        reject(error);
    }];
}

- (instancetype)init
{
    return [self initWithBlock:nil];
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
        
        self.rejectBlock = ^(id error) {
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

- (void)reject:(id)error
{
    self.rejectBlock(error);
}

- (void)progress:(id)percent
{
    if (self.percentBlock) {
        self.percentBlock(percent);
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

- (FWPromise *(^)(FWResolveBlock))done
{
    __weak FWPromise *weakSelf = self;
    return ^FWPromise *(FWResolveBlock resolveBlock) {
        __weak FWPromise *newPromise = nil;
        newPromise = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            __strong FWPromise *strongSelf = weakSelf;
            resolve(strongSelf);
        }];
        newPromise.thenBlock = ^id(id value) {
            resolveBlock(value);
            return nil;
        };
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
        newPromise.catchBlock = ^(id error) {
            runBlock();
        };
    };
}

- (FWPromise *(^)(FWProgressBlock))progress
{
    __weak FWPromise *weakSelf = self;
    return ^FWPromise *(FWProgressBlock percentBlock){
        weakSelf.percentBlock = percentBlock;
        return weakSelf;
    };
}

+ (FWPromise *)progress:(FWProgressPromiseBlock)block
{
    FWPromise *promise = [[FWPromise alloc] initWithBlock:nil];
    __weak FWPromise *weakPromise = promise;
    promise.progressBlock = ^(id percent) {
        __strong FWPromise *strongPromise = weakPromise;
        if (strongPromise.state != FWPromiseStatePending) {
            return;
        }
        
        if (strongPromise.percentBlock) {
            strongPromise.percentBlock(percent);
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
        
        newPromise.catchBlock = ^(id error){
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

#ifdef DEBUG

#pragma mark - Test

#import "FWTest.h"
#import "FWCoroutine.h"

@interface FWTestCase_FWPromise : FWTestCase

@end

@implementation FWTestCase_FWPromise

- (void)testPromise
{
    __block NSNumber *result = nil;
    FWPromise *promise = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        dispatch_queue_t queue = dispatch_queue_create("FWTestCase_FWPromise", NULL);
        dispatch_async(queue, ^{
            [NSThread sleepForTimeInterval:0.1];
            resolve(@1);
        });
    }];
    promise.then(^id(NSNumber *value) {
        return [FWPromise resolve:@(value.integerValue + 1)];
    }).done(^(id  _Nullable value) {
        result = value;
    }).finally(^{
        FWAssertTrue(result.integerValue == 2);
    });
    
    result = nil;
    promise = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        resolve(@1);
    }];
    promise.then(^id(NSNumber *value) {
        return [FWPromise reject:nil];
    }).then(^id(id value) {
        result = value;
        return nil;
    }).catch(^(id error) {
        result = nil;
    }).finally(^{
        FWAssertTrue(result == nil);
    });
}

- (FWCoroutineClosure)login:(NSString *)account pwd:(NSString *)pwd
{
    return ^(FWCoroutineCallback callback){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([account isEqualToString:@"test"] && [pwd isEqualToString:@"123"]) {
                callback(@{@"uid": @"1", @"token": @"token"}, nil);
            } else {
                callback(nil, [NSError errorWithDomain:@"FWTest" code:1 userInfo:nil]);
            }
        });
    };
}

- (FWPromise *)query:(NSString *)uid token:(NSString *)token
{
    return [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([uid isEqualToString:@"1"] && [token isEqualToString:@"token"]) {
                resolve(@{@"name": @"test"});
            } else {
                reject([NSError errorWithDomain:@"FWTest" code:2 userInfo:nil]);
            }
        });
    }];
}

- (void)testCoroutine
{
    __block NSInteger value = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    fw_async(^{
        FWResult *result = nil;
        
        result = fw_await([self login:@"test" pwd:@"123"]);
        FWAssertTrue(!result.error);
        
        NSDictionary *user = result.value;
        value = [user[@"uid"] integerValue];
        FWAssertTrue([user[@"uid"] isEqualToString:@"1"]);
        
        result = fw_await([self query:user[@"uid"] token:user[@"token"]]);
        FWAssertTrue(!result.error);
        
        NSDictionary *info = result.value;
        FWAssertTrue([info[@"name"] isEqualToString:@"test"]);
        
        result = fw_await([self login:@"test" pwd:@""]);
        FWAssertTrue(result.error);
    }).finally(^{
        value++;
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    FWAssertTrue(value == 2);
}

@end

#endif
