/*!
 @header     NSAttributedString+FWFramework.m
 @indexgroup FWFramework
 @brief      NSAttributedString+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/25
 */

#import "NSAttributedString+FWFramework.h"
#import "FWToolkit.h"
#import "FWTheme.h"

@implementation NSAttributedString (FWFramework)

#pragma mark - Convert

+ (instancetype)fwAttributedString:(NSString *)string withFont:(UIFont *)font
{
    return [self fwAttributedString:string withFont:font textColor:nil];
}

+ (instancetype)fwAttributedString:(NSString *)string withFont:(UIFont *)font textColor:(UIColor *)textColor
{
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    if (font) {
        attr[NSFontAttributeName] = font;
    }
    if (textColor) {
        attr[NSForegroundColorAttributeName] = textColor;
    }
    return [[self alloc] initWithString:string attributes:attr];
}

#pragma mark - Html

+ (instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString defaultAttributes:(nullable NSDictionary<NSAttributedStringKey,id> *)attributes
{
    if (!htmlString || htmlString.length < 1) return nil;
    
    if (attributes != nil) {
        NSString *cssString = @"";
        UIColor *textColor = attributes[NSForegroundColorAttributeName];
        if (textColor != nil) {
            cssString = [cssString stringByAppendingFormat:@"color:%@;", [self fwCSSStringWithColor:textColor]];
        }
        UIFont *font = attributes[NSFontAttributeName];
        if (font != nil) {
            cssString = [cssString stringByAppendingString:[self fwCSSStringWithFont:font]];
        }
        if (cssString.length > 0) {
            htmlString = [NSString stringWithFormat:@"<style type='text/css'>html{%@}</style>%@", cssString, htmlString];
        }
    }
    
    return [self fwAttributedStringWithHtmlString:htmlString];
}

+ (FWThemeObject<NSAttributedString *> *)fwThemeObjectWithHtmlString:(NSString *)htmlString defaultAttributes:(NSDictionary<NSAttributedStringKey,id> *)attributes
{
    NSMutableDictionary *lightAttributes = [NSMutableDictionary dictionary];
    NSMutableDictionary *darkAttributes = [NSMutableDictionary dictionary];
    if (attributes != nil) {
        UIColor *textColor = attributes[NSForegroundColorAttributeName];
        if (textColor != nil) {
            lightAttributes[NSForegroundColorAttributeName] = [textColor fwThemeColor:FWThemeStyleLight];
            darkAttributes[NSForegroundColorAttributeName] = [textColor fwThemeColor:FWThemeStyleDark];
        }
        UIFont *font = attributes[NSFontAttributeName];
        if (font != nil) {
            lightAttributes[NSFontAttributeName] = font;
            darkAttributes[NSFontAttributeName] = font;
        }
    }
    
    NSAttributedString *lightObject = [self fwAttributedStringWithHtmlString:htmlString defaultAttributes:lightAttributes];
    NSAttributedString *darkObject = [self fwAttributedStringWithHtmlString:htmlString defaultAttributes:darkAttributes];
    return [FWThemeObject objectWithLight:lightObject dark:darkObject];
}

+ (NSString *)fwCSSStringWithColor:(UIColor *)color
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![color getRed:&r green:&g blue:&b alpha:&a]) {
        if ([color getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    if (a >= 1.0) {
        return [NSString stringWithFormat:@"rgb(%u, %u, %u)",
                (unsigned)round(r * 255), (unsigned)round(g * 255), (unsigned)round(b * 255)];
    } else {
        return [NSString stringWithFormat:@"rgba(%u, %u, %u, %g)",
                (unsigned)round(r * 255), (unsigned)round(g * 255), (unsigned)round(b * 255), a];
    }
}

+ (NSString *)fwCSSStringWithFont:(UIFont *)font
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
    
    NSString *fontName = [font.fontName lowercaseString];
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
    
    return [NSString stringWithFormat:@"font-weight:%@;font-style:%@;font-size:%.0fpx;",
            fontWeight, fontStyle, font.pointSize];
}

#pragma mark - Size

- (CGSize)fwSize
{
    return [self fwSizeWithDrawSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)fwSizeWithDrawSize:(CGSize)drawSize
{
    CGSize size = [self boundingRectWithSize:drawSize
                                     options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                     context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

@end
