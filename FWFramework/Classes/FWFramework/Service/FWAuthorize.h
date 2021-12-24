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

/// 权限类型可扩展枚举
typedef NSInteger FWAuthorizeType NS_TYPED_EXTENSIBLE_ENUM;
/// 定位，Info.plst需配置NSLocationWhenInUseUsageDescription，iOS7需配置NSLocationUsageDescription
static const FWAuthorizeType FWAuthorizeTypeLocationWhenInUse = 1;
/// 后台定位，Info.plst需配置NSLocationAlwaysUsageDescription和NSLocationAlwaysAndWhenInUseUsageDescription，iOS7需配置NSLocationUsageDescription
static const FWAuthorizeType FWAuthorizeTypeLocationAlways = 2;
/// 相册，Info.plst需配置NSPhotoLibraryUsageDescription
static const FWAuthorizeType FWAuthorizeTypePhotoLibrary = 3;
/// 照相机，Info.plst需配置NSCameraUsageDescription
static const FWAuthorizeType FWAuthorizeTypeCamera = 4;
/// 通知，远程推送需打开Push Notifications开关和Background Modes的Remote notifications开关
static const FWAuthorizeType FWAuthorizeTypeNotifications = 5;

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
 权限管理器。由于打包上传ipa时会自动检查隐私库并提供Info.plist描述，所以默认关闭隐私库声明
 @note 开启指定权限方法：
 一、Pod项目：添加pod时同时指定
 pod 'FWFramework', :subspecs => ['Contacts']
 二、SPM项目：添加依赖时选中target
 FWFrameworkContacts
 */
@interface FWAuthorizeManager : NSObject

/// 获取指定类型的权限管理器单例，部分权限未启用时返回nil
+ (nullable id<FWAuthorizeProtocol>)managerWithType:(FWAuthorizeType)type;

/// 注册指定类型的权限管理器创建句柄，用于动态扩展权限类型
+ (void)registerAuthorize:(FWAuthorizeType)type withBlock:(id<FWAuthorizeProtocol> (^)(void))block;

@end

NS_ASSUME_NONNULL_END
