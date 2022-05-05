//
//  FWLocation.h
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWLocationManager

/// 定位更新通知
extern NSNotificationName const FWLocationUpdatedNotification;
/// 定位失败通知
extern NSNotificationName const FWLocationFailedNotification;
/// 方向改变通知
extern NSNotificationName const FWHeadingUpdatedNotification;

/**
 位置服务
 @note 注意：Info.plist需要添加NSLocationWhenInUseUsageDescription项
 如果请求Always定位，还需添加NSLocationAlwaysUsageDescription项和NSLocationAlwaysAndWhenInUseUsageDescription项
 iOS11可通过showsBackgroundLocationIndicator配置是否显示后台定位指示器
 */
@interface FWLocationManager : NSObject

/// 单例模式
@property (class, nonatomic, readonly) FWLocationManager *sharedInstance;

/// 是否启用Always定位，默认NO，请求WhenInUse定位
@property (nonatomic, assign) BOOL alwaysLocation;

/// 是否启用后台定位，默认NO。如果需要后台定位，设为YES即可
@property (nonatomic, assign) BOOL backgroundLocation;

/// 是否启用方向监听，默认NO。如果设备不支持方向，则不能启用
@property (nonatomic, assign) BOOL headingEnabled;

/// 是否发送通知，默认NO。如果需要通知，设为YES即可
@property (nonatomic, assign) BOOL notificationEnabled;

/// 定位完成是否立即stop，默认NO。如果为YES，只会回调一次
@property (nonatomic, assign) BOOL stopWhenCompleted;

/// 位置管理对象
@property (nonatomic, readonly) CLLocationManager *locationManager;

/// 当前位置，中途定位失败时不会重置
@property (nullable, nonatomic, readonly) CLLocation *location;

/// 当前方向，headingEnabled启用后生效
@property (nullable, nonatomic, readonly) CLHeading *heading;

/// 当前错误，表示最近一次定位回调状态
@property (nullable, nonatomic, readonly) NSError *error;

/// 定位改变block方式回调，可通过error判断是否定位成功
@property (nullable, nonatomic, copy) void (^locationChanged)(FWLocationManager *manager);

/// 坐标转"纬度,经度"字符串
+ (NSString *)locationString:(CLLocationCoordinate2D)coordinate;

/// "纬度,经度"字符串转坐标
+ (CLLocationCoordinate2D)locationCoordinate:(NSString *)string;

/// 开始更新位置
- (void)startUpdateLocation;

/// 停止更新位置
- (void)stopUpdateLocation;

@end

NS_ASSUME_NONNULL_END
