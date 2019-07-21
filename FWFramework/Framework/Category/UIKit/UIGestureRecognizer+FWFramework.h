/*!
 @header     UIGestureRecognizer+FWFramework.h
 @indexgroup FWFramework
 @brief      UIGestureRecognizer+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/3/12
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIGestureRecognizer+FWFramework
 */
@interface UIGestureRecognizer (FWFramework)

// 是否正在拖动中：Began || Changed
- (BOOL)fwIsTracking;

// 是否是激活状态: isEnabled && (Began || Changed)
- (BOOL)fwIsActive;

@end

/*!
 @brief UIPanGestureRecognizer+FWFramework
 */
@interface UIPanGestureRecognizer (FWFramework)

// 当前滑动方向，失败返回0
- (UISwipeGestureRecognizerDirection)fwSwipeDirection;

/*!
 @brief 设置抽屉拖拽效果。不支持滚动视图，滚动视图请使用FWDrawerView
 
 @param view 抽屉视图，默认为self.view
 @param direction 拖拽方向，如向上拖动视图时为Up
 @param fromPosition 相对于view父视图的起点originY位置
 @param toPosition 相对于view父视图的终点originY位置
 @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
 @param callback 抽屉视图位移回调，参数为相对view父视图的origin位置和是否拖拽完成的标记
 */
- (void)fwDrawerView:(nullable UIView *)view
           direction:(UISwipeGestureRecognizerDirection)direction
        fromPosition:(CGFloat)fromPosition
          toPosition:(CGFloat)toPosition
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(nullable void (^)(CGFloat position, BOOL finished))callback;

// 判断抽屉效果视图是否位于打开位置(toPosition)
- (BOOL)fwDrawerViewIsOpen;

// 设置抽屉效果视图到打开位置(toPosition)或关闭位置(fromPosition)，如果位置发生改变，会触发抽屉callback回调
- (void)fwDrawerViewToggleOpen:(BOOL)open;

@end

NS_ASSUME_NONNULL_END
