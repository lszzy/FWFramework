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
 @brief 抽屉拖拽效果，在action中调用即可
 
 @param view 抽屉视图，默认为self.view
 @param topPosition 相对于view父视图的顶部originY位置
 @param bottomPosition 相对于view父视图的底部originY位置
 @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
 @param callback 抽屉视图位移回调，参数为相对view父视图的originY位置
 */
- (void)fwDrawerView:(UIView *)view
         topPosition:(CGFloat)topPosition
      bottomPosition:(CGFloat)bottomPosition
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(void (^)(CGFloat position))callback;

/*!
 @brief 获取当前抽屉视图拖拽的位置
 
 @param view 抽屉视图，默认为self.view
 @return 当前抽屉视图拖拽的位置
 */
- (CGFloat)fwPositionWithDrawerView:(UIView *)view;

@end
