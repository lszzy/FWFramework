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
#import "FWScrollViewController.h"

@interface UIViewController (FWViewController)

@end

@implementation UIViewController (FWViewController)

+ (void)load
{
    [UIViewController fwSwizzleInstanceMethod:@selector(methodSignatureForSelector:) with:@selector(fwInnerMethodSignatureForSelector:)];
    [UIViewController fwSwizzleInstanceMethod:@selector(forwardInvocation:) with:@selector(fwInnerForwardInvocation:)];
}

- (NSMethodSignature *)fwInnerMethodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *methodSignature = [self fwInnerMethodSignatureForSelector:aSelector];
    // 挂钩处理FWViewController
    if (![self respondsToSelector:aSelector] && [self conformsToProtocol:@protocol(FWViewController)]) {
        // 替换实现fwXXX为fwInnerXXX
        SEL hookSelector = NSSelectorFromString([NSStringFromSelector(aSelector) stringByReplacingOccurrencesOfString:@"fw" withString:@"fwInner"]);
        if ([self respondsToSelector:hookSelector]) {
            methodSignature = [self.class instanceMethodSignatureForSelector:hookSelector];
        }
    }
    return methodSignature;
}

- (void)fwInnerForwardInvocation:(NSInvocation *)anInvocation
{
    // 挂钩处理FWViewController
    if (![self respondsToSelector:anInvocation.selector] && [self conformsToProtocol:@protocol(FWViewController)]) {
        // 替换实现fwXXX为fwInnerXXX
        SEL hookSelector = NSSelectorFromString([NSStringFromSelector(anInvocation.selector) stringByReplacingOccurrencesOfString:@"fw" withString:@"fwInner"]);
        if ([self respondsToSelector:hookSelector]) {
            anInvocation.selector = hookSelector;
            [anInvocation invoke];
        } else {
            [self fwInnerForwardInvocation:anInvocation];
        }
    } else {
        [self fwInnerForwardInvocation:anInvocation];
    }
}

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

#pragma mark - Hook

- (void)hookInit:(UIViewController *)viewController
{
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
        if ([viewController respondsToSelector:@selector(fwRenderInit)]) {
            [viewController performSelector:@selector(fwRenderInit)];
        }
    }
}

- (void)hookLoadView:(UIViewController *)viewController
{
    if ([viewController conformsToProtocol:@protocol(FWScrollViewController)]) {
        [self setupScrollViewController:viewController];
    }
    
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
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

@end
