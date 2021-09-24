/*!
 @header     FWUIKit.h
 @indexgroup FWFramework
 @brief      FWUIKit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIDevice+FWUIKit

/*!
 @brief UIDevice+FWUIKit
 */
@interface UIDevice (FWUIKit)

/// 设置设备token原始Data，格式化并保存
+ (void)fwSetDeviceTokenData:(nullable NSData *)tokenData;

/// 获取设备Token格式化后的字符串
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceToken;

/// 获取设备模型，格式："iPhone6,1"
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceModel;

/// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceIDFV;

/// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Component_Tracking组件后生效
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceIDFA;

@end

#pragma mark - UIView+FWUIKit

/*!
 @brief UIView+FWUIKit
 */
@interface UIView (FWUIKit)

/// 获取响应的视图控制器
@property (nonatomic, strong, readonly, nullable) __kindof UIViewController *fwViewController;

@end

#pragma mark - UIViewController+FWUIKit

/*!
 @brief UIViewController+FWUIKit
 */
@interface UIViewController (FWUIKit)

/// 判断当前控制器是否是根控制器。如果是导航栏的第一个控制器或者不含有导航栏，则返回YES
@property (nonatomic, assign, readonly) BOOL fwIsRoot;

/// 判断当前控制器是否是子控制器。如果父控制器存在，且不是导航栏或标签栏控制器，则返回YES
@property (nonatomic, assign, readonly) BOOL fwIsChild;

/// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES
@property (nonatomic, assign, readonly) BOOL fwIsPresented;

/// 判断当前控制器是否是iOS13+默认pageSheet弹出样式。该样式下导航栏高度等与默认样式不同
@property (nonatomic, assign, readonly) BOOL fwIsPageSheet;

/// 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
@property (nonatomic, assign, readonly) BOOL fwIsViewVisible;

/// 是否已经加载完，默认NO，加载完成后可标记为YES，可用于第一次加载时显示loading等判断
@property (nonatomic, assign) BOOL fwIsLoaded;

@end

NS_ASSUME_NONNULL_END
