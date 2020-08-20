//
//  UITextField+FWKeyboard.h
//  FWFramework
//
//  Created by wuyong on 2017/4/6.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 文本输入框键盘管理分类
@interface UITextField (FWKeyboard)

// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL fwKeyboardManager UI_APPEARANCE_SELECTOR;

// 设置输入框和键盘的空白高度，默认10.0
@property (nonatomic, assign) CGFloat fwKeyboardSpacing UI_APPEARANCE_SELECTOR;

// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
@property (nonatomic, assign) BOOL fwKeyboardResign UI_APPEARANCE_SELECTOR;

// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
@property (nonatomic, assign) BOOL fwTouchResign UI_APPEARANCE_SELECTOR;

@end

// 多行输入框键盘管理分类
@interface UITextView (FWKeyboard)

// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL fwKeyboardManager UI_APPEARANCE_SELECTOR;

// 设置输入框和键盘的空白高度，默认10.0
@property (nonatomic, assign) CGFloat fwKeyboardSpacing UI_APPEARANCE_SELECTOR;

// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
@property (nonatomic, assign) BOOL fwKeyboardResign UI_APPEARANCE_SELECTOR;

// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
@property (nonatomic, assign) BOOL fwTouchResign UI_APPEARANCE_SELECTOR;

@end

NS_ASSUME_NONNULL_END
