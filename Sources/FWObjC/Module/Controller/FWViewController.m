//
//  FWViewController.m
//  
//
//  Created by wuyong on 2022/8/23.
//

#import "FWViewController.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - UIViewController+FWViewController

@interface UIViewController (FWViewController)

- (SEL)fw_innerIntercepterForwardSelector:(SEL)aSelector;

@end

#pragma mark - FWViewControllerIntercepter

@implementation FWViewControllerIntercepter

@end

#pragma mark - FWViewControllerManager

@interface FWViewControllerManager ()

@property (nonatomic, strong) NSMutableDictionary *intercepters;

@end

@implementation FWViewControllerManager

+ (void)load
{
    [FWViewControllerManager sharedInstance];
}

+ (FWViewControllerManager *)sharedInstance
{
    static FWViewControllerManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWViewControllerManager alloc] init];
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

- (void)registerProtocol:(Protocol *)protocol withIntercepter:(FWViewControllerIntercepter *)intercepter
{
    [self.intercepters setObject:intercepter forKey:NSStringFromProtocol(protocol)];
}

- (id)performIntercepter:(SEL)intercepter withObject:(UIViewController *)object
{
    SEL forwardSelector = [object fw_innerIntercepterForwardSelector:intercepter];
    if (forwardSelector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        char *type = method_copyReturnType(class_getInstanceMethod([object class], forwardSelector));
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
    SEL forwardSelector = [object fw_innerIntercepterForwardSelector:intercepter];
    if (forwardSelector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        char *type = method_copyReturnType(class_getInstanceMethod([object class], forwardSelector));
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
    
    // 解析协议列表，包含父协议。始终包含FWViewController，且位于第一位
    NSMutableArray *protocolNames = [NSMutableArray arrayWithObject:@"FWViewController"];
    while (clazz != NULL) {
        unsigned int count = 0;
        __unsafe_unretained Protocol **list = class_copyProtocolList(clazz, &count);
        for (unsigned int i = 0; i < count; i++) {
            Protocol *protocol = list[i];
            if (!protocol_conformsToProtocol(protocol, @protocol(FWViewController))) continue;
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
        FWViewControllerIntercepter *intercepter = [self.intercepters objectForKey:protocolName];
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
    // FWViewController全局拦截器init方法示例：
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
        FWViewControllerIntercepter *intercepter = [self.intercepters objectForKey:protocolName];
        if (intercepter.initIntercepter && [self respondsToSelector:intercepter.initIntercepter]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:intercepter.initIntercepter withObject:viewController];
#pragma clang diagnostic pop
        }
    }
    
    // 3. 控制器didInitialize
    if ([viewController respondsToSelector:@selector(didInitialize)]) {
        [(id<FWViewController>)viewController didInitialize];
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
        FWViewControllerIntercepter *intercepter = [self.intercepters objectForKey:protocolName];
        if (intercepter.viewDidLoadIntercepter && [self respondsToSelector:intercepter.viewDidLoadIntercepter]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:intercepter.viewDidLoadIntercepter withObject:viewController];
#pragma clang diagnostic pop
        }
    }
    
    // 3. 控制器setupNavbar
    if ([viewController respondsToSelector:@selector(setupNavbar)]) {
        [(id<FWViewController>)viewController setupNavbar];
    }
    
    // 4. 控制器setupSubviews
    if ([viewController respondsToSelector:@selector(setupSubviews)]) {
        [(id<FWViewController>)viewController setupSubviews];
    }
    
    // 5. 控制器setupLayout
    if ([viewController respondsToSelector:@selector(setupLayout)]) {
        [(id<FWViewController>)viewController setupLayout];
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
        FWViewControllerIntercepter *intercepter = [self.intercepters objectForKey:protocolName];
        if (intercepter.viewDidLayoutSubviewsIntercepter && [self respondsToSelector:intercepter.viewDidLayoutSubviewsIntercepter]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:intercepter.viewDidLayoutSubviewsIntercepter withObject:viewController];
#pragma clang diagnostic pop
        }
    }
}

@end

#pragma mark - UIViewController+FWViewController

@implementation UIViewController (FWViewController)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(initWithNibName:bundle:), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(NSString *nibNameOrNil, NSBundle *nibBundleOrNil), FWSwizzleCode({
            UIViewController *viewController = FWSwizzleOriginal(nibNameOrNil, nibBundleOrNil);
            if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
                [[FWViewControllerManager sharedInstance] hookInit:viewController];
            }
            return viewController;
        }));
        FWSwizzleClass(UIViewController, @selector(initWithCoder:), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(NSCoder *coder), FWSwizzleCode({
            UIViewController *viewController = FWSwizzleOriginal(coder);
            if (viewController && [viewController conformsToProtocol:@protocol(FWViewController)]) {
                [[FWViewControllerManager sharedInstance] hookInit:viewController];
            }
            return viewController;
        }));
        FWSwizzleClass(UIViewController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            if ([selfObject conformsToProtocol:@protocol(FWViewController)]) {
                [[FWViewControllerManager sharedInstance] hookViewDidLoad:selfObject];
            }
        }));
        FWSwizzleClass(UIViewController, @selector(viewDidLayoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            if ([selfObject conformsToProtocol:@protocol(FWViewController)]) {
                [[FWViewControllerManager sharedInstance] hookViewDidLayoutSubviews:selfObject];
            }
        }));
        
        [UIViewController fw_exchangeInstanceMethod:@selector(respondsToSelector:) swizzleMethod:@selector(fw_innerIntercepterRespondsToSelector:)];
        [UIViewController fw_exchangeInstanceMethod:@selector(methodSignatureForSelector:) swizzleMethod:@selector(fw_innerIntercepterMethodSignatureForSelector:)];
        [UIViewController fw_exchangeInstanceMethod:@selector(forwardInvocation:) swizzleMethod:@selector(fw_innerIntercepterForwardInvocation:)];
    });
}

#pragma mark - Forward

- (NSMutableDictionary *)fw_innerIntercepterForwardSelectors
{
    NSMutableDictionary *forwardSelectors = objc_getAssociatedObject(self, _cmd);
    if (!forwardSelectors) {
        forwardSelectors = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, forwardSelectors, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return forwardSelectors;
}

- (SEL)fw_innerIntercepterForwardSelector:(SEL)aSelector
{
    if ([self conformsToProtocol:@protocol(FWViewController)]) {
        // 查找forward方法缓存是否存在
        NSString *selectorName = NSStringFromSelector(aSelector);
        NSString *forwardName = [[self fw_innerIntercepterForwardSelectors] objectForKey:selectorName];
        if (!forwardName) {
            // 如果缓存不存在，查找一次并生成缓存
            forwardName = [[FWViewControllerManager sharedInstance] forwardSelector:selectorName withClass:self.class];
            [[self fw_innerIntercepterForwardSelectors] setObject:(forwardName ?: @"") forKey:selectorName];
        }
        
        SEL forwardSelector = forwardName.length > 0 ? NSSelectorFromString(forwardName) : NULL;
        if (forwardSelector && [self fw_innerIntercepterRespondsToSelector:forwardSelector]) {
            return forwardSelector;
        }
    }
    return NULL;
}

- (BOOL)fw_innerIntercepterRespondsToSelector:(SEL)aSelector
{
    if ([self fw_innerIntercepterRespondsToSelector:aSelector]) {
        return YES;
    } else {
        SEL forwardSelector = [self fw_innerIntercepterForwardSelector:aSelector];
        return forwardSelector ? YES : NO;
    }
}

- (NSMethodSignature *)fw_innerIntercepterMethodSignatureForSelector:(SEL)aSelector
{
    SEL forwardSelector = NULL;
    if (![self fw_innerIntercepterRespondsToSelector:aSelector]) {
        forwardSelector = [self fw_innerIntercepterForwardSelector:aSelector];
    }
    if (forwardSelector) {
        return [self.class instanceMethodSignatureForSelector:forwardSelector];
    } else {
        return [self fw_innerIntercepterMethodSignatureForSelector:aSelector];
    }
}

- (void)fw_innerIntercepterForwardInvocation:(NSInvocation *)anInvocation
{
    SEL forwardSelector = NULL;
    if (![self fw_innerIntercepterRespondsToSelector:anInvocation.selector]) {
        forwardSelector = [self fw_innerIntercepterForwardSelector:anInvocation.selector];
    }
    if (forwardSelector) {
        anInvocation.selector = forwardSelector;
        [anInvocation invoke];
    } else {
        [self fw_innerIntercepterForwardInvocation:anInvocation];
    }
}

@end
