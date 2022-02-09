/**
 @header     FWRelative.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import "FWRelative.h"

#pragma mark - UIScreen+FWRelative

static CGFloat fwStaticReferenceWidth = 375;
static CGFloat fwStaticReferenceHeight = 812;

@implementation UIScreen (FWRelative)

+ (CGSize)fwReferenceSize
{
    return CGSizeMake(fwStaticReferenceWidth, fwStaticReferenceHeight);
}

+ (void)setFwReferenceSize:(CGSize)size
{
    fwStaticReferenceWidth = size.width;
    fwStaticReferenceHeight = size.height;
}

+ (CGFloat)fwScaleWidth
{
    if ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) {
        return [UIScreen mainScreen].bounds.size.width / fwStaticReferenceWidth;
    } else {
        return [UIScreen mainScreen].bounds.size.width / fwStaticReferenceHeight;
    }
}

+ (CGFloat)fwScaleHeight
{
    if ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) {
        return [UIScreen mainScreen].bounds.size.height / fwStaticReferenceHeight;
    } else {
        return [UIScreen mainScreen].bounds.size.height / fwStaticReferenceWidth;
    }
}

+ (CGFloat)fwRelativeValue:(CGFloat)value
{
    return value * [self fwScaleWidth];
}

@end
