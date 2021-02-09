//
//  UITableView+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 2017/6/1.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITableView+FWFramework.h"
#import "FWDynamicLayout.h"

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

- (void)fwReloadDataWithoutCache
{
    [self fwClearHeightCache];
    [self fwClearTemplateHeightCache];
    [self reloadData];
}

- (void)fwReloadDataWithoutAnimation
{
    [UIView performWithoutAnimation:^{
        [self reloadData];
    }];
}

- (void)fwReloadSectionsWithoutAnimation:(NSIndexSet *)sections
{
    [UIView performWithoutAnimation:^{
        [self reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
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

- (UITableView *)fwTableView
{
    UIView *superview = self.superview;
    while (superview) {
        if ([superview isKindOfClass:[UITableView class]]) {
            return (UITableView *)superview;
        }
        superview = superview.superview;
    }
    return nil;
}

- (NSIndexPath *)fwIndexPath
{
    return [[self fwTableView] indexPathForCell:self];
}

@end
