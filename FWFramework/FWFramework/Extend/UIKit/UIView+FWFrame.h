//
//  UIView+FWFrame.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FWFrame)

// frame.origin.y
@property (nonatomic, assign) CGFloat fwTop;

// frame.origin.y + frame.size.height
@property (nonatomic, assign) CGFloat fwBottom;

// frame.origin.x
@property (nonatomic, assign) CGFloat fwLeft;

// frame.origin.x + frame.size.width
@property (nonatomic, assign) CGFloat fwRight;

// frame.size.width
@property (nonatomic, assign) CGFloat fwWidth;

// frame.size.height
@property (nonatomic, assign) CGFloat fwHeight;

// center.x
@property (nonatomic, assign) CGFloat fwCenterX;

// center.y
@property (nonatomic, assign) CGFloat fwCenterY;

// frame.origin.x
@property (nonatomic, assign) CGFloat fwX;

// frame.origin.y
@property (nonatomic, assign) CGFloat fwY;

// frame.origin
@property (nonatomic, assign) CGPoint fwOrigin;

// frame.size
@property (nonatomic, assign) CGSize fwSize;

@end
