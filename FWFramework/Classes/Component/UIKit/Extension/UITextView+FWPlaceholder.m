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
        [self fwSetNeedsUpdatePlaceholder];
        [self insertSubview:label atIndex:0];
        
        // 监听当前输入框的文本改变通知
        [self fwObserveNotification:UITextViewTextDidChangeNotification object:self target:self action:@selector(fwSetNeedsUpdateText)];
        
        // 监听当前输入框属性改变
        [self fwObserveProperty:@"attributedText" target:self action:@selector(fwSetNeedsUpdateText)];
        [self fwObserveProperty:@"text" target:self action:@selector(fwSetNeedsUpdateText)];
        [self fwObserveProperty:@"bounds" target:self action:@selector(fwSetNeedsUpdatePlaceholder)];
        [self fwObserveProperty:@"frame" target:self action:@selector(fwSetNeedsUpdatePlaceholder)];
        [self fwObserveProperty:@"textAlignment" target:self action:@selector(fwSetNeedsUpdatePlaceholder)];
        [self fwObserveProperty:@"textContainerInset" target:self action:@selector(fwSetNeedsUpdatePlaceholder)];
        
        // 监听字体改变
        [self fwObserveProperty:@"font" block:^(UITextView *textView, NSDictionary *change) {
            if (change[NSKeyValueChangeNewKey] != nil) textView.fwPlaceholderLabel.font = textView.font;
            [textView fwSetNeedsUpdatePlaceholder];
        }];
    }
    return label;
}

- (void)fwSetNeedsUpdatePlaceholder
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwUpdatePlaceholder) object:nil];
    [self performSelector:@selector(fwUpdatePlaceholder) withObject:nil afterDelay:0];
}

- (void)fwSetNeedsUpdateText
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwUpdateText) object:nil];
    [self performSelector:@selector(fwUpdateText) withObject:nil afterDelay:0];
}

- (void)fwUpdatePlaceholder
{
    if (self.text.length) {
        self.fwPlaceholderLabel.hidden = YES;
        return;
    }
    
    CGFloat x = self.textContainer.lineFragmentPadding + self.textContainerInset.left;
    CGFloat width = CGRectGetWidth(self.bounds) - x - self.textContainer.lineFragmentPadding - self.textContainerInset.right;
    CGFloat height = [self.fwPlaceholderLabel sizeThatFits:CGSizeMake(width, 0)].height;
    CGFloat maxHeight = (self.fwAutoHeightEnabled ? self.fwMaxHeight : self.bounds.size.height) - self.textContainerInset.top - self.textContainerInset.bottom;
    CGRect targetFrame = CGRectMake(x, self.textContainerInset.top, width, MIN(height, maxHeight));
    self.fwPlaceholderLabel.hidden = NO;
    self.fwPlaceholderLabel.textAlignment = self.textAlignment;
    self.fwPlaceholderLabel.frame = targetFrame;
}

- (void)fwUpdateText
{
    [self fwUpdatePlaceholder];
    if (!self.fwAutoHeightEnabled) return;
    
    NSInteger currentHeight = ceil([self sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)].height);
    // 如果显示placeholder，同时计算placeholder高度，取其中较大值
    if (!self.fwPlaceholderLabel.isHidden) currentHeight = MAX(currentHeight, ceil(self.fwPlaceholderHeight));
    currentHeight = MAX(self.fwMinHeight, MIN(currentHeight, self.fwMaxHeight));
    if (currentHeight == self.fwLastHeight) return;
    
    CGRect targetFrame = self.frame;
    targetFrame.size.height = currentHeight;
    self.frame = targetFrame;
    if (self.fwHeightDidChange) self.fwHeightDidChange(currentHeight);
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
    [self fwSetNeedsUpdateText];
}

- (NSAttributedString *)fwAttributedPlaceholder
{
    return self.fwPlaceholderLabel.attributedText;
}

- (void)setFwAttributedPlaceholder:(NSAttributedString *)fwAttributedPlaceholder
{
    self.fwPlaceholderLabel.attributedText = fwAttributedPlaceholder;
    [self fwSetNeedsUpdateText];
}

- (UIColor *)fwPlaceholderColor
{
    return self.fwPlaceholderLabel.textColor;
}

- (void)setFwPlaceholderColor:(UIColor *)fwPlaceholderColor
{
    self.fwPlaceholderLabel.textColor = fwPlaceholderColor;
}

- (CGFloat)fwPlaceholderHeight
{
    return CGRectGetMaxY(self.fwPlaceholderLabel.frame) + self.textContainerInset.bottom;
}

#pragma mark - AutoHeight

- (BOOL)fwAutoHeightEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwAutoHeightEnabled)) boolValue];
}

- (void)setFwAutoHeightEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fwAutoHeightEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwSetNeedsUpdateText];
}

- (CGFloat)fwMaxHeight
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fwMaxHeight));
    return value ? value.doubleValue : CGFLOAT_MAX;
}

- (void)setFwMaxHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fwMaxHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwSetNeedsUpdateText];
}

- (CGFloat)fwMinHeight
{
    return [objc_getAssociatedObject(self, @selector(fwMinHeight)) doubleValue];
}

- (void)setFwMinHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fwMinHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwSetNeedsUpdateText];
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
