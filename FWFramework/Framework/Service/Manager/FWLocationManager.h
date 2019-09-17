//
//  FWLocationManager.h
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

// 坐标转"纬度,经度"字符串
FOUNDATION_EXPORT NSString * FWLocationStringWithCoordinate(CLLocationCoordinate2D coordinate);

// "纬度,经度"字符串转坐标
FOUNDATION_EXPORT CLLocationCoordinate2D FWLocationCoordinateWithString(NSString *string);

// 计算起点经纬度到终点经纬度的角度(0~360)
FOUNDATION_EXPORT CLLocationDegrees FWLocationDegreeWithCoordinates(CLLocationCoordinate2D origin, CLLocationCoordinate2D destination);

// 计算起点经纬度朝指定角度移动指定距离(米)的终点经纬度
FOUNDATION_EXPORT CLLocationCoordinate2D FWLocationCoordinateWithDistanceAndDegree(CLLocationCoordinate2D origin, CLLocationDistance distance, CLLocationDegrees degree);

#pragma mark - FWLocationManager

// 定位更新通知
extern NSString *const FWLocationUpdatedNotification;
// 定位失败通知
extern NSString *const FWLocationFailedNotification;
// 方向改变通知
extern NSString *const FWHeadingUpdatedNotification;

/**
 @brief 位置服务
 @discussion 注意：Info.plist需要添加NSLocationWhenInUseUsageDescription项
 如果请求Always定位，还需添加NSLocationAlwaysUsageDescription项和NSLocationAlwaysAndWhenInUseUsageDescription项
 iOS11可通过showsBackgroundLocationIndicator配置是否显示后台定位指示器
 */
@interface FWLocationManager : NSObject

// 是否启用Always定位，默认NO，请求WhenInUse定位
@property (nonatomic, assign) BOOL alwaysLocation;

// 是否启用后台定位，默认NO。如果需要后台定位，设为YES即可
@property (nonatomic, assign) BOOL backgroundLocation;

// 是否启用方向监听，默认NO。如果设备不支持方向，则不能启用
@property (nonatomic, assign) BOOL headingEnabled;

// 位置管理对象
@property (nonatomic, readonly) CLLocationManager *locationManager;

// 当前位置
@property (nullable, nonatomic, readonly) CLLocation *location;

// 当前方向，headingEnabled启用后生效
@property (nullable, nonatomic, readonly) CLHeading *heading;

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWLocationManager *sharedInstance;

// 开始更新位置
- (void)startUpdateLocation;

// 停止更新位置
- (void)stopUpdateLocation;

@end

NS_ASSUME_NONNULL_END
