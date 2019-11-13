/*!
 @header     UIGestureRecognizer+FWFramework.h
 @indexgroup FWFramework
 @brief      UIGestureRecognizer+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/3/12
 */

#import <UIKit/UIKit.h>
#import "UIGestureRecognizer+FWDrawerView.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIGestureRecognizer+FWFramework

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

// 计算指定方向的滑动进度
- (CGFloat)fwSwipePercentOfDirection:(UISwipeGestureRecognizerDirection)direction;

@end

#pragma mark - FWPanGestureRecognizer

/*!
 @brief FWPanGestureRecognizer
 @discussion 自动处理与滚动视图pan手势在指定方向的冲突，默认设置delegate为自身。如果找到滚动视图则处理之，否则同父类
 */
@interface FWPanGestureRecognizer : UIPanGestureRecognizer

// 是否自动检测滚动视图，默认YES。如需手工指定，请禁用之
@property (nonatomic, assign) BOOL autoDetected;

// 指定滚动视图，自动处理与滚动视图pan手势在指定方向的冲突。自动设置默认delegate为自身
@property (nullable, nonatomic, weak) UIScrollView *scrollView;

// 指定与滚动视图pan手势的冲突交互方向，默认向下
@property (nonatomic, assign) UISwipeGestureRecognizerDirection direction;

// 自定义Failed判断句柄。默认判定失败时直接修改状态为Failed，可设置此block修改判定条件
@property (nullable, nonatomic, copy) BOOL (^shouldFailed)(FWPanGestureRecognizer *gestureRecognizer);

// 自定义shouldRequireFailure判断句柄
@property (nullable, nonatomic, copy) BOOL (^shouldRequireFailure)(UIGestureRecognizer *otherGestureRecognizer);

@end

NS_ASSUME_NONNULL_END
