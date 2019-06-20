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

- (FWViewChain *(^)(BOOL))userInteractionEnabled
{
    return ^id(BOOL enabled) {
        self.view.userInteractionEnabled = enabled;
        return self;
    };
}

- (FWViewChain *(^)(NSInteger))tag
{
    return ^id(NSInteger tag) {
        self.view.tag = tag;
        return self;
    };
}

- (FWViewChain *(^)(CGRect))frame
{
    return ^id(CGRect frame) {
        self.view.frame = frame;
        return self;
    };
}

- (FWViewChain *(^)(CGRect))bounds
{
    return ^id(CGRect bounds) {
        self.view.bounds = bounds;
        return self;
    };
}

- (FWViewChain *(^)(CGPoint))center
{
    return ^id(CGPoint center) {
        self.view.center = center;
        return self;
    };
}

- (FWViewChain *(^)(void))removeFromSuperview
{
    return ^id(void) {
        [self.view removeFromSuperview];
        return self;
    };
}

- (FWViewChain *(^)(UIView *))addSubview
{
    return ^id(UIView *view) {
        [self.view addSubview:view];
        return self;
    };
}

- (FWViewChain *(^)(UIView *))moveToSuperview
{
    return ^id(UIView *view) {
        if (view) {
            [view addSubview:self.view];
        } else {
            [self.view removeFromSuperview];
        }
        return self;
    };
}

- (FWViewChain *(^)(BOOL))clipsToBounds
{
    return ^id(BOOL clipsToBounds) {
        self.view.clipsToBounds = clipsToBounds;
        return self;
    };
}

- (FWViewChain *(^)(UIColor *))backgroundColor
{
    return ^id(UIColor *backgroundColor) {
        self.view.backgroundColor = backgroundColor;
        return self;
    };
}

- (FWViewChain *(^)(CGFloat))alpha
{
    return ^id(CGFloat alpha) {
        self.view.alpha = alpha;
        return self;
    };
}

- (FWViewChain *(^)(BOOL))opaque
{
    return ^id(BOOL opaque) {
        self.view.opaque = opaque;
        return self;
    };
}

- (FWViewChain *(^)(BOOL))hidden
{
    return ^id(BOOL hidden) {
        self.view.hidden = hidden;
        return self;
    };
}

- (FWViewChain *(^)(UIViewContentMode))contentMode
{
    return ^id(UIViewContentMode contentMode) {
        self.view.contentMode = contentMode;
        return self;
    };
}

- (FWViewChain *(^)(UIColor *))tintColor
{
    return ^id(UIColor *tintColor) {
        self.view.tintColor = tintColor;
        return self;
    };
}

- (FWViewChain *(^)(UIViewTintAdjustmentMode))tintAdjustmentMode
{
    return ^id(UIViewTintAdjustmentMode tintAdjustmentMode) {
        self.view.tintAdjustmentMode = tintAdjustmentMode;
        return self;
    };
}

#pragma mark - UILabel

- (FWViewChain *(^)(NSString *))text
{
    return ^id(NSString *text) {
        if ([self.view respondsToSelector:@selector(setText:)]) {
            ((UILabel *)self.view).text = text;
        }
        return self;
    };
}

@end

#pragma mark - UIView+FWViewChain

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
