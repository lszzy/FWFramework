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
#import "FWSwizzle.h"
#import <objc/runtime.h>

@implementation UILabel (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UILabel, @selector(drawTextInRect:), FWSwizzleReturn(void), FWSwizzleArgs(CGRect rect), FWSwizzleCode({
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(fwContentInset));
            if (contentInsetValue) {
                rect = UIEdgeInsetsInsetRect(rect, [contentInsetValue UIEdgeInsetsValue]);
            }
            
            UIControlContentVerticalAlignment verticalAlignment = [objc_getAssociatedObject(selfObject, @selector(fwVerticalAlignment)) integerValue];
            if (verticalAlignment == UIControlContentVerticalAlignmentTop) {
                CGSize fitsSize = [selfObject sizeThatFits:rect.size];
                rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, fitsSize.height);
            } else if (verticalAlignment == UIControlContentVerticalAlignmentBottom) {
                CGSize fitsSize = [selfObject sizeThatFits:rect.size];
                rect = CGRectMake(rect.origin.x, rect.origin.y + (rect.size.height - fitsSize.height), rect.size.width, fitsSize.height);
            }
            
            FWSwizzleOriginal(rect);
        }));
        FWSwizzleClass(UILabel, @selector(intrinsicContentSize), FWSwizzleReturn(CGSize), FWSwizzleArgs(), FWSwizzleCode({
            // 兼容UIView自定义估算
            NSValue *value = objc_getAssociatedObject(selfObject, @selector(fwSetIntrinsicContentSize:));
            if (value) {
                return [value CGSizeValue];
            }
            
            // 无自定义估算时动态计算
            CGSize size = FWSwizzleOriginal();
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(fwContentInset));
            if (contentInsetValue) {
                UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
                size = CGSizeMake(size.width + contentInset.left + contentInset.right, size.height + contentInset.top + contentInset.bottom);
            }
            return size;
        }));
    });
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

#pragma mark - Size

- (CGSize)fwTextSize
{
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    attr[NSFontAttributeName] = self.font;
    if (self.lineBreakMode != NSLineBreakByWordWrapping) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        // 由于lineBreakMode默认值为TruncatingTail，多行显示时仍然按照WordWrapping计算
        if (self.numberOfLines != 1 && self.lineBreakMode == NSLineBreakByTruncatingTail) {
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        } else {
            paragraphStyle.lineBreakMode = self.lineBreakMode;
        }
        attr[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    
    CGSize drawSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.text boundingRectWithSize:drawSize
                                          options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attr
                                          context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

- (CGSize)fwAttributedTextSize
{
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    CGSize drawSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.attributedText boundingRectWithSize:drawSize
                                                    options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                    context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

@end
