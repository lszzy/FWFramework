//
//  FWLocationManager.h
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// 定位更新通知
extern NSString *const FWLocationUpdatedNotification;
// 定位失败通知
extern NSString *const FWLocationFailedNotification;
// 方向改变通知
extern NSString *const FWHeadingUpdatedNotification;

/**
 @brief 位置服务
 @discussion 注意：Info.plist需要添加NSLocationWhenInUseUsageDescription项或NSLocationAlwaysUsageDescription项
 */
@interface FWLocationManager : NSObject

// 是否请求Always定位，默认NO，请求WhenInUse定位
@property (nonatomic, assign) BOOL alwaysLocation;

// 是否监听方向，默认NO。如果设备不支持方向，则不能启用
@property (nonatomic, assign) BOOL headingEnabled;

// 位置管理对象
@property (nonatomic, readonly) CLLocationManager *locationManager;

// 当前位置
@property (nonatomic, readonly) CLLocation *location;

// 当前方向，headingEnabled启用后生效
@property (nonatomic, readonly) CLHeading *heading;

// 单例模式
+ (instancetype)sharedInstance;

// 开始位置监听
- (void)startNotifier;

// 停止位置监听
- (void)stopNotifier;

@end
