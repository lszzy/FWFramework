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
#import "FWPlugin.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

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
    id<FWEmptyPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWEmptyPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwShowEmptyViewWithText:detail:image:action:block:inView:)]) {
        plugin = FWEmptyPluginImpl.sharedInstance;
    }
    
    if ([self isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self;
        [scrollView fwShowOverlayView];
        [plugin fwShowEmptyViewWithText:text detail:detail image:image action:action block:block inView:scrollView.fwOverlayView];
    } else {
        [plugin fwShowEmptyViewWithText:text detail:detail image:image action:action block:block inView:self];
    }
}

- (void)fwHideEmptyView
{
    id<FWEmptyPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWEmptyPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwHideEmptyView:)]) {
        plugin = FWEmptyPluginImpl.sharedInstance;
    }
    
    if ([self isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self;
        [plugin fwHideEmptyView:scrollView.fwOverlayView];
        [scrollView fwHideOverlayView];
    } else {
        [plugin fwHideEmptyView:self];
    }
}

- (BOOL)fwHasEmptyView
{
    id<FWEmptyPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWEmptyPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwHasEmptyView:)]) {
        plugin = FWEmptyPluginImpl.sharedInstance;
    }
    
    if ([self isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self;
        return scrollView.fwHasOverlayView && [plugin fwHasEmptyView:scrollView.fwOverlayView];;
    } else {
        return [plugin fwHasEmptyView:self];
    }
}

@end

@implementation UIViewController (FWEmptyPluginView)

- (void)fwShowEmptyView
{
    [self.view fwShowEmptyView];
}

- (void)fwShowEmptyViewWithText:(NSString *)text
{
    [self.view fwShowEmptyViewWithText:text];
}

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail
{
    [self.view fwShowEmptyViewWithText:text detail:detail];
}

- (void)fwShowEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image
{
    [self.view fwShowEmptyViewWithText:text detail:detail image:image];
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
    if (!delegate) [self fwInvalidateEmptyView];
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
    
    BOOL hideSuccess = [self fwInvalidateEmptyView];
    if (shouldDisplay) {
        objc_setAssociatedObject(self, @selector(fwInvalidateEmptyView), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldScroll:)]) {
            self.scrollEnabled = [self.fwEmptyViewDelegate fwEmptyViewShouldScroll:self];
        } else {
            self.scrollEnabled = NO;
        }
        
        BOOL fadeAnimated = FWEmptyPluginImpl.sharedInstance.fadeAnimated;
        FWEmptyPluginImpl.sharedInstance.fadeAnimated = hideSuccess ? NO : fadeAnimated;
        if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwShowEmptyView:)]) {
            [self.fwEmptyViewDelegate fwShowEmptyView:self];
        } else {
            [self fwShowEmptyView];
        }
        FWEmptyPluginImpl.sharedInstance.fadeAnimated = fadeAnimated;
    }
}

- (BOOL)fwInvalidateEmptyView
{
    if (![objc_getAssociatedObject(self, @selector(fwInvalidateEmptyView)) boolValue]) return NO;
    objc_setAssociatedObject(self, @selector(fwInvalidateEmptyView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    self.scrollEnabled = YES;
    
    if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwHideEmptyView:)]) {
        [self.fwEmptyViewDelegate fwHideEmptyView:self];
    } else {
        [self fwHideEmptyView];
    }
    return YES;
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
