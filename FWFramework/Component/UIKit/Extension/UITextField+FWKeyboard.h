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

#pragma mark - Keyboard

// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL fwKeyboardManager UI_APPEARANCE_SELECTOR;

// 设置输入框和键盘的空白高度，默认10.0
@property (nonatomic, assign) CGFloat fwKeyboardSpacing UI_APPEARANCE_SELECTOR;

// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
@property (nonatomic, assign) BOOL fwKeyboardResign UI_APPEARANCE_SELECTOR;

// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
@property (nonatomic, assign) BOOL fwTouchResign UI_APPEARANCE_SELECTOR;

#pragma mark - Return

// 点击键盘完成按钮是否关闭键盘，默认NO，二选一
@property (nonatomic, assign) BOOL fwReturnResign;

// 设置点击键盘完成按钮自动切换的下一个输入框，二选一
@property (nullable, nonatomic, weak) UIResponder *fwReturnResponder;

// 设置点击键盘完成按钮的事件句柄
@property (nullable, nonatomic, copy) void (^fwReturnBlock)(UITextField *textField);

#pragma mark - Toolbar

// 添加Toolbar，指定右边按钮标题和句柄，默认完成并收起键盘
- (void)fwAddToolbar:(UIBarStyle)barStyle title:(nullable NSString *)title block:(nullable void (^)(id sender))block;

// 添加Toolbar，可选指定左边和右边按钮
- (void)fwAddToolbar:(UIBarStyle)barStyle leftItem:(nullable UIBarButtonItem *)leftItem rightItem:(nullable UIBarButtonItem *)rightItem;

@end

// 多行输入框键盘管理分类
@interface UITextView (FWKeyboard)

#pragma mark - Keyboard

// 是否启用键盘管理(自动滚动)，默认NO
@property (nonatomic, assign) BOOL fwKeyboardManager UI_APPEARANCE_SELECTOR;

// 设置输入框和键盘的空白高度，默认10.0
@property (nonatomic, assign) CGFloat fwKeyboardSpacing UI_APPEARANCE_SELECTOR;

// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
@property (nonatomic, assign) BOOL fwKeyboardResign UI_APPEARANCE_SELECTOR;

// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
@property (nonatomic, assign) BOOL fwTouchResign UI_APPEARANCE_SELECTOR;

#pragma mark - Return

// 点击键盘完成按钮是否关闭键盘，默认NO，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
@property (nonatomic, assign) BOOL fwReturnResign;

// 设置点击键盘完成按钮自动切换的下一个输入框，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
@property (nullable, nonatomic, weak) UIResponder *fwReturnResponder;

// 设置点击键盘完成按钮的事件句柄。此方法会修改delegate，可使用fwDelegate访问原始delegate
@property (nullable, nonatomic, copy) void (^fwReturnBlock)(UITextView *textView);

// 调用上面三个方法后会修改delegate，此方法始终访问外部delegate
@property (nullable, nonatomic, weak) id<UITextViewDelegate> fwDelegate;

#pragma mark - Toolbar

// 添加Toolbar，指定右边按钮标题和句柄，默认完成并收起键盘
- (void)fwAddToolbar:(UIBarStyle)barStyle title:(nullable NSString *)title block:(nullable void (^)(id sender))block;

// 添加Toolbar，可选指定左边和右边按钮
- (void)fwAddToolbar:(UIBarStyle)barStyle leftItem:(nullable UIBarButtonItem *)leftItem rightItem:(nullable UIBarButtonItem *)rightItem;

@end

NS_ASSUME_NONNULL_END
