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

#pragma mark - UIFont+FWRelative

UIFont * FWFontThinRelative(CGFloat size) { return [UIFont fwThinFontRelative:size]; }
UIFont * FWFontLightRelative(CGFloat size) { return [UIFont fwLightFontRelative:size]; }
UIFont * FWFontRegularRelative(CGFloat size) { return [UIFont fwFontRelative:size]; }
UIFont * FWFontMediumRelative(CGFloat size) { return [UIFont fwMediumFontRelative:size]; }
UIFont * FWFontSemiboldRelative(CGFloat size) { return [UIFont fwSemiboldFontRelative:size]; }
UIFont * FWFontBoldRelative(CGFloat size) { return [UIFont fwBoldFontRelative:size]; }
UIFont * FWFontItalicRelative(CGFloat size) { return [UIFont fwItalicFontRelative:size]; }

@implementation UIFont (FWRelative)

+ (UIFont *)fwThinFontRelative:(CGFloat)size
{
    return [UIFont systemFontOfSize:[UIScreen fwRelativeValue:size] weight:UIFontWeightThin];
}

+ (UIFont *)fwLightFontRelative:(CGFloat)size
{
    return [UIFont systemFontOfSize:[UIScreen fwRelativeValue:size] weight:UIFontWeightLight];
}

+ (UIFont *)fwFontRelative:(CGFloat)size
{
    return [UIFont systemFontOfSize:[UIScreen fwRelativeValue:size]];
}

+ (UIFont *)fwMediumFontRelative:(CGFloat)size
{
    return [UIFont systemFontOfSize:[UIScreen fwRelativeValue:size] weight:UIFontWeightMedium];
}

+ (UIFont *)fwSemiboldFontRelative:(CGFloat)size
{
    return [UIFont systemFontOfSize:[UIScreen fwRelativeValue:size] weight:UIFontWeightSemibold];
}

+ (UIFont *)fwBoldFontRelative:(CGFloat)size
{
    return [UIFont boldSystemFontOfSize:[UIScreen fwRelativeValue:size]];
}

+ (UIFont *)fwItalicFontRelative:(CGFloat)size
{
    return [UIFont italicSystemFontOfSize:[UIScreen fwRelativeValue:size]];
}

+ (UIFont *)fwFontRelative:(CGFloat)size weight:(UIFontWeight)weight
{
    return [UIFont systemFontOfSize:[UIScreen fwRelativeValue:size] weight:weight];
}

@end
