//
//  UITextView+FWPlaceholder.m
//  FWFramework
//
//  Created by wuyong on 17/3/29.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITextView+FWPlaceholder.h"
#import "FWSwizzle.h"
#import "FWMessage.h"
#import <objc/runtime.h>

@implementation UITextView (FWPlaceholder)

#pragma mark - Private

- (UILabel *)fwPlaceholderLabel
{
    UILabel *label = objc_getAssociatedObject(self, @selector(fwPlaceholderLabel));
    if (!label) {
        // 默认占位颜色
        static UIColor *defaultPlaceholderColor = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            UITextField *textField = [[UITextField alloc] init];
            textField.placeholder = @" ";
            UILabel *placeholderLabel = [textField fwPerformGetter:@"_placeholderLabel"];
            defaultPlaceholderColor = placeholderLabel.textColor;
        });
        
        NSAttributedString *originalText = self.attributedText;
        self.text = @" ";
        self.attributedText = originalText;
        
        label = [[UILabel alloc] init];
        label.textColor = defaultPlaceholderColor;
        label.numberOfLines = 0;
        label.userInteractionEnabled = NO;
        label.font = self.font;
        objc_setAssociatedObject(self, @selector(fwPlaceholderLabel), label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self fwUpdatePlaceholder];
        
        // 监听当前输入框的文本改变通知
        [self fwObserveNotification:UITextViewTextDidChangeNotification object:self target:self action:@selector(fwTextDidChange)];
        
        // 监听当前输入框属性改变
        [self fwObserveProperty:@"attributedText" target:self action:@selector(fwTextDidChange)];
        [self fwObserveProperty:@"text" target:self action:@selector(fwTextDidChange)];
        [self fwObserveProperty:@"bounds" target:self action:@selector(fwUpdatePlaceholder)];
        [self fwObserveProperty:@"frame" target:self action:@selector(fwUpdatePlaceholder)];
        [self fwObserveProperty:@"textAlignment" target:self action:@selector(fwUpdatePlaceholder)];
        [self fwObserveProperty:@"textContainerInset" target:self action:@selector(fwUpdatePlaceholder)];
        
        // 监听字体改变
        [self fwObserveProperty:@"font" block:^(UITextView *textView, NSDictionary *change) {
            if (change[NSKeyValueChangeNewKey] != nil) textView.fwPlaceholderLabel.font = textView.font;
            [textView fwUpdatePlaceholder];
        }];
    }
    return label;
}

- (void)fwUpdatePlaceholder
{
    if (self.text.length) {
        [self.fwPlaceholderLabel removeFromSuperview];
        return;
    }
    
    [self insertSubview:self.fwPlaceholderLabel atIndex:0];
    self.fwPlaceholderLabel.textAlignment = self.textAlignment;
    CGFloat lineFragmentPadding = self.textContainer.lineFragmentPadding;
    UIEdgeInsets textContainerInset = self.textContainerInset;
    CGFloat x = lineFragmentPadding + textContainerInset.left;
    CGFloat y = textContainerInset.top;
    CGFloat width = CGRectGetWidth(self.bounds) - x - lineFragmentPadding - textContainerInset.right;
    CGFloat height = [self.fwPlaceholderLabel sizeThatFits:CGSizeMake(width, 0)].height;
    self.fwPlaceholderLabel.frame = CGRectMake(x, y, width, height);
}

- (void)fwTextDidChange
{
    [self fwUpdatePlaceholder];
    if (!self.fwAutoHeightEnabled) return;
    
    NSInteger currentHeight = ceil([self sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)].height);
    // 如果显示placeholder，同时计算placeholder高度，取其中较大值
    if (self.fwPlaceholderLabel.superview) {
        NSInteger placeholderHeight = ceil(CGRectGetMaxY(self.fwPlaceholderLabel.frame) + self.textContainerInset.bottom);
        currentHeight = MAX(currentHeight, placeholderHeight);
    }
    currentHeight = MAX(self.fwMinHeight, MIN(currentHeight, self.fwMaxHeight));
    if (currentHeight == self.fwLastHeight) return;
    
    CGRect frame = self.frame;
    frame.size.height = currentHeight;
    self.frame = frame;
    if (self.fwHeightDidChange) {
        self.fwHeightDidChange(currentHeight);
    }
    self.fwLastHeight = currentHeight;
}

#pragma mark - Public

- (NSString *)fwPlaceholder
{
    return self.fwPlaceholderLabel.text;
}

- (void)setFwPlaceholder:(NSString *)fwPlaceholder
{
    self.fwPlaceholderLabel.text = fwPlaceholder;
    [self fwTextDidChange];
}

- (NSAttributedString *)fwAttributedPlaceholder
{
    return self.fwPlaceholderLabel.attributedText;
}

- (void)setFwAttributedPlaceholder:(NSAttributedString *)fwAttributedPlaceholder
{
    self.fwPlaceholderLabel.attributedText = fwAttributedPlaceholder;
    [self fwTextDidChange];
}

- (UIColor *)fwPlaceholderColor
{
    return self.fwPlaceholderLabel.textColor;
}

- (void)setFwPlaceholderColor:(UIColor *)fwPlaceholderColor
{
    self.fwPlaceholderLabel.textColor = fwPlaceholderColor;
}

#pragma mark - AutoHeight

- (BOOL)fwAutoHeightEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwAutoHeightEnabled)) boolValue];
}

- (void)setFwAutoHeightEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fwAutoHeightEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwTextDidChange];
}

- (CGFloat)fwMaxHeight
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fwMaxHeight));
    return value ? value.doubleValue : CGFLOAT_MAX;
}

- (void)setFwMaxHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fwMaxHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fwMinHeight
{
    return [objc_getAssociatedObject(self, @selector(fwMinHeight)) doubleValue];
}

- (void)setFwMinHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fwMinHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(CGFloat))fwHeightDidChange
{
    return objc_getAssociatedObject(self, @selector(fwHeightDidChange));
}

- (void)setFwHeightDidChange:(void (^)(CGFloat))block
{
    objc_setAssociatedObject(self, @selector(fwHeightDidChange), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CGFloat)fwLastHeight
{
    return [objc_getAssociatedObject(self, @selector(fwLastHeight)) doubleValue];
}

- (void)setFwLastHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fwLastHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwAutoHeightWithMaxHeight:(CGFloat)maxHeight didChange:(void (^)(CGFloat))didChange
{
    self.fwMaxHeight = maxHeight;
    if (didChange) self.fwHeightDidChange = didChange;
    self.fwAutoHeightEnabled = YES;
}

@end
