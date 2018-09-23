//
//  UIView+FWFrame.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UIView+FWFrame.h"

@implementation UIView (FWFrame)

- (CGFloat)fwTop
{
    return self.frame.origin.y;
}

- (void)setFwTop:(CGFloat)fwTop
{
    CGRect frame = self.frame;
    frame.origin.y = fwTop;
    self.frame = frame;
}

- (CGFloat)fwBottom
{
    return self.fwTop + self.fwHeight;
}

- (void)setFwBottom:(CGFloat)fwBottom
{
    self.fwTop = fwBottom - self.fwHeight;
}

- (CGFloat)fwLeft
{
    return self.frame.origin.x;
}

- (void)setFwLeft:(CGFloat)fwLeft
{
    CGRect frame = self.frame;
    frame.origin.x = fwLeft;
    self.frame = frame;
}

- (CGFloat)fwRight
{
    return self.fwLeft + self.fwWidth;
}

- (void)setFwRight:(CGFloat)fwRight
{
    self.fwLeft = fwRight - self.fwWidth;
}

- (CGFloat)fwWidth
{
    return self.frame.size.width;
}

- (void)setFwWidth:(CGFloat)fwWidth
{
    CGRect frame = self.frame;
    frame.size.width = fwWidth;
    self.frame = frame;
}

- (CGFloat)fwHeight
{
    return self.frame.size.height;
}

- (void)setFwHeight:(CGFloat)fwHeight
{
    CGRect frame = self.frame;
    frame.size.height = fwHeight;
    self.frame = frame;
}

- (CGFloat)fwCenterX
{
    return self.center.x;
}

- (void)setFwCenterX:(CGFloat)fwCenterX
{
    self.center = CGPointMake(fwCenterX, self.fwCenterY);
}

- (CGFloat)fwCenterY
{
    return self.center.y;
}

- (void)setFwCenterY:(CGFloat)fwCenterY
{
    self.center = CGPointMake(self.fwCenterX, fwCenterY);
}

- (CGFloat)fwX
{
    return self.frame.origin.x;
}

- (void)setFwX:(CGFloat)fwX
{
    CGRect frame = self.frame;
    frame.origin.x = fwX;
    self.frame = frame;
}

- (CGFloat)fwY
{
    return self.frame.origin.y;
}

- (void)setFwY:(CGFloat)fwY
{
    CGRect frame = self.frame;
    frame.origin.y = fwY;
    self.frame = frame;
}

- (CGPoint)fwOrigin
{
    return self.frame.origin;
}

- (void)setFwOrigin:(CGPoint)fwOrigin
{
    CGRect frame = self.frame;
    frame.origin = fwOrigin;
    self.frame = frame;
}

- (CGSize)fwSize
{
    return self.frame.size;
}

- (void)setFwSize:(CGSize)fwSize
{
    CGRect frame = self.frame;
    frame.size = fwSize;
    self.frame = frame;
}

@end
