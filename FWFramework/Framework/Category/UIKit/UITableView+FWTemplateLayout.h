//
//  UITableView+FWTemplateLayout.h
//  FWFramework
//
//  Created by wuyong on 2017/4/24.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - UITableView+FWTemplateLayout

// 表格自动计算cell高度分类
@interface UITableView (FWTemplateLayout)

/*!
 @brief 单独启用或禁用高度估算
 @discussion 启用高度估算，需要子视图布局完整，无需实现heightForRow方法；禁用高度估算(iOS11默认启用，会先cellForRow再heightForRow)
 
 @param enabled 是否启用
 */
- (void)fwSetTemplateLayout:(BOOL)enabled UI_APPEARANCE_SELECTOR;

// 缓存方式获取估算高度，estimatedHeightForRowAtIndexPath调用即可。解决reloadData闪烁跳动问题
- (CGFloat)fwTemplateHeightAtIndexPath:(NSIndexPath *)indexPath;

// 设置估算高度缓存，willDisplayCell调用即可，height为cell.frame.size.height。设置为0时清除缓存。解决reloadData闪烁跳动问题
- (void)fwSetTemplateHeight:(CGFloat)height atIndexPath:(NSIndexPath *)indexPath;

// 清空估算高度缓存，cell高度动态变化时调用
- (void)fwClearTemplateHeightCache;

@end

#pragma mark - UIView+FWTemplateLayout

// 视图自动收缩分类。参考：https://github.com/forkingdog/UIView-FDCollapsibleConstraints
@interface UIView (FWTemplateLayout)

// 设置视图是否收缩，默认NO，YES时常量值为0，NO时常量值为原始值
@property (nonatomic, assign) BOOL fwCollapsed;

// 设置视图是否自动收缩，如image为nil，text为nil、@""时自动收缩，默认NO
@property (nonatomic, assign) BOOL fwAutoCollapse;

// 添加视图的收缩常量，必须先添加才能生效
- (void)fwAddCollapseConstraint:(NSLayoutConstraint *)constraint;

// 计算动态视图的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法。也可以setNeedsLayout再layoutIfNeeded计算视图frame
- (CGFloat)fwTemplateHeightWithWidth:(CGFloat)width;

@end
