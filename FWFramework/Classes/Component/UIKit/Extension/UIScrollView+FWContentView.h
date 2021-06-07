/*!
 @header     UIScrollView+FWContentView.h
 @indexgroup FWFramework
 @brief      UIScrollView+FWContentView
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/25
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIScrollView内容过多时自动滚动，需布局约束完整
 */
@interface UIScrollView (FWContentView)

/// 快速创建通用配置滚动视图
+ (instancetype)fwScrollView;

/// 内容视图，子视图需添加到本视图，布局约束完整时可自动滚动
@property (nonatomic, strong, readonly) UIView *fwContentView;

@end

NS_ASSUME_NONNULL_END
