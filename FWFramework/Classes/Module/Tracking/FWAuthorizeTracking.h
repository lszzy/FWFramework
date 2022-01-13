//
//  FWAuthorizeTracking.h
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (FWAuthorizeTracking)

/// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Tracking子模块后生效
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceIDFA;

@end
