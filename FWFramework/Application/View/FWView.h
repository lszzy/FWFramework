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
 @brief UIView+FWView
 */
@interface UIView (FWView)

/// 通用视图模型，可监听
@property (nonatomic, strong, nullable) id fwViewModel;

/// 通用事件代理，弱引用
@property (nonatomic, weak, nullable) id<FWViewDelegate> fwViewDelegate;

/// 触发通用事件
- (void)fwTouchEvent:(NSNotification *)event;

@end

NS_ASSUME_NONNULL_END
