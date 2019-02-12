//
//  UITextView+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/29.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextView+FWPlaceholder.h"

#pragma mark - UITextView+FWFramework

// 多行输入框分类
@interface UITextView (FWFramework)

#pragma mark - Length

// 最大字数限制，0为无限制，二选一
@property (nonatomic, assign) NSInteger fwMaxLength;

// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
@property (nonatomic, assign) NSInteger fwMaxUnicodeLength;

#pragma mark - Return

// 点击键盘完成按钮是否关闭键盘，默认NO，二选一
@property (nonatomic, assign) BOOL fwReturnResign;

// 设置点击键盘完成按钮自动切换的下一个输入框，二选一
@property (nonatomic, weak) UIResponder *fwReturnResponder;

// 设置点击键盘完成按钮的事件句柄
@property (nonatomic, copy) void (^fwReturnBlock)(UITextView *textView);

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

@end
