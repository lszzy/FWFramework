/*!
 @header     FWCoroutine.h
 @indexgroup FWFramework
 @brief      FWCoroutine
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019-09-20
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FWResult;
@class FWCoroutine;
@class FWCoroutineEpilog;

id _Nullable fw_yield(id _Nullable value);
FWResult * fw_await(id _Nullable value);
FWCoroutineEpilog * fw_async(dispatch_block_t block);

typedef id _Nullable (*FWGeneratorFunc)(id _Nullable);
typedef void (^FWCoroutineCallback)(id _Nullable value, id _Nullable error);
typedef void (^FWCoroutineClosure)(FWCoroutineCallback callback);

/*!
 @brief 协程类，兼容FWPromise
 
 @see https://github.com/renjinkui2719/RJIterator
 */
@interface FWCoroutine : NSObject
{
    int *_ev_leave;
    int *_ev_entry;
    BOOL _ev_entry_valid;
    void *_stack;
    int _stack_size;
    FWCoroutine * _nest;
    FWGeneratorFunc _func;
    id _target;
    SEL _selector;
    id _block;
    NSMutableArray *_args;
    NSMethodSignature *_signature;
    BOOL _done;
    id _value;
    id _error;
}

- (id)initWithFunc:(FWGeneratorFunc)func arg:(id _Nullable)arg;
- (id)initWithTarget:(id)target selector:(SEL)selector, ...;
- (id)initWithBlock:(id)block, ...;

- (id)initWithTarget:(id)target selector:(SEL)selector args:(NSArray *_Nullable)args;
- (id)initWithBlock:(id _Nullable (^)(id _Nullable))block arg:(id _Nullable)arg;
- (id)initWithStandardBlock:(dispatch_block_t)block;

- (FWResult *)next;
- (FWResult *)next:(id)value;

@end

@protocol FWCoroutineClosureCaller <NSObject>

@optional
+ (void)callWithClosure:(id)closure completion:(FWCoroutineCallback)completion;

@end

@interface FWResult: NSObject
{
    id _value;
    BOOL _done;
}

@property (nullable, nonatomic, strong, readonly) id value;
@property (nullable, nonatomic, strong, readonly) id error;
@property (nonatomic, readonly) BOOL done;

+ (instancetype)resultWithValue:(id _Nullable)value error:(id _Nullable)error done:(BOOL)done;

@end

typedef void (^FWFinallyHandler)(dispatch_block_t);

@interface FWCoroutineEpilog: NSObject
{
    id _finally_handler;
}

@property (nonatomic, readonly) FWFinallyHandler finally;

@end

NS_ASSUME_NONNULL_END
