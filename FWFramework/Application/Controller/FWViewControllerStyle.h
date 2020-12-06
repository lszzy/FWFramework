/*!
 @header     FWViewControllerStyle.h
 @indexgroup FWFramework
 @brief      FWViewControllerStyle
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

/*!
 @brief UIViewController+FWStyle
 */
@interface UIViewController (FWStyle)

/// 当前导航栏样式，设置后才会在viewWillAppear:自动应用生效
@property (nonatomic, assign) FWNavigationBarStyle fwNavigationBarStyle;

@end

/// 导航栏样式配置
@interface FWNavigationBarAppearance : NSObject

@property (nullable, nonatomic, strong, readonly) UIColor *backgroundColor;
@property (nullable, nonatomic, strong, readonly) UIColor *foregroundColor;
@property (nullable, nonatomic, copy, readonly) void (^appearanceBlock)(UINavigationBar *navigationBar);

- (instancetype)initWithBackgroundColor:(nullable UIColor *)backgroundColor
                        foregroundColor:(nullable UIColor *)foregroundColor
                        appearanceBlock:(nullable void (^)(UINavigationBar *navigationBar))appearanceBlock;

+ (nullable FWNavigationBarAppearance *)appearanceForStyle:(FWNavigationBarStyle)style;
+ (void)setAppearance:(nullable FWNavigationBarAppearance *)appearance forStyle:(FWNavigationBarStyle)style;

@end

NS_ASSUME_NONNULL_END
