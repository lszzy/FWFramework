/*!
 @header     UIScrollView+FWContentView.m
 @indexgroup FWFramework
 @brief      UIScrollView+FWContentView
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/25
 */

#import "UIScrollView+FWContentView.h"
#import "FWAutoLayout.h"
#import <objc/runtime.h>

@implementation UIScrollView (FWContentView)

+ (instancetype)fwScrollView
{
    UIScrollView *scrollView = [[self alloc] init];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    return scrollView;
}

- (UIView *)fwContentView
{
    UIView *contentView = objc_getAssociatedObject(self, _cmd);
    if (!contentView) {
        contentView = [[UIView alloc] init];
        objc_setAssociatedObject(self, _cmd, contentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [self addSubview:contentView];
        [contentView fwPinEdgesToSuperview];
    }
    return contentView;
}

@end
