/*!
 @header     UIFont+FWFramework.m
 @indexgroup FWFramework
 @brief      UIFont+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import "UIFont+FWFramework.h"

UIFont * FWFontLight(CGFloat size) {
    return [UIFont systemFontOfSize:size weight:UIFontWeightLight];
}

UIFont * FWFontRegular(CGFloat size) {
    return [UIFont systemFontOfSize:size];
}

UIFont * FWFontBold(CGFloat size) {
    return [UIFont boldSystemFontOfSize:size];
}

UIFont * FWFontItalic(CGFloat size) {
    return [UIFont italicSystemFontOfSize:size];
}

@implementation UIFont (FWFramework)

#pragma mark - Static

+ (UIFont *)fwLightFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightLight];
}

+ (UIFont *)fwFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size];
}

+ (UIFont *)fwBoldFontOfSize:(CGFloat)size
{
    return [UIFont boldSystemFontOfSize:size];
}

+ (UIFont *)fwItalicFontOfSize:(CGFloat)size
{
    return [UIFont italicSystemFontOfSize:size];
}

+ (UIFont *)fwFontOfSize:(CGFloat)size weight:(UIFontWeight)weight
{
    return [UIFont systemFontOfSize:size weight:weight];
}

#pragma mark - Font

- (BOOL)fwIsBold
{
    return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) > 0;
}

- (BOOL)fwIsItalic
{
    return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic) > 0;
}

- (UIFont *)fwBoldFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (UIFont *)fwNonBoldFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitBold;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (UIFont *)fwItalicFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (UIFont *)fwNonItalicFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitItalic;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

#pragma mark - Height

- (CGFloat)fwLineHeight
{
    return self.lineHeight;
}

- (CGFloat)fwPointHeight
{
    return self.pointSize;
}

- (CGFloat)fwSpaceHeight
{
    return self.lineHeight - self.pointSize;
}

- (CGFloat)fwLineSpacingWithMultiplier:(CGFloat)multiplier
{
    return self.pointSize * multiplier - (self.lineHeight - self.pointSize);
}

- (CGFloat)fwLineHeightWithMultiplier:(CGFloat)multiplier
{
    return self.pointSize * multiplier;
}

@end
