/*!
 @header     FWIterator.h
 @indexgroup FWFramework
 @brief      FWIterator
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019-09-20
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FWResult;
@class FWIterator;
@class FWAsyncEpilog;

id _Nullable fw_yield(id _Nullable value);
FWResult * fw_await(id _Nullable value);
FWAsyncEpilog * fw_async(dispatch_block_t block);

typedef id _Nullable (*FWGenetarorFunc)(id _Nullable);
typedef void (^FWAsyncCallback)(id _Nullable value, id _Nullable error);
typedef void (^FWAsyncClosure)(FWAsyncCallback callback);

/*!
 @brief 生成器和迭代器
 
 @see https://github.com/renjinkui2719/FWIterator
 */
@interface FWIterator : NSObject
{
    int *_ev_leave;
    int *_ev_entry;
    BOOL _ev_entry_valid;
    void *_stack;
    int _stack_size;
    FWIterator * _nest;
    FWGenetarorFunc _func;
    id _target;
    SEL _selector;
    id _block;
    NSMutableArray *_args;
    NSMethodSignature *_signature;
    BOOL _done;
    id _value;
    id _error;
}

- (id)initWithFunc:(FWGenetarorFunc)func arg:(id _Nullable)arg;
- (id)initWithTarget:(id)target selector:(SEL)selector, ...;
- (id)initWithBlock:(id)block, ...;

- (id)initWithTarget:(id)target selector:(SEL)selector args:(NSArray *_Nullable)args;
- (id)initWithBlock:(id _Nullable (^)(id _Nullable))block arg:(id _Nullable)arg;
- (id)initWithStandardBlock:(dispatch_block_t)block;

- (FWResult *)next;
- (FWResult *)next:(id)value;

@end

@protocol FWAsyncClosureCaller <NSObject>

@optional
+ (void)callWithClosure:(id)closure completion:(FWAsyncCallback)completion;

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

typedef void (^FWFinallyConfiger)(dispatch_block_t);

@interface FWAsyncEpilog: NSObject
{
    id _finally_handler;
}

@property (nonatomic, readonly) FWFinallyConfiger finally;

@end

NS_ASSUME_NONNULL_END
