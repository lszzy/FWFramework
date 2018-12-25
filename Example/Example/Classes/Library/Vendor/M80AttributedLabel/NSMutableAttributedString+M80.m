//
//  NSMutableAttributedString+M80.m
//  M80AttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import "NSMutableAttributedString+M80.h"

@implementation NSMutableAttributedString (M80)

- (void)fwSetTextColor:(UIColor*)color
{
    [self fwSetTextColor:color range:NSMakeRange(0, [self length])];
}

- (void)fwSetTextColor:(UIColor*)color range:(NSRange)range
{
    [self removeAttribute:(NSString *)kCTForegroundColorAttributeName range:range];
    if (color.CGColor)
    {
        
        
        [self addAttribute:(NSString *)kCTForegroundColorAttributeName
                     value:(id)color.CGColor
                     range:range];
    }
}


- (void)fwSetFont:(UIFont*)font
{
    [self fwSetFont:font range:NSMakeRange(0, [self length])];
}

- (void)fwSetFont:(UIFont*)font range:(NSRange)range
{
    if (font)
    {
        [self removeAttribute:(NSString*)kCTFontAttributeName range:range];
        
        CTFontRef fontRef = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, nil);
        if (nil != fontRef)
        {
            [self addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontRef range:range];
            CFRelease(fontRef);
        }
    }
}

- (void)fwSetUnderlineStyle:(CTUnderlineStyle)style
                 modifier:(CTUnderlineStyleModifiers)modifier
{
    [self fwSetUnderlineStyle:style
                   modifier:modifier
                      range:NSMakeRange(0, self.length)];
}

- (void)fwSetUnderlineStyle:(CTUnderlineStyle)style
                 modifier:(CTUnderlineStyleModifiers)modifier
                    range:(NSRange)range
{
    [self removeAttribute:(NSString *)kCTUnderlineColorAttributeName range:range];
    [self addAttribute:(NSString *)kCTUnderlineStyleAttributeName
                 value:[NSNumber numberWithInt:(style|modifier)]
                 range:range];
    
}

@end
