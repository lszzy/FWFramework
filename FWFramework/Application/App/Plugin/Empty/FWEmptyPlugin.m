/*!
 @header     FWEmptyPlugin.m
 @indexgroup FWFramework
 @brief      FWEmptyPlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import "FWEmptyPlugin.h"
#import "FWEmptyPluginImpl.h"
#import "FWAutoLayout.h"
#import "FWBlock.h"
#import "FWPlugin.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import <objc/runtime.h>

#pragma mark - FWEmptyPlugin

@implementation FWEmptyPluginConfig

+ (FWEmptyPluginConfig *)sharedInstance
{
    static FWEmptyPluginConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWEmptyPluginConfig alloc] init];
        instance.fadeAnimated = YES;
    });
    return instance;
}

@end

#pragma mark - FWEmptyPluginView

@implementation UIView (FWEmptyPluginView)

- (void)fwShowEmptyView
{
    [self fwShowEmptyViewWithText:nil];
}

- (void)fwShowEmptyViewWithText:(NSString *)text
{
    [self fwShowEmptyViewWithText:text detail:nil];
}

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail
{
    [self fwShowEmptyViewWithText:text detail:detail image:nil];
}

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image
{
    [self fwShowEmptyViewWithText:text detail:detail image:image action:nil block:nil];
}

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image action:(NSString *)action block:(void (^)(id _Nonnull))block
{
    NSString *emptyText = text;
    if (!emptyText && FWEmptyPluginConfig.sharedInstance.defaultText) {
        emptyText = FWEmptyPluginConfig.sharedInstance.defaultText();
    }
    NSString *emptyDetail = detail;
    if (!emptyDetail && FWEmptyPluginConfig.sharedInstance.defaultDetail) {
        emptyDetail = FWEmptyPluginConfig.sharedInstance.defaultDetail();
    }
    UIImage *emptyImage = image;
    if (!emptyImage && FWEmptyPluginConfig.sharedInstance.defaultImage) {
        emptyImage = FWEmptyPluginConfig.sharedInstance.defaultImage();
    }
    NSString *emptyAction = action;
    if (!emptyAction && block && FWEmptyPluginConfig.sharedInstance.defaultAction) {
        emptyAction = FWEmptyPluginConfig.sharedInstance.defaultAction();
    }
    
    id<FWEmptyPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWEmptyPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwShowEmptyViewWithText:detail:image:action:block:inView:)]) {
        [plugin fwShowEmptyViewWithText:emptyText detail:emptyDetail image:emptyImage action:emptyAction block:block inView:self];
        return;
    }
    
    FWEmptyView *emptyView = [self viewWithTag:2021];
    if (emptyView) { [emptyView removeFromSuperview]; }
    
    emptyView = [[FWEmptyView alloc] initWithFrame:self.bounds];
    emptyView.tag = 2021;
    emptyView.alpha = 0;
    [self addSubview:emptyView];
    [emptyView fwPinEdgesToSuperview];
    [emptyView setLoadingViewHidden:YES];
    [emptyView setImage:emptyImage];
    [emptyView setTextLabelText:emptyText];
    [emptyView setDetailTextLabelText:emptyDetail];
    [emptyView setActionButtonTitle:emptyAction];
    if (block) [emptyView.actionButton fwAddTouchBlock:block];
    
    if (FWEmptyPluginConfig.sharedInstance.fadeAnimated) {
        [UIView animateWithDuration:0.25 animations:^{
            emptyView.alpha = 1.0;
        } completion:NULL];
    } else {
        emptyView.alpha = 1.0;
    }
}

- (void)fwHideEmptyView
{
    id<FWEmptyPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWEmptyPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHideEmptyView:)]) {
        [plugin fwHideEmptyView:self];
        return;
    }
    
    UIView *emptyView = [self viewWithTag:2021];
    if (emptyView) { [emptyView removeFromSuperview]; }
}

- (BOOL)fwHasEmptyView
{
    id<FWEmptyPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWEmptyPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwHasEmptyView:)]) {
        return [plugin fwHasEmptyView:self];
    }
    
    UIView *emptyView = [self viewWithTag:2021];
    return emptyView != nil ? YES : NO;
}

@end

@implementation UIScrollView (FWEmptyPluginView)

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image action:(NSString *)action block:(void (^)(id _Nonnull))block
{
    [self fwShowOverlayView];
    [self.fwOverlayView fwShowEmptyViewWithText:text detail:detail image:image action:action block:block];
}

- (void)fwHideEmptyView
{
    [self.fwOverlayView fwHideEmptyView];
    [self fwHideOverlayView];
}

- (BOOL)fwHasEmptyView
{
    return self.fwHasOverlayView && [self.fwOverlayView fwHasEmptyView];
}

@end

@implementation UIViewController (FWEmptyPluginView)

- (void)fwShowEmptyView
{
    [self fwShowEmptyViewWithText:nil];
}

- (void)fwShowEmptyViewWithText:(NSString *)text
{
    [self fwShowEmptyViewWithText:text detail:nil];
}

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail
{
    [self fwShowEmptyViewWithText:text detail:detail image:nil];
}

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image
{
    [self fwShowEmptyViewWithText:text detail:detail image:image action:nil block:nil];
}

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image action:(NSString *)action block:(void (^)(id _Nonnull))block
{
    [self.view fwShowEmptyViewWithText:text detail:detail image:image action:action block:block];
}

- (void)fwHideEmptyView
{
    [self.view fwHideEmptyView];
}

- (BOOL)fwHasEmptyView
{
    return [self.view fwHasEmptyView];
}

@end

#pragma mark - UIScrollView+FWEmptyPlugin

@implementation UIScrollView (FWEmptyPlugin)

+ (void)fwEnableEmptyPlugin
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UITableView, @selector(reloadData), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            [selfObject fwReloadEmptyView];
            FWSwizzleOriginal();
        }));
        
        FWSwizzleClass(UITableView, @selector(endUpdates), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            [selfObject fwReloadEmptyView];
            FWSwizzleOriginal();
        }));
        
        FWSwizzleClass(UICollectionView, @selector(reloadData), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            [selfObject fwReloadEmptyView];
            FWSwizzleOriginal();
        }));
    });
}

- (id<FWEmptyViewDelegate>)fwEmptyViewDelegate
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwEmptyViewDelegate));
    return value.object;
}

- (void)setFwEmptyViewDelegate:(id<FWEmptyViewDelegate>)delegate
{
    if (!delegate) [self fwEmptyInvalidate];
    objc_setAssociatedObject(self, @selector(fwEmptyViewDelegate), [[FWWeakObject alloc] initWithObject:delegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [UIScrollView fwEnableEmptyPlugin];
}

- (void)fwReloadEmptyView
{
    if (!self.fwEmptyViewDelegate) return;
    
    BOOL shouldDisplay = NO;
    if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewForceDisplay:)]) {
        shouldDisplay = [self.fwEmptyViewDelegate fwEmptyViewForceDisplay:self];
    }
    if (!shouldDisplay) {
        if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldDisplay:)]) {
            shouldDisplay = [self.fwEmptyViewDelegate fwEmptyViewShouldDisplay:self] && [self fwEmptyItemsCount] == 0;
        } else {
            shouldDisplay = [self fwEmptyItemsCount] == 0;
        }
    }
    
    [self fwEmptyInvalidate];
    
    if (shouldDisplay) {
        if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldScroll:)]) {
            self.scrollEnabled = [self.fwEmptyViewDelegate fwEmptyViewShouldScroll:self];
        } else {
            self.scrollEnabled = NO;
        }
        
        if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwShowEmptyView:)]) {
            [self.fwEmptyViewDelegate fwShowEmptyView:self];
        } else {
            [self fwShowEmptyView];
        }
    }
}

- (void)fwEmptyInvalidate
{
    if (!self.fwEmptyViewDelegate) return;
    
    self.scrollEnabled = YES;
    
    if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwHideEmptyView:)]) {
        [self.fwEmptyViewDelegate fwHideEmptyView:self];
    } else {
        [self fwHideEmptyView];
    }
}

- (NSInteger)fwEmptyItemsCount
{
    NSInteger items = 0;
    if (![self respondsToSelector:@selector(dataSource)]) {
        return items;
    }
    
    if ([self isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self;
        id<UITableViewDataSource> dataSource = tableView.dataSource;
        
        NSInteger sections = 1;
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            sections = [dataSource numberOfSectionsInTableView:tableView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource tableView:tableView numberOfRowsInSection:section];
            }
        }
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        id<UICollectionViewDataSource> dataSource = collectionView.dataSource;
        
        NSInteger sections = 1;
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
            sections = [dataSource numberOfSectionsInCollectionView:collectionView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource collectionView:collectionView numberOfItemsInSection:section];
            }
        }
    }
    return items;
}

@end
