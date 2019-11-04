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

@end

NS_ASSUME_NONNULL_END
