//
//  UITableView+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 2017/6/1.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UITableView+FWFramework.h"
#import <objc/runtime.h>

@implementation UITableView (FWFramework)

- (void)fwResetGroupedStyle
{
    self.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    self.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    self.sectionHeaderHeight = 0;
    self.sectionFooterHeight = 0;
}

- (void)fwFollowWithHeader:(CGFloat)headerHeight footer:(CGFloat)footerHeight
{
    CGFloat offsetY = self.contentOffset.y;
    if (offsetY >= 0 && offsetY <= headerHeight) {
        self.contentInset = UIEdgeInsetsMake(-offsetY, 0, -footerHeight, 0);
    } else if (offsetY >= headerHeight && offsetY <= self.contentSize.height - self.frame.size.height - footerHeight) {
        self.contentInset = UIEdgeInsetsMake(-headerHeight, 0, -footerHeight, 0);
    } else if (offsetY >= self.contentSize.height - self.frame.size.height - footerHeight && offsetY <= self.contentSize.height - self.frame.size.height) {
        self.contentInset = UIEdgeInsetsMake(-offsetY, 0, -(self.contentSize.height - self.frame.size.height - footerHeight), 0);
    }
}

- (void)fwReloadDataWithCompletion:(void (^)(void))completion
{
    [UIView animateWithDuration:0 animations:^{
        [self reloadData];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)fwReloadRowsWithoutAnimation:(NSArray<NSIndexPath *> *)indexPaths
{
    [UIView performWithoutAnimation:^{
        [self reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }];
}

@end

@implementation UITableViewCell (FWFramework)

- (UIEdgeInsets)fwSeparatorInset
{
    return self.separatorInset;
}

- (void)setFwSeparatorInset:(UIEdgeInsets)fwSeparatorInset
{
    self.separatorInset = fwSeparatorInset;
    
    // iOS8+
    if ([self respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [self setPreservesSuperviewLayoutMargins:NO];
    }
    if ([self respondsToSelector:@selector(setLayoutMargins:)]) {
        [self setLayoutMargins:fwSeparatorInset];
    }
}

- (id)fwModel
{
    return objc_getAssociatedObject(self, @selector(fwModel));
}

- (void)setFwModel:(id)fwModel
{
    if (fwModel != self.fwModel) {
        [self willChangeValueForKey:@"fwModel"];
        objc_setAssociatedObject(self, @selector(fwModel), fwModel, fwModel ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:@"fwModel"];
    }
}

+ (CGFloat)fwHeightWithModel:(id)model
{
    return 44.f;
}

@end

@implementation UICollectionView (FWFramework)

- (void)fwReloadDataWithCompletion:(void (^)(void))completion
{
    [UIView animateWithDuration:0 animations:^{
        [self reloadData];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

@end

@implementation UICollectionViewCell (FWFramework)

- (id)fwModel
{
    return objc_getAssociatedObject(self, @selector(fwModel));
}

- (void)setFwModel:(id)fwModel
{
    if (fwModel != self.fwModel) {
        [self willChangeValueForKey:@"fwModel"];
        objc_setAssociatedObject(self, @selector(fwModel), fwModel, fwModel ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:@"fwModel"];
    }
}

+ (CGSize)fwSizeWithModel:(id)model
{
    return CGSizeZero;
}

@end

@implementation UICollectionViewFlowLayout (FWFramework)

- (void)fwHoverWithHeader:(BOOL)header footer:(BOOL)footer
{
    if (@available(iOS 9.0, *)) {
        self.sectionHeadersPinToVisibleBounds = header;
        self.sectionFootersPinToVisibleBounds = footer;
    }
}

@end

@implementation UICollectionReusableView (FWFramework)

- (id)fwModel
{
    return objc_getAssociatedObject(self, @selector(fwModel));
}

- (void)setFwModel:(id)fwModel
{
    if (fwModel != self.fwModel) {
        [self willChangeValueForKey:@"fwModel"];
        objc_setAssociatedObject(self, @selector(fwModel), fwModel, fwModel ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:@"fwModel"];
    }
}

+ (CGSize)fwSizeWithModel:(id)model
{
    return CGSizeZero;
}

@end
