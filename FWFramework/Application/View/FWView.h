/*!
 @header     FWView.h
 @indexgroup FWFramework
 @brief      FWView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief FWViewDelegate
 */
@protocol FWViewDelegate <NSObject>

/// 通用事件代理方法
- (void)onTouchView:(__kindof UIView *)view withEvent:(NSNotification *)event;

@end

/*!
 @brief UIView+FWEvent
 */
@interface UIView (FWEvent)

/// 通用事件代理
@property (nonatomic, weak, nullable) id<FWViewDelegate> fwViewDelegate;

/// 调用事件代理
- (void)fwTouchEvent:(NSNotification *)event;

/// 通用视图数据
@property (nonatomic, strong, nullable) id fwViewData;

/// 渲染数据，子类重写
- (void)fwRenderData;

@end

NS_ASSUME_NONNULL_END
