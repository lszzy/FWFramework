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
    
    // 解析协议列表，目前用不到父协议，暂不解析
    unsigned int count = 0;
    __unsafe_unretained Protocol **list = class_copyProtocolList(clazz, &count);
    NSMutableArray *protocolNames = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i++) {
        Protocol *protocol = list[i];
        const char *cName = protocol_getName(protocol);
        NSString *name = [NSString stringWithUTF8String:cName];
        [protocolNames addObject:name];
    }
    free(list);
    
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
        // 统一初始化视图控制器
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
        
        if ([viewController respondsToSelector:@selector(fwRenderInit)]) {
            [viewController performSelector:@selector(fwRenderInit)];
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
        
        if ([viewController respondsToSelector:@selector(fwRenderView)]) {
            [viewController performSelector:@selector(fwRenderView)];
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
        
        if ([viewController respondsToSelector:@selector(fwRenderModel)]) {
            [viewController performSelector:@selector(fwRenderModel)];
        }
        if ([viewController respondsToSelector:@selector(fwRenderData)]) {
            [viewController performSelector:@selector(fwRenderData)];
        }
    }
}

#pragma mark - FWViewController

- (void)viewControllerInit:(UIViewController *)viewController
{
    // 默认不被导航栏等遮挡，隐藏TabBar；如果不同，覆盖即可
    viewController.edgesForExtendedLayout = UIRectEdgeNone;
    viewController.hidesBottomBarWhenPushed = YES;
}

@end

#pragma mark - UIViewController+FWViewController

@interface UIViewController (FWViewController)

@end

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
    if (![self fwInnerRespondsToSelector:aSelector] && [self conformsToProtocol:@protocol(FWViewController)]) {
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
    SEL forwardSelector = [self fwInnerForwardSelector:aSelector];
    if (!forwardSelector) {
        return [self fwInnerRespondsToSelector:aSelector];
    } else {
        return YES;
    }
}

- (NSMethodSignature *)fwInnerMethodSignatureForSelector:(SEL)aSelector
{
    SEL forwardSelector = [self fwInnerForwardSelector:aSelector];
    if (!forwardSelector) {
        return [self fwInnerMethodSignatureForSelector:aSelector];
    } else {
        return [self.class instanceMethodSignatureForSelector:forwardSelector];
    }
}

- (void)fwInnerForwardInvocation:(NSInvocation *)anInvocation
{
    SEL forwardSelector = [self fwInnerForwardSelector:anInvocation.selector];
    if (!forwardSelector) {
        [self fwInnerForwardInvocation:anInvocation];
    } else {
        anInvocation.selector = forwardSelector;
        [anInvocation invoke];
    }
}

@end
