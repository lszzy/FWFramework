/*!
 @header     FWHelper.h
 @indexgroup FWFramework
 @brief      FWHelper
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/11/30
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSAttributedString+FWHelper

/*!
 @brief NSAttributedString+FWHelper
 */
@interface NSAttributedString (FWHelper)

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
+ (nullable instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString;

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)fwHtmlString;

@end

#pragma mark - NSDate+FWHelper

/*!
 @brief NSDate+FWHelper
 */
@interface NSDate (FWHelper)

/// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (class, nonatomic, assign) NSTimeInterval fwCurrentTime;

@end

#pragma mark - UIDevice+FWHelper

/*!
 @brief UIDevice+FWHelper
 */
@interface UIDevice (FWHelper)

// 设置设备token原始Data，格式化并保存
+ (void)fwSetDeviceTokenData:(nullable NSData *)tokenData;

// 获取设备Token格式化后的字符串
+ (nullable NSString *)fwDeviceToken;

/// 获取设备模型，格式："iPhone6,1"
+ (nullable NSString *)fwDeviceModel;

/// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
+ (nullable NSString *)fwDeviceIDFV;

/// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Component_Tracking组件后生效
+ (nullable NSString *)fwDeviceIDFA;

@end

#pragma mark - UIView+FWHelper

/*!
 @brief UIView+FWHelper
 */
@interface UIView (FWHelper)

/// 获取响应的视图控制器
- (nullable UIViewController *)fwViewController;

@end

NS_ASSUME_NONNULL_END
