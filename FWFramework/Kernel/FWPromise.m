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

@property (nonatomic, copy) FWResolveBlock resolveBlock;

@property (nonatomic, copy) FWRejectBlock rejectBlock;

@property (nonatomic, copy) FWPromiseBlock promiseBlock;

@property (nonatomic, copy) FWRejectBlock catchBlock;

@property (nonatomic, copy) FWThenBlock thenBlock;

// 循环引用自身，防止自动释放
@property (nonatomic, strong) id strongSelf;

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
        self.resolveBlock = ^(id value) {
            __strong FWPromise *strongSelf = weakSelf;
            if (strongSelf.state != FWPromiseStatePending) {
                return;
            }
            
            if ([value isKindOfClass:[FWPromise class]]) {
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

+ (FWPromise *)timer:(NSTimeInterval)interval
{
    return [self promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            resolve(@(interval));
        });
    }];
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

FWTestTearDown() {}

FWTestCaseEnd()

#endif
