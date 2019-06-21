/*!
 @header     UIControl+FWFramework.h
 @indexgroup FWFramework
 @brief      UIControl+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/21
 */

#import <UIKit/UIKit.h>

/*!
 @brief UIControl+FWFramework
 */
@interface UIControl (FWFramework)

// 设置Touch事件触发间隔，防止短时间多次触发事件，默认0。也可以手工控制enabled或userInteractionEnabled
@property (nonatomic, assign) NSTimeInterval fwTouchEventInterval UI_APPEARANCE_SELECTOR;

@end
