/*!
 @header     UISearchBar+FWFramework.h
 @indexgroup FWFramework
 @brief      UISearchBar+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/10/15
 */

#import <UIKit/UIKit.h>

/*!
 @brief UISearchBar+FWFramework
 */
@interface UISearchBar (FWFramework)

// 自定义内容边距，可调整左右距离和TextField高度。未设置时为系统默认
@property (nonatomic, assign) UIEdgeInsets fwContentInset;

// 设置整体背景色
- (void)fwSetBackgroundColor:(UIColor *)color;

// 设置输入框背景色
- (void)fwSetTextFieldBackgroundColor:(UIColor *)color;

// 设置TextField搜索图标(placeholder)离左侧的位置
- (void)fwSetSearchIconPosition:(CGFloat)offset;

// 设置TextField搜索图标(placeholder)是否居中，否则居左
- (void)fwSetSearchIconCenter:(BOOL)center;

// 输入框
- (UITextField *)fwTextField;

// 取消按钮
- (UIButton *)fwCancelButton;

#pragma mark - Navigation

// 添加到导航栏titleView。不能直接设置为titleView，需要包裹一层再添加
- (UIView *)fwAddToNavigationItem:(UINavigationItem *)navigationItem;

@end
