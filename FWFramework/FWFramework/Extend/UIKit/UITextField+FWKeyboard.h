//
//  UITextField+FWKeyboard.h
//  FWFramework
//
//  Created by wuyong on 2017/4/6.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

// 文本输入框键盘管理分类
@interface UITextField (FWKeyboard)

// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL fwKeyboardManager;

// 设置输入框和键盘的空白高度，默认10.0
@property (nonatomic, assign) CGFloat fwKeyboardSpacing;

// 是否启用点击背景关闭键盘，默认NO
@property (nonatomic, assign) BOOL fwTouchResign;

// 设置键盘弹出时移动到键盘上方的视图，如底部输入框视图
@property (nonatomic, weak) UIView *fwKeyboardView;

@end

// 多行输入框键盘管理分类
@interface UITextView (FWKeyboard)

// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL fwKeyboardManager;

// 设置输入框和键盘的空白高度，默认10.0
@property (nonatomic, assign) CGFloat fwKeyboardSpacing;

// 是否启用点击背景关闭键盘，默认NO
@property (nonatomic, assign) BOOL fwTouchResign;

// 设置键盘弹出时移动到键盘上方的视图，如底部输入框视图
@property (nonatomic, weak) UIView *fwKeyboardView;

@end
