//
//  UITextView+FWPlaceholder.m
//  FWFramework
//
//  Created by wuyong on 17/3/29.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITextView+FWPlaceholder.h"
#import "NSObject+FWRuntime.h"
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
            UILabel *placeholderLabel = [textField fwPerformPropertySelector:@"_placeholderLabel"];
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
        [self fwObserveNotification:UITextViewTextDidChangeNotification object:self target:self action:@selector(fwUpdatePlaceholder)];
        
        // 监听当前输入框属性改变
        [self fwObserveProperty:@"attributedText" target:self action:@selector(fwUpdatePlaceholder)];
        [self fwObserveProperty:@"bounds" target:self action:@selector(fwUpdatePlaceholder)];
        [self fwObserveProperty:@"frame" target:self action:@selector(fwUpdatePlaceholder)];
        [self fwObserveProperty:@"text" target:self action:@selector(fwUpdatePlaceholder)];
        [self fwObserveProperty:@"textAlignment" target:self action:@selector(fwUpdatePlaceholder)];
        [self fwObserveProperty:@"textContainerInset" target:self action:@selector(fwUpdatePlaceholder)];
        
        // 监听字体改变
        [self fwObserveProperty:@"font" block:^(UITextView *textView, NSDictionary *change) {
            if (change[NSKeyValueChangeNewKey] != nil) {
                textView.fwPlaceholderLabel.font = textView.font;
            }
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
    
    // iOS7以上
    self.fwPlaceholderLabel.textAlignment = self.textAlignment;
    CGFloat lineFragmentPadding = self.textContainer.lineFragmentPadding;
    UIEdgeInsets textContainerInset = self.textContainerInset;
    CGFloat x = lineFragmentPadding + textContainerInset.left;
    CGFloat y = textContainerInset.top;
    CGFloat width = CGRectGetWidth(self.bounds) - x - lineFragmentPadding - textContainerInset.right;
    CGFloat height = [self.fwPlaceholderLabel sizeThatFits:CGSizeMake(width, 0)].height;
    self.fwPlaceholderLabel.frame = CGRectMake(x, y, width, height);
}

#pragma mark - Public

- (NSString *)fwPlaceholder
{
    return self.fwPlaceholderLabel.text;
}

- (void)setFwPlaceholder:(NSString *)fwPlaceholder
{
    self.fwPlaceholderLabel.text = fwPlaceholder;
    [self fwUpdatePlaceholder];
}

- (NSAttributedString *)fwAttributedPlaceholder
{
    return self.fwPlaceholderLabel.attributedText;
}

- (void)setFwAttributedPlaceholder:(NSAttributedString *)fwAttributedPlaceholder
{
    self.fwPlaceholderLabel.attributedText = fwAttributedPlaceholder;
    [self fwUpdatePlaceholder];
}

- (UIColor *)fwPlaceholderColor
{
    return self.fwPlaceholderLabel.textColor;
}

- (void)setFwPlaceholderColor:(UIColor *)fwPlaceholderColor
{
    self.fwPlaceholderLabel.textColor = fwPlaceholderColor;
}

@end
