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
 @discussion gestureRecognizerShouldBegin：是否继续进行手势识别，默认YES
    shouldRecognizeSimultaneouslyWithGestureRecognizer: 是否支持多手势触发。默认NO
    shouldRequireFailureOfGestureRecognizer：是否otherGestureRecognizer触发失败时，才开始触发gestureRecognizer。返回YES，第一个手势失败
    shouldBeRequiredToFailByGestureRecognizer：在otherGestureRecognizer识别其手势之前，是否gestureRecognizer必须触发失败。返回YES，第二个手势失败
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

// 当前滑动方向，如果多个方向滑动，取绝对值较大的一方，失败返回0
- (UISwipeGestureRecognizerDirection)fwSwipeDirection;

// 当前滑动进度，滑动绝对值相对于手势视图的宽或高
- (CGFloat)fwSwipePercent;

#pragma mark - DrawerView

/*!
 @brief 二级抽屉拖拽效果(简单版)。如果view为滚动视图，自动设置delegate处理与滚动视图pan手势冲突的问题
 
 @param view 抽屉视图，默认为self.view
 @param direction 拖拽方向，如向上拖动视图时为Up，向下为Down，向右为Right，向左为Left
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

/*!
 @brief 多级抽屉拖拽效果(详细版)。如果view为滚动视图，自动设置delegate处理与滚动视图pan手势冲突的问题
 
 @param view 抽屉视图，默认为self.view
 @param direction 拖拽方向，如向上拖动视图时为Up，向下为Down，向右为Right，向左为Left
 @param positions 抽屉位置，至少两级，相对于view父视图的originY位置
 @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
 @param callback 抽屉视图位移回调，参数为相对view父视图的origin位置和是否拖拽完成的标记
 */
- (void)fwDrawerView:(nullable UIView *)view
           direction:(UISwipeGestureRecognizerDirection)direction
           positions:(NSArray<NSNumber *> *)positions
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(nullable void (^)(CGFloat position, BOOL finished))callback;

/*!
 @brief 判断二级或多级抽屉效果视图是否位于打开位置
 @discussion 打开位置定义：拖拽方向为Up时fromPosition，Down时toPosition，Right时toPosition，Left时fromPosition，关闭位置取反即可
 
 @return 是否位于打开位置
 */
- (BOOL)fwDrawerViewIsOpen;

// 设置二级抽屉效果视图到打开位置或关闭位置，如果位置发生改变，会触发抽屉callback回调
- (void)fwDrawerViewToggleOpen:(BOOL)open;

// 判断多级抽屉效果视图是否位于指定位置
- (BOOL)fwDrawerViewIsPosition:(CGFloat)position;

// 设置多级抽屉效果视图到指定位置，如果位置发生改变，会触发抽屉callback回调
- (void)fwDrawerViewTogglePosition:(CGFloat)position;

@end

NS_ASSUME_NONNULL_END
