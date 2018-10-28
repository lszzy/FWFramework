/*!
 @header     UILabel+FWFramework.m
 @indexgroup FWFramework
 @brief      UILabel+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/10/22
 */

#import "UILabel+FWFramework.h"
#import "UIView+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

@implementation UILabel (FWFramework)

+ (void)load
{
    // 动态替换方法
    [self fwSwizzleInstanceMethod:@selector(drawTextInRect:) with:@selector(fwInnerDrawTextInRect:)];
    [self fwSwizzleInstanceMethod:@selector(intrinsicContentSize) with:@selector(fwInnerUILabelIntrinsicContentSize)];
}

- (UIEdgeInsets)fwContentInset
{
    return [objc_getAssociatedObject(self, @selector(fwContentInset)) UIEdgeInsetsValue];
}

- (void)setFwContentInset:(UIEdgeInsets)fwContentInset
{
    objc_setAssociatedObject(self, @selector(fwContentInset), [NSValue valueWithUIEdgeInsets:fwContentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self setNeedsDisplay];
}

- (UIControlContentVerticalAlignment)fwVerticalAlignment
{
    return [objc_getAssociatedObject(self, @selector(fwVerticalAlignment)) integerValue];
}

- (void)setFwVerticalAlignment:(UIControlContentVerticalAlignment)fwVerticalAlignment
{
    objc_setAssociatedObject(self, @selector(fwVerticalAlignment), @(fwVerticalAlignment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self setNeedsDisplay];
}

- (void)fwInnerDrawTextInRect:(CGRect)rect
{
    NSValue *contentInsetValue = objc_getAssociatedObject(self, @selector(fwContentInset));
    if (contentInsetValue) {
        rect = UIEdgeInsetsInsetRect(rect, [contentInsetValue UIEdgeInsetsValue]);
    }
    
    UIControlContentVerticalAlignment verticalAlignment = [objc_getAssociatedObject(self, @selector(fwVerticalAlignment)) integerValue];
    if (verticalAlignment == UIControlContentVerticalAlignmentTop) {
        CGSize fitsSize = [self sizeThatFits:rect.size];
        rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, fitsSize.height);
    } else if (verticalAlignment == UIControlContentVerticalAlignmentBottom) {
        CGSize fitsSize = [self sizeThatFits:rect.size];
        rect = CGRectMake(rect.origin.x, rect.origin.y + (rect.size.height - fitsSize.height), rect.size.width, fitsSize.height);
    }
    
    [self fwInnerDrawTextInRect:rect];
}

- (CGSize)fwInnerUILabelIntrinsicContentSize
{
    // 兼容UIView自定义估算
    NSValue *value = objc_getAssociatedObject(self, @selector(fwSetIntrinsicContentSize:));
    if (value) {
        return [value CGSizeValue];
    }
    
    // 无自定义估算时动态计算
    CGSize size = [self fwInnerUILabelIntrinsicContentSize];
    NSValue *contentInsetValue = objc_getAssociatedObject(self, @selector(fwContentInset));
    if (contentInsetValue) {
        UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
        size = CGSizeMake(size.width + contentInset.left + contentInset.right, size.height + contentInset.top + contentInset.bottom);
    }
    return size;
}

- (void)fwSetFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text
{
    if (font) {
        self.font = font;
    }
    if (textColor) {
        self.textColor = textColor;
    }
    if (text) {
        self.text = text;
    }
}

+ (instancetype)fwLabelWithFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text
{
    UILabel *label = [[self alloc] init];
    [label fwSetFont:font textColor:textColor text:text];
    return label;
}

@end
