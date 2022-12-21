//
//  FWEmptyPlugin.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWEmptyPlugin.h"
#import "FWEmptyPluginImpl.h"
#import "Plugin.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

+ (BOOL)fw_swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier block:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - UIView+FWEmptyPlugin

@implementation UIView (FWEmptyPlugin)

- (id<FWEmptyPlugin>)fw_emptyPlugin
{
    id<FWEmptyPlugin> emptyPlugin = objc_getAssociatedObject(self, @selector(fw_emptyPlugin));
    if (!emptyPlugin) emptyPlugin = [__FWPluginManager loadPlugin:@protocol(FWEmptyPlugin)];
    if (!emptyPlugin) emptyPlugin = FWEmptyPluginImpl.sharedInstance;
    return emptyPlugin;
}

- (void)setFw_emptyPlugin:(id<FWEmptyPlugin>)emptyPlugin
{
    objc_setAssociatedObject(self, @selector(fw_emptyPlugin), emptyPlugin, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)fw_emptyInsets
{
    UIView *view = self;
    if ([self isKindOfClass:[UIScrollView class]]) {
        view = ((UIScrollView *)self).fw_overlayView;
    }
    NSValue *insets = objc_getAssociatedObject(view, @selector(fw_emptyInsets));
    return insets ? [insets UIEdgeInsetsValue] : UIEdgeInsetsZero;
}

- (void)setFw_emptyInsets:(UIEdgeInsets)emptyInsets
{
    UIView *view = self;
    if ([self isKindOfClass:[UIScrollView class]]) {
        view = ((UIScrollView *)self).fw_overlayView;
    }
    objc_setAssociatedObject(view, @selector(fw_emptyInsets), [NSValue valueWithUIEdgeInsets:emptyInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_showEmptyView
{
    [self fw_showEmptyViewWithText:nil];
}

- (void)fw_showEmptyViewLoading
{
    [self fw_showEmptyViewWithText:nil detail:nil image:nil loading:YES action:nil block:nil];
}

- (void)fw_showEmptyViewWithText:(NSString *)text
{
    [self fw_showEmptyViewWithText:text detail:nil];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail
{
    [self fw_showEmptyViewWithText:text detail:detail image:nil];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image
{
    [self fw_showEmptyViewWithText:text detail:detail image:image action:nil block:nil];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image action:(NSString *)action block:(void (^)(id _Nonnull))block
{
    [self fw_showEmptyViewWithText:text detail:detail image:image loading:NO action:action block:block];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image loading:(BOOL)loading action:(NSString *)action block:(void (^)(id _Nonnull))block
{
    [self fw_showEmptyViewWithText:text detail:detail image:image loading:loading actions:action ? @[action] : nil block:block ? ^(NSInteger index, id  _Nonnull sender) { if (block) block(sender); } : nil];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image loading:(BOOL)loading actions:(NSArray<NSString *> *)actions block:(void (^)(NSInteger, id _Nonnull))block
{
    id<FWEmptyPlugin> plugin = self.fw_emptyPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(showEmptyViewWithText:detail:image:loading:actions:block:inView:)]) {
        plugin = FWEmptyPluginImpl.sharedInstance;
    }
    
    if ([self isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self;
        [scrollView fw_showOverlayView];
        [plugin showEmptyViewWithText:text detail:detail image:image loading:loading actions:actions block:block inView:scrollView.fw_overlayView];
    } else {
        [plugin showEmptyViewWithText:text detail:detail image:image loading:loading actions:actions block:block inView:self];
    }
}

- (void)fw_hideEmptyView
{
    id<FWEmptyPlugin> plugin = self.fw_emptyPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(hideEmptyView:)]) {
        plugin = FWEmptyPluginImpl.sharedInstance;
    }
    
    if ([self isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self;
        [plugin hideEmptyView:scrollView.fw_overlayView];
        [scrollView fw_hideOverlayView];
    } else {
        [plugin hideEmptyView:self];
    }
}

- (BOOL)fw_hasEmptyView
{
    id<FWEmptyPlugin> plugin = self.fw_emptyPlugin;
    if (!plugin || ![plugin respondsToSelector:@selector(hasEmptyView:)]) {
        plugin = FWEmptyPluginImpl.sharedInstance;
    }
    
    if ([self isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self;
        return scrollView.fw_hasOverlayView && [plugin hasEmptyView:scrollView.fw_overlayView];;
    } else {
        return [plugin hasEmptyView:self];
    }
}

@end

#pragma mark - UIViewController+FWEmptyPlugin

@implementation UIViewController (FWEmptyPlugin)

- (UIEdgeInsets)fw_emptyInsets
{
    return self.view.fw_emptyInsets;
}

- (void)setFw_emptyInsets:(UIEdgeInsets)emptyInsets
{
    self.view.fw_emptyInsets = emptyInsets;
}

- (void)fw_showEmptyView
{
    [self.view fw_showEmptyView];
}

- (void)fw_showEmptyViewLoading
{
    [self.view fw_showEmptyViewLoading];
}

- (void)fw_showEmptyViewWithText:(NSString *)text
{
    [self.view fw_showEmptyViewWithText:text];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail
{
    [self.view fw_showEmptyViewWithText:text detail:detail];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image
{
    [self.view fw_showEmptyViewWithText:text detail:detail image:image];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image action:(NSString *)action block:(void (^)(id _Nonnull))block
{
    [self.view fw_showEmptyViewWithText:text detail:detail image:image action:action block:block];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image loading:(BOOL)loading action:(NSString *)action block:(void (^)(id _Nonnull))block
{
    [self.view fw_showEmptyViewWithText:text detail:detail image:image loading:loading action:action block:block];
}

- (void)fw_showEmptyViewWithText:(NSString *)text detail:(NSString *)detail image:(UIImage *)image loading:(BOOL)loading actions:(NSArray<NSString *> *)actions block:(void (^)(NSInteger, id _Nonnull))block
{
    [self.view fw_showEmptyViewWithText:text detail:detail image:image loading:loading actions:actions block:block];
}

- (void)fw_hideEmptyView
{
    [self.view fw_hideEmptyView];
}

- (BOOL)fw_hasEmptyView
{
    return [self.view fw_hasEmptyView];
}

@end

#pragma mark - UIScrollView+FWEmptyPlugin

@implementation UIScrollView (FWEmptyPlugin)

+ (void)fw_enableEmptyPlugin
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UITableView, @selector(reloadData), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            [selfObject fw_reloadEmptyView];
            FWSwizzleOriginal();
        }));
        
        FWSwizzleClass(UITableView, @selector(endUpdates), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            [selfObject fw_reloadEmptyView];
            FWSwizzleOriginal();
        }));
        
        FWSwizzleClass(UICollectionView, @selector(reloadData), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            [selfObject fw_reloadEmptyView];
            FWSwizzleOriginal();
        }));
    });
}

- (id<FWEmptyViewDelegate>)fw_emptyViewDelegate
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fw_emptyViewDelegate));
    return value.object;
}

- (void)setFw_emptyViewDelegate:(id<FWEmptyViewDelegate>)delegate
{
    if (!delegate) [self fw_invalidateEmptyView];
    objc_setAssociatedObject(self, @selector(fw_emptyViewDelegate), [[FWWeakObject alloc] initWithObject:delegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [UIScrollView fw_enableEmptyPlugin];
}

- (void)fw_reloadEmptyView
{
    if (!self.fw_emptyViewDelegate) return;
    
    BOOL shouldDisplay = NO;
    if ([self.fw_emptyViewDelegate respondsToSelector:@selector(emptyViewForceDisplay:)]) {
        shouldDisplay = [self.fw_emptyViewDelegate emptyViewForceDisplay:self];
    }
    if (!shouldDisplay) {
        if ([self.fw_emptyViewDelegate respondsToSelector:@selector(emptyViewShouldDisplay:)]) {
            shouldDisplay = [self.fw_emptyViewDelegate emptyViewShouldDisplay:self] && [self fw_emptyItemsCount] == 0;
        } else {
            shouldDisplay = [self fw_emptyItemsCount] == 0;
        }
    }
    
    BOOL hideSuccess = [self fw_invalidateEmptyView];
    if (shouldDisplay) {
        objc_setAssociatedObject(self, @selector(fw_invalidateEmptyView), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if ([self.fw_emptyViewDelegate respondsToSelector:@selector(emptyViewShouldScroll:)]) {
            self.scrollEnabled = [self.fw_emptyViewDelegate emptyViewShouldScroll:self];
        } else {
            self.scrollEnabled = NO;
        }
        
        BOOL fadeAnimated = FWEmptyPluginImpl.sharedInstance.fadeAnimated;
        FWEmptyPluginImpl.sharedInstance.fadeAnimated = hideSuccess ? NO : fadeAnimated;
        if ([self.fw_emptyViewDelegate respondsToSelector:@selector(showEmptyView:)]) {
            [self.fw_emptyViewDelegate showEmptyView:self];
        } else {
            [self fw_showEmptyView];
        }
        FWEmptyPluginImpl.sharedInstance.fadeAnimated = fadeAnimated;
    }
}

- (BOOL)fw_invalidateEmptyView
{
    if (![objc_getAssociatedObject(self, @selector(fw_invalidateEmptyView)) boolValue]) return NO;
    objc_setAssociatedObject(self, @selector(fw_invalidateEmptyView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    self.scrollEnabled = YES;
    
    if ([self.fw_emptyViewDelegate respondsToSelector:@selector(hideEmptyView:)]) {
        [self.fw_emptyViewDelegate hideEmptyView:self];
    } else {
        [self fw_hideEmptyView];
    }
    return YES;
}

- (NSInteger)fw_emptyItemsCount
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
