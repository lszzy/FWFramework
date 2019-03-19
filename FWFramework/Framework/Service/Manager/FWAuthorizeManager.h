//
//  FWAuthorizeManager.h
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Enum

/*!
 @brief 权限类型枚举。由于打包上传ipa时会自动检查隐私库并提供Info.plist描述，所以默认关闭隐私库声明
 @discussion 开启指定权限方法：
 1. 主项目：GCC_PREPROCESSOR_DEFINITIONS添加配置：FWAuthorizeContactsEnabled=1
 2. Pod项目：在Podfile最后添加：
 post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        if target.name == 'FWFramework'
            target.build_configurations.each do |config|
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'FWAuthorizeContactsEnabled=1'
            end
        end
    end
 end
 */
typedef NS_ENUM(NSInteger, FWAuthorizeType) {
    // 定位，Info.plst需配置NSLocationWhenInUseUsageDescription，iOS7需配置NSLocationUsageDescription
    FWAuthorizeTypeLocationWhenInUse = 1,
    // 后台定位，Info.plst需配置NSLocationAlwaysUsageDescription和NSLocationAlwaysAndWhenInUseUsageDescription，iOS7需配置NSLocationUsageDescription
    FWAuthorizeTypeLocationAlways = 2,
#if FWAuthorizeMicrophoneEnabled
    // 麦克风，Info.plst需配置NSMicrophoneUsageDescription
    FWAuthorizeTypeMicrophone = 3,
#endif
    // 相册，Info.plst需配置NSPhotoLibraryUsageDescription
    FWAuthorizeTypePhotoLibrary = 4,
    // 照相机，Info.plst需配置NSCameraUsageDescription
    FWAuthorizeTypeCamera = 5,
#if FWAuthorizeContactsEnabled
    // 联系人，Info.plst需配置NSContactsUsageDescription
    FWAuthorizeTypeContacts = 6,
#endif
#if FWAuthorizeCalendarEnabled
    // 日历，Info.plst需配置NSCalendarsUsageDescription
    FWAuthorizeTypeCalendars = 7,
    // 提醒，Info.plst需配置NSRemindersUsageDescription
    FWAuthorizeTypeReminders = 8,
#endif
#if FWAuthorizeAppleMusicEnabled
    // 音乐，Info.plst需配置NSAppleMusicUsageDescription
    FWAuthorizeTypeAppleMusic = 9,
#endif
    // 通知，远程推送需打开Push Notifications开关和Background Modes的Remote notifications开关
    FWAuthorizeTypeNotifications = 10,
};

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
