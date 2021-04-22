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
#import <objc/runtime.h>

#pragma mark - UIView+FWEmptyPlugin

@implementation FWEmptyPluginConfig

+ (FWEmptyPluginConfig *)sharedInstance
{
    static FWEmptyPluginConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWEmptyPluginConfig alloc] init];
    });
    return instance;
}

@end

@implementation UIView (FWEmptyPlugin)

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
    [self addSubview:emptyView];
    [emptyView fwPinEdgesToSuperview];
    [emptyView setLoadingViewHidden:YES];
    [emptyView setImage:emptyImage];
    [emptyView setTextLabelText:emptyText];
    [emptyView setDetailTextLabelText:emptyDetail];
    [emptyView setActionButtonTitle:emptyAction];
    if (block) [emptyView.actionButton fwAddTouchBlock:block];
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

- (BOOL)fwExistsEmptyView
{
    id<FWEmptyPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWEmptyPlugin)];
    if (plugin && [plugin respondsToSelector:@selector(fwExistsEmptyView:)]) {
        return [plugin fwExistsEmptyView:self];
    }
    
    UIView *emptyView = [self viewWithTag:2021];
    return emptyView != nil ? YES : NO;
}

@end

#pragma mark - UIScrollView+FWEmptyView

@interface FWEmptyContentView : UIView

@end

@implementation FWEmptyContentView

- (void)didMoveToSuperview
{
    self.frame = self.superview.bounds;
}

@end

@implementation UIScrollView (FWEmptyView)

+ (void)fwEnableEmptyDelegate
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
    if (!delegate) [self fwRemoveEmptyView];
    objc_setAssociatedObject(self, @selector(fwEmptyViewDelegate), [[FWWeakObject alloc] initWithObject:delegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [UIScrollView fwEnableEmptyDelegate];
}

- (BOOL)fwIsEmptyViewVisible
{
    return self.fwEmptyContentView ? YES : NO;
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
    
    [self fwRemoveEmptyView];
    
    if (shouldDisplay) {
        UIView *contentView = [FWEmptyContentView new];
        self.fwEmptyContentView = contentView;
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        contentView.userInteractionEnabled = YES;
        contentView.backgroundColor = [UIColor clearColor];
        contentView.clipsToBounds = YES;
        if (([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]]) && self.subviews.count > 1) {
            [self insertSubview:contentView atIndex:0];
        } else {
            [self addSubview:contentView];
        }
        
        if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwEmptyViewShouldScroll:)]) {
            self.scrollEnabled = [self.fwEmptyViewDelegate fwEmptyViewShouldScroll:self];
        } else {
            self.scrollEnabled = NO;
        }
        
        if ([self.fwEmptyViewDelegate respondsToSelector:@selector(fwShowEmptyView:scrollView:)]) {
            [self.fwEmptyViewDelegate fwShowEmptyView:contentView scrollView:self];
        } else {
            [contentView fwShowEmptyView];
        }
    }
}

- (void)fwRemoveEmptyView
{
    UIView *contentView = self.fwEmptyContentView;
    if (!contentView) return;
    
    self.scrollEnabled = YES;
    
    if (self.fwEmptyViewDelegate && [self.fwEmptyViewDelegate respondsToSelector:@selector(fwHideEmptyView:scrollView:)]) {
        [self.fwEmptyViewDelegate fwHideEmptyView:contentView scrollView:self];
    } else {
        [contentView fwHideEmptyView];
    }
    
    if (contentView.superview) {
        [contentView removeFromSuperview];
    }
    self.fwEmptyContentView = nil;
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

- (UIView *)fwEmptyContentView
{
    return objc_getAssociatedObject(self, @selector(fwEmptyContentView));
}

- (void)setFwEmptyContentView:(UIView *)contentView
{
    objc_setAssociatedObject(self, @selector(fwEmptyContentView), contentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
