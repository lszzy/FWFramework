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
#import <objc/runtime.h>

@implementation UISearchBar (FWFramework)

+ (void)load
{
    // 动态替换方法
    [self fwSwizzleInstanceMethod:@selector(layoutSubviews) with:@selector(fwInnerLayoutSubviews)];
}

- (UIEdgeInsets)fwContentInset
{
    return [objc_getAssociatedObject(self, @selector(fwContentInset)) UIEdgeInsetsValue];
}

- (void)setFwContentInset:(UIEdgeInsets)fwContentInset
{
    objc_setAssociatedObject(self, @selector(fwContentInset), [NSValue valueWithUIEdgeInsets:fwContentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwInnerLayoutSubviews
{
    [self fwInnerLayoutSubviews];
    
    NSValue *contentInsetValue = objc_getAssociatedObject(self, @selector(fwContentInset));
    if (contentInsetValue) {
        UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
        UITextField *textField = [self fwTextField];
        textField.frame = CGRectMake(contentInset.left, contentInset.top, self.bounds.size.width - contentInset.left - contentInset.right, self.bounds.size.height - contentInset.top - contentInset.bottom);
    }
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

- (UITextField *)fwTextField
{
    return [self fwSubviewOfClass:[UITextField class]];
}

- (UIButton *)fwCancelButton
{
    return [self fwSubviewOfClass:[UIButton class]];
}

#pragma mark - Navigation

- (UIView *)fwAddToNavigationItem:(UINavigationItem *)navigationItem
{
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, FWNavigationBarHeight)];
    titleView.backgroundColor = [UIColor clearColor];
    [titleView addSubview:self];
    [self fwPinEdgesToSuperview];
    
    navigationItem.titleView = titleView;
    return titleView;
}

@end
