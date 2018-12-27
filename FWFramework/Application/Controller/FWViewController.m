/*!
 @header     FWViewController.m
 @indexgroup FWFramework
 @brief      FWViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWViewController.h"
#import "FWScrollViewController.h"
#import "FWAspect.h"

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
        [UIViewController fwHookSelector:@selector(initWithNibName:bundle:) withBlock:^(id<FWAspectInfo>aspectInfo, NSString *nibNameOrNil, NSBundle *nibBundleOrNil){
            [self loadInit:aspectInfo.instance];
        } options:FWAspectPositionAfter error:NULL];
        
        [UIViewController fwHookSelector:@selector(loadView) withBlock:^(id<FWAspectInfo>aspectInfo){
            [self loadView:aspectInfo.instance];
        } options:FWAspectPositionAfter error:NULL];
        
        [UIViewController fwHookSelector:@selector(viewDidLoad) withBlock:^(id<FWAspectInfo>aspectInfo){
            [self viewDidLoad:aspectInfo.instance];
        } options:FWAspectPositionAfter error:NULL];
    }
    return self;
}

#pragma mark - Hook

- (void)loadInit:(UIViewController *)viewController
{
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
        if ([viewController respondsToSelector:@selector(fwRenderInit)]) {
            [viewController performSelector:@selector(fwRenderInit)];
        }
    }
}

- (void)loadView:(UIViewController *)viewController
{
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
        [self setupViewController:viewController];
    }
    if ([viewController conformsToProtocol:@protocol(FWScrollViewController)]) {
        [self setupScrollViewController:viewController];
    }
    
    if ([viewController conformsToProtocol:@protocol(FWViewController)]) {
        if ([viewController respondsToSelector:@selector(fwRenderView)]) {
            [viewController performSelector:@selector(fwRenderView)];
        }
    }
}

- (void)viewDidLoad:(UIViewController *)viewController
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

#pragma mark - Private

- (void)setupViewController:(UIViewController *)viewController
{
    // 不做任何处理
}

@end
