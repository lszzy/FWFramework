/*!
 @header     UIViewController+FWStyle.h
 @indexgroup FWFramework
 @brief      UIViewController+FWStyle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/5
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 导航栏样式可扩展枚举
typedef NSInteger FWNavigationBarStyle NS_TYPED_EXTENSIBLE_ENUM;
static const FWNavigationBarStyle FWNavigationBarStyleDefault = 0;
static const FWNavigationBarStyle FWNavigationBarStyleClear   = 1;
static const FWNavigationBarStyle FWNavigationBarStyleHidden  = 2;

/*!
 @brief UIViewController+FWStyle
 */
@interface UIViewController (FWStyle)

/// 当前导航栏样式，设置后才生效
@property (nonatomic, assign) FWNavigationBarStyle fwNavigationBarStyle;

@end

/// 导航栏样式配置
@interface FWNavigationBarConfig : NSObject

@property (nullable, nonatomic, strong, readonly) UIColor *backgroundColor;
@property (nullable, nonatomic, strong, readonly) UIColor *foregroundColor;
@property (nullable, nonatomic, copy, readonly) void (^configBlock)(UINavigationBar *navigationBar);

- (instancetype)initWithBackgroundColor:(nullable UIColor *)backgroundColor
                        foregroundColor:(nullable UIColor *)foregroundColor
                            configBlock:(nullable void (^)(UINavigationBar *navigationBar))configBlock;

/// 框架样式配置，默认方案
+ (nullable FWNavigationBarConfig *)configForStyle:(FWNavigationBarStyle)style;
+ (void)setConfig:(nullable FWNavigationBarConfig *)config forStyle:(FWNavigationBarStyle)style;

/// 系统样式配置，iOS13+，可选方案
+ (nullable UINavigationBarAppearance *)appearanceForStyle:(FWNavigationBarStyle)style API_AVAILABLE(ios(13.0));
+ (void)setAppearance:(nullable UINavigationBarAppearance *)appearance forStyle:(FWNavigationBarStyle)style API_AVAILABLE(ios(13.0));

@end

NS_ASSUME_NONNULL_END
