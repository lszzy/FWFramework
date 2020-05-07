/*!
 @header     UIAlertController+FWFramework.h
 @indexgroup FWFramework
 @brief      UIAlertController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/4/25
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIAlertAction+FWFramework

/*!
 @brief 系统弹出框动作分类，自定义属性
 @discussion 系统弹出动作title仅支持NSString，如果需要支持NSAttributedString等，请使用FWAlertController
*/
@interface UIAlertAction (FWFramework)

// 快速创建弹出动作，title仅支持NSString
+ (instancetype)fwActionWithObject:(nullable id)object style:(UIAlertActionStyle)style handler:(void (^ __nullable)(UIAlertAction *action))handler;

// 指定标题颜色
@property (nonatomic, strong, nullable) UIColor *fwTitleColor;

@end

#pragma mark - UIAlertController+FWFramework

/*!
 @brief 系统弹出框控制器分类，自定义样式
 @discussion 系统弹出框title和message仅支持NSString，如果需要支持NSAttributedString等，请使用FWAlertController
*/
@interface UIAlertController (FWFramework)

// 快速创建弹出控制器，title和message仅支持NSString
+ (instancetype)fwAlertControllerWithTitle:(nullable id)title message:(nullable id)message preferredStyle:(UIAlertControllerStyle)preferredStyle;

// 设置属性标题
@property (nonatomic, copy, nullable) NSAttributedString *fwAttributedTitle;

// 设置属性消息
@property (nonatomic, copy, nullable) NSAttributedString *fwAttributedMessage;

@end

#pragma mark - FWAlertAppearance

/*!
 @brief 系统弹出框样式配置类，由于系统兼容性，建议优先使用FWAlertController
 @discussion 如果未自定义样式，显示效果和系统一致，不会产生任何影响；框架会先渲染actions动作再渲染cancel动作
*/
@interface FWAlertAppearance : NSObject

// 单例模式，统一设置样式
+ (instancetype)appearance;

// 自定义首选动作句柄，默认nil，跟随系统
@property (nonatomic, copy, nullable) id _Nullable (^preferredActionBlock)(id alertController);

// 是否启用Controller样式，设置后自动启用
@property (nonatomic, assign, readonly) BOOL controllerEnabled;
// 标题颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *titleColor;
// 标题字体，仅全局生效
@property (nonatomic, strong, nullable) UIFont *titleFont;
// 消息颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *messageColor;
// 消息字体，仅全局生效
@property (nonatomic, strong, nullable) UIFont *messageFont;

// 是否启用Action样式，设置后自动启用
@property (nonatomic, assign, readonly) BOOL actionEnabled;
// 默认动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *defaultActionColor;
// 取消动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *cancelActionColor;
// 警告动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *destructiveActionColor;
// 禁用动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *disabledActionColor;
// 首选动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *preferredActionColor;

@end

NS_ASSUME_NONNULL_END
