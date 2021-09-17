/*!
 @header     FWViewController.m
 @indexgroup FWFramework
 @brief      FWViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWViewController.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - UIViewController+FWViewController

@interface UIViewController (FWViewController)

- (SEL)fwInnerIntercepterForwardSelector:(SEL)aSelector;

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
    SEL forwardSelector = [object fwInnerIntercepterForwardSelector:intercepter];
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
    SEL forwardSelector = [object fwInnerIntercepterForwardSelector:intercepter];
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
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
        /*
        // FWViewController全局拦截器init方法示例：
        // 视图默认不被顶部导航栏遮挡，如果UIToolbar顶部出现空白，需设为Bottom|All
        viewController.edgesForExtendedLayout = UIRectEdgeBottom;
        // 开启不透明bar(translucent为NO)情况下延伸包括bar，占满全屏
        viewController.extendedLayoutIncludesOpaqueBars = YES;
        // 解决iOS7-10时scrollView占不满导航栏问题
        viewController.automaticallyAdjustsScrollViewInsets = NO;
        // 默认push时隐藏TabBar，TabBar初始化控制器时设置为NO
        viewController.hidesBottomBarWhenPushed = YES;
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
        
        // 3. 控制器renderInit
        if ([viewController respondsToSelector:@selector(renderInit)]) {
            [(id<FWViewController>)viewController renderInit];
        }
    }
}

- (void)hookLoadView:(UIViewController *)viewController
{
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
        // 1. 默认loadView
        if (self.hookLoadView) {
            self.hookLoadView(viewController);
        }
        
        // 2. 拦截器loadView
        NSArray *protocolNames = [self protocolsWithClass:viewController.class];
        for (NSString *protocolName in protocolNames) {
            FWViewControllerIntercepter *intercepter = [self.intercepters objectForKey:protocolName];
            if (intercepter.loadViewIntercepter && [self respondsToSelector:intercepter.loadViewIntercepter]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:intercepter.loadViewIntercepter withObject:viewController];
#pragma clang diagnostic pop
            }
        }
        
        // 3. 控制器renderView
        if ([viewController respondsToSelector:@selector(renderView)]) {
            [(id<FWViewController>)viewController renderView];
        }
    }
}

- (void)hookViewDidLoad:(UIViewController *)viewController
{
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
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
        
        // 3. 控制器renderModel
        if ([viewController respondsToSelector:@selector(renderModel)]) {
            [(id<FWViewController>)viewController renderModel];
        }
        
        // 4. 控制器renderData
        if ([viewController respondsToSelector:@selector(renderData)]) {
            [(id<FWViewController>)viewController renderData];
        }
        
        // 5. 控制器renderState
        if ([viewController respondsToSelector:@selector(renderState:withObject:)]) {
            [(id<FWViewController>)viewController renderState:FWViewControllerStateReady withObject:nil];
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
            [[FWViewControllerManager sharedInstance] hookInit:viewController];
            return viewController;
        }));
        FWSwizzleClass(UIViewController, @selector(initWithCoder:), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(NSCoder *coder), FWSwizzleCode({
            UIViewController *viewController = FWSwizzleOriginal(coder);
            if (viewController) {
                [[FWViewControllerManager sharedInstance] hookInit:viewController];
            }
            return viewController;
        }));
        FWSwizzleClass(UIViewController, @selector(loadView), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            [[FWViewControllerManager sharedInstance] hookLoadView:selfObject];
        }));
        FWSwizzleClass(UIViewController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            [[FWViewControllerManager sharedInstance] hookViewDidLoad:selfObject];
        }));
        
        [UIViewController fwSwizzleInstanceMethod:@selector(respondsToSelector:) with:@selector(fwInnerIntercepterRespondsToSelector:)];
        [UIViewController fwSwizzleInstanceMethod:@selector(methodSignatureForSelector:) with:@selector(fwInnerIntercepterMethodSignatureForSelector:)];
        [UIViewController fwSwizzleInstanceMethod:@selector(forwardInvocation:) with:@selector(fwInnerIntercepterForwardInvocation:)];
    });
}

#pragma mark - Forward

- (NSMutableDictionary *)fwInnerIntercepterForwardSelectors
{
    NSMutableDictionary *forwardSelectors = objc_getAssociatedObject(self, _cmd);
    if (!forwardSelectors) {
        forwardSelectors = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, forwardSelectors, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return forwardSelectors;
}

- (SEL)fwInnerIntercepterForwardSelector:(SEL)aSelector
{
    if ([self conformsToProtocol:@protocol(FWViewController)]) {
        // 查找forward方法缓存是否存在
        NSString *selectorName = NSStringFromSelector(aSelector);
        NSString *forwardName = [[self fwInnerIntercepterForwardSelectors] objectForKey:selectorName];
        if (!forwardName) {
            // 如果缓存不存在，查找一次并生成缓存
            forwardName = [[FWViewControllerManager sharedInstance] forwardSelector:selectorName withClass:self.class];
            [[self fwInnerIntercepterForwardSelectors] setObject:(forwardName ?: @"") forKey:selectorName];
        }
        
        SEL forwardSelector = forwardName.length > 0 ? NSSelectorFromString(forwardName) : NULL;
        if (forwardSelector && [self fwInnerIntercepterRespondsToSelector:forwardSelector]) {
            return forwardSelector;
        }
    }
    return NULL;
}

- (BOOL)fwInnerIntercepterRespondsToSelector:(SEL)aSelector
{
    if ([self fwInnerIntercepterRespondsToSelector:aSelector]) {
        return YES;
    } else {
        SEL forwardSelector = [self fwInnerIntercepterForwardSelector:aSelector];
        return forwardSelector ? YES : NO;
    }
}

- (NSMethodSignature *)fwInnerIntercepterMethodSignatureForSelector:(SEL)aSelector
{
    SEL forwardSelector = NULL;
    if (![self fwInnerIntercepterRespondsToSelector:aSelector]) {
        forwardSelector = [self fwInnerIntercepterForwardSelector:aSelector];
    }
    if (forwardSelector) {
        return [self.class instanceMethodSignatureForSelector:forwardSelector];
    } else {
        return [self fwInnerIntercepterMethodSignatureForSelector:aSelector];
    }
}

- (void)fwInnerIntercepterForwardInvocation:(NSInvocation *)anInvocation
{
    SEL forwardSelector = NULL;
    if (![self fwInnerIntercepterRespondsToSelector:anInvocation.selector]) {
        forwardSelector = [self fwInnerIntercepterForwardSelector:anInvocation.selector];
    }
    if (forwardSelector) {
        anInvocation.selector = forwardSelector;
        [anInvocation invoke];
    } else {
        [self fwInnerIntercepterForwardInvocation:anInvocation];
    }
}

@end
