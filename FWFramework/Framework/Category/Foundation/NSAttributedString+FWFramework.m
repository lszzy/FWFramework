/*!
 @header     NSAttributedString+FWFramework.m
 @indexgroup FWFramework
 @brief      NSAttributedString+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/25
 */

#import "NSAttributedString+FWFramework.h"

@implementation NSAttributedString (FWFramework)

+ (instancetype)fwAttributedString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

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

@end

@implementation NSMutableParagraphStyle (FWFramework)

+ (instancetype)fwParagraphStyleWithLineHeight:(CGFloat)lineHeight
{
    return [self fwParagraphStyleWithLineHeight:lineHeight
                                  lineBreakMode:NSLineBreakByWordWrapping];
}

+ (instancetype)fwParagraphStyleWithLineHeight:(CGFloat)lineHeight
                                 lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    return [self fwParagraphStyleWithLineHeight:lineHeight
                                  lineBreakMode:lineBreakMode
                                  textAlignment:NSTextAlignmentLeft];
}

+ (instancetype)fwParagraphStyleWithLineHeight:(CGFloat)lineHeight
                                 lineBreakMode:(NSLineBreakMode)lineBreakMode
                                 textAlignment:(NSTextAlignment)textAlignment
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    paragraphStyle.lineBreakMode = lineBreakMode;
    paragraphStyle.alignment = textAlignment;
    return paragraphStyle;
}

@end
