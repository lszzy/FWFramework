/*!
 @header     UIFont+FWFramework.m
 @indexgroup FWFramework
 @brief      UIFont+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import "UIFont+FWFramework.h"

@implementation UIFont (FWFramework)

#pragma mark - Static

+ (UIFont *)fwLightSystemFontOfSize:(CGFloat)fontSize
{
    return [UIFont fontWithName:([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) ? @".SFUIText-Light" : @"HelveticaNeue-Light" size:fontSize];
}

+ (UIFont *)fwSystemFontOfSize:(CGFloat)fontSize
{
    return [UIFont systemFontOfSize:fontSize];
}

+ (UIFont *)fwBoldSystemFontOfSize:(CGFloat)fontSize
{
    return [UIFont boldSystemFontOfSize:fontSize];
}

+ (UIFont *)fwItalicSystemFontOfSize:(CGFloat)fontSize
{
    return [UIFont italicSystemFontOfSize:fontSize];
}

#pragma mark - Weight

+ (UIFont *)fwSystemFontOfSize:(CGFloat)fontSize weight:(FWFontWeight)weight
{
    return [self fwSystemFontOfSize:fontSize weight:weight italic:NO];
}

+ (UIFont *)fwSystemFontOfSize:(CGFloat)fontSize weight:(FWFontWeight)weight italic:(BOOL)italic
{
    UIFont *font = nil;
    
    // weight
    if (@available(iOS 8.2, *)) {
        switch (weight) {
            case FWFontWeightLight:
                font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightLight];
                break;
            case FWFontWeightBold:
                font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold];
                break;
            case FWFontWeightNormal:
            default:
                font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
                break;
        }
    } else {
        switch (weight) {
            case FWFontWeightLight:
                font = [UIFont fwLightSystemFontOfSize:fontSize];
                break;
            case FWFontWeightBold:
                font = [UIFont boldSystemFontOfSize:fontSize];
                break;
            case FWFontWeightNormal:
            default:
                font = [UIFont systemFontOfSize:fontSize];
                break;
        }
    }
    
    // italic
    if (italic) {
        UIFontDescriptorSymbolicTraits symbolicTraits = font.fontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic;
        font = [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:font.pointSize];
    }
    
    return font;
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

- (UIFont *)fwNormalFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitBold;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (UIFont *)fwBoldFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (UIFont *)fwRegularFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitItalic;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (UIFont *)fwItalicFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic;
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
    return (self.lineHeight - self.pointSize) / 2.f;
}

@end
