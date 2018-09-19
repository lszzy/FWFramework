//
//  UIView+FWDrag.h
//  FWFramework
//
//  Created by wuyong on 2017/6/1.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FWDrag)

// 是否启用拖动，默认NO
@property (nonatomic, assign) BOOL fwDragEnabled;

// 拖动手势，延迟加载
@property (nonatomic, readonly) UIPanGestureRecognizer *fwDragGesture;

// 设置拖动限制区域，默认CGRectZero，无限制
@property (nonatomic, assign) CGRect fwDragLimit;

// 设置拖动动作有效区域，默认self.frame
@property (nonatomic, assign) CGRect fwDragArea;

// 是否允许横向拖动(X)，默认YES
@property (nonatomic, assign) BOOL fwDragHorizontal;

// 是否允许纵向拖动(Y)，默认YES
@property (nonatomic, assign) BOOL fwDragVertical;

// 开始拖动回调
@property (nonatomic, copy) void (^fwDragStartedBlock)(void);

// 结束拖动回调
@property (nonatomic, copy) void (^fwDragEndedBlock)(void);

@end
