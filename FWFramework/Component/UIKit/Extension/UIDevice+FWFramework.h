/*!
 @header     UIDevice+FWFramework.h
 @indexgroup FWFramework
 @brief      UIDevice+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIDevice+FWFramework
 */
@interface UIDevice (FWFramework)

#pragma mark - UUID

/// 获取或设置设备UUID，自动keychain持久化。默认获取IDFV(未使用IDFA，避免额外权限)，失败则随机生成一个
@property (class, nonatomic, copy) NSString *fwDeviceUUID;

#pragma mark - Jailbroken

// 是否越狱
@property (class, nonatomic, assign, readonly) BOOL fwIsJailbroken;

#pragma mark - Network

// 本地IP地址
@property (class, nonatomic, copy, readonly, nullable) NSString *fwIpAddress;

// 本地主机名称
@property (class, nonatomic, copy, readonly, nullable) NSString *fwHostName;

// 手机运营商名称
@property (class, nonatomic, copy, readonly, nullable) NSString *fwCarrierName;

@end

NS_ASSUME_NONNULL_END
