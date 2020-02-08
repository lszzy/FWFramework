/*!
 @header     FWAspect.m
 @indexgroup FWFramework
 @brief      AOP管理器
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-13
 */

#import "FWAspect.h"
#import <libkern/OSAtomic.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "FWLog.h"

#pragma mark - FWAspectBlock

// 内部block
typedef NS_OPTIONS(int, FWAspectBlockFlags) {
    FWAspectBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    FWAspectBlockFlagsHasSignature          = (1 << 30),
};

typedef struct FWAspectBlock {
    __unused Class isa;
    FWAspectBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct FWAspectBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        // 需要FWAspectBlockHasCopyDisposeHelpers
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        // 需要FWAspectBlockHasSignature
        const char *signature;
        const char *layout;
    } *descriptor;
} *FWAspectBlockRef;

#pragma mark - FWAspectInfo

@interface FWAspectInfo : NSObject <FWAspectInfo>

- (id)initWithInstance:(__unsafe_unretained id)instance invocation:(NSInvocation *)invocation;
@property (nonatomic, unsafe_unretained, readonly) id instance;
@property (nonatomic, strong, readonly) NSArray *arguments;
@property (nonatomic, strong, readonly) NSInvocation *originalInvocation;

@end

#pragma mark - FWAspectIdentifier

// 追踪单个Aspect
@interface FWAspectIdentifier : NSObject

+ (instancetype)identifierWithSelector:(SEL)selector object:(id)object options:(FWAspectOptions)options block:(id)block error:(NSError **)error;
- (BOOL)invokeWithInfo:(id<FWAspectInfo>)info;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) id block;
@property (nonatomic, strong) NSMethodSignature *blockSignature;
@property (nonatomic, weak) id object;
@property (nonatomic, assign) FWAspectOptions options;

@end

#pragma mark - FWAspectContainer

// 追踪类或对象的所有Aspect
@interface FWAspectContainer : NSObject

- (void)addAspect:(FWAspectIdentifier *)aspect withOptions:(FWAspectOptions)injectPosition;
- (BOOL)removeAspect:(id)aspect;
- (BOOL)hasAspects;
@property (atomic, copy) NSArray *beforeAspects;
@property (atomic, copy) NSArray *insteadAspects;
@property (atomic, copy) NSArray *afterAspects;

@end

#pragma mark - FWAspectTracker

@interface FWAspectTracker : NSObject

- (id)initWithTrackedClass:(Class)trackedClass;
@property (nonatomic, strong) Class trackedClass;
@property (nonatomic, readonly) NSString *trackedClassName;
@property (nonatomic, strong) NSMutableSet *selectorNames;
@property (nonatomic, strong) NSMutableDictionary *selectorNamesToSubclassTrackers;
- (void)addSubclassTracker:(FWAspectTracker *)subclassTracker hookingSelectorName:(NSString *)selectorName;
- (void)removeSubclassTracker:(FWAspectTracker *)subclassTracker hookingSelectorName:(NSString *)selectorName;
- (BOOL)subclassHasHookedSelectorName:(NSString *)selectorName;
- (NSSet *)subclassTrackersHookingSelectorName:(NSString *)selectorName;

@end

#pragma mark - NSInvocation+FWAspect

@interface NSInvocation (FWAspect)

- (NSArray *)fwAspectArguments;

@end

#pragma mark - NSObject+FWAspect

// 默认关闭调试日志，只开启错误日志
#define FWAspectLog(...)

// 统一错误处理
#define FWAspectError(errorDescription) \
    do { \
        FWLogError(@"FWAspect: %@", errorDescription); \
        if (error) { *error = [NSError errorWithDomain:@"FWFramework" code:0 userInfo:@{NSLocalizedDescriptionKey: errorDescription}]; } \
    } while(0)

#define FWAspectPositionFilter 0x07

static NSString *const FWAspectSubclassSuffix = @"FWAspect_";
static NSString *const FWAspectMessagePrefix = @"fwaspect_";

@implementation NSObject (FWAspect)

#pragma mark - Public

+ (id<FWAspectToken>)fwHookSelector:(SEL)selector
                          withBlock:(id)block
                            options:(FWAspectOptions)options
                              error:(NSError * __autoreleasing *)error
{
    return fw_aspect_add((id)self, selector, options, block, error);
}

- (id<FWAspectToken>)fwHookSelector:(SEL)selector withBlock:(id)block options:(FWAspectOptions)options error:(NSError * __autoreleasing *)error
{
    return fw_aspect_add(self, selector, options, block, error);
}

#pragma mark - Private

static id fw_aspect_add(id self, SEL selector, FWAspectOptions options, id block, NSError * __autoreleasing *error) {
    NSCParameterAssert(self);
    NSCParameterAssert(selector);
    NSCParameterAssert(block);
    
    __block FWAspectIdentifier *identifier = nil;
    fw_aspect_performLocked(^{
        if (fw_aspect_isSelectorAllowedAndTrack(self, selector, options, error)) {
            FWAspectContainer *aspectContainer = fw_aspect_getContainerForObject(self, selector);
            identifier = [FWAspectIdentifier identifierWithSelector:selector object:self options:options block:block error:error];
            if (identifier) {
                [aspectContainer addAspect:identifier withOptions:options];
                
                // 修改class允许消息拦截
                fw_aspect_prepareClassAndHookSelector(self, selector, error);
            }
        }
    });
    return identifier;
}

static BOOL fw_aspect_remove(FWAspectIdentifier *aspect, NSError * __autoreleasing *error) {
    NSCAssert([aspect isKindOfClass:FWAspectIdentifier.class], @"Must have correct type.");
    
    __block BOOL success = NO;
    fw_aspect_performLocked(^{
        // 强引用
        id self = aspect.object;
        if (self) {
            FWAspectContainer *aspectContainer = fw_aspect_getContainerForObject(self, aspect.selector);
            success = [aspectContainer removeAspect:aspect];
            
            fw_aspect_cleanupHookedClassAndSelector(self, aspect.selector);
            // 释放token
            aspect.object = nil;
            aspect.block = nil;
            aspect.selector = NULL;
        }else {
            NSString *errrorDesc = [NSString stringWithFormat:@"Unable to deregister hook. Object already deallocated: %@", aspect];
            FWAspectError(errrorDesc);
        }
    });
    return success;
}

static void fw_aspect_performLocked(dispatch_block_t block) {
    static OSSpinLock fw_aspect_lock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&fw_aspect_lock);
    block();
    OSSpinLockUnlock(&fw_aspect_lock);
}

static SEL fw_aspect_aliasForSelector(SEL selector) {
    NSCParameterAssert(selector);
    return NSSelectorFromString([FWAspectMessagePrefix stringByAppendingFormat:@"_%@", NSStringFromSelector(selector)]);
}

static NSMethodSignature *fw_aspect_blockMethodSignature(id block, NSError **error) {
    FWAspectBlockRef layout = (__bridge void *)block;
    if (!(layout->flags & FWAspectBlockFlagsHasSignature)) {
        NSString *description = [NSString stringWithFormat:@"The block %@ doesn't contain a type signature.", block];
        FWAspectError(description);
        return nil;
    }
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    if (layout->flags & FWAspectBlockFlagsHasCopyDisposeHelpers) {
        desc += 2 * sizeof(void *);
    }
    if (!desc) {
        NSString *description = [NSString stringWithFormat:@"The block %@ doesn't has a type signature.", block];
        FWAspectError(description);
        return nil;
    }
    const char *signature = (*(const char **)desc);
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

static BOOL fw_aspect_isCompatibleBlockSignature(NSMethodSignature *blockSignature, id object, SEL selector, NSError **error) {
    NSCParameterAssert(blockSignature);
    NSCParameterAssert(object);
    NSCParameterAssert(selector);
    
    BOOL signaturesMatch = YES;
    NSMethodSignature *methodSignature = [[object class] instanceMethodSignatureForSelector:selector];
    if (blockSignature.numberOfArguments > methodSignature.numberOfArguments) {
        signaturesMatch = NO;
    }else {
        if (blockSignature.numberOfArguments > 1) {
            const char *blockType = [blockSignature getArgumentTypeAtIndex:1];
            if (blockType[0] != '@') {
                signaturesMatch = NO;
            }
        }
        // 参数0是self/block，参数1是SEL或者id<AspectInfo>。从参数2开始比较，block可以比method少参数
        if (signaturesMatch) {
            for (NSUInteger idx = 2; idx < blockSignature.numberOfArguments; idx++) {
                const char *methodType = [methodSignature getArgumentTypeAtIndex:idx];
                const char *blockType = [blockSignature getArgumentTypeAtIndex:idx];
                // 只比较参数，而不是可选类型的数据
                if (!methodType || !blockType || methodType[0] != blockType[0]) {
                    signaturesMatch = NO; break;
                }
            }
        }
    }
    
    if (!signaturesMatch) {
        NSString *description = [NSString stringWithFormat:@"Block signature %@ doesn't match %@.", blockSignature, methodSignature];
        FWAspectError(description);
        return NO;
    }
    return YES;
}

static BOOL fw_aspect_isMsgForwardIMP(IMP impl) {
    return impl == _objc_msgForward
#if !defined(__arm64__)
    || impl == (IMP)_objc_msgForward_stret
#endif
    ;
}

static IMP fw_aspect_getMsgForwardIMP(NSObject *self, SEL selector) {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    // 兼容32位处理，检查该方法返回struct或者非id类型
    // https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/LowLevelABI/000-Introduction/introduction.html
    // https://github.com/ReactiveCocoa/ReactiveCocoa/issues/783
    // http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042e/IHI0042E_aapcs.pdf (Section 5.4)
    Method method = class_getInstanceMethod(self.class, selector);
    const char *encoding = method_getTypeEncoding(method);
    BOOL methodReturnsStructValue = encoding[0] == _C_STRUCT_B;
    if (methodReturnsStructValue) {
        @try {
            NSUInteger valueSize = 0;
            NSGetSizeAndAlignment(encoding, &valueSize, NULL);
            
            if (valueSize == 1 || valueSize == 2 || valueSize == 4 || valueSize == 8) {
                methodReturnsStructValue = NO;
            }
        } @catch (__unused NSException *e) {}
    }
    if (methodReturnsStructValue) {
        msgForwardIMP = (IMP)_objc_msgForward_stret;
    }
#endif
    return msgForwardIMP;
}

static void fw_aspect_prepareClassAndHookSelector(NSObject *self, SEL selector, NSError **error) {
    NSCParameterAssert(selector);
    Class klass = fw_aspect_hookClass(self, error);
    Method targetMethod = class_getInstanceMethod(klass, selector);
    IMP targetMethodIMP = method_getImplementation(targetMethod);
    if (!fw_aspect_isMsgForwardIMP(targetMethodIMP)) {
        // 生成已存在方法实现的别名，它不会被拷贝
        const char *typeEncoding = method_getTypeEncoding(targetMethod);
        SEL aliasSelector = fw_aspect_aliasForSelector(selector);
        if (![klass instancesRespondToSelector:aliasSelector]) {
            __unused BOOL addedAlias = class_addMethod(klass, aliasSelector, method_getImplementation(targetMethod), typeEncoding);
            NSCAssert(addedAlias, @"Original implementation for %@ is already copied to %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), klass);
        }
        
        // 使用forwardInvocation来注册hook
        class_replaceMethod(klass, selector, fw_aspect_getMsgForwardIMP(self, selector), typeEncoding);
        FWAspectLog(@"FWAspect: Installed hook for -[%@ %@].", klass, NSStringFromSelector(selector));
    }
}

// 反注册runtime改变
static void fw_aspect_cleanupHookedClassAndSelector(NSObject *self, SEL selector) {
    NSCParameterAssert(self);
    NSCParameterAssert(selector);
    
    Class klass = object_getClass(self);
    BOOL isMetaClass = class_isMetaClass(klass);
    if (isMetaClass) {
        klass = (Class)self;
    }
    
    // 检查方法是否标记转发，并撤销
    Method targetMethod = class_getInstanceMethod(klass, selector);
    IMP targetMethodIMP = method_getImplementation(targetMethod);
    if (fw_aspect_isMsgForwardIMP(targetMethodIMP)) {
        // 恢复原始实现
        const char *typeEncoding = method_getTypeEncoding(targetMethod);
        SEL aliasSelector = fw_aspect_aliasForSelector(selector);
        Method originalMethod = class_getInstanceMethod(klass, aliasSelector);
        IMP originalIMP = method_getImplementation(originalMethod);
        NSCAssert(originalMethod, @"Original implementation for %@ not found %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), klass);
        
        class_replaceMethod(klass, selector, originalIMP, typeEncoding);
        FWAspectLog(@"FWAspect: Removed hook for -[%@ %@].", klass, NSStringFromSelector(selector));
    }
    
    // 反注册全局追踪的selector
    fw_aspect_deregisterTrackedSelector(self, selector);
    
    // 检查AOP容器是否还剩余AOP，如果没有则请理之
    FWAspectContainer *container = fw_aspect_getContainerForObject(self, selector);
    if (!container.hasAspects) {
        // 释放容器
        fw_aspect_destroyContainerForObject(self, selector);
        
        // 检查class使用哪种方式修改，并撤销修改
        NSString *className = NSStringFromClass(klass);
        if ([className hasSuffix:FWAspectSubclassSuffix]) {
            Class originalClass = NSClassFromString([className stringByReplacingOccurrencesOfString:FWAspectSubclassSuffix withString:@""]);
            NSCAssert(originalClass != nil, @"Original class must exist");
            object_setClass(self, originalClass);
            FWAspectLog(@"FWAspect: %@ has been restored.", NSStringFromClass(originalClass));
            
            // 没有使用subclass的实例时才能释放class pair，因为未检查，所以没法确定
            //objc_disposeClassPair(object.class);
        }else {
            // 撤销class通过swizzle替换
            if (isMetaClass) {
                fw_aspect_undoSwizzleClassInPlace((Class)self);
            }else if (self.class != klass) {
                fw_aspect_undoSwizzleClassInPlace(klass);
            }
        }
    }
}

static Class fw_aspect_hookClass(NSObject *self, NSError **error) {
    NSCParameterAssert(self);
    Class statedClass = self.class;
    Class baseClass = object_getClass(self);
    NSString *className = NSStringFromClass(baseClass);
    
    // 已经处理过
    if ([className hasSuffix:FWAspectSubclassSuffix]) {
        return baseClass;
    // 替换类对象，而非单个对象
    } else if (class_isMetaClass(baseClass)) {
        return fw_aspect_swizzleClassInPlace((Class)self);
    // 可能是KVO过的类，替换之。并替换meta类
    } else if (statedClass != baseClass) {
        return fw_aspect_swizzleClassInPlace(baseClass);
    }
    
    // 默认处理，动态创建子类
    const char *subclassName = [className stringByAppendingString:FWAspectSubclassSuffix].UTF8String;
    Class subclass = objc_getClass(subclassName);
    
    if (subclass == nil) {
        subclass = objc_allocateClassPair(baseClass, subclassName, 0);
        if (subclass == nil) {
            NSString *errrorDesc = [NSString stringWithFormat:@"objc_allocateClassPair failed to allocate class %s.", subclassName];
            FWAspectError(errrorDesc);
            return nil;
        }
        
        fw_aspect_swizzleForwardInvocation(subclass);
        fw_aspect_hookedGetClass(subclass, statedClass);
        fw_aspect_hookedGetClass(object_getClass(subclass), statedClass);
        objc_registerClassPair(subclass);
    }
    
    object_setClass(self, subclass);
    return subclass;
}

static NSString *const FWAspectForwardInvocationSelectorName = @"fwaspect_inner_forwardInvocation:";
static NSString *const FWAspectForwardInvocationOriginSelectorName = @"fwaspect_inner_originForwardInvocation:";
static void fw_aspect_swizzleForwardInvocation(Class klass) {
    NSCParameterAssert(klass);
    // 如果方法不存在，使用class_addMethod
    Method forwardMethod = class_getInstanceMethod(klass, @selector(forwardInvocation:));
    IMP originalImplementation = method_getImplementation(forwardMethod);
    if (originalImplementation) {
        class_addMethod(klass, NSSelectorFromString(FWAspectForwardInvocationOriginSelectorName), originalImplementation, "v@:@");
    }
    IMP replaceImplementation = class_replaceMethod(klass, @selector(forwardInvocation:), (IMP)fw_aspect_inner_forward_invocation, "v@:@");
    if (replaceImplementation) {
        class_addMethod(klass, NSSelectorFromString(FWAspectForwardInvocationSelectorName), replaceImplementation, "v@:@");
    }
    FWAspectLog(@"FWAspect: %@ is now aspect aware.", NSStringFromClass(klass));
}

static void fw_aspect_undoSwizzleForwardInvocation(Class klass) {
    NSCParameterAssert(klass);
    Method originalMethod = class_getInstanceMethod(klass, NSSelectorFromString(FWAspectForwardInvocationSelectorName));
    Method objectMethod = class_getInstanceMethod(NSObject.class, @selector(forwardInvocation:));
    // 由于没有class_removeMethod方法，因此只能还原原始实现，或虚拟实现
    IMP originalImplementation = method_getImplementation(originalMethod ?: objectMethod);
    class_replaceMethod(klass, @selector(forwardInvocation:), originalImplementation, "v@:@");
    FWAspectLog(@"FWAspect: %@ has been restored.", NSStringFromClass(klass));
}

static void fw_aspect_hookedGetClass(Class class, Class statedClass) {
    NSCParameterAssert(class);
    NSCParameterAssert(statedClass);
    Method method = class_getInstanceMethod(class, @selector(class));
    IMP newIMP = imp_implementationWithBlock(^(id self) {
        return statedClass;
    });
    class_replaceMethod(class, @selector(class), newIMP, method_getTypeEncoding(method));
}

static void fw_aspect_modifySwizzledClasses(void (^block)(NSMutableSet *swizzledClasses)) {
    static NSMutableSet *swizzledClasses;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        swizzledClasses = [NSMutableSet new];
    });
    @synchronized(swizzledClasses) {
        block(swizzledClasses);
    }
}

static Class fw_aspect_swizzleClassInPlace(Class klass) {
    NSCParameterAssert(klass);
    NSString *className = NSStringFromClass(klass);
    
    fw_aspect_modifySwizzledClasses(^(NSMutableSet *swizzledClasses) {
        if (![swizzledClasses containsObject:className]) {
            fw_aspect_swizzleForwardInvocation(klass);
            [swizzledClasses addObject:className];
        }
    });
    return klass;
}

static void fw_aspect_undoSwizzleClassInPlace(Class klass) {
    NSCParameterAssert(klass);
    NSString *className = NSStringFromClass(klass);
    
    fw_aspect_modifySwizzledClasses(^(NSMutableSet *swizzledClasses) {
        if ([swizzledClasses containsObject:className]) {
            fw_aspect_undoSwizzleForwardInvocation(klass);
            [swizzledClasses removeObject:className];
        }
    });
}

// 更直观清晰的追踪宏
#define fw_aspect_invoke(aspects, info) \
    for (FWAspectIdentifier *aspect in aspects) {\
        [aspect invokeWithInfo:info];\
        if (aspect.options & FWAspectAutomaticRemoval) { \
            aspectsToRemove = [aspectsToRemove?:@[] arrayByAddingObject:aspect]; \
        } \
    }

// forwardInvocation:方法替换实现
static void fw_aspect_inner_forward_invocation(__unsafe_unretained NSObject *self, SEL selector, NSInvocation *invocation) {
    NSCParameterAssert(self);
    NSCParameterAssert(invocation);
    SEL originalSelector = invocation.selector;
    SEL aliasSelector = fw_aspect_aliasForSelector(invocation.selector);
    invocation.selector = aliasSelector;
    FWAspectContainer *objectContainer = objc_getAssociatedObject(self, aliasSelector);
    FWAspectContainer *classContainer = fw_aspect_getContainerForClass(object_getClass(self), aliasSelector);
    FWAspectInfo *info = [[FWAspectInfo alloc] initWithInstance:self invocation:invocation];
    NSArray *aspectsToRemove = nil;
    
    // 执行Before hooks
    fw_aspect_invoke(classContainer.beforeAspects, info);
    fw_aspect_invoke(objectContainer.beforeAspects, info);
    
    // 执行Instead hooks
    BOOL respondsToAlias = YES;
    if (objectContainer.insteadAspects.count || classContainer.insteadAspects.count) {
        fw_aspect_invoke(classContainer.insteadAspects, info);
        fw_aspect_invoke(objectContainer.insteadAspects, info);
    }else {
        Class klass = object_getClass(invocation.target);
        do {
            if ((respondsToAlias = [klass instancesRespondToSelector:aliasSelector])) {
                [invocation invoke];
                break;
            }
        }while (!respondsToAlias && (klass = class_getSuperclass(klass)));
    }
    
    // 执行After hooks
    fw_aspect_invoke(classContainer.afterAspects, info);
    fw_aspect_invoke(objectContainer.afterAspects, info);
    
    // 如果未安装hooks，调用原始实现(一般抛出异常)
    if (!respondsToAlias) {
        invocation.selector = originalSelector;
        SEL originalForwardInvocationSEL = NSSelectorFromString(FWAspectForwardInvocationSelectorName);
        if ([self respondsToSelector:originalForwardInvocationSEL]) {
            ((void( *)(id, SEL, NSInvocation *))objc_msgSend)(self, originalForwardInvocationSEL, invocation);
        }else {
            SEL originalForwardInvocationSEL = NSSelectorFromString(FWAspectForwardInvocationOriginSelectorName);
            Class klass = object_getClass(invocation.target);
            Method originalForwardMethod = class_getInstanceMethod(klass, originalForwardInvocationSEL);
            IMP originalImplementation = method_getImplementation(originalForwardMethod);
            if (originalImplementation) {
                ((void( *)(id, SEL, NSInvocation *))originalImplementation)(self, selector, invocation);
            }else {
                [self doesNotRecognizeSelector:invocation.selector];
            }
        }
    }
    
    // 自动移除反注册队列中的hooks
    [aspectsToRemove makeObjectsPerformSelector:@selector(remove)];
}

// 创建或加载AOP容器
static FWAspectContainer *fw_aspect_getContainerForObject(NSObject *self, SEL selector) {
    NSCParameterAssert(self);
    SEL aliasSelector = fw_aspect_aliasForSelector(selector);
    FWAspectContainer *aspectContainer = objc_getAssociatedObject(self, aliasSelector);
    if (!aspectContainer) {
        aspectContainer = [FWAspectContainer new];
        objc_setAssociatedObject(self, aliasSelector, aspectContainer, OBJC_ASSOCIATION_RETAIN);
    }
    return aspectContainer;
}

static FWAspectContainer *fw_aspect_getContainerForClass(Class klass, SEL selector) {
    NSCParameterAssert(klass);
    FWAspectContainer *classContainer = nil;
    do {
        classContainer = objc_getAssociatedObject(klass, selector);
        if (classContainer.hasAspects) break;
    }while ((klass = class_getSuperclass(klass)));
    
    return classContainer;
}

static void fw_aspect_destroyContainerForObject(id<NSObject> self, SEL selector) {
    NSCParameterAssert(self);
    SEL aliasSelector = fw_aspect_aliasForSelector(selector);
    objc_setAssociatedObject(self, aliasSelector, nil, OBJC_ASSOCIATION_RETAIN);
}

static NSMutableDictionary *fw_aspect_getSwizzledClassesDict() {
    static NSMutableDictionary *swizzledClassesDict;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        swizzledClassesDict = [NSMutableDictionary new];
    });
    return swizzledClassesDict;
}

static BOOL fw_aspect_isSelectorAllowedAndTrack(NSObject *self, SEL selector, FWAspectOptions options, NSError **error) {
    static NSSet *disallowedSelectorList;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        disallowedSelectorList = [NSSet setWithObjects:@"retain", @"release", @"autorelease", @"forwardInvocation:", nil];
    });
    
    // 检查黑名单
    NSString *selectorName = NSStringFromSelector(selector);
    if ([disallowedSelectorList containsObject:selectorName]) {
        NSString *errorDescription = [NSString stringWithFormat:@"Selector %@ is blacklisted.", selectorName];
        FWAspectError(errorDescription);
        return NO;
    }
    
    // 其它检测
    FWAspectOptions position = options & FWAspectPositionFilter;
    if ([selectorName isEqualToString:@"dealloc"] && position != FWAspectPositionBefore) {
        NSString *errorDesc = @"AspectPositionBefore is the only valid position when hooking dealloc.";
        FWAspectError(errorDesc);
        return NO;
    }
    
    if (![self respondsToSelector:selector] && ![self.class instancesRespondToSelector:selector]) {
        NSString *errorDesc = [NSString stringWithFormat:@"Unable to find selector -[%@ %@].", NSStringFromClass(self.class), selectorName];
        FWAspectError(errorDesc);
        return NO;
    }
    
    // 修改class对象时，搜索当前类和类层级
    if (class_isMetaClass(object_getClass(self))) {
        Class klass = [self class];
        NSMutableDictionary *swizzledClassesDict = fw_aspect_getSwizzledClassesDict();
        Class currentClass = [self class];
        
        FWAspectTracker *tracker = swizzledClassesDict[currentClass];
        if ([tracker subclassHasHookedSelectorName:selectorName]) {
            NSSet *subclassTracker = [tracker subclassTrackersHookingSelectorName:selectorName];
            NSSet *subclassNames = [subclassTracker valueForKey:@"trackedClassName"];
            NSString *errorDescription = [NSString stringWithFormat:@"Error: %@ already hooked subclasses: %@. A method can only be hooked once per class hierarchy.", selectorName, subclassNames];
            FWAspectError(errorDescription);
            return NO;
        }
        
        do {
            tracker = swizzledClassesDict[currentClass];
            if ([tracker.selectorNames containsObject:selectorName]) {
                if (klass == currentClass) {
                    // 已经修改并且在顶层
                    return YES;
                }
                NSString *errorDescription = [NSString stringWithFormat:@"Error: %@ already hooked in %@. A method can only be hooked once per class hierarchy.", selectorName, NSStringFromClass(currentClass)];
                FWAspectError(errorDescription);
                return NO;
            }
        } while ((currentClass = class_getSuperclass(currentClass)));
        
        // 添加正在修改的selector
        currentClass = klass;
        FWAspectTracker *subclassTracker = nil;
        do {
            tracker = swizzledClassesDict[currentClass];
            if (!tracker) {
                tracker = [[FWAspectTracker alloc] initWithTrackedClass:currentClass];
                swizzledClassesDict[(id<NSCopying>)currentClass] = tracker;
            }
            if (subclassTracker) {
                [tracker addSubclassTracker:subclassTracker hookingSelectorName:selectorName];
            } else {
                [tracker.selectorNames addObject:selectorName];
            }
            
            // 所有父类标记子类被修改过
            subclassTracker = tracker;
        } while ((currentClass = class_getSuperclass(currentClass)));
    } else {
        return YES;
    }
    
    return YES;
}

static void fw_aspect_deregisterTrackedSelector(id self, SEL selector) {
    if (!class_isMetaClass(object_getClass(self))) return;
    
    NSMutableDictionary *swizzledClassesDict = fw_aspect_getSwizzledClassesDict();
    NSString *selectorName = NSStringFromSelector(selector);
    Class currentClass = [self class];
    FWAspectTracker *subclassTracker = nil;
    do {
        FWAspectTracker *tracker = swizzledClassesDict[currentClass];
        if (subclassTracker) {
            [tracker removeSubclassTracker:subclassTracker hookingSelectorName:selectorName];
        } else {
            [tracker.selectorNames removeObject:selectorName];
        }
        if (tracker.selectorNames.count == 0 && tracker.selectorNamesToSubclassTrackers) {
            [swizzledClassesDict removeObjectForKey:currentClass];
        }
        subclassTracker = tracker;
    } while ((currentClass = class_getSuperclass(currentClass)));
}

@end

#pragma mark - FWAspectTracker

@implementation FWAspectTracker

- (id)initWithTrackedClass:(Class)trackedClass {
    if (self = [super init]) {
        _trackedClass = trackedClass;
        _selectorNames = [NSMutableSet new];
        _selectorNamesToSubclassTrackers = [NSMutableDictionary new];
    }
    return self;
}

- (BOOL)subclassHasHookedSelectorName:(NSString *)selectorName {
    return self.selectorNamesToSubclassTrackers[selectorName] != nil;
}

- (void)addSubclassTracker:(FWAspectTracker *)subclassTracker hookingSelectorName:(NSString *)selectorName {
    NSMutableSet *trackerSet = self.selectorNamesToSubclassTrackers[selectorName];
    if (!trackerSet) {
        trackerSet = [NSMutableSet new];
        self.selectorNamesToSubclassTrackers[selectorName] = trackerSet;
    }
    [trackerSet addObject:subclassTracker];
}
- (void)removeSubclassTracker:(FWAspectTracker *)subclassTracker hookingSelectorName:(NSString *)selectorName {
    NSMutableSet *trackerSet = self.selectorNamesToSubclassTrackers[selectorName];
    [trackerSet removeObject:subclassTracker];
    if (trackerSet.count == 0) {
        [self.selectorNamesToSubclassTrackers removeObjectForKey:selectorName];
    }
}
- (NSSet *)subclassTrackersHookingSelectorName:(NSString *)selectorName {
    NSMutableSet *hookingSubclassTrackers = [NSMutableSet new];
    for (FWAspectTracker *tracker in self.selectorNamesToSubclassTrackers[selectorName]) {
        if ([tracker.selectorNames containsObject:selectorName]) {
            [hookingSubclassTrackers addObject:tracker];
        }
        [hookingSubclassTrackers unionSet:[tracker subclassTrackersHookingSelectorName:selectorName]];
    }
    return hookingSubclassTrackers;
}
- (NSString *)trackedClassName {
    return NSStringFromClass(self.trackedClass);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %@, trackedClass: %@, selectorNames:%@, subclass selector names: %@>", self.class, self, NSStringFromClass(self.trackedClass), self.selectorNames, self.selectorNamesToSubclassTrackers.allKeys];
}

@end

#pragma mark - NSInvocation+FWAspect

#define FWAspectWrapReturn(type) do { type val = 0; [self getArgument:&val atIndex:(NSInteger)index]; return @(val); } while (0)

@implementation NSInvocation (FWAspect)

// 感谢ReactiveCocoa提供的通用解决方案
- (id)fwAspectArgumentAtIndex:(NSUInteger)index
{
    const char *argType = [self.methodSignature getArgumentTypeAtIndex:index];
    // 忽略const类型限定符
    if (argType[0] == _C_CONST) argType++;
    
    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        __autoreleasing id returnObj;
        [self getArgument:&returnObj atIndex:(NSInteger)index];
        return returnObj;
    } else if (strcmp(argType, @encode(SEL)) == 0) {
        SEL selector = 0;
        [self getArgument:&selector atIndex:(NSInteger)index];
        return NSStringFromSelector(selector);
    } else if (strcmp(argType, @encode(Class)) == 0) {
        __autoreleasing Class theClass = Nil;
        [self getArgument:&theClass atIndex:(NSInteger)index];
        return theClass;
    // 使用具体的类型封装number，而不是NSValue
    } else if (strcmp(argType, @encode(char)) == 0) {
        FWAspectWrapReturn(char);
    } else if (strcmp(argType, @encode(int)) == 0) {
        FWAspectWrapReturn(int);
    } else if (strcmp(argType, @encode(short)) == 0) {
        FWAspectWrapReturn(short);
    } else if (strcmp(argType, @encode(long)) == 0) {
        FWAspectWrapReturn(long);
    } else if (strcmp(argType, @encode(long long)) == 0) {
        FWAspectWrapReturn(long long);
    } else if (strcmp(argType, @encode(unsigned char)) == 0) {
        FWAspectWrapReturn(unsigned char);
    } else if (strcmp(argType, @encode(unsigned int)) == 0) {
        FWAspectWrapReturn(unsigned int);
    } else if (strcmp(argType, @encode(unsigned short)) == 0) {
        FWAspectWrapReturn(unsigned short);
    } else if (strcmp(argType, @encode(unsigned long)) == 0) {
        FWAspectWrapReturn(unsigned long);
    } else if (strcmp(argType, @encode(unsigned long long)) == 0) {
        FWAspectWrapReturn(unsigned long long);
    } else if (strcmp(argType, @encode(float)) == 0) {
        FWAspectWrapReturn(float);
    } else if (strcmp(argType, @encode(double)) == 0) {
        FWAspectWrapReturn(double);
    } else if (strcmp(argType, @encode(BOOL)) == 0) {
        FWAspectWrapReturn(BOOL);
    } else if (strcmp(argType, @encode(bool)) == 0) {
        FWAspectWrapReturn(BOOL);
    } else if (strcmp(argType, @encode(char *)) == 0) {
        FWAspectWrapReturn(const char *);
    } else if (strcmp(argType, @encode(void (^)(void))) == 0) {
        __unsafe_unretained id block = nil;
        [self getArgument:&block atIndex:(NSInteger)index];
        return [block copy];
    } else {
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(argType, &valueSize, NULL);
        unsigned char valueBytes[valueSize];
        [self getArgument:valueBytes atIndex:(NSInteger)index];
        return [NSValue valueWithBytes:valueBytes objCType:argType];
    }
    return nil;
}

- (NSArray *)fwAspectArguments
{
    NSMutableArray *argumentsArray = [NSMutableArray array];
    for (NSUInteger idx = 2; idx < self.methodSignature.numberOfArguments; idx++) {
        [argumentsArray addObject:[self fwAspectArgumentAtIndex:idx] ?: NSNull.null];
    }
    return [argumentsArray copy];
}

@end

#pragma mark - FWAspectIdentifier

@implementation FWAspectIdentifier

+ (instancetype)identifierWithSelector:(SEL)selector object:(id)object options:(FWAspectOptions)options block:(id)block error:(NSError **)error {
    NSCParameterAssert(block);
    NSCParameterAssert(selector);
    // 检查签名兼容性
    NSMethodSignature *blockSignature = fw_aspect_blockMethodSignature(block, error);
    if (!fw_aspect_isCompatibleBlockSignature(blockSignature, object, selector, error)) {
        return nil;
    }
    
    FWAspectIdentifier *identifier = nil;
    if (blockSignature) {
        identifier = [FWAspectIdentifier new];
        identifier.selector = selector;
        identifier.block = block;
        identifier.blockSignature = blockSignature;
        identifier.options = options;
        identifier.object = object;
    }
    return identifier;
}

- (BOOL)invokeWithInfo:(id<FWAspectInfo>)info {
    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:self.blockSignature];
    NSInvocation *originalInvocation = info.originalInvocation;
    NSUInteger numberOfArguments = self.blockSignature.numberOfArguments;
    
    // 额外检查参数个数
    if (numberOfArguments > originalInvocation.methodSignature.numberOfArguments) {
        FWLogError(@"Block has too many arguments. Not calling %@", info);
        return NO;
    }
    
    // block中的self参数为FWAspectInfo，可选
    if (numberOfArguments > 1) {
        [blockInvocation setArgument:&info atIndex:1];
    }
    
    void *argBuf = NULL;
    for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
        const char *type = [originalInvocation.methodSignature getArgumentTypeAtIndex:idx];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);
        
        if (!(argBuf = reallocf(argBuf, argSize))) {
            FWLogError(@"Failed to allocate memory for block invocation.");
            return NO;
        }
        
        [originalInvocation getArgument:argBuf atIndex:idx];
        [blockInvocation setArgument:argBuf atIndex:idx];
    }
    
    [blockInvocation invokeWithTarget:self.block];
    
    if (argBuf != NULL) {
        free(argBuf);
    }
    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, SEL:%@ object:%@ options:%tu block:%@ (#%tu args)>", self.class, self, NSStringFromSelector(self.selector), self.object, self.options, self.block, self.blockSignature.numberOfArguments];
}

- (BOOL)remove {
    return fw_aspect_remove(self, NULL);
}

@end

#pragma mark - FWAspectContainer

@implementation FWAspectContainer

- (BOOL)hasAspects {
    return self.beforeAspects.count > 0 || self.insteadAspects.count > 0 || self.afterAspects.count > 0;
}

- (void)addAspect:(FWAspectIdentifier *)aspect withOptions:(FWAspectOptions)options {
    NSParameterAssert(aspect);
    NSUInteger position = options & FWAspectPositionFilter;
    switch (position) {
        case FWAspectPositionBefore:  self.beforeAspects  = [(self.beforeAspects ?:@[]) arrayByAddingObject:aspect]; break;
        case FWAspectPositionInstead: self.insteadAspects = [(self.insteadAspects?:@[]) arrayByAddingObject:aspect]; break;
        case FWAspectPositionAfter:   self.afterAspects   = [(self.afterAspects  ?:@[]) arrayByAddingObject:aspect]; break;
    }
}

- (BOOL)removeAspect:(id)aspect {
    for (NSString *aspectArrayName in @[NSStringFromSelector(@selector(beforeAspects)),
                                        NSStringFromSelector(@selector(insteadAspects)),
                                        NSStringFromSelector(@selector(afterAspects))]) {
        NSArray *array = [self valueForKey:aspectArrayName];
        NSUInteger index = [array indexOfObjectIdenticalTo:aspect];
        if (array && index != NSNotFound) {
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:array];
            [newArray removeObjectAtIndex:index];
            [self setValue:newArray forKey:aspectArrayName];
            return YES;
        }
    }
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, before:%@, instead:%@, after:%@>", self.class, self, self.beforeAspects, self.insteadAspects, self.afterAspects];
}

@end

#pragma mark - FWAspectInfo

@implementation FWAspectInfo

@synthesize arguments = _arguments;

- (id)initWithInstance:(__unsafe_unretained id)instance invocation:(NSInvocation *)invocation
{
    NSCParameterAssert(instance);
    NSCParameterAssert(invocation);
    if (self = [super init]) {
        _instance = instance;
        _originalInvocation = invocation;
    }
    return self;
}

- (NSArray *)arguments
{
    // 为节省资源，懒加载arguments
    if (!_arguments) {
        _arguments = self.originalInvocation.fwAspectArguments;
    }
    return _arguments;
}

@end
