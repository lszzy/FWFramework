//
//  FWAuthorizeManager.h
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Enum

// 权限状态枚举
typedef NS_ENUM(NSInteger, FWAuthorizeStatus) {
    // 未确认
    FWAuthorizeStatusNotDetermined = 0,
    // 受限制
    FWAuthorizeStatusRestricted,
    // 被拒绝
    FWAuthorizeStatusDenied,
    // 已授权
    FWAuthorizeStatusAuthorized,
};

// 权限类型枚举
typedef NS_ENUM(NSInteger, FWAuthorizeType) {
    // 定位，Info.plst需配置NSLocationWhenInUseUsageDescription，iOS7需配置NSLocationUsageDescription
    FWAuthorizeTypeLocationWhenInUse = 1,
    // 后台定位，Info.plst需配置NSLocationAlwaysUsageDescription，iOS7需配置NSLocationUsageDescription
    FWAuthorizeTypeLocationAlways,
    // 麦克风，Info.plst需配置NSMicrophoneUsageDescription
    FWAuthorizeTypeMicrophone,
    // 相册，Info.plst需配置NSPhotoLibraryUsageDescription
    FWAuthorizeTypePhotoLibrary,
    // 照相机，Info.plst需配置NSCameraUsageDescription
    FWAuthorizeTypeCamera,
    // 联系人，Info.plst需配置NSContactsUsageDescription
    FWAuthorizeTypeContacts,
    // 日历，Info.plst需配置NSCalendarsUsageDescription
    FWAuthorizeTypeCalendars,
    // 提醒，Info.plst需配置NSRemindersUsageDescription
    FWAuthorizeTypeReminders,
    // 音乐，Info.plst需配置NSAppleMusicUsageDescription
    FWAuthorizeTypeAppleMusic,
    // 通知，远程推送需打开Push Notifications开关和Background Modes的Remote notifications开关
    FWAuthorizeTypeNotifications,
};

#pragma mark - FWAuthorizeProtocol

// 权限授权协议
@protocol FWAuthorizeProtocol <NSObject>

@required

// 获取权限状态，子类重写
- (FWAuthorizeStatus)authorizeStatus;

// 执行权限授权，子类重写
- (void)authorize:(void (^)(FWAuthorizeStatus status))completion;

@end

#pragma mark - FWAuthorizeManager

/**
 *  权限管理器。备注：iOS应用运行时到设置中修改部分权限会导致系统自动重启应用
 */
@interface FWAuthorizeManager : NSObject <FWAuthorizeProtocol>

// 获取指定类型的权限管理器单例
+ (instancetype)managerWithType:(FWAuthorizeType)type;

@end
