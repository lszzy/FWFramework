/*!
 @header     NSAttributedString+FWFramework.m
 @indexgroup FWFramework
 @brief      NSAttributedString+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/25
 */

#import "NSAttributedString+FWFramework.h"
#import "UIColor+FWFramework.h"

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

+ (instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString
{
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[self alloc] initWithData:htmlData options:@{
        NSDocumentTypeDocumentOption: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding),
    } documentAttributes:nil error:nil];
}

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
            cssString = [cssString stringByAppendingFormat:@"font-size:%.0f;", font.pointSize];
        }
        if (cssString.length > 0) {
            htmlString = [NSString stringWithFormat:@"<style type='text/css'>body{%@}</style>%@", cssString, htmlString];
        }
    }
    
    return [self fwAttributedStringWithHtmlString:htmlString];
}

- (NSString *)fwHtmlString
{
    NSData *htmlData = [self dataFromRange:NSMakeRange(0, self.length) documentAttributes:@{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
    } error:nil];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
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
