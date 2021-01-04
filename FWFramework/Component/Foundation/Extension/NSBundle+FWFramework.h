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

// 自定义GoogleMaps反解析地址结果语言，为nil时不指定
+ (void)fwSetGoogleMapsLanguage:(nullable NSString *)language;

// 自定义GooglePlaces查询地址结果语言，为nil时不指定
+ (void)fwSetGooglePlacesLanguage:(nullable NSString *)language;

@end

NS_ASSUME_NONNULL_END
