//
//  FWLocationManager.h
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// 定位更新通知
extern NSString *const FWLocationUpdatedNotification;
// 定位失败通知
extern NSString *const FWLocationFailedNotification;

/**
 *  位置服务。注意：Info.plist需要添加NSLocationWhenInUseUsageDescription项
 */
@interface FWLocationManager : NSObject

// 位置管理对象
@property (nonatomic, readonly) CLLocationManager *locationManager;

// 当前位置
@property (nonatomic, readonly) CLLocation *location;

// 单例模式
+ (instancetype)sharedInstance;

// 开始位置监听
- (void)startNotifier;

// 停止位置监听
- (void)stopNotifier;

@end
