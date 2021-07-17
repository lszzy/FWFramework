/*!
 @header     FWNavigationView.m
 @indexgroup FWFramework
 @brief      FWNavigationView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import "FWNavigationView.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import "FWAdaptive.h"
#import "FWBlock.h"
#import "FWRouter.h"
#import "FWViewControllerStyle.h"
#import <objc/runtime.h>

#pragma mark - FWNavigationView

@implementation FWNavigationView

- (instancetype)init
{
    return [self initWithFrame:CGRectMake(0, 0, FWScreenWidth, FWTopBarHeight)];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) [self setupView];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) [self setupView];
    return self;
}

- (void)setupView
{
    _navigationItem = [[UINavigationItem alloc] init];
    _navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, self.frame.size.height - FWNavigationBarHeight, self.frame.size.width, FWNavigationBarHeight)];
    _navigationBar.items = @[_navigationItem];
    [self addSubview:_navigationBar];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.navigationBar.frame = CGRectMake(0, self.frame.size.height - self.navigationBar.frame.size.height, self.frame.size.width, self.navigationBar.frame.size.height);
}

@end

#pragma mark - UIViewController+FWNavigationView

@implementation UIViewController (FWNavigationView)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationBar, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if ([selfObject.superview isKindOfClass:[FWNavigationView class]]) {
                UIView *backgroundView = selfObject.fwBackgroundView;
                backgroundView.frame = CGRectMake(backgroundView.frame.origin.x, -(selfObject.superview.bounds.size.height - backgroundView.frame.size.height), backgroundView.frame.size.width, selfObject.superview.bounds.size.height);
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwView), FWSwizzleReturn(UIView *), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            return selfObject.fwContainerView;
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwNavigationBar), FWSwizzleReturn(UINavigationBar *), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            return selfObject.fwNavigationView.navigationBar;
        }));
        
        FWSwizzleClass(UIViewController, @selector(navigationItem), FWSwizzleReturn(UINavigationItem *), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            return selfObject.fwNavigationView.navigationItem;
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwNavigationBarHeight), FWSwizzleReturn(CGFloat), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            
            if (selfObject.fwNavigationView.isHidden) return 0.0;
            return selfObject.fwNavigationView.navigationBar.frame.size.height;
        }));
        
        FWSwizzleClass(UIViewController, @selector(fwTopBarHeight), FWSwizzleReturn(CGFloat), FWSwizzleArgs(), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal();
            
            if (selfObject.fwNavigationView.isHidden) return 0.0;
            return selfObject.fwNavigationView.frame.size.height;
        }));
        
        FWSwizzleClass(UIViewController, @selector(setFwBackBarItem:), FWSwizzleReturn(void), FWSwizzleArgs(id object), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) {
                FWSwizzleOriginal(object);
                return;
            }
            
            UIBarButtonItem *backItem;
            if ([object isKindOfClass:[UIBarButtonItem class]]) {
                backItem = (UIBarButtonItem *)object;
            } else {
                backItem = [UIBarButtonItem fwBarItemWithObject:(object ?: [UIImage new]) target:nil action:nil];
            }
            selfObject.navigationItem.backBarButtonItem = backItem;
        }));
        
        FWSwizzleClass(UIViewController, @selector(loadView), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            if (!selfObject.fwNavigationViewEnabled) return;
            
            BOOL hidden = selfObject.fwNavigationBarHidden || !selfObject.navigationController;
            selfObject.fwNavigationView.hidden = hidden;
            [selfObject fwNavigationViewUpdateLayout];
            [selfObject.view addSubview:selfObject.fwNavigationView];
            [selfObject.view addSubview:selfObject.fwContainerView];
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidLayoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            if (!selfObject.fwNavigationViewEnabled) return;
            
            [selfObject fwNavigationViewUpdateLayout];
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillTransitionToSize:withTransitionCoordinator:), FWSwizzleReturn(void), FWSwizzleArgs(CGSize size, id<UIViewControllerTransitionCoordinator> coordinator), FWSwizzleCode({
            FWSwizzleOriginal(size, coordinator);
            if (!selfObject.fwNavigationViewEnabled) return;
            
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                [selfObject fwNavigationViewUpdateLayout];
            } completion:nil];
        }));
        
        FWSwizzleClass(UIViewController, NSSelectorFromString(@"fwSetNavigationBarHidden:animated:"), FWSwizzleReturn(void), FWSwizzleArgs(BOOL hidden, BOOL animated), FWSwizzleCode({
            if (!selfObject.fwNavigationViewEnabled) return FWSwizzleOriginal(hidden, animated);
            
            FWSwizzleOriginal(YES, animated);
            selfObject.fwNavigationView.hidden = hidden;
            [selfObject fwNavigationViewUpdateLayout];
            
            if (selfObject.navigationItem.leftBarButtonItem && selfObject.navigationItem.leftBarButtonItem != selfObject.navigationItem.backBarButtonItem) return;
            if (selfObject.navigationController.viewControllers.firstObject == selfObject) {
                selfObject.navigationItem.leftBarButtonItem = nil;
            } else if (selfObject.navigationItem.leftBarButtonItem != selfObject.navigationItem.backBarButtonItem) {
                [selfObject.navigationItem.backBarButtonItem fwSetBlock:^(id sender) {
                    if (![selfObject fwPopBackBarItem]) return;
                    [selfObject fwCloseViewControllerAnimated:YES];
                }];
                selfObject.navigationItem.leftBarButtonItem = selfObject.navigationItem.backBarButtonItem;
            }
        }));
    });
}

- (FWNavigationView *)fwNavigationView
{
    FWNavigationView *navigationView = objc_getAssociatedObject(self, _cmd);
    if (!navigationView) {
        navigationView = [[FWNavigationView alloc] init];
        objc_setAssociatedObject(self, _cmd, navigationView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return navigationView;
}

- (UIView *)fwContainerView
{
    UIView *containerView = objc_getAssociatedObject(self, _cmd);
    if (!containerView) {
        containerView = [[UIView alloc] init];
        objc_setAssociatedObject(self, _cmd, containerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return containerView;
}

- (BOOL)fwNavigationViewEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwNavigationViewEnabled)) boolValue];
}

- (void)setFwNavigationViewEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fwNavigationViewEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwNavigationViewUpdateLayout
{
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    CGFloat barHeight = navigationBar.frame.size.height;
    if (!navigationBar || barHeight < 1) {
        CGFloat topHeight = self.fwNavigationView.isHidden ? 0 : self.fwNavigationView.bounds.size.height;
        self.fwContainerView.frame = CGRectMake(0, topHeight, self.view.bounds.size.width, self.view.bounds.size.height - topHeight);
        return;
    }
    
    CGFloat staticHeight = FWTopBarHeight;
    if (@available(iOS 13.0, *)) {
        BOOL isPageSheet = self.navigationController.modalPresentationStyle == UIModalPresentationAutomatic || self.navigationController.modalPresentationStyle == UIModalPresentationPageSheet;
        isPageSheet = isPageSheet && self.navigationController.presentingViewController != nil;
        if (isPageSheet) staticHeight = barHeight;
    }
    self.fwNavigationView.frame = CGRectMake(self.fwNavigationView.frame.origin.x, self.fwNavigationView.frame.origin.y, navigationBar.frame.size.width, staticHeight);
    self.fwNavigationView.navigationBar.frame = CGRectMake(0, staticHeight - barHeight, navigationBar.frame.size.width, barHeight);
    CGFloat topHeight = self.fwNavigationView.isHidden ? 0 : staticHeight;
    self.fwContainerView.frame = CGRectMake(0, topHeight, self.view.bounds.size.width, self.view.bounds.size.height - topHeight);
}

@end
