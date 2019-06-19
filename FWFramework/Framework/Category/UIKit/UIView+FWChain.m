/*!
 @header     UIView+FWChain.m
 @indexgroup FWFramework
 @brief      UIView+FWChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import "UIView+FWChain.h"

@implementation UIView (FWChain)

+ (__kindof UIView *(^)(void))fwChain
{
    return ^id(void) {
        return [[self alloc] init];
    };
}

+ (__kindof UIView *(^)(CGRect frame))fwChainFrame
{
    return ^id(CGRect frame) {
        return [[self alloc] initWithFrame:frame];
    };
}

- (__kindof UIView *(^)(CGRect frame))fwChainFrame
{
    return ^id(CGRect frame) {
        self.frame = frame;
        return self;
    };
}

- (__kindof UIView *(^)(UIColor *backgroundColor))fwChainBackgroundColor
{
    return ^id(UIColor *backgroundColor) {
        self.backgroundColor = backgroundColor;
        return self;
    };
}

- (__kindof UIView *(^)(UIView *view))fwChainAddSubview
{
    return ^id(UIView *view) {
        [self addSubview:view];
        return self;
    };
}

- (__kindof UIView *(^)(UIView *view))fwChainMoveToSuperview
{
    return ^id(UIView *view) {
        if (view) {
            [view addSubview:self];
        } else {
            [self removeFromSuperview];
        }
        return self;
    };
}

@end

@implementation UILabel (FWChain)

- (__kindof UILabel *(^)(NSString *text))fwChainText
{
    return ^id(NSString *text) {
        self.text = text;
        return self;
    };
}

@end
