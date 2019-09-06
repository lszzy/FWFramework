/*!
 @header     FWViewController.m
 @indexgroup FWFramework
 @brief      FWViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWViewController.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

#pragma mark - UIViewController+FWViewController

@interface UIViewController (FWViewController)

- (SEL)fwInnerForwardSelector:(SEL)aSelector;

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

- (id)performIntercepter:(UIViewController *)viewController withSelector:(SEL)aSelector
{
    SEL forwardSelector = [viewController fwInnerForwardSelector:aSelector];
    if (forwardSelector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [viewController performSelector:forwardSelector];
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
        // 全局控制器init
        [self viewControllerInit:viewController];
        
        // 调用init拦截器
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
        
        if ([viewController respondsToSelector:@selector(renderInit)]) {
            [viewController performSelector:@selector(renderInit)];
        }
    }
}

- (void)hookLoadView:(UIViewController *)viewController
{
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
        // 调用loadView拦截器
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
        
        if ([viewController respondsToSelector:@selector(renderView)]) {
            [viewController performSelector:@selector(renderView)];
        }
    }
}

- (void)hookViewDidLoad:(UIViewController *)viewController
{
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
        // 调用viewDidLoad拦截器
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
        
        if ([viewController respondsToSelector:@selector(renderModel)]) {
            [viewController performSelector:@selector(renderModel)];
        }
        if ([viewController respondsToSelector:@selector(renderData)]) {
            [viewController performSelector:@selector(renderData)];
        }
    }
}

#pragma mark - FWViewController

- (void)viewControllerInit:(UIViewController *)viewController
{
    // 默认不被导航栏等遮挡，隐藏TabBar；如果不同，覆盖即可
    viewController.edgesForExtendedLayout = UIRectEdgeNone;
    // 开启不透明bar(translucent为NO)情况下延伸包括bar，占满全屏
    viewController.extendedLayoutIncludesOpaqueBars = YES;
    // 解决iOS7-10时scrollView占不满导航栏问题
    viewController.automaticallyAdjustsScrollViewInsets = NO;
    // 默认push时隐藏TabBar，TabBar初始化控制器时设置为NO
    viewController.hidesBottomBarWhenPushed = YES;
}

@end

#pragma mark - UIViewController+FWViewController

@implementation UIViewController (FWViewController)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIViewController fwSwizzleInstanceMethod:@selector(initWithNibName:bundle:) with:@selector(fwInnerInitWithNibName:bundle:)];
        [UIViewController fwSwizzleInstanceMethod:@selector(loadView) with:@selector(fwInnerLoadView)];
        [UIViewController fwSwizzleInstanceMethod:@selector(viewDidLoad) with:@selector(fwInnerViewDidLoad)];
        
        [UIViewController fwSwizzleInstanceMethod:@selector(respondsToSelector:) with:@selector(fwInnerRespondsToSelector:)];
        [UIViewController fwSwizzleInstanceMethod:@selector(methodSignatureForSelector:) with:@selector(fwInnerMethodSignatureForSelector:)];
        [UIViewController fwSwizzleInstanceMethod:@selector(forwardInvocation:) with:@selector(fwInnerForwardInvocation:)];
    });
}

#pragma mark - Hook

- (instancetype)fwInnerInitWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    id instance = [self fwInnerInitWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    [[FWViewControllerManager sharedInstance] hookInit:instance];
    return instance;
}

- (void)fwInnerLoadView
{
    [self fwInnerLoadView];
    [[FWViewControllerManager sharedInstance] hookLoadView:self];
}

- (void)fwInnerViewDidLoad
{
    [self fwInnerViewDidLoad];
    [[FWViewControllerManager sharedInstance] hookViewDidLoad:self];
}

#pragma mark - Forward

- (NSMutableDictionary *)fwInnerForwardSelectors
{
    NSMutableDictionary *forwardSelectors = objc_getAssociatedObject(self, _cmd);
    if (!forwardSelectors) {
        forwardSelectors = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, forwardSelectors, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return forwardSelectors;
}

- (SEL)fwInnerForwardSelector:(SEL)aSelector
{
    if ([self conformsToProtocol:@protocol(FWViewController)]) {
        // 查找forward方法缓存是否存在
        NSString *selectorName = NSStringFromSelector(aSelector);
        NSString *forwardName = [[self fwInnerForwardSelectors] objectForKey:selectorName];
        if (!forwardName) {
            // 如果缓存不存在，查找一次并生成缓存
            forwardName = [[FWViewControllerManager sharedInstance] forwardSelector:selectorName withClass:self.class];
            [[self fwInnerForwardSelectors] setObject:(forwardName ?: @"") forKey:selectorName];
        }
        
        SEL forwardSelector = forwardName.length > 0 ? NSSelectorFromString(forwardName) : NULL;
        if (forwardSelector && [self fwInnerRespondsToSelector:forwardSelector]) {
            return forwardSelector;
        }
    }
    return NULL;
}

- (BOOL)fwInnerRespondsToSelector:(SEL)aSelector
{
    if ([self fwInnerRespondsToSelector:aSelector]) {
        return YES;
    } else {
        SEL forwardSelector = [self fwInnerForwardSelector:aSelector];
        return forwardSelector ? YES : NO;
    }
}

- (NSMethodSignature *)fwInnerMethodSignatureForSelector:(SEL)aSelector
{
    SEL forwardSelector = NULL;
    if (![self fwInnerRespondsToSelector:aSelector]) {
        forwardSelector = [self fwInnerForwardSelector:aSelector];
    }
    if (forwardSelector) {
        return [self.class instanceMethodSignatureForSelector:forwardSelector];
    } else {
        return [self fwInnerMethodSignatureForSelector:aSelector];
    }
}

- (void)fwInnerForwardInvocation:(NSInvocation *)anInvocation
{
    SEL forwardSelector = NULL;
    if (![self fwInnerRespondsToSelector:anInvocation.selector]) {
        forwardSelector = [self fwInnerForwardSelector:anInvocation.selector];
    }
    if (forwardSelector) {
        anInvocation.selector = forwardSelector;
        [anInvocation invoke];
    } else {
        [self fwInnerForwardInvocation:anInvocation];
    }
}

@end
