/*!
 @header     UIPageControl+FWFramework.h
 @indexgroup FWFramework
 @brief      UIPageControl+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/3
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIPageControl分类
 */
@interface UIPageControl (FWFramework)

// 自定义圆点大小，默认{10, 10}
- (void)fwSetIndicatorSize:(CGSize)indicatorSize;

@end

/*!
 @brief UIActivityIndicatorView分类
 */
@interface UIActivityIndicatorView (FWFramework)

// 自定义指示器大小
- (void)fwSetIndicatorSize:(CGSize)indicatorSize;

@end

NS_ASSUME_NONNULL_END
