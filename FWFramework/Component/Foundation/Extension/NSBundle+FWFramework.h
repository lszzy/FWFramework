/*!
 @header     NSBundle+FWFramework.h
 @indexgroup FWFramework
 @brief      NSBundle分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
@brief NSBundle+FWFramework
*/
@interface NSBundle (FWFramework)

// 指定名称读取并创建bundle对象，bundle文件需位于mainBundle
+ (nullable instancetype)fwBundleWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
