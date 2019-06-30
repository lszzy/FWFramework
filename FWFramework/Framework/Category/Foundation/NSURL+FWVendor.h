/*!
 @header     NSURL+FWVendor.h
 @indexgroup FWFramework
 @brief      NSURL+FWVendor
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/31
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 第三方URL生成器，可先判断canOpenURL，再openURL
 @discussion 需添加对应URL SCHEME到LSApplicationQueriesSchemes配置数组
 */
@interface NSURL (FWVendor)

#pragma mark - Map

/*!
 @brief 生成苹果地图地址外部URL
 
 @param addr 显示地址，格式latitude,longitude或搜索地址
 @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
 @return NSURL
 */
+ (nullable instancetype)fwAppleMapsURLWithAddr:(NSString *)addr options:(NSDictionary *)options;

/*!
 @brief 生成苹果地图导航外部URL
 
 @param saddr 导航起始点，格式latitude,longitude或搜索地址
 @param daddr 导航结束点，格式latitude,longitude或搜索地址
 @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
 @return NSURL
 */
+ (nullable instancetype)fwAppleMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr options:(NSDictionary *)options;

/*!
 @brief 生成谷歌地图外部URL，URL SCHEME为：comgooglemaps
 
 @param addr 显示地址，格式latitude,longitude或搜索地址
 @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14"}
 @return NSURL
 */
+ (nullable instancetype)fwGoogleMapsURLWithAddr:(NSString *)addr options:(NSDictionary *)options;

/*!
 @brief 生成谷歌地图导航外部URL，URL SCHEME为：comgooglemaps
 
 @param saddr 导航起始点，格式latitude,longitude或搜索地址
 @param daddr 导航结束点，格式latitude,longitude或搜索地址
 @param mode 导航模式，支持driving|transit|bicycling|walking，默认driving
 @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14", @"dirflg": @"t,h"}
 @return NSURL
 */
+ (nullable instancetype)fwGoogleMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr mode:(NSString *)mode options:(NSDictionary *)options;

/*!
 @brief 生成百度地图外部URL，URL SCHEME为：baidumap
 
 @param addr 显示地址，格式latitude,longitude或搜索地址
 @param options 可选附加参数，如@{@"src": @"site.wuyong.Example", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
 @return NSURL
 */
+ (nullable instancetype)fwBaiduMapsURLWithAddr:(NSString *)addr options:(NSDictionary *)options;

/*!
 @brief 生成百度地图导航外部URL，URL SCHEME为：baidumap
 
 @param saddr 导航起始点，格式latitude,longitude或搜索地址
 @param daddr 导航结束点，格式latitude,longitude或搜索地址
 @param mode 导航模式，支持driving|transit|navigation|riding|walking，默认driving
 @param options 可选附加参数，如@{@"src": @"site.wuyong.Example", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
 @return NSURL
 */
+ (nullable instancetype)fwBaiduMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr mode:(NSString *)mode options:(NSDictionary *)options;

@end

NS_ASSUME_NONNULL_END
