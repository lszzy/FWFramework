//
//  UITextView+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/29.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextView+FWPlaceholder.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UITextView+FWFramework

// 多行输入框分类
@interface UITextView (FWFramework)

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

#pragma mark - Menu

// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
@property (nonatomic, assign) BOOL fwMenuDisabled;

#pragma mark - Select

// 获取及设置当前选中文字范围
@property (nonatomic, assign) NSRange fwSelectedRange;

// 选中所有文字
- (void)fwSelectAllText;

#pragma mark - Size

// 计算当前文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整
@property (nonatomic, assign, readonly) CGSize fwTextSize;

// 计算当前属性文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整，attributedText需指定字体
@property (nonatomic, assign, readonly) CGSize fwAttributedTextSize;

@end

NS_ASSUME_NONNULL_END
