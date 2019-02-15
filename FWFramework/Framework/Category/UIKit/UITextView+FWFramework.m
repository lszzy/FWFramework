//
//  UITextView+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/29.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITextView+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import "FWMessage.h"
#import "FWProxy.h"
#import "NSString+FWEncode.h"
#import <objc/runtime.h>

#pragma mark - FWTextViewDelegateProxy

@interface FWTextViewDelegateProxy : FWDelegateProxy <UITextViewDelegate>

@end

@implementation FWTextViewDelegateProxy

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL shouldChange = YES;
    // 先执行代理方法
    if (self.delegate && [self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        shouldChange = [self.delegate textView:textView shouldChangeTextInRange:range replacementText:text];
    }
    
    // 再执行内部方法
    if (textView.fwReturnResign || textView.fwReturnResponder || textView.fwReturnBlock) {
        // 判断是否输入回车
        if ([text isEqualToString:@"\n"]) {
            // 切换到下一个输入框
            if (textView.fwReturnResponder) {
                [textView.fwReturnResponder becomeFirstResponder];
            // 关闭键盘
            } else if (textView.fwReturnResign) {
                [textView resignFirstResponder];
            }
            // 执行回调
            if (textView.fwReturnBlock) {
                textView.fwReturnBlock(textView);
            }
            shouldChange = NO;
        }
    }
    return shouldChange;
}

@end

#pragma mark - UITextView+FWFramework

@implementation UITextView (FWFramework)

#pragma mark - Delegate

- (id<UITextViewDelegate>)fwDelegate
{
    if (!self.fwDelegateProxyEnabled) {
        return self.delegate;
    } else {
        return self.fwDelegateProxy.delegate;
    }
}

- (void)setFwDelegate:(id<UITextViewDelegate>)fwDelegate
{
    if (!self.fwDelegateProxyEnabled) {
        self.delegate = fwDelegate;
    } else {
        self.fwDelegateProxy.delegate = fwDelegate;
    }
}

- (BOOL)fwDelegateProxyEnabled
{
    return self.delegate == self.fwDelegateProxy;
}

- (void)setFwDelegateProxyEnabled:(BOOL)enabled
{
    if (enabled != self.fwDelegateProxyEnabled) {
        if (enabled) {
            self.fwDelegateProxy.delegate = self.delegate;
            self.delegate = self.fwDelegateProxy;
        } else {
            self.delegate = self.fwDelegateProxy.delegate;
            self.fwDelegateProxy.delegate = nil;
        }
    }
}

- (__kindof FWDelegateProxy *)fwDelegateProxy
{
    FWDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if (!proxy) {
        proxy = [[FWTextViewDelegateProxy alloc] init];
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

#pragma mark - Length

- (NSInteger)fwMaxLength
{
    return [objc_getAssociatedObject(self, @selector(fwMaxLength)) integerValue];
}

- (void)setFwMaxLength:(NSInteger)fwMaxLength
{
    objc_setAssociatedObject(self, @selector(fwMaxLength), @(fwMaxLength), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwInnerLengthEvent];
}

- (NSInteger)fwMaxUnicodeLength
{
    return [objc_getAssociatedObject(self, @selector(fwMaxUnicodeLength)) integerValue];
}

- (void)setFwMaxUnicodeLength:(NSInteger)fwMaxUnicodeLength
{
    objc_setAssociatedObject(self, @selector(fwMaxUnicodeLength), @(fwMaxUnicodeLength), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwInnerLengthEvent];
}

- (void)fwInnerLengthEvent
{
    id object = objc_getAssociatedObject(self, _cmd);
    if (!object) {
        [self fwObserveNotification:UITextViewTextDidChangeNotification object:self target:self action:@selector(fwInnerLengthAction)];
        objc_setAssociatedObject(self, _cmd, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)fwInnerLengthAction
{
    // 英文字数限制
    if (self.fwMaxLength > 0) {
        if (self.markedTextRange) {
            if (![self positionFromPosition:self.markedTextRange.start offset:0]) {
                if (self.text.length > self.fwMaxLength) {
                    // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [self.text rangeOfComposedCharacterSequenceAtIndex:self.fwMaxLength];
                    self.text = [self.text substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // self.text = [self.text substringToIndex:self.fwMaxLength];
                }
            }
        } else {
            if (self.text.length > self.fwMaxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [self.text rangeOfComposedCharacterSequenceAtIndex:self.fwMaxLength];
                self.text = [self.text substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // self.text = [self.text substringToIndex:self.fwMaxLength];
            }
        }
    }
    
    // Unicode字数限制
    if (self.fwMaxUnicodeLength > 0) {
        if (self.markedTextRange) {
            if (![self positionFromPosition:self.markedTextRange.start offset:0]) {
                if ([self.text fwUnicodeLength] > self.fwMaxUnicodeLength) {
                    self.text = [self.text fwUnicodeSubstring:self.fwMaxUnicodeLength];
                }
            }
        } else {
            if ([self.text fwUnicodeLength] > self.fwMaxUnicodeLength) {
                self.text = [self.text fwUnicodeSubstring:self.fwMaxUnicodeLength];
            }
        }
    }
}

#pragma mark - Return

- (BOOL)fwReturnResign
{
    return [objc_getAssociatedObject(self, @selector(fwReturnResign)) boolValue];
}

- (void)setFwReturnResign:(BOOL)fwReturnResign
{
    objc_setAssociatedObject(self, @selector(fwReturnResign), @(fwReturnResign), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.fwDelegateProxyEnabled = YES;
}

- (UIResponder *)fwReturnResponder
{
    return objc_getAssociatedObject(self, @selector(fwReturnResponder));
}

- (void)setFwReturnResponder:(UIResponder *)fwReturnResponder
{
    // 此处weak引用responder
    objc_setAssociatedObject(self, @selector(fwReturnResponder), fwReturnResponder, OBJC_ASSOCIATION_ASSIGN);
    self.fwDelegateProxyEnabled = YES;
}

- (void (^)(UITextView *textView))fwReturnBlock
{
    return objc_getAssociatedObject(self, @selector(fwReturnBlock));
}

- (void)setFwReturnBlock:(void (^)(UITextView *textView))fwReturnBlock
{
    objc_setAssociatedObject(self, @selector(fwReturnBlock), fwReturnBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    self.fwDelegateProxyEnabled = YES;
}

#pragma mark - Menu

- (BOOL)fwMenuDisabled
{
    return [objc_getAssociatedObject(self, @selector(fwMenuDisabled)) boolValue];
}

- (void)setFwMenuDisabled:(BOOL)fwMenuDisabled
{
    objc_setAssociatedObject(self, @selector(fwMenuDisabled), @(fwMenuDisabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (self.fwMenuDisabled) {
        return NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}

#pragma mark - Select

- (NSRange)fwSelectedRange
{
    UITextPosition *beginning = self.beginningOfDocument;
    
    UITextRange *selectedRange = self.selectedTextRange;
    UITextPosition *selectionStart = selectedRange.start;
    UITextPosition *selectionEnd = selectedRange.end;
    
    NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (void)fwSetSelectedRange:(NSRange)range
{
    UITextPosition *beginning = self.beginningOfDocument;
    UITextPosition *startPosition = [self positionFromPosition:beginning offset:range.location];
    UITextPosition *endPosition = [self positionFromPosition:beginning offset:NSMaxRange(range)];
    UITextRange *selectionRange = [self textRangeFromPosition:startPosition toPosition:endPosition];
    [self setSelectedTextRange:selectionRange];
}

- (void)fwSelectAllText
{
    UITextRange *range = [self textRangeFromPosition:self.beginningOfDocument toPosition:self.endOfDocument];
    [self setSelectedTextRange:range];
}

@end
