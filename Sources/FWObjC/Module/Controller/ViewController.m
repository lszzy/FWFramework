//
//  ViewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ViewController.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

+ (BOOL)__fw_swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier block:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;
+ (BOOL)__fw_exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - UIViewController+__FWViewController

@interface UIViewController (__FWViewController)

- (SEL)__fw_intercepterForwardSelector:(SEL)aSelector;

@end

#pragma mark - __FWViewControllerIntercepter

@implementation __FWViewControllerIntercepter

@end

#pragma mark - __FWViewControllerManager

@interface __FWViewControllerManager ()

@property (nonatomic, strong) NSMutableDictionary *intercepters;

@end

@implementation __FWViewControllerManager

+ (void)load
{
    [__FWViewControllerManager sharedInstance];
}

+ (__FWViewControllerManager *)sharedInstance
{
    static __FWViewControllerManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWViewControllerManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _intercepters = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public

- (void)registerProtocol:(Protocol *)protocol withIntercepter:(__FWViewControllerIntercepter *)intercepter
{
    [self.intercepters setObject:intercepter forKey:NSStringFromProtocol(protocol)];
}

- (id)performIntercepter:(SEL)intercepter withObject:(UIViewController *)object
{
    SEL forwardSelector = [object __fw_intercepterForwardSelector:intercepter];
    if (forwardSelector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        char *type = method_copyReturnType(class_getInstanceMethod(object_getClass(object), forwardSelector));
        if (type && *type == 'v') {
            free(type);
            [object performSelector:forwardSelector];
        } else {
            free(type);
            return [object performSelector:forwardSelector];
        }
#pragma clang diagnostic pop
    }
    return nil;
}

- (id)performIntercepter:(SEL)intercepter withObject:(UIViewController *)object parameter:(id)parameter
{
    SEL forwardSelector = [object __fw_intercepterForwardSelector:intercepter];
    if (forwardSelector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        char *type = method_copyReturnType(class_getInstanceMethod(object_getClass(object), forwardSelector));
        if (type && *type == 'v') {
            free(type);
            [object performSelector:forwardSelector withObject:parameter];
        } else {
            free(type);
            return [object performSelector:forwardSelector withObject:parameter];
        }
#pragma clang diagnostic pop
    }
    return nil;
}

- (NSArray *)protocolsWithClass:(Class)clazz
{
    static NSMutableDictionary *classProtocols = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classProtocols = [NSMutableDictionary dictionary];
    });
    
    // 同一个类只解析一次
    NSString *className = NSStringFromClass(clazz);
    NSArray *protocolList = [classProtocols objectForKey:className];
    if (protocolList) {
        return protocolList;
    }
    
    // 解析协议列表，包含父协议。始终包含__FWViewController，且位于第一位
    NSMutableArray *protocolNames = [NSMutableArray arrayWithObject:NSStringFromProtocol(@protocol(__FWViewController))];
    while (clazz != NULL) {
        unsigned int count = 0;
        __unsafe_unretained Protocol **list = class_copyProtocolList(clazz, &count);
        for (unsigned int i = 0; i < count; i++) {
            Protocol *protocol = list[i];
            if (!protocol_conformsToProtocol(protocol, @protocol(__FWViewController))) continue;
            NSString *name = [NSString stringWithUTF8String:protocol_getName(protocol)];
            if (!name || [protocolNames containsObject:name]) continue;
            [protocolNames addObject:name];
        }
        free(list);
        
        clazz = class_getSuperclass(clazz);
        if (nil == clazz || clazz == [NSObject class]) break;
    }
    
    // 写入协议缓存
    [classProtocols setObject:protocolNames forKey:className];
    return protocolNames;
}

// 查找指定类中是否存在已定义的协议跳转方法
- (NSString *)forwardSelector:(NSString *)selectorName withClass:(Class)clazz
{
    NSString *forwardName = nil;
    NSArray *protocolNames = [self protocolsWithClass:clazz];
    for (NSString *protocolName in protocolNames) {
        __FWViewControllerIntercepter *intercepter = [self.intercepters objectForKey:protocolName];
        forwardName = intercepter ? [intercepter.forwardSelectors objectForKey:selectorName] : nil;
        if (forwardName) {
            break;
        }
    }
    return forwardName;
}

#pragma mark - Hook

- (void)hookInit:(UIViewController *)viewController
{
    /*
    // __FWViewController全局拦截器init方法示例：
    // 开启不透明bar(translucent为NO)情况下视图延伸到屏幕顶部，顶部推荐safeArea方式布局
    viewController.extendedLayoutIncludesOpaqueBars = YES;
    // 默认push时隐藏TabBar，TabBar初始化控制器时设置为NO
    viewController.hidesBottomBarWhenPushed = YES;
    // 视图默认all延伸到全部工具栏，可指定top|bottom不被工具栏遮挡
    viewController.edgesForExtendedLayout = UIRectEdgeAll;
    */
    
    // 1. 默认init
    if (self.hookInit) {
        self.hookInit(viewController);
    }
    
    // 2. 拦截器init
    NSArray *protocolNames = [self protocolsWithClass:viewController.class];
    for (NSString *protocolName in protocolNames) {
        __FWViewControllerIntercepter *intercepter = [self.intercepters objectForKey:protocolName];
        if (intercepter.initIntercepter && [self respondsToSelector:intercepter.initIntercepter]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:intercepter.initIntercepter withObject:viewController];
#pragma clang diagnostic pop
        }
    }
    
    // 3. 控制器didInitialize
    if ([viewController respondsToSelector:@selector(didInitialize)]) {
        [(id<__FWViewController>)viewController didInitialize];
    }
}

- (void)hookViewDidLoad:(UIViewController *)viewController
{
    // 1. 默认viewDidLoad
    if (self.hookViewDidLoad) {
        self.hookViewDidLoad(viewController);
    }
    
    // 2. 拦截器viewDidLoad
    NSArray *protocolNames = [self protocolsWithClass:viewController.class];
    for (NSString *protocolName in protocolNames) {
        __FWViewControllerIntercepter *intercepter = [self.intercepters objectForKey:protocolName];
        if (intercepter.viewDidLoadIntercepter && [self respondsToSelector:intercepter.viewDidLoadIntercepter]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:intercepter.viewDidLoadIntercepter withObject:viewController];
#pragma clang diagnostic pop
        }
    }
    
    // 3. 控制器setupNavbar
    if ([viewController respondsToSelector:@selector(setupNavbar)]) {
        [(id<__FWViewController>)viewController setupNavbar];
    }
    
    // 4. 控制器setupSubviews
    if ([viewController respondsToSelector:@selector(setupSubviews)]) {
        [(id<__FWViewController>)viewController setupSubviews];
    }
    
    // 5. 控制器setupLayout
    if ([viewController respondsToSelector:@selector(setupLayout)]) {
        [(id<__FWViewController>)viewController setupLayout];
    }
}

- (void)hookViewDidLayoutSubviews:(UIViewController *)viewController
{
    // 1. 默认viewDidLayoutSubviews
    if (self.hookViewDidLayoutSubviews) {
        self.hookViewDidLayoutSubviews(viewController);
    }
    
    // 2. 拦截器viewDidLayoutSubviews
    NSArray *protocolNames = [self protocolsWithClass:viewController.class];
    for (NSString *protocolName in protocolNames) {
        __FWViewControllerIntercepter *intercepter = [self.intercepters objectForKey:protocolName];
        if (intercepter.viewDidLayoutSubviewsIntercepter && [self respondsToSelector:intercepter.viewDidLayoutSubviewsIntercepter]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:intercepter.viewDidLayoutSubviewsIntercepter withObject:viewController];
#pragma clang diagnostic pop
        }
    }
}

@end

#pragma mark - UIViewController+__FWViewController

@implementation UIViewController (__FWViewController)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSObject __fw_swizzleMethod:[UIViewController class] selector:@selector(initWithNibName:bundle:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^UIViewController * (__unsafe_unretained UIViewController *selfObject, NSString *nibNameOrNil, NSBundle *nibBundleOrNil) {
                UIViewController * (*originalMSG)(id, SEL, NSString *, NSBundle *) = (UIViewController * (*)(id, SEL, NSString *, NSBundle *))originalIMP();
                UIViewController *viewController = originalMSG(selfObject, originalCMD, nibNameOrNil, nibBundleOrNil);
                if ([viewController conformsToProtocol:@protocol(__FWViewController)]) {
                    [[__FWViewControllerManager sharedInstance] hookInit:viewController];
                }
                return viewController;
            };
        }];
        
        [NSObject __fw_swizzleMethod:[UIViewController class] selector:@selector(initWithCoder:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^UIViewController * (__unsafe_unretained UIViewController *selfObject, NSCoder *coder) {
                UIViewController * (*originalMSG)(id, SEL, NSCoder *) = (UIViewController * (*)(id, SEL, NSCoder *))originalIMP();
                UIViewController *viewController = originalMSG(selfObject, originalCMD, coder);
                if (viewController && [viewController conformsToProtocol:@protocol(__FWViewController)]) {
                    [[__FWViewControllerManager sharedInstance] hookInit:viewController];
                }
                return viewController;
            };
        }];
        
        [NSObject __fw_swizzleMethod:[UIViewController class] selector:@selector(viewDidLoad) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained UIViewController *selfObject) {
                void (*originalMSG)(id, SEL) = (void (*)(id, SEL))originalIMP();
                originalMSG(selfObject, originalCMD);
                if ([selfObject conformsToProtocol:@protocol(__FWViewController)]) {
                    [[__FWViewControllerManager sharedInstance] hookViewDidLoad:selfObject];
                }
            };
        }];
        
        [NSObject __fw_swizzleMethod:[UIViewController class] selector:@selector(viewDidLayoutSubviews) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained UIViewController *selfObject) {
                void (*originalMSG)(id, SEL) = (void (*)(id, SEL))originalIMP();
                originalMSG(selfObject, originalCMD);
                if ([selfObject conformsToProtocol:@protocol(__FWViewController)]) {
                    [[__FWViewControllerManager sharedInstance] hookViewDidLayoutSubviews:selfObject];
                }
            };
        }];
        
        [UIViewController __fw_exchangeInstanceMethod:@selector(respondsToSelector:) swizzleMethod:@selector(__fw_intercepterRespondsToSelector:)];
        [UIViewController __fw_exchangeInstanceMethod:@selector(methodSignatureForSelector:) swizzleMethod:@selector(__fw_intercepterMethodSignatureForSelector:)];
        [UIViewController __fw_exchangeInstanceMethod:@selector(forwardInvocation:) swizzleMethod:@selector(__fw_intercepterForwardInvocation:)];
    });
}

#pragma mark - Forward

- (NSMutableDictionary *)__fw_intercepterForwardSelectors
{
    NSMutableDictionary *forwardSelectors = objc_getAssociatedObject(self, _cmd);
    if (!forwardSelectors) {
        forwardSelectors = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, forwardSelectors, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return forwardSelectors;
}

- (SEL)__fw_intercepterForwardSelector:(SEL)aSelector
{
    if ([self conformsToProtocol:@protocol(__FWViewController)]) {
        // 查找forward方法缓存是否存在
        NSString *selectorName = NSStringFromSelector(aSelector);
        NSString *forwardName = [[self __fw_intercepterForwardSelectors] objectForKey:selectorName];
        if (!forwardName) {
            // 如果缓存不存在，查找一次并生成缓存
            forwardName = [[__FWViewControllerManager sharedInstance] forwardSelector:selectorName withClass:self.class];
            [[self __fw_intercepterForwardSelectors] setObject:(forwardName ?: @"") forKey:selectorName];
        }
        
        SEL forwardSelector = forwardName.length > 0 ? NSSelectorFromString(forwardName) : NULL;
        if (forwardSelector && [self __fw_intercepterRespondsToSelector:forwardSelector]) {
            return forwardSelector;
        }
    }
    return NULL;
}

- (BOOL)__fw_intercepterRespondsToSelector:(SEL)aSelector
{
    if ([self __fw_intercepterRespondsToSelector:aSelector]) {
        return YES;
    } else {
        SEL forwardSelector = [self __fw_intercepterForwardSelector:aSelector];
        return forwardSelector ? YES : NO;
    }
}

- (NSMethodSignature *)__fw_intercepterMethodSignatureForSelector:(SEL)aSelector
{
    SEL forwardSelector = NULL;
    if (![self __fw_intercepterRespondsToSelector:aSelector]) {
        forwardSelector = [self __fw_intercepterForwardSelector:aSelector];
    }
    if (forwardSelector) {
        return [self.class instanceMethodSignatureForSelector:forwardSelector];
    } else {
        return [self __fw_intercepterMethodSignatureForSelector:aSelector];
    }
}

- (void)__fw_intercepterForwardInvocation:(NSInvocation *)anInvocation
{
    SEL forwardSelector = NULL;
    if (![self __fw_intercepterRespondsToSelector:anInvocation.selector]) {
        forwardSelector = [self __fw_intercepterForwardSelector:anInvocation.selector];
    }
    if (forwardSelector) {
        anInvocation.selector = forwardSelector;
        [anInvocation invoke];
    } else {
        [self __fw_intercepterForwardInvocation:anInvocation];
    }
}

@end
