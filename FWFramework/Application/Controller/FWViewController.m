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
#import "FWAspect.h"
#import <objc/runtime.h>

#pragma mark - FWViewControllerIntercepter

@interface FWViewControllerIntercepter ()

@property (nonatomic, strong) NSMutableDictionary *intercepters;
@property (nonatomic, strong) NSMutableDictionary *forwardSelectors;

@end

@implementation FWViewControllerIntercepter

+ (void)load
{
    [FWViewControllerIntercepter sharedInstance];
}

+ (FWViewControllerIntercepter *)sharedInstance
{
    static FWViewControllerIntercepter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWViewControllerIntercepter alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _intercepters = [NSMutableDictionary dictionary];
        _forwardSelectors = [NSMutableDictionary dictionary];
        
        [UIViewController fwHookSelector:@selector(initWithNibName:bundle:) withBlock:^(id<FWAspectInfo>aspectInfo){
            [self hookInit:aspectInfo.instance];
        } options:FWAspectPositionAfter error:NULL];
        
        [UIViewController fwHookSelector:@selector(loadView) withBlock:^(id<FWAspectInfo>aspectInfo){
            [self hookLoadView:aspectInfo.instance];
        } options:FWAspectPositionAfter error:NULL];
        
        [UIViewController fwHookSelector:@selector(viewDidLoad) withBlock:^(id<FWAspectInfo>aspectInfo){
            [self hookViewDidLoad:aspectInfo.instance];
        } options:FWAspectPositionAfter error:NULL];
    }
    return self;
}

#pragma mark - Public

- (void)registerProtocol:(Protocol *)protocol
         withIntercepter:(SEL)intercepter
        forwardSelectors:(NSDictionary *)forwardSelectors
{
    NSString *protocolName = NSStringFromProtocol(protocol);
    [self.intercepters setObject:NSStringFromSelector(intercepter) forKey:protocolName];
    if (forwardSelectors) {
        [self.forwardSelectors setObject:forwardSelectors forKey:protocolName];
    } else {
        [self.forwardSelectors removeObjectForKey:protocolName];
    }
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
        NSDictionary *forwardSelectors = [self.forwardSelectors objectForKey:protocolName];
        forwardName = forwardSelectors ? [forwardSelectors objectForKey:selectorName] : nil;
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
        // 统一设置视图控制器
        [self setupViewController:viewController];
        
        if ([viewController respondsToSelector:@selector(fwRenderInit)]) {
            [viewController performSelector:@selector(fwRenderInit)];
        }
    }
}

- (void)hookLoadView:(UIViewController *)viewController
{
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
        // 调用对应拦截器
        NSArray *protocolNames = [self protocolsWithClass:viewController.class];
        for (NSString *protocolName in protocolNames) {
            NSString *intercepter = [self.intercepters objectForKey:protocolName];
            SEL intercepterSelector = intercepter ? NSSelectorFromString(intercepter) : NULL;
            if (intercepterSelector && [self respondsToSelector:intercepterSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:intercepterSelector withObject:viewController];
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
        if ([viewController respondsToSelector:@selector(fwRenderModel)]) {
            [viewController performSelector:@selector(fwRenderModel)];
        }
        if ([viewController respondsToSelector:@selector(fwRenderData)]) {
            [viewController performSelector:@selector(fwRenderData)];
        }
    }
}

#pragma mark - FWViewController

- (void)setupViewController:(UIViewController *)viewController
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
    [UIViewController fwSwizzleInstanceMethod:@selector(respondsToSelector:) with:@selector(fwInnerRespondsToSelector:)];
    [UIViewController fwSwizzleInstanceMethod:@selector(methodSignatureForSelector:) with:@selector(fwInnerMethodSignatureForSelector:)];
    [UIViewController fwSwizzleInstanceMethod:@selector(forwardInvocation:) with:@selector(fwInnerForwardInvocation:)];
}

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
            forwardName = [[FWViewControllerIntercepter sharedInstance] forwardSelector:selectorName withClass:self.class];
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
