/*!
 @header     UIView+FWChain.m
 @indexgroup FWFramework
 @brief      UIView+FWChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import "UIView+FWChain.h"
#import <objc/runtime.h>

#pragma mark - FWViewChain

@interface FWViewChain ()

@property (nonatomic, weak) __kindof UIView *view;

@end

@implementation FWViewChain

#pragma mark - UIView

- (FWViewChain *(^)(CGRect))frame
{
    return ^FWViewChain *(CGRect frame) {
        self.view.frame = frame;
        return self;
    };
}

- (FWViewChain *(^)(UIColor *))backgroundColor
{
    return ^FWViewChain *(UIColor *backgroundColor) {
        self.view.backgroundColor = backgroundColor;
        return self;
    };
}

- (FWViewChain *(^)(UIView *))addSubview
{
    return ^FWViewChain *(UIView *view) {
        [self.view addSubview:view];
        return self;
    };
}

- (FWViewChain *(^)(UIView *))moveToSuperview
{
    return ^FWViewChain *(UIView *view) {
        if (view) {
            [view addSubview:self.view];
        } else {
            [self.view removeFromSuperview];
        }
        return self;
    };
}

#pragma mark - UILabel

- (FWViewChain *(^)(NSString *))text
{
    return ^FWViewChain *(NSString *text) {
        if ([self.view respondsToSelector:@selector(setText:)]) {
            ((UILabel *)self.view).text = text;
        }
        return self;
    };
}

@end

@implementation UIView (FWViewChain)

- (FWViewChain *)fwViewChain
{
    FWViewChain *viewChain = objc_getAssociatedObject(self, _cmd);
    if (!viewChain) {
        viewChain = [[FWViewChain alloc] init];
        viewChain.view = self;
        objc_setAssociatedObject(self, _cmd, viewChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return viewChain;
}

@end
