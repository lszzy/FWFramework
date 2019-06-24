/*!
 @header     UIView+FWLayoutChain.m
 @indexgroup FWFramework
 @brief      UIView+FWLayoutChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/22
 */

#import "UIView+FWLayoutChain.h"
#import "UIView+FWAutoLayout.h"
#import <objc/runtime.h>

#pragma mark - FWLayoutChain

@interface FWLayoutChain ()

@property (nonatomic, weak) __kindof UIView *view;

@end

@implementation FWLayoutChain

- (FWLayoutChain *(^)(CGSize))size
{
    return ^id(CGSize size) {
        [self.view fwSetDimensionsToSize:size];
        return self;
    };
}

- (FWLayoutChain *(^)(CGFloat))width
{
    return ^id(CGFloat width) {
        [self.view fwSetDimension:NSLayoutAttributeWidth toSize:width];
        return self;
    };
}

- (FWLayoutChain *(^)(CGFloat))height
{
    return ^id(CGFloat height) {
        [self.view fwSetDimension:NSLayoutAttributeHeight toSize:height];
        return self;
    };
}

- (FWLayoutChain *(^)(CGFloat, NSLayoutRelation))widthWithRelation
{
    return ^id(CGFloat width, NSLayoutRelation relation) {
        [self.view fwSetDimension:NSLayoutAttributeWidth toSize:width relation:relation];
        return self;
    };
}

- (FWLayoutChain *(^)(CGFloat, NSLayoutRelation))heightWithRelation
{
    return ^id(CGFloat height, NSLayoutRelation relation) {
        [self.view fwSetDimension:NSLayoutAttributeHeight toSize:height relation:relation];
        return self;
    };
}

@end

#pragma mark - UIView+FWLayoutChain

@implementation UIView (FWLayoutChain)

- (FWLayoutChain *)fwLayoutChain
{
    FWLayoutChain *layoutChain = objc_getAssociatedObject(self, _cmd);
    if (!layoutChain) {
        layoutChain = [[FWLayoutChain alloc] init];
        layoutChain.view = self;
        objc_setAssociatedObject(self, _cmd, layoutChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return layoutChain;
}

@end
