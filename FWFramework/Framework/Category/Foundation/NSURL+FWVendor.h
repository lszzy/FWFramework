/*!
 @header     NSURL+FWVendor.h
 @indexgroup FWFramework
 @brief      NSURL+FWVendor
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/31
 */

#import <Foundation/Foundation.h>

/*!
 @brief 第三方URL生成器，可先判断canOpenURL，再openURL
 @discussion 需添加对应URL SCHEME到LSApplicationQueriesSchemes配置数组
 */
@interface NSURL (FWVendor)

#pragma mark - Map

/*!
 @brief 生成谷歌地图外部URL，URL SCHEME为：comgooglemaps|comgooglemaps-x-callback
 
 @param query 搜索地址，自动URL编码
 @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14", @"x-source": @"应用名称", @"x-success": @"回调地址"}
 @return NSURL
 */
+ (instancetype)fwGoogleMapsURLWithQuery:(NSString *)query options:(NSDictionary *)options;

/*!
 @brief 生成谷歌地图导航外部URL，URL SCHEME为：comgooglemaps|comgooglemaps-x-callback
 
 @param saddr 导航起始点，格式latitude,longitude或搜索地址
 @param daddr 导航结束点，格式latitude,longitude或搜索地址
 @param directionsmode 导航模式，支持driving|transit|bicycling|walking，默认walking
 @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14", @"x-source": @"应用名称", @"x-success": @"回调地址"}
 @return NSURL
 */
+ (instancetype)fwGoogleMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr directionsmode:(NSString *)directionsmode options:(NSDictionary *)options;

@end
