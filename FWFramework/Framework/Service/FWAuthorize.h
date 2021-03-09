//
//  FWAuthorize.h
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum

/*!
 @brief 权限类型枚举。由于打包上传ipa时会自动检查隐私库并提供Info.plist描述，所以默认关闭隐私库声明
 @discussion 开启指定权限方法：
 一、Pod项目：添加pod时同时指定
 pod 'FWFramework', :subspecs => ['Component-Contacts']
 二、Pod项目：在Podfile最后添加
 post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        if target.name == 'FWFramework'
            target.build_configurations.each do |config|
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'FWCONFIGURATION_CONTACTS_ENABLED=1'
            end
        end
    end
 end
 三、Framework项目：修改项目GCC_PREPROCESSOR_DEFINITIONS添加配置：FWCONFIGURATION_CONTACTS_ENABLED=1
 */
typedef NSInteger FWAuthorizeType NS_TYPED_EXTENSIBLE_ENUM;
/// 定位，Info.plst需配置NSLocationWhenInUseUsageDescription，iOS7需配置NSLocationUsageDescription
static const FWAuthorizeType FWAuthorizeTypeLocationWhenInUse = 1;
/// 后台定位，Info.plst需配置NSLocationAlwaysUsageDescription和NSLocationAlwaysAndWhenInUseUsageDescription，iOS7需配置NSLocationUsageDescription
static const FWAuthorizeType FWAuthorizeTypeLocationAlways = 2;
/// 麦克风，需配置FWCONFIGURATION_MICROPHONE_ENABLED=1，Info.plst需配置NSMicrophoneUsageDescription
static const FWAuthorizeType FWAuthorizeTypeMicrophone = 3;
/// 相册，Info.plst需配置NSPhotoLibraryUsageDescription
static const FWAuthorizeType FWAuthorizeTypePhotoLibrary = 4;
/// 照相机，Info.plst需配置NSCameraUsageDescription
static const FWAuthorizeType FWAuthorizeTypeCamera = 5;
/// 联系人，需配置FWCONFIGURATION_CONTACTS_ENABLED=1，Info.plst需配置NSContactsUsageDescription
static const FWAuthorizeType FWAuthorizeTypeContacts = 6;
/// 日历，需配置FWCONFIGURATION_CALENDAR_ENABLED=1，Info.plst需配置NSCalendarsUsageDescription
static const FWAuthorizeType FWAuthorizeTypeCalendars = 7;
/// 提醒，需配置FWCONFIGURATION_CALENDAR_ENABLED=1，Info.plst需配置NSRemindersUsageDescription
static const FWAuthorizeType FWAuthorizeTypeReminders = 8;
/// 音乐，需配置FWCONFIGURATION_APPLEMUSIC_ENABLED=1，Info.plst需配置NSAppleMusicUsageDescription
static const FWAuthorizeType FWAuthorizeTypeAppleMusic = 9;
/// 通知，远程推送需打开Push Notifications开关和Background Modes的Remote notifications开关
static const FWAuthorizeType FWAuthorizeTypeNotifications = 10;
/// 广告跟踪，需配置FWCONFIGURATION_TRACKING_ENABLED=1，Info.plst需配置NSUserTrackingUsageDescription
static const FWAuthorizeType FWAuthorizeTypeTracking = 11;

/// 权限状态枚举
typedef NS_ENUM(NSInteger, FWAuthorizeStatus) {
    /// 未确认
    FWAuthorizeStatusNotDetermined = 0,
    /// 受限制
    FWAuthorizeStatusRestricted,
    /// 被拒绝
    FWAuthorizeStatusDenied,
    /// 已授权
    FWAuthorizeStatusAuthorized,
};

#pragma mark - FWAuthorizeProtocol

/// 权限授权协议
@protocol FWAuthorizeProtocol <NSObject>

@required

/// 查询权限状态，必须实现。某些权限会阻塞当前线程，建议异步查询，如通知
- (FWAuthorizeStatus)authorizeStatus;

/// 执行权限授权，主线程回调，必须实现
- (void)authorize:(nullable void (^)(FWAuthorizeStatus status))completion;

@optional

/// 异步查询权限状态，当前线程回调，可选实现。某些权限建议异步查询，不会阻塞当前线程，如通知
- (void)authorizeStatus:(nullable void (^)(FWAuthorizeStatus status))completion;

@end

#pragma mark - FWAuthorizeManager

/**
 @brief 权限管理器。备注：iOS应用运行时到设置中修改部分权限会导致系统自动重启应用
 @discussion 部分权限需配置编译时FWCONFIGURATION_CONTACTS_ENABLED为1才可用，如麦克风、日历、联系人等
 */
@interface FWAuthorizeManager : NSObject <FWAuthorizeProtocol>

/// 获取指定类型的权限管理器单例，部分权限未启用时返回nil
+ (nullable instancetype)managerWithType:(FWAuthorizeType)type;

@end

NS_ASSUME_NONNULL_END
