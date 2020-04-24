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

#pragma mark - UIAlertController+FWFramework

/*!
 @brief 系统弹出框控制器分类，自定义样式
 @discussion 系统弹出框title和message仅支持NSString，如果需要支持NSAttributedString等，请使用FWAlertController
*/
@interface UIAlertController (FWFramework)

// 快速创建弹出控制器，支持NSString|NSAttributedString
+ (instancetype)fwAlertControllerWithTitle:(nullable id)title message:(nullable id)message preferredStyle:(UIAlertControllerStyle)preferredStyle;

#pragma mark - Appearance

// 样式单例，全局设置样式
+ (instancetype)fwAppearance;

// 标题颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *fwTitleColor;
// 标题字体，仅全局生效
@property (nonatomic, strong, nullable) UIFont *fwTitleFont;
// 消息颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *fwMessageColor;
// 消息字体，仅全局生效
@property (nonatomic, strong, nullable) UIFont *fwMessageFont;

@end

#pragma mark - UIAlertAction+FWFramework

/*!
 @brief 系统弹出框动作分类，自定义属性
 @discussion 系统弹出框action仅支持NSString和UIAlertAction，如果需要支持NSAttributedString等，请使用FWAlertController
*/
@interface UIAlertAction (FWFramework)

// 快速创建弹出动作，支持标题和样式
+ (instancetype)fwActionWithTitle:(nullable NSString *)title style:(UIAlertActionStyle)style;

// 快速创建弹出动作，支持NSString|UIAlertAction(拷贝)
+ (instancetype)fwActionWithObject:(nullable id)object style:(UIAlertActionStyle)style handler:(void (^ __nullable)(UIAlertAction *action))handler;

// 是否是首选动作
@property (nonatomic, assign) BOOL fwIsPreferred;

// 快捷设置首选动作
@property (nonatomic, copy, readonly) UIAlertAction *(^fwPreferred)(BOOL preferred) NS_REFINED_FOR_SWIFT;

// 快捷设置是否禁用
@property (nonatomic, copy, readonly) UIAlertAction *(^fwEnabled)(BOOL enabled) NS_REFINED_FOR_SWIFT;

#pragma mark - Appearance

// Appearance单例，统一设置样式
+ (instancetype)fwAppearance;

// 默认动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *fwDefaultActionColor;
// 取消动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *fwCancelActionColor;
// 警告动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *fwDestructiveActionColor;
// 禁用动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *fwDisabledActionColor;
// 首选动作颜色，仅全局生效
@property (nonatomic, strong, nullable) UIColor *fwPreferredActionColor;

@end

NS_ASSUME_NONNULL_END
