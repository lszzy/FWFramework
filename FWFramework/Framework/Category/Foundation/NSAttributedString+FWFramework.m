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
    return [self fwAttributedString:string withFont:font textColor:textColor paragraphStyle:nil];
}

+ (instancetype)fwAttributedString:(NSString *)string withFont:(UIFont *)font textColor:(UIColor *)textColor paragraphStyle:(NSParagraphStyle *)paragraphStyle
{
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    if (font) {
        attr[NSFontAttributeName] = font;
    }
    if (textColor) {
        attr[NSForegroundColorAttributeName] = textColor;
    }
    if (paragraphStyle) {
        attr[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    return [[self alloc] initWithString:string attributes:attr];
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

@implementation NSMutableParagraphStyle (FWFramework)

+ (instancetype)fwParagraphStyleWithLineSpacing:(CGFloat)lineSpacing
{
    return [self fwParagraphStyleWithLineSpacing:lineSpacing textAlignment:NSTextAlignmentLeft];
}

+ (instancetype)fwParagraphStyleWithLineSpacing:(CGFloat)lineSpacing textAlignment:(NSTextAlignment)textAlignment
{
    return [self fwParagraphStyleWithLineSpacing:lineSpacing textAlignment:textAlignment lineBreakMode:NSLineBreakByWordWrapping];
}

+ (instancetype)fwParagraphStyleWithLineSpacing:(CGFloat)lineSpacing textAlignment:(NSTextAlignment)textAlignment lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpacing;
    paragraphStyle.alignment = textAlignment;
    paragraphStyle.lineBreakMode = lineBreakMode;
    return paragraphStyle;
}

@end
