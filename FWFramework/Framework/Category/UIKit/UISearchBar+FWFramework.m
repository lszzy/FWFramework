/*!
 @header     UISearchBar+FWFramework.m
 @indexgroup FWFramework
 @brief      UISearchBar+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/10/15
 */

#import "UISearchBar+FWFramework.h"
#import "UIView+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import "UIImage+FWFramework.h"
#import "UIScreen+FWFramework.h"
#import "NSString+FWFramework.h"
#import "FWMessage.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

@implementation UISearchBar (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(layoutSubviews) with:@selector(fwInnerUISearchBarLayoutSubviews)];
        
        // iOS13因为层级关系变化，兼容处理
        if (@available(iOS 13, *)) {
            FWSwizzleMethod(objc_getClass("UISearchBarTextField"), @selector(setFrame:), nil, FWSwizzleType(UITextField *), FWSwizzleReturn(void), FWSwizzleArgs(CGRect frame), FWSwizzleCode({
                UISearchBar *searchBar = nil;
                if (@available(iOS 13.0, *)) {
                    searchBar = (UISearchBar *)selfObject.superview.superview.superview;
                } else {
                    searchBar = (UISearchBar *)selfObject.superview.superview;
                }
                if ([searchBar isKindOfClass:[UISearchBar class]]) {
                    NSValue *contentInsetValue = objc_getAssociatedObject(searchBar, @selector(fwContentInset));
                    if (contentInsetValue) {
                        UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
                        frame = CGRectMake(contentInset.left, contentInset.top, searchBar.bounds.size.width - contentInset.left - contentInset.right, searchBar.bounds.size.height - contentInset.top - contentInset.bottom);
                    }
                }
                
                FWSwizzleOriginal(frame);
            }));
        }
    });
}

- (UIEdgeInsets)fwContentInset
{
    return [objc_getAssociatedObject(self, @selector(fwContentInset)) UIEdgeInsetsValue];
}

- (void)setFwContentInset:(UIEdgeInsets)fwContentInset
{
    objc_setAssociatedObject(self, @selector(fwContentInset), [NSValue valueWithUIEdgeInsets:fwContentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwSetSearchIconCenter:(BOOL)center
{
    objc_setAssociatedObject(self, @selector(fwSetSearchIconCenter:), @(center), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsLayout];
}

- (void)fwInnerUISearchBarLayoutSubviews
{
    [self fwInnerUISearchBarLayoutSubviews];
    
    // 自定义了才处理
    if (@available(iOS 13, *)) {
    } else {
        NSValue *contentInsetValue = objc_getAssociatedObject(self, @selector(fwContentInset));
        if (contentInsetValue) {
            UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
            UITextField *textField = [self fwTextField];
            textField.frame = CGRectMake(contentInset.left, contentInset.top, self.bounds.size.width - contentInset.left - contentInset.right, self.bounds.size.height - contentInset.top - contentInset.bottom);
        }
    }
    
    // 自定义了才处理
    NSNumber *isCenterNumber = objc_getAssociatedObject(self, @selector(fwSetSearchIconCenter:));
    if (isCenterNumber) {
        if (@available(iOS 11.0, *)) {
            if (![isCenterNumber boolValue]) {
                [self setPositionAdjustment:UIOffsetMake(0, 0) forSearchBarIcon:UISearchBarIconSearch];
            } else {
                UITextField *textField = [self fwTextField];
                CGFloat placeholdWidth = [self.placeholder fwSizeWithFont:textField.font].width;
                CGFloat leftWidth = textField.leftView ? textField.leftView.frame.size.width : 0;
                CGFloat position = (textField.frame.size.width - placeholdWidth) / 2 - leftWidth;
                [self setPositionAdjustment:UIOffsetMake(position > 0 ? position : 0, 0) forSearchBarIcon:UISearchBarIconSearch];
            }
        } else {
            SEL centerSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@", @"setCenter", @"Placeholder:"]);
            if ([self respondsToSelector:centerSelector]) {
                BOOL centerPlaceholder = [isCenterNumber boolValue];
                NSMethodSignature *signature = [[UISearchBar class] instanceMethodSignatureForSelector:centerSelector];
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                [invocation setTarget:self];
                [invocation setSelector:centerSelector];
                [invocation setArgument:&centerPlaceholder atIndex:2];
                [invocation invoke];
            }
        }
    }
}

- (UITextField *)fwTextField
{
    return [self fwPerformPropertySelector:@"searchField"];
}

- (UIButton *)fwCancelButton
{
    return [self fwPerformPropertySelector:@"cancelButton"];
}

- (void)fwSetBackgroundColor:(UIColor *)color
{
    self.backgroundImage = [UIImage fwImageWithColor:color];
}

- (void)fwSetTextFieldBackgroundColor:(UIColor *)color
{
    UITextField *textField = [self fwTextField];
    textField.backgroundColor = color;
}

- (void)fwSetSearchIconPosition:(CGFloat)offset
{
    [self setPositionAdjustment:UIOffsetMake(offset, 0) forSearchBarIcon:UISearchBarIconSearch];
}

- (void)fwForceCancelButtonEnabled:(BOOL)force
{
    if (force) {
        [self.fwCancelButton fwObserveProperty:@"enabled" block:^(UIButton *object, NSDictionary *change) {
            if (!object.enabled) {
                object.enabled = YES;
            }
        }];
    } else {
        [self.fwCancelButton fwUnobserveProperty:@"enabled"];
    }
}

#pragma mark - Navigation

- (UIView *)fwAddToNavigationItem:(UINavigationItem *)navigationItem
{
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, FWNavigationBarHeight)];
    [titleView fwSetIntrinsicContentSize:UILayoutFittingExpandedSize];
    titleView.backgroundColor = [UIColor clearColor];
    [titleView addSubview:self];
    [self fwPinEdgesToSuperview];
    
    navigationItem.titleView = titleView;
    return titleView;
}

@end
