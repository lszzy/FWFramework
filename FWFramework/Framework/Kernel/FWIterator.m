/*!
 @header     FWIterator.m
 @indexgroup FWFramework
 @brief      FWIterator
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019-09-20
 */

#import "FWIterator.h"
#import "FWPromise.h"
#import "FWProxy.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <setjmp.h>
#import <pthread.h>

#if __has_feature(objc_arc)
#error FWIterator Must be compiled with MRC
#endif

#define DEFAULT_STACK_SIZE (256 * 1024)
#define JMP_CONTINUE 1
#define JMP_DONE 2

#define is_null(arg) (!(arg) || [(arg) isKindOfClass:NSNull.self])
#define arg_or_nil(arg) (is_null(arg) ? nil : arg)

#pragma mark - FWAsyncEpilog

@interface FWAsyncEpilog()
@property (nonatomic, copy) dispatch_block_t finally_hanler;
- (void)do_finally;
@end

@implementation FWAsyncEpilog
@synthesize finally_hanler = _finally_handler;

- (FWFinallyConfiger)finally {
    FWFinallyConfiger configer = ^(dispatch_block_t handler){
        self.finally_hanler = handler;
    };
    return [[(id)configer copy] autorelease];
}

- (void)dealloc {
    if (_finally_handler) {
        Block_release(_finally_handler);
    }
    [super dealloc];
}

- (void)do_finally {
    if (_finally_handler) {
        ((dispatch_block_t)_finally_handler)();
    }
}

@end

#pragma mark - FWResult

@implementation FWResult
@synthesize value = _value;
@synthesize done = _done;

- (id)initWithValue:(id)value error:(id)error done:(BOOL)done {
    if (self = [super init]) {
        _value = [value retain];
        _error = [error retain];
        _done = done;
    }
    return self;
}

- (void)dealloc {
    [_value release];
    [_error release];
    [super dealloc];
}

+ (instancetype)resultWithValue:(id)value error:(id)error done:(BOOL)done{
    return [[[self alloc] initWithValue:value error:error done:done] autorelease];
}
@end

#pragma mark - FWIteratorStack

static pthread_key_t iterator_stack_key;
static void destroy_iterator_stack(void * stack) {
    CFRelease((CFArrayRef)stack);
}

@interface FWIteratorStack: NSObject
+ (void)push:(FWIterator *)iterator;
+ (FWIterator *)pop;
+ (FWIterator *)top;
@end

@implementation FWIteratorStack
+ (void)load {
    pthread_key_create(&iterator_stack_key, destroy_iterator_stack);
}

+ (void)push:(FWIterator *)iterator {
    CFMutableArrayRef stack = pthread_getspecific(iterator_stack_key);
    if (!stack) {
        stack = CFArrayCreateMutable(kCFAllocatorSystemDefault, 16, &kCFTypeArrayCallBacks);
        pthread_setspecific(iterator_stack_key, (void *)stack);
    }
    CFArrayAppendValue(stack, (void *)iterator);
}

+ (FWIterator *)pop {
    CFMutableArrayRef stack = pthread_getspecific(iterator_stack_key);
    CFIndex count = stack ? CFArrayGetCount(stack) : 0;
    if (count > 0) {
        FWIterator *iterator = (FWIterator *)CFArrayGetValueAtIndex(stack, count - 1);
        [iterator retain];
        CFArrayRemoveValueAtIndex(stack, count - 1);
        return iterator.autorelease;
    }
    return nil;
}

+ (FWIterator *)top {
    CFMutableArrayRef stack = pthread_getspecific(iterator_stack_key);
    CFIndex count = stack ? CFArrayGetCount(stack) : 0;
    if (count > 0) {
        FWIterator *iterator = (FWIterator *)CFArrayGetValueAtIndex(stack, count - 1);
        return iterator;
    }
    return nil;
}
@end

#pragma mark - FWIterator

@interface FWIterator() <FWAsyncClosureCaller>
@property (nonatomic, strong) FWIterator * nest;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) id error;
@property (nonatomic, assign) BOOL done;
@end

@implementation FWIterator
@synthesize nest = _nest;
@synthesize value = _value;
@synthesize error = _error;
@synthesize done = _done;

- (id)init {
    if (self = [super init]) {
        _stack = malloc(DEFAULT_STACK_SIZE);
        memset(_stack, 0x00, DEFAULT_STACK_SIZE);
        _stack_size = DEFAULT_STACK_SIZE;
        
        _ev_leave = malloc(sizeof(jmp_buf));
        memset(_ev_leave, 0x00, sizeof(jmp_buf));
        _ev_entry = malloc(sizeof(jmp_buf));
        memset(_ev_entry, 0x00, sizeof(jmp_buf));
        
        _args = [NSMutableArray arrayWithCapacity:8].retain;
    }
    return self;
}

- (void)dealloc {
    [_args release];
    [_target release];
    [_signature release];
    [_value release];
    [_error release];
    [_nest release];
    
    if (_stack) {
        free(_stack);
        _stack = NULL;
    }
    if (_ev_leave) {
        free(_ev_leave);
        _ev_leave = NULL;
    }
    if (_ev_entry) {
        free(_ev_entry);
        _ev_entry = NULL;
    }
    
    [super dealloc];
}

- (id)initWithFunc:(FWGenetarorFunc)func arg:(id)arg {
    if (self = [self init]) {
        _func = func;
        [_args addObject:arg ?: NSNull.null];
    }
    return self;
}

- (id)initWithTarget:(id)target selector:(SEL)selector, ... {
    NSAssert(target && selector, @"target and selector must not be nil");
    
    NSMethodSignature *signature = [self.class signatureForTarget:target selector:selector];
    [self.class checkGeneratorSignature:signature];
    
    NSMutableArray *args = [NSMutableArray array];
    va_list ap;
    va_start(ap, selector);
    for (int i=0; i < (int)signature.numberOfArguments - 2; ++i) {
        id arg = va_arg(ap, id);
        [args addObject:arg ?: NSNull.null];
    }
    va_end(ap);
    
    return [self initWithTarget:target selector:selector args:args signature:signature];
}

- (id)initWithTarget:(id)target selector:(SEL)selector args:(NSArray *)args {
    NSAssert(target && selector, @"target and selector must not be nil");
    
    NSMethodSignature *signature = [self.class signatureForTarget:target selector:selector];
    [self.class checkGeneratorSignature:signature];
    
    return [self initWithTarget:target selector:selector args:args signature:signature];
}

- (id)initWithTarget:(id)target selector:(SEL)selector args:(NSArray *)args signature:(NSMethodSignature *)signature {
    if (self = [self init]) {
        _target = [target retain];
        _selector = selector;
        _signature = signature.retain;
        _args = [args copy];
    }
    return self;
}

- (id)initWithBlock:(id)block, ... {
    NSAssert(block, @"block must not be nil");
    
    NSMethodSignature *signature = [FWBlockProxy methodSignatureForBlock:block];
    [self.class checkGeneratorSignature:signature];
    
    NSMutableArray *args = [NSMutableArray array];
    va_list ap;
    va_start(ap, block);
    for (int i=0; i < (int)signature.numberOfArguments - 2; ++i) {
        id arg = va_arg(ap, id);
        [args addObject:arg ?: NSNull.null];
    }
    va_end(ap);
    
    return [self initWithBlock:block args:args signature:signature];
}

- (id)initWithBlock:(id  _Nullable (^)(id _Nullable))block arg:(id)arg {
    NSAssert(block, @"block must not be nil");
    
    NSMethodSignature *signature = [FWBlockProxy methodSignatureForBlock:block];
    [self.class checkGeneratorSignature:signature];
    
    return [self initWithBlock:block args:arg ? @[arg] : @[] signature:signature];
}

- (id)initWithStandardBlock:(dispatch_block_t)block {
    return [self initWithBlock:(id)block arg:nil];
}

- (id)initWithBlock:(id)block args:(NSArray *_Nullable)args signature:(NSMethodSignature *)signature {
    if (self = [self init]) {
        _block = [block copy];
        _signature = signature.retain;
        _args = [args copy];
    }
    return self;
}

+ (NSMethodSignature *)signatureForTarget:(id)target selector:(SEL)selector {
    Method m = NULL;
    // 生成器是类方法
    if (object_isClass(target)) {
        Class cls = (Class)target;
        m = class_getClassMethod(cls, selector);
    // 生成器是实例方法
    } else {
        Class cls = [target class];
        m = class_getInstanceMethod(cls, selector);
    }
    const char *encoding = method_getTypeEncoding(m);
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:encoding];
    return signature;
}

+ (void)checkGeneratorSignature:(NSMethodSignature *)signature{
    // 返回值必须是id或者void
    __unused BOOL ret_valid = signature.methodReturnType[0] == 'v' || signature.methodReturnType[0] == '@';
    NSAssert(ret_valid, @"return type of generator must be id or void");
    BOOL args_valid = YES;
    // 方法调用最多支持8个参数,方法调用默认有第一个参数self(target)，第二个参数_cmd(selector)
    NSAssert(signature.numberOfArguments <= 10, @"arguments count of method must <= 8");
    // 所有参数必须为对象类型
    if (signature.numberOfArguments > 2) {
        for (int i=2; i < signature.numberOfArguments; ++i) {
            if ([signature getArgumentTypeAtIndex:i][0] != '@') {
                args_valid = NO;
                break;
            }
        }
    }
    
    NSAssert(args_valid, @"argument type of generator must all be id");
}

- (FWResult *)next {
    return [self next:nil set_value:NO];
}

- (FWResult *)next:(id)value {
    return [self next:value set_value:YES];
}

- (FWResult *)next:(id)value set_value:(BOOL)set_value {
    if (_done) {
        return [FWResult resultWithValue:_value error:_error done:_done];
    }
    
    [FWIteratorStack push:self];
    
    // 设置跳转返回点
    int leave_value = setjmp(_ev_leave);
    // 非跳转返回
    if (leave_value == 0) {
        // 已经设置了生成器进入点
        if (_ev_entry_valid) {
            // 直接从生成器进入点进入
            if (set_value) {
                self.value = value;
            }
            longjmp(_ev_entry, JMP_CONTINUE);
        } else {
            // wrapper进入。next栈会销毁,所以为wrapper启用新栈
            intptr_t sp = (intptr_t)(_stack + _stack_size);
            // 预留安全空间，防止直接move [sp] 传参 以及msgsend向上访问堆栈
            sp -= 256;
            // 对齐sp
            sp &= ~0x07;
            
#if defined(__arm__)
            asm volatile("mov sp, %0" : : "r"(sp));
#elif defined(__arm64__)
            asm volatile("mov sp, %0" : : "r"(sp));
#elif defined(__i386__)
            asm volatile("movl %0, %%esp" : : "r"(sp));
#elif defined(__x86_64__)
            asm volatile("movq %0, %%rsp" : : "r"(sp));
#endif
            // 在新栈上调用wrapper,至此可以认为wrapper,以及生成器函数的运行栈和next无关
            [self wrapper];
        }
    // 生成器内部跳转返回
    } else if (leave_value == JMP_CONTINUE) {
        // 还可以继续迭代
    // 生成器wrapper跳转返回
    } else if (leave_value == JMP_DONE) {
        //生成器结束，迭代完成
        _done = YES;
    }
    
    [FWIteratorStack pop];

    return [FWResult resultWithValue:_value error:_error done:_done];
}

- (void)wrapper {
    id value = nil;
    if (_func) {
        value = _func(arg_or_nil(_args.firstObject));
    } else if (_target && _selector) {
        id arg0 = _signature.numberOfArguments > 2 ? arg_or_nil(_args[0]) : nil;
        id arg1 = _signature.numberOfArguments > 3 ? arg_or_nil(_args[1]) : nil;
        id arg2 = _signature.numberOfArguments > 4 ? arg_or_nil(_args[2]) : nil;
        id arg3 = _signature.numberOfArguments > 5 ? arg_or_nil(_args[3]) : nil;
        id arg4 = _signature.numberOfArguments > 6 ? arg_or_nil(_args[4]) : nil;
        id arg5 = _signature.numberOfArguments > 7 ? arg_or_nil(_args[5]) : nil;
        id arg6 = _signature.numberOfArguments > 8 ? arg_or_nil(_args[6]) : nil;
        id arg7 = _signature.numberOfArguments > 9 ? arg_or_nil(_args[7]) : nil;
        if (_signature.methodReturnType[0] == 'v') {
            ((void (*)(id, SEL, id, id, id, id, id, id, id, id))objc_msgSend)(_target, _selector,
                                                                              arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7
                                                                              );
            
        } else {
            value = ((id (*)(id, SEL, id, id, id, id, id, id, id, id))objc_msgSend)(_target, _selector,
                                                                                    arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7
                                                                                    );
        }
    } else if (_block) {
        id arg0 = _signature.numberOfArguments > 2 ? arg_or_nil(_args[0]) : nil;
        id arg1 = _signature.numberOfArguments > 3 ? arg_or_nil(_args[1]) : nil;
        id arg2 = _signature.numberOfArguments > 4 ? arg_or_nil(_args[2]) : nil;
        id arg3 = _signature.numberOfArguments > 5 ? arg_or_nil(_args[3]) : nil;
        id arg4 = _signature.numberOfArguments > 6 ? arg_or_nil(_args[4]) : nil;
        id arg5 = _signature.numberOfArguments > 7 ? arg_or_nil(_args[5]) : nil;
        id arg6 = _signature.numberOfArguments > 8 ? arg_or_nil(_args[6]) : nil;
        id arg7 = _signature.numberOfArguments > 9 ? arg_or_nil(_args[7]) : nil;
        
        if (_signature.methodReturnType[0] == 'v') {
            ((void (^)(id, id, id, id, id, id, id, id))_block)(arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7);
        } else {
            value = ((id (^)(id, id, id, id, id, id, id, id))_block)(arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7);
        }
    }
    // 从生成器返回，说明生成器完全执行结束，直接返回到迭代器设置的返回点
    self.value = value;
    
    longjmp(_ev_leave, JMP_DONE);
    // 不会到此
    assert(0);
}

- (id)yield:(id)value {
    id yield_value = value;
    if ([value isKindOfClass:self.class]) {
        // 嵌套的迭代器
        self.nest = (FWIterator *)value;
    }
    
next: {
    FWResult * result = [self.nest next];
    if (result) {
        yield_value = result.value;
    }
    
    _ev_entry_valid = YES;
    if (setjmp(_ev_entry) == 0) {
        self.value = yield_value;
        longjmp(_ev_leave, JMP_CONTINUE);
    }
}
    
    // 嵌套迭代器还可继续
    if (self.nest && !self.nest.done) {
        goto next;
    }
    
    self.nest = nil;
    
    return self.value;
}

@end

id fw_yield(id value) {
    FWIterator *iterator = [FWIteratorStack top];
    return [iterator yield:value];
}

FWResult * fw_await(id _Nullable value) {
    return (FWResult *) fw_yield(value);
}

FWAsyncEpilog * fw_async(dispatch_block_t block) {
    FWIterator *iterator = [[FWIterator alloc] initWithStandardBlock:block];
    FWAsyncEpilog *epilog = [[FWAsyncEpilog alloc] init];
    FWResult * __block result = nil;
    
    dispatch_block_t __block step;
    step = ^{
        if (!result.done) {
            id value = result.value;
            // oc闭包
            if ([value isKindOfClass:NSClassFromString(@"__NSGlobalBlock__")] ||
                [value isKindOfClass:NSClassFromString(@"__NSStackBlock__")] ||
                [value isKindOfClass:NSClassFromString(@"__NSMallocBlock__")]
                ) {
                ((FWAsyncClosure)value)(^(id value, id error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [result release];
                        result = [iterator next:[FWResult resultWithValue:value error:error done:NO]].retain;
                        step();
                    });
                });
            // swift 闭包
            } else if (NSClassFromString(@"__SwiftValue") &&
                     [value isKindOfClass:NSClassFromString(@"__SwiftValue")] &&
                     [[value description] containsString:@"(Function)"]
                     ) {
                [FWIterator callWithClosure:value completion:^(id  _Nullable value, id  _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [result release];
                        result = [iterator next: [FWResult resultWithValue:value error:error done:NO]].retain;
                        step();
                    });
                }];
            // FWPromise
            } else if ([value isKindOfClass:[FWPromise class]]) {
                FWPromise *promise = (FWPromise *)value;
                void (^__block then_block)(id) = NULL;
                void (^__block catch_block)(id) = NULL;
                
                then_block = Block_copy(^(id value){
                    if (then_block) { Block_release(then_block); then_block = NULL; }
                    if (catch_block) { Block_release(catch_block); catch_block = NULL; }
                    
                    [result release];
                    result = [iterator next:[FWResult resultWithValue:value error:nil done:NO]].retain;
                    step();
                });
                
                catch_block = Block_copy(^(id error){
                    if (then_block) { Block_release(then_block); then_block = NULL; }
                    if (catch_block) { Block_release(catch_block); catch_block = NULL; }
                    
                    [result release];
                    result = [iterator next:[FWResult resultWithValue:nil error:error done:NO]].retain;
                    step();
                });
                
                promise.done(then_block).catch(catch_block);
            // 普通对象
            } else {
                FWResult *old_result = result;
                result = [iterator next: old_result].retain;
                [old_result release];
                
                step();
            }
        } else {
            [epilog do_finally];
            
            [epilog release];
            Block_release(step);
            [result release];
            [iterator release];
        }
    };
    
    step =  Block_copy(step);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        result = iterator.next.retain;
        step();
    });
    
    return epilog.retain.autorelease;
}

#ifdef DEBUG

#pragma mark - Test

#import "FWTest.h"
#import "NSObject+FWBlock.h"

@interface FWTestCase_FWIterator : FWTestCase

@end

@implementation FWTestCase_FWIterator

- (FWAsyncClosure)login:(NSString *)account pwd:(NSString *)pwd
{
    return Block_copy(^(FWAsyncCallback callback){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([account isEqualToString:@"test"] && [pwd isEqualToString:@"123"]) {
                callback(@{@"uid": @"1", @"token": @"token"}, nil);
            } else {
                callback(nil, [NSError errorWithDomain:@"FWTest" code:1 userInfo:nil]);
            }
        });
    });
}

- (FWPromise *)query:(NSString *)uid token:(NSString *)token
{
    return [FWPromise promise:^(FWPromiseBlock resolve, FWPromiseBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([uid isEqualToString:@"1"] && [token isEqualToString:@"token"]) {
                resolve(@{@"name": @"test"});
            } else {
                reject([NSError errorWithDomain:@"FWTest" code:2 userInfo:nil]);
            }
        });
    }];
}

- (void)testIterator
{
    __block NSInteger value = 0;
    [self fwSyncPerformAsyncBlock:^(void (^completionHandler)(void)) {
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
            completionHandler();
        });
    }];
    FWAssertTrue(value == 2);
}

@end

#endif
