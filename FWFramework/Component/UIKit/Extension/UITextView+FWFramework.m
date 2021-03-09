//
//  UITextView+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/29.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITextView+FWFramework.h"
#import "FWEncode.h"
#import "FWMessage.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - UITextView+FWFramework

@implementation UITextView (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UITextView, @selector(canPerformAction:withSender:), FWSwizzleReturn(BOOL), FWSwizzleArgs(SEL action, id sender), FWSwizzleCode({
            if (selfObject.fwMenuDisabled) {
                return NO;
            }
            return FWSwizzleOriginal(action, sender);
        }));
    });
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

#pragma mark - AutoComplete

- (NSTimeInterval)fwAutoCompleteInterval
{
    NSTimeInterval interval = [objc_getAssociatedObject(self, @selector(fwAutoCompleteInterval)) doubleValue];
    return interval > 0 ? interval : 1.0;
}

- (void)setFwAutoCompleteInterval:(NSTimeInterval)fwAutoCompleteInterval
{
    objc_setAssociatedObject(self, @selector(fwAutoCompleteInterval), @(fwAutoCompleteInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(NSString *))fwAutoCompleteBlock
{
    return objc_getAssociatedObject(self, @selector(fwAutoCompleteBlock));
}

- (void)setFwAutoCompleteBlock:(void (^)(NSString *))fwAutoCompleteBlock
{
    objc_setAssociatedObject(self, @selector(fwAutoCompleteBlock), fwAutoCompleteBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fwInnerLengthEvent];
}

- (NSTimeInterval)fwAutoCompleteTimestamp
{
    return [objc_getAssociatedObject(self, @selector(fwAutoCompleteTimestamp)) doubleValue];
}

- (void)setFwAutoCompleteTimestamp:(NSTimeInterval)fwAutoCompleteTimestamp
{
    objc_setAssociatedObject(self, @selector(fwAutoCompleteTimestamp), @(fwAutoCompleteTimestamp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    
    // 自动完成回调
    if (self.fwAutoCompleteBlock) {
        self.fwAutoCompleteTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *inputText = self.text;
        if (inputText.fwTrimString.length < 1) {
            self.fwAutoCompleteBlock(@"");
        } else {
            NSTimeInterval currentTimestamp = self.fwAutoCompleteTimestamp;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.fwAutoCompleteInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (currentTimestamp == self.fwAutoCompleteTimestamp) {
                    self.fwAutoCompleteBlock(inputText);
                }
            });
        }
    }
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

- (void)setFwSelectedRange:(NSRange)range
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

#pragma mark - Size

- (CGSize)fwTextSize
{
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    attr[NSFontAttributeName] = self.font;
    
    CGSize drawSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.text boundingRectWithSize:drawSize
                                          options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attr
                                          context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)) + self.textContainerInset.left + self.textContainerInset.right, MIN(drawSize.height, ceilf(size.height)) + self.textContainerInset.top + self.textContainerInset.bottom);
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
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)) + self.textContainerInset.left + self.textContainerInset.right, MIN(drawSize.height, ceilf(size.height)) + self.textContainerInset.top + self.textContainerInset.bottom);
}

@end
