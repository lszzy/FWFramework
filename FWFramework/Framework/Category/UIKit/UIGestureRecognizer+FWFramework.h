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
 @param fromPosition 相对于view父视图的起始originY位置
 @param toPosition 相对于view父视图的目标originY位置
 @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
 @return 当前状态停留位置，Ended时返回为目标位置
 */
- (CGFloat)fwDrawerView:(UIView *)view
           fromPosition:(CGFloat)fromPosition
             toPosition:(CGFloat)toPosition
         kickbackHeight:(CGFloat)kickbackHeight;

@end
