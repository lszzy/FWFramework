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

// 是否越狱
+ (BOOL)fwIsJailbroken;

#pragma mark - Landscape

// 界面是否横屏
+ (BOOL)fwIsInterfaceLandscape;

// 设备是否横屏，无论支不支持横屏
+ (BOOL)fwIsDeviceLandscape;

// 设置界面方向，支持旋转方向时生效
+ (BOOL)fwSetDeviceOrientation:(UIDeviceOrientation)orientation;

#pragma mark - Model

// 设备模型，格式："iPhone6,1"
+ (nullable NSString *)fwDeviceModel;

#pragma mark - UUID

/*!
 @brief 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
 @discussion 如需获取设备IDFA(外部使用)，重置广告或系统后会改变，需导入AdSupport，算法：
    1. 先调用[[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]判断是否启用广告追踪
    2. 执行[[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]获取IDFA
 */
+ (nullable NSString *)fwDeviceIDFV;

/*!
@brief 获取或设置设备UUID，自动keychain持久化。默认获取IDFV(未使用IDFA，避免额外权限)，失败则随机生成一个
*/
@property (class, nonatomic, copy) NSString *fwDeviceUUID;

#pragma mark - Token

// 设置设备token原始Data，格式化并保存
+ (void)fwSetDeviceTokenData:(nullable NSData *)tokenData;

// 获取设备Token格式化后的字符串
+ (nullable NSString *)fwDeviceToken;

#pragma mark - Network

// 本地IP地址
+ (nullable NSString *)fwIpAddress;

// 本地主机名称
+ (nullable NSString *)fwHostName;

// 手机运营商名称
+ (nullable NSString *)fwCarrierName;

@end

NS_ASSUME_NONNULL_END
