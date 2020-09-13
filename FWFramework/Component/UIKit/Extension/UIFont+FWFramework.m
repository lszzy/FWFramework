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

- (NSString *)fwCSSString
{
    static NSDictionary *fontWeights = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fontWeights = @{
            @"ultralight": @"100",
            @"thin": @"200",
            @"light": @"300",
            @"medium": @"500",
            @"semibold": @"600",
            @"demibold": @"600",
            @"extrabold": @"800",
            @"ultrabold": @"800",
            @"bold": @"700",
            @"heavy": @"900",
            @"black": @"900",
        };
    });
    
    NSString *fontName = [self.fontName lowercaseString];
    NSString *fontStyle = @"normal";
    if ([fontName rangeOfString:@"italic"].location != NSNotFound) {
        fontStyle = @"italic";
    } else if ([fontName rangeOfString:@"oblique"].location != NSNotFound) {
        fontStyle = @"oblique";
    }
    
    NSString *fontWeight = @"400";
    for (NSString *fontKey in fontWeights) {
        if ([fontName rangeOfString:fontKey].location != NSNotFound) {
            fontWeight = fontWeights[fontKey];
            break;
        }
    }
    
    return [NSString stringWithFormat:@"font-family:'%@';font-weight:%@;font-style:%@;font-size:%.0fpx;",
            self.fontName, fontWeight, fontStyle, self.pointSize];
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

- (CGFloat)fwBaselineOffset:(UIFont *)font
{
    return (self.lineHeight - font.lineHeight) / 2 + (self.descender - font.descender);
}

@end
