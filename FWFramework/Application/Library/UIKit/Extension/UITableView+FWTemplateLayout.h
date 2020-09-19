//
//  UITableView+FWTemplateLayout.h
//  FWFramework
//
//  Created by wuyong on 2017/4/24.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UITableView+FWTemplateLayout

/*!
 @brief 表格自动计算并缓存cell高度分类，布局必须完整，系统方案实现
 */
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

NS_ASSUME_NONNULL_END
