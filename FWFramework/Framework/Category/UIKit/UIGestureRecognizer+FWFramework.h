/*!
 @header     UIGestureRecognizer+FWFramework.h
 @indexgroup FWFramework
 @brief      UIGestureRecognizer+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/3/12
 */

#import <UIKit/UIKit.h>

/*!
 @brief UIPanGestureRecognizer+FWFramework
 */
@interface UIPanGestureRecognizer (FWFramework)

// 当前滑动方向，失败返回0
- (UISwipeGestureRecognizerDirection)fwSwipeDirection;

/*!
 @brief 设置抽屉拖拽效果。如果view为滚动视图，自动设置delegate处理与滚动视图pan手势冲突的问题
 
 @param view 抽屉视图，默认为self.view
 @param direction 拖拽方向，如向上拖动视图时为Up
 @param fromPosition 相对于view父视图的起点originY位置
 @param toPosition 相对于view父视图的终点originY位置
 @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
 @param callback 抽屉视图位移回调，参数为相对view父视图的originY位置
 */
- (void)fwDrawerView:(UIView *)view
           direction:(UISwipeGestureRecognizerDirection)direction
        fromPosition:(CGFloat)fromPosition
          toPosition:(CGFloat)toPosition
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(void (^)(CGFloat position))callback;

// 交换抽屉效果视图位置，会触发抽屉callback回调
- (void)fwDrawerViewTogglePosition;

@end
