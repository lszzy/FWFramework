//
//  UITableView+FWEstimatedHeight.m
//  FWFramework
//
//  Created by wuyong on 2017/4/24.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UITableView+FWEstimatedHeight.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

#pragma mark - UITableView+FWEstimatedHeight

@implementation UITableView (FWEstimatedHeight)

+ (void)fwSetEstimatedHeight:(BOOL)enabled
{
    if (enabled) {
        [UITableView appearance].estimatedRowHeight = UITableViewAutomaticDimension;
        [UITableView appearance].estimatedSectionHeaderHeight = UITableViewAutomaticDimension;
        [UITableView appearance].estimatedSectionFooterHeight = UITableViewAutomaticDimension;
        [UITableView appearance].rowHeight = UITableViewAutomaticDimension;
        [UITableView appearance].sectionHeaderHeight = UITableViewAutomaticDimension;
        [UITableView appearance].sectionFooterHeight = UITableViewAutomaticDimension;
    } else {
        [UITableView appearance].estimatedRowHeight = 0.f;
        [UITableView appearance].estimatedSectionHeaderHeight = 0.f;
        [UITableView appearance].estimatedSectionFooterHeight = 0.f;
    }
}

- (void)fwSetEstimatedHeight:(BOOL)enabled
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

- (CGFloat)fwEstimatedHeightAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *height = [self.fwInnerEstimatedHeightCache objectForKey:indexPath];
    if (height) {
        return height.floatValue;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (void)fwSetEstimatedHeight:(CGFloat)height atIndexPath:(NSIndexPath *)indexPath
{
    if (height > 0) {
        [self.fwInnerEstimatedHeightCache setObject:@(height) forKey:indexPath];
    }
}

- (void)fwClearEstimatedHeightCache
{
    [self.fwInnerEstimatedHeightCache removeAllObjects];
}

- (NSMutableDictionary *)fwInnerEstimatedHeightCache
{
    NSMutableDictionary *cache = objc_getAssociatedObject(self, _cmd);
    if (!cache) {
        cache = [NSMutableDictionary new];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

@end

#pragma mark - UIView+FWEstimatedHeight

@interface NSLayoutConstraint (FWEstimatedHeight)

@property (nonatomic, assign) CGFloat fwOriginalConstant;

@end

@implementation NSLayoutConstraint (FWEstimatedHeight)

- (CGFloat)fwOriginalConstant
{
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (void)setFwOriginalConstant:(CGFloat)fwOriginalConstant
{
    objc_setAssociatedObject(self, @selector(fwOriginalConstant), @(fwOriginalConstant), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIView (FWEstimatedHeight)

+ (void)load
{
    // 动态替换方法
    [self fwSwizzleInstanceMethod:@selector(updateConstraints) with:@selector(fwInnerUpdateConstraints)];
}

- (BOOL)fwCollapsed
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwCollapsed:(BOOL)fwCollapsed
{
    [self.fwInnerCollapseConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        if (fwCollapsed) {
            constraint.constant = 0;
        } else {
            constraint.constant = constraint.fwOriginalConstant;
        }
    }];
    
    objc_setAssociatedObject(self, @selector(fwCollapsed), @(fwCollapsed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwAutoCollapse
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwAutoCollapse:(BOOL)fwAutoCollapse
{
    objc_setAssociatedObject(self, @selector(fwAutoCollapse), @(fwAutoCollapse), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwAddCollapseConstraint:(NSLayoutConstraint *)constraint
{
    constraint.fwOriginalConstant = constraint.constant;
    [self.fwInnerCollapseConstraints addObject:constraint];
}

- (NSMutableArray *)fwInnerCollapseConstraints
{
    NSMutableArray *constraints = objc_getAssociatedObject(self, _cmd);
    if (!constraints) {
        constraints = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
}

- (void)fwInnerUpdateConstraints
{
    [self fwInnerUpdateConstraints];
    
    if (self.fwAutoCollapse && self.fwInnerCollapseConstraints.count > 0) {
        // Absent意味着视图没有固有size，即{-1, -1}
        const CGSize absentIntrinsicContentSize = CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
        
        // 计算固有尺寸
        const CGSize contentSize = [self intrinsicContentSize];
        
        // 如果视图没有固定尺寸，自动设置约束
        if (CGSizeEqualToSize(contentSize, absentIntrinsicContentSize) ||
            CGSizeEqualToSize(contentSize, CGSizeZero)) {
            self.fwCollapsed = YES;
        } else {
            self.fwCollapsed = NO;
        }
    }
}

- (CGFloat)fwEstimatedHeightWithWidth:(CGFloat)width
{
    CGFloat contentViewWidth = width;
    CGFloat fittingHeight = 0;
    
    // 添加固定的width约束，从而使动态视图(如UILabel)纵向扩张。而不是水平增长，flow-layout的方式
    NSLayoutConstraint *widthFenceConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:contentViewWidth];
    [self addConstraint:widthFenceConstraint];
    // 自动布局引擎计算
    fittingHeight = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    [self removeConstraint:widthFenceConstraint];
    
    if (fittingHeight == 0) {
        // 尝试frame布局，调用sizeThatFits:
        fittingHeight = [self sizeThatFits:CGSizeMake(contentViewWidth, 0)].height;
    }
    
    return fittingHeight;
}

@end
