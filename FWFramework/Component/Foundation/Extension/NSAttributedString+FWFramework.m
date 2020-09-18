/*!
 @header     NSAttributedString+FWFramework.m
 @indexgroup FWFramework
 @brief      NSAttributedString+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/25
 */

#import "NSAttributedString+FWFramework.h"
#import "FWTheme.h"
#import "FWToolkitManager.h"
#import "UIColor+FWFramework.h"
#import "UIFont+FWFramework.h"

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
            cssString = [cssString stringByAppendingFormat:@"color:%@;", textColor.fwCSSString];
        }
        UIFont *font = attributes[NSFontAttributeName];
        if (font != nil) {
            cssString = [cssString stringByAppendingString:font.fwCSSString];
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

@end
