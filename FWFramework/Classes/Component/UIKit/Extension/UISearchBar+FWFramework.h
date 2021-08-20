/*!
 @header     UISearchBar+FWFramework.h
 @indexgroup FWFramework
 @brief      UISearchBar+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/10/15
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UISearchBar+FWFramework
 */
@interface UISearchBar (FWFramework)

// 自定义内容边距，可调整左右距离和TextField高度，未设置时为系统默认
@property (nonatomic, assign) UIEdgeInsets fwContentInset;

// 自定义取消按钮边距，未设置时为系统默认
@property (nonatomic, assign) UIEdgeInsets fwCancelButtonInset;

// 输入框内部视图
@property (nullable, nonatomic, weak, readonly) UITextField *fwTextField;

// 取消按钮内部视图，showsCancelButton开启后才存在
@property (nullable, nonatomic, weak, readonly) UIButton *fwCancelButton;

// 设置整体背景色
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor;

// 设置输入框背景色
@property (nonatomic, strong, nullable) UIColor *fwTextFieldBackgroundColor;

// 设置搜索图标离左侧的偏移位置，非居中时生效
@property (nonatomic, assign) CGFloat fwSearchIconOffset;

// 设置搜索文本离左侧图标的偏移位置
@property (nonatomic, assign) CGFloat fwSearchTextOffset;

// 设置TextField搜索图标(placeholder)是否居中，否则居左
@property (nonatomic, assign) BOOL fwSearchIconCenter;

// 强制取消按钮一直可点击，需在showsCancelButton设置之后生效。默认SearchBar失去焦点之后取消按钮不可点击
@property (nonatomic, assign) BOOL fwForceCancelButtonEnabled;

@end

NS_ASSUME_NONNULL_END
