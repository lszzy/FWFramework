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

// 自定义内容边距，可调整左右距离和TextField高度。未设置时为系统默认
@property (nonatomic, assign) UIEdgeInsets fwContentInset;

// 输入框内部视图
@property (nullable, nonatomic, weak, readonly) UITextField *fwTextField;

// 取消按钮内部视图
@property (nullable, nonatomic, weak, readonly) UIButton *fwCancelButton;

// 设置整体背景色
- (void)fwSetBackgroundColor:(nullable UIColor *)color;

// 设置输入框背景色
- (void)fwSetTextFieldBackgroundColor:(nullable UIColor *)color;

// 设置TextField搜索图标(placeholder)离左侧的位置
- (void)fwSetSearchIconPosition:(CGFloat)offset;

// 设置TextField搜索图标(placeholder)是否居中，否则居左
- (void)fwSetSearchIconCenter:(BOOL)center;

// 强制取消按钮一直可点击，需在showsCancelButton设置之后生效。默认SearchBar失去焦点之后取消按钮不可点击
- (void)fwForceCancelButtonEnabled:(BOOL)force;

#pragma mark - Navigation

// 添加到导航栏titleView。不能直接设置为titleView，需要包裹一层再添加
- (UIView *)fwAddToNavigationItem:(UINavigationItem *)navigationItem;

@end

NS_ASSUME_NONNULL_END
