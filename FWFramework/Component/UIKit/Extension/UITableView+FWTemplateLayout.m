//
//  UITableView+FWTemplateLayout.m
//  FWFramework
//
//  Created by wuyong on 2017/4/24.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITableView+FWTemplateLayout.h"
#import <objc/runtime.h>

#pragma mark - UITableView+FWTemplateLayout

@implementation UITableView (FWTemplateLayout)

- (void)fwSetTemplateLayout:(BOOL)enabled
{
    if (enabled) {
        self.rowHeight = UITableViewAutomaticDimension;
        self.sectionHeaderHeight = UITableViewAutomaticDimension;
        self.sectionFooterHeight = UITableViewAutomaticDimension;
        self.estimatedRowHeight = UITableViewAutomaticDimension;
        self.estimatedSectionHeaderHeight = UITableViewAutomaticDimension;
        self.estimatedSectionFooterHeight = UITableViewAutomaticDimension;
    } else {
        self.estimatedRowHeight = 0.f;
        self.estimatedSectionHeaderHeight = 0.f;
        self.estimatedSectionFooterHeight = 0.f;
    }
}

- (CGFloat)fwTemplateHeightAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *height = [self.fwInnerTemplateHeightCache objectForKey:indexPath];
    if (height) {
        return height.floatValue;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (void)fwSetTemplateHeight:(CGFloat)height atIndexPath:(NSIndexPath *)indexPath
{
    if (height > 0) {
        [self.fwInnerTemplateHeightCache setObject:@(height) forKey:indexPath];
    } else {
        [self.fwInnerTemplateHeightCache removeObjectForKey:indexPath];
    }
}

- (void)fwClearTemplateHeightCache
{
    [self.fwInnerTemplateHeightCache removeAllObjects];
}

- (NSMutableDictionary *)fwInnerTemplateHeightCache
{
    NSMutableDictionary *cache = objc_getAssociatedObject(self, _cmd);
    if (!cache) {
        cache = [NSMutableDictionary new];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

@end
