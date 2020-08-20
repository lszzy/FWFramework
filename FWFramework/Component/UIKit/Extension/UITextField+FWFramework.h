//
//  UITextField+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/29.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextField+FWKeyboard.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UITextField+FWFramework

// 文本输入框分类
@interface UITextField (FWFramework)

#pragma mark - Length

// 最大字数限制，0为无限制，二选一
@property (nonatomic, assign) NSInteger fwMaxLength;

// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
@property (nonatomic, assign) NSInteger fwMaxUnicodeLength;

#pragma mark - AutoComplete

// 设置自动完成时间间隔，默认1秒，和fwAutoCompleteBlock配套使用
@property (nonatomic, assign) NSTimeInterval fwAutoCompleteInterval UI_APPEARANCE_SELECTOR;

// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
@property (nullable, nonatomic, copy) void (^fwAutoCompleteBlock)(NSString *text);

#pragma mark - Return

// 点击键盘完成按钮是否关闭键盘，默认NO，二选一
@property (nonatomic, assign) BOOL fwReturnResign;

// 设置点击键盘完成按钮自动切换的下一个输入框，二选一
@property (nullable, nonatomic, weak) UIResponder *fwReturnResponder;

// 设置点击键盘完成按钮的事件句柄
@property (nullable, nonatomic, copy) void (^fwReturnBlock)(UITextField *textField);

#pragma mark - Menu

// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
@property (nonatomic, assign) BOOL fwMenuDisabled;

#pragma mark - Select

// 获取当前选中的字符串范围
- (NSRange)fwSelectedRange;

// 选中指定范围的文字
- (void)fwSetSelectedRange:(NSRange)range;

// 选中所有文字
- (void)fwSelectAllText;

#pragma mark - Toolbar

// 添加Toolbar，指定右边按钮标题和句柄，默认完成并收起键盘
- (void)fwAddToolbar:(UIBarStyle)barStyle title:(nullable NSString *)title block:(nullable void (^)(id sender))block;

// 添加Toolbar，可选指定左边和右边按钮
- (void)fwAddToolbar:(UIBarStyle)barStyle leftItem:(nullable UIBarButtonItem *)leftItem rightItem:(nullable UIBarButtonItem *)rightItem;

@end

NS_ASSUME_NONNULL_END
