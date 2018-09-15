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

@property (nonatomic, copy) FWPromiseBlock promiseBlock;

@property (nonatomic, copy) FWResolveBlock resolveBlock;

@property (nonatomic, copy) FWRejectBlock rejectBlock;

@property (nonatomic, copy) FWProgressBlock progressBlock;

@property (nonatomic, copy) FWRejectBlock catchBlock;

@property (nonatomic, copy) FWThenBlock thenBlock;

@property (nonatomic, copy) FWProgressBlock ratioBlock;

@property (nonatomic, strong) FWPromise *dependPromise;

@property (nonatomic, strong) id retryValue;

@property (nonatomic, strong) id strongSelf;

@property (nonatomic, strong) NSMutableSet<FWPromise *> *promises;

@property (nonatomic, strong) NSMutableArray *values;

@end

@interface FWAllPromise : FWPromise

@end

@interface FWRacePromise : FWPromise

@end

@interface FWRetryPromise : FWPromise

@end

@implementation FWPromise

+ (FWPromise *)promise:(FWPromiseBlock)block
{
    return [[FWPromise alloc] initWithBlock:block progressBlock:nil promises:nil];
}

+ (FWPromise *)progress:(FWProgressPromiseBlock)block
{
    return [[FWPromise alloc] initWithBlock:nil progressBlock:block promises:nil];
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

- (instancetype)initWithBlock:(FWPromiseBlock)block progressBlock:(FWProgressPromiseBlock)progressBlock promises:(NSArray *)promises
{
    self = [super init];
    if (self) {
        self.state = FWPromiseStatePending;
        self.strongSelf = self;
        
        if (promises) {
            self.promises = [NSMutableSet set];
            self.values = [NSMutableArray array];
            [promises enumerateObjectsUsingBlock:^(FWPromise *promise, NSUInteger idx, BOOL *stop) {
                [promise fwObserveProperty:@"state" target:self action:@selector(onState:change:)];
                if (promise.state == FWPromiseStatePending) {
                    [self.promises addObject:promise];
                }
            }];
        }
        
        __weak FWPromise *weakSelf = self;
        self.resolveBlock = ^(id value) {
            __strong FWPromise *strongSelf = weakSelf;
            if (strongSelf.state != FWPromiseStatePending) {
                return;
            }
            
            if ([value isKindOfClass:[FWPromise class]]) {
                if (((FWPromise *)value).state == FWPromiseStatePending) {
                    strongSelf.dependPromise = value;
                }
                [value fwObserveProperty:@"state" target:strongSelf action:@selector(onState:change:)];
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
        
        if (progressBlock) {
            self.progressBlock = ^(double ratio, id value) {
                __strong FWPromise *strongSelf = weakSelf;
                if (strongSelf.state != FWPromiseStatePending) {
                    return;
                }
                
                if (strongSelf.ratioBlock) {
                    strongSelf.ratioBlock(ratio, value);
                }
            };
            
            self.promiseBlock = ^(FWResolveBlock resolve, FWRejectBlock reject) {
                progressBlock(resolve, reject, weakSelf.progressBlock);
            };
            
            if (self.promiseBlock) {
                self.promiseBlock(self.resolveBlock, self.rejectBlock);
            }
        } else if (block) {
            self.promiseBlock = block;
            
            if (self.promiseBlock) {
                self.promiseBlock(self.resolveBlock, self.rejectBlock);
            }
        }
    }
    return self;
}

- (void)dealloc
{
    self.state = self.state;
    self.dependPromise = nil;
}

- (void)onState:(FWPromise *)promise change:(NSDictionary *)change
{
    FWPromiseState newState = [change[NSKeyValueChangeNewKey] integerValue];
    if (newState == FWPromiseStateRejected) {
        [promise fwUnobserveProperty:@"state" target:self action:@selector(onState:change:)];
        if (self.catchBlock) {
            self.catchBlock(promise.error);
            self.resolveBlock(nil);
        } else {
            self.rejectBlock(promise.error);
        }
    } else if (newState == FWPromiseStateResolved) {
        [promise fwUnobserveProperty:@"state" target:self action:@selector(onState:change:)];
        self.retryValue = promise.value;
        if (self.thenBlock) {
            id value = self.thenBlock(promise.value);
            self.thenBlock = nil;
            if (value && [value isKindOfClass:[NSError class]]) {
                if (self.catchBlock) {
                    self.catchBlock(value);
                    self.resolveBlock(nil);
                } else {
                    self.rejectBlock(value);
                }
            } else {
                self.resolveBlock(value);
            }
        } else {
            self.resolveBlock(promise.value);
        }
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

- (FWPromise *(^)(FWProgressBlock))progress
{
    __weak FWPromise *weakSelf = self;
    return ^FWPromise *(FWProgressBlock ratioBlock){
        weakSelf.ratioBlock = ratioBlock;
        return weakSelf;
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

+ (FWPromise *)all:(NSArray<FWPromise *> *)promises
{
    return [[FWAllPromise alloc] initWithBlock:nil progressBlock:nil promises:promises];
}

+ (FWPromise *)race:(NSArray<FWPromise *> *)promises
{
    return [[FWRacePromise alloc] initWithBlock:nil progressBlock:nil promises:promises];
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
    return ^FWPromise *(NSTimeInterval interval) {
        __weak FWPromise *newPromise = [FWPromise race:[NSArray arrayWithObjects:self, [FWPromise timer:interval], nil]];
        return newPromise;
    };
}

- (FWPromise *(^)(NSUInteger))retry
{
    __weak FWPromise *weakSelf = self;
    return ^FWPromise *(NSUInteger retryCount) {
        FWPromise *newPromise = nil;
        newPromise = [[FWRetryPromise alloc] initWithBlock:^(FWResolveBlock resolve, FWRejectBlock reject) {
            __strong FWPromise *strongSelf = weakSelf;
            resolve(strongSelf);
        } progressBlock:nil promises:nil];
        
        BOOL thenBlock = NO;
        id block = self.promiseBlock;
        if (self.thenBlock != nil) {
            block = self.thenBlock;
            thenBlock = YES;
        }
        
        __weak FWPromise *weakPromise = newPromise;
        newPromise.catchBlock = ^(NSError *error){
            static NSUInteger retried = 0;
            if (retried++ < retryCount){
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

@end

@implementation FWAllPromise

- (void)onState:(FWPromise *)promise change:(NSDictionary *)change
{
    FWPromiseState newState = [change[NSKeyValueChangeNewKey] integerValue];
    [promise fwUnobserveProperty:@"state" target:self action:@selector(onState:change:)];
    [self.promises removeObject:promise];
    if (newState == FWPromiseStateRejected) {
        [self.promises enumerateObjectsUsingBlock:^(FWPromise *obj, BOOL *stop) {
            [obj fwUnobserveProperty:@"state" target:self action:@selector(onState:change:)];
        }];
        self.rejectBlock(promise.error);
    } else if (newState == FWPromiseStateResolved) {
        [self.values addObject:promise.value];
    }
    
    if (self.promises.count == 0) {
        self.resolveBlock(self.values);
    }
}

@end

@implementation FWRacePromise

- (void)onState:(FWPromise *)promise change:(NSDictionary *)change
{
    FWPromiseState newState = [change[NSKeyValueChangeNewKey] integerValue];
    [promise fwUnobserveProperty:@"state" target:self action:@selector(onState:change:)];
    [self.promises removeObject:promise];
    if (newState == FWPromiseStateRejected) {
        [self.values addObject:promise.error];
        if (self.promises.count == 0) {
            self.rejectBlock(promise.error);
        }
    } else if (newState == FWPromiseStateResolved) {
        [self.promises enumerateObjectsUsingBlock:^(FWPromise *obj, BOOL *stop) {
            [obj fwUnobserveProperty:@"state" target:self action:@selector(onState:change:)];
        }];
        self.resolveBlock(promise.value);
    }
}

@end

@implementation FWRetryPromise

- (void)onState:(FWPromise *)promise change:(NSDictionary *)change
{
    FWPromiseState newState = [change[NSKeyValueChangeNewKey] integerValue];
    if (newState == FWPromiseStateRejected) {
        [promise fwUnobserveProperty:@"state" target:self action:@selector(onState:change:)];
        if (self.catchBlock) {
            self.catchBlock(promise.error);
        } else {
            self.rejectBlock(promise.error);
        }
    } else if (newState == FWPromiseStateResolved) {
        [super onState:promise change:change];
    }
}

@end

#import "FWTest.h"

#if FW_TEST

FWTestCase(FWFramework, FWPromise)

FWTestSetUp() {}

FWTest(lifecycle)
{
    __weak id object = nil;
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        }];
        object = p1;
    }
    FWTestAssert(object != nil);
    
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(nil);
        }];
        object = p1;
    }
    FWTestAssert(object == nil);
}

FWTest(then)
{
    NSString *expected = @"expected";
    __block NSString *result = nil;
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(expected);
        }];
        p1.then(^id(id value){
            result = value;
            return @"Done";
        });
    }
    FWTestAssert([expected isEqualToString:result]);
    
    result = nil;
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(@"1");
        }];
        p1.then(^id(NSString *value){
            return [value stringByAppendingString:@"2"];
        }).then(^id(NSString *value){
            return [value stringByAppendingString:@"3"];
        }).then(^id(NSString *value){
            result = value;
            return nil;
        });
    }
    FWTestAssert([result isEqualToString:@"123"]);
    
    result = nil;
    @autoreleasepool {
        FWPromise* p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(@"1");
        }];
        p1.then(^id(NSString* value){
            result = value;
            FWPromise* p2 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
                resolve(@"2");
            }];
            return p2;
        }).then(^id(NSString *value){
            result = [result stringByAppendingString:value];
            return nil;
        });
    }
    FWTestAssert([result isEqualToString:@"12"]);
}

FWTest(catch)
{
    __block NSError *err = nil;
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            reject([NSError errorWithDomain:@"test" code:0 userInfo:nil]);
        }];
        p1.catch(^(NSError *error){
            err = error;
        });
    }
    FWTestAssert([err.domain isEqualToString:@"test"]);
    
    err = nil;
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            reject([NSError errorWithDomain:@"test" code:0 userInfo:nil]);
        }];
        p1.then(^id(NSString* value){
            return [value stringByAppendingString:@"2"];
        }).then(^id(NSString* value){
            return [value stringByAppendingString:@"3"];
        }).catch(^(NSError *error){
            err = error;
        });
    }
    FWTestAssert([err.domain isEqualToString:@"test"]);
    
    err = nil;
    __block id res = @"Not nil";
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            reject([NSError errorWithDomain:@"test" code:0 userInfo:nil]);
        }];
        p1.then(^id(NSString* value){
            return [value stringByAppendingString:@"2"];
        }).catch(^(NSError *error){
            err = error;
        }).then(^id(id value){
            res = value;
            return nil;
        });
    }
    FWTestAssert([err.domain isEqualToString:@"test"]);
    FWTestAssert(res == nil);
    
    err = nil;
    @autoreleasepool {
        FWPromise* p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(nil);
        }];
        p1.then(^id(id value){
            return [FWPromise reject:[NSError errorWithDomain:@"test" code:0 userInfo:nil]];
        }).catch(^(NSError* error){
            err = error;
        });
    }
    FWTestAssert(err != nil);
    
    err = nil;
    @autoreleasepool {
        FWPromise* p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(nil);
        }];
        p1.then(^id(id value){
            return [NSError errorWithDomain:@"test" code:0 userInfo:nil];
        }).catch(^(NSError *error){
            err = error;
        });
    }
    FWTestAssert(err != nil);
}

FWTest(finally)
{
    __block id result = nil;
    @autoreleasepool {
        [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(@"1");
        }].then(^id(id value){
            result = value;
            return nil;
        }).catch(^(NSError *error){
            
        }).finally(^{
            result = @"finally";
        });
    }
    FWTestAssert([result isEqualToString:@"finally"]);
    
    result = nil;
    @autoreleasepool {
        [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            reject(nil);
        }].then(^id(id value){
            result = value;
            return nil;
        }).catch(^(NSError *error){
            
        }).finally(^{
            result = @"finally";
        });
    }
    FWTestAssert([result isEqualToString:@"finally"]);
}

- (FWPromise *)promiseTask:(NSInteger)value
{
    return [FWPromise progress:^(FWResolveBlock resolve, FWRejectBlock reject, FWProgressBlock progress) {
        __block NSInteger result = value;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            for (int i = 0; i < 10; i++) {
                result += i;
                progress(i / 10.f, @(i));
            }
            resolve(@(result));
        });
    }];
}

FWTest(progress)
{
    __block NSMutableArray *res = @[].mutableCopy;
    @autoreleasepool {
        FWPromise *p = [FWPromise progress:^(FWResolveBlock resolve, FWRejectBlock reject, FWProgressBlock progress) {
        }];
        p.progress(^(double ratio, id value){
            [res addObject:value];
        }).then(^id(id value){
            [res addObject:value];
            return nil;
        });
        [p progress:0.f value:@1];
        [p progress:1.f value:@2];
        [p resolve:@3];
    }
    FWTestAssert([res[0] isEqualToNumber:@1]);
    FWTestAssert([res[1] isEqualToNumber:@2]);
    FWTestAssert([res[2] isEqualToNumber:@3]);
    
    __block NSInteger result = 0;
    __block double prog = 0;
    @autoreleasepool {
        FWPromise *p1 = [self promiseTask:result];
        p1.progress(^(double ratio, id value){
            prog = ratio;
        }).then(^id(id value){
            result = [value integerValue];
            return nil;
        });
    }
    [NSThread sleepForTimeInterval:0.5];
    FWTestAssert(result == 45);
    FWTestAssert(prog > 0 && prog <= 1.0);
}

FWTest(timer)
{
    __weak id object = nil;
    @autoreleasepool {
        FWPromise* p1 = [FWPromise timer:1];
        p1.then(^id(NSString* value){
            return nil;
        });
        object = p1;
    }
    FWTestAssert(object != nil);
    
    [NSThread sleepForTimeInterval:1.5];
    FWTestAssert(object == nil);
}

FWTest(timeout)
{
    __block id result = nil;
    [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        
    }].timeout(3).then(^id(id value){
        result = value;
        return nil;
    });
    FWTestAssert(result == nil);
    [NSThread sleepForTimeInterval:4];
    FWTestAssert([result isEqual:@(3)]);
}

FWTest(all)
{
    __block id result = nil;
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(@"1");
        }];
        FWPromise *p2 = [FWPromise timer:1];
        FWPromise *p3 = [FWPromise timer:2];
        [FWPromise all:@[p1,p2,p3]].then(^id(NSArray* values){
            result = values;
            return nil;
        });
    }
    [NSThread sleepForTimeInterval:3];
    FWTestAssert([result[0] isEqualToString:@"1"]);
    FWTestAssert([result[1] isEqualToNumber:@1]);
    FWTestAssert([result[2] isEqualToNumber:@2]);
    
    result = nil;
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            reject([NSError errorWithDomain:@"test" code:0 userInfo:@{NSLocalizedDescriptionKey: @"on purpose"}]);
        }];
        FWPromise *p2 = [FWPromise timer:1];
        FWPromise *p3 = [FWPromise timer:2];
        [FWPromise all:@[p1,p2,p3]].then(^id(NSArray* values){
            result = values;
            return nil;
        }).catch(^(NSError* error){
            result = error;
        });
    }
    [NSThread sleepForTimeInterval:3];
    FWTestAssert([result isKindOfClass:[NSError class]]);
    FWTestAssert([((NSError *)result).localizedDescription isEqualToString:@"on purpose"]);
}

FWTest(race)
{
    __block id result = nil;
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(@"1");
        }];
        FWPromise *p2 = [FWPromise timer:1];
        FWPromise *p3 = [FWPromise timer:2];
        [FWPromise race:@[p1,p2,p3]].then(^id(id value){
            result = value;
            return nil;
        });
    }
    [NSThread sleepForTimeInterval:3];
    FWTestAssert([(NSString*)result isEqualToString:@"1"]);
    
    result = nil;
    @autoreleasepool {
        FWPromise *p2 = [FWPromise timer:1].then(^id (id value){
            return @"2";
        });
        FWPromise *p3 = [FWPromise timer:2].then(^id (id value){
            return @"3";
        });
        [FWPromise race:@[p2,p3]].then(^id(id value){
            result = value;
            return nil;
        });
    }
    [NSThread sleepForTimeInterval:3];
    FWTestAssert([(NSString*)result isEqualToString:@"2"]);
    
    result = nil;
    @autoreleasepool {
        FWPromise *p1 = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            reject([NSError errorWithDomain:@"test" code:0 userInfo:@{NSLocalizedDescriptionKey: @"1"}]);
        }];
        FWPromise *p2 = [FWPromise timer:1].then(^id (id value){
            return [NSError errorWithDomain:@"test" code:0 userInfo:@{NSLocalizedDescriptionKey: @"1"}];
        });
        FWPromise *p3 = [FWPromise timer:2].then(^id (id value){
            return [NSError errorWithDomain:@"test" code:0 userInfo:@{NSLocalizedDescriptionKey: @"1"}];
        });
        [FWPromise race:@[p1,p2,p3]].then(^id(id value){
            result = value;
            return nil;
        }).catch(^(NSError* error){
            result = error;
        });
    }
    [NSThread sleepForTimeInterval:3];
    FWTestAssert([result isKindOfClass:[NSError class]]);
}

FWTest(retry)
{
    NSUInteger retryCount = 3;
    __block NSMutableArray *res = @[].mutableCopy;
    __block id final = nil;
    @autoreleasepool {
        [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            static NSUInteger triedCount = 0;
            triedCount++;
            [res addObject:@(triedCount)];
            if (triedCount == retryCount) {
                resolve(@"ahha");
            }else{
                reject([NSError errorWithDomain:@"test" code:0 userInfo:@{NSLocalizedDescriptionKey: @"needRetry"}]);
            }
        }]
        .retry(retryCount)
        .then(^id(id value){
            final = value;
            return nil;
        });
    }
    FWTestAssert(res.count == retryCount);
    FWTestAssert([final isEqualToString:@"ahha"]);
    
    retryCount = 3;
    res = @[].mutableCopy;
    final = nil;
    @autoreleasepool {
        [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            static NSUInteger triedCount = 0;
            triedCount++;
            [res addObject:@(triedCount)];
            reject([NSError errorWithDomain:@"test" code:0 userInfo:@{NSLocalizedDescriptionKey: @"needRetry"}]);
        }]
        .retry(retryCount)
        .then(^id(id value){
            final = value;
            return nil;
        })
        .catch(^(NSError* e){
            final = e;
        });
    }
    FWTestAssert(res.count == retryCount + 1);
    FWTestAssert([final isKindOfClass:[NSError class]]);
    
    retryCount = 3;
    res = @[].mutableCopy;
    final = nil;
    @autoreleasepool {
        [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
            resolve(@"1");
        }]
        .then(^id(id value){
            static NSUInteger triedCount = 0;
            triedCount++;
            [res addObject:[value copy]];
            if (triedCount == retryCount) {
                return @"hola";
            }else{
                return [NSError errorWithDomain:@"test" code:0 userInfo:@{NSLocalizedDescriptionKey: @"needRetry"}];
            }
        })
        .retry(retryCount)
        .then(^id(id value){
            final = value;
            return nil;
        })
        .catch(^(NSError* e){
            final = e;
        });
    }
    FWTestAssert(res.count == retryCount);
    FWTestAssert([final isEqualToString:@"hola"]);
}

FWTestTearDown() {}

FWTestCaseEnd()

#endif
