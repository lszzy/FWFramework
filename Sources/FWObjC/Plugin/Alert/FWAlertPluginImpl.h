//
//  FWAlertPluginImpl.h
//  
//
//  Created by wuyong on 2022/8/23.
//

#import "FWAlertPlugin.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAlertAppearance

/**
 系统弹出框样式配置类，由于系统兼容性，建议优先使用FWAlertController
 @note 如果未自定义样式，显示效果和系统一致，不会产生任何影响；框架会先渲染actions动作再渲染cancel动作
*/
NS_SWIFT_NAME(AlertAppearance)
@interface FWAlertAppearance : NSObject

// 单例模式，统一设置样式
@property (class, nonatomic, readonly) FWAlertAppearance *appearance;

// 自定义首选动作句柄，默认nil，跟随系统
@property (nonatomic, copy, nullable) id _Nullable (^preferredActionBlock)(id alertController);

// 是否启用Controller样式，设置后自动启用
@property (nonatomic, assign, readonly) BOOL controllerEnabled;
// 标题颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *titleColor;
// 标题字体，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIFont *titleFont;
// 消息颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *messageColor;
// 消息字体，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIFont *messageFont;

// 是否启用Action样式，设置后自动启用
@property (nonatomic, assign, readonly) BOOL actionEnabled;
// 默认动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *actionColor;
// 首选动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *preferredActionColor;
// 取消动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *cancelActionColor;
// 警告动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *destructiveActionColor;
// 禁用动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *disabledActionColor;

@end

#pragma mark - UIAlertAction+FWAlert

/**
 系统弹出框动作分类，自定义属性
 @note 系统弹出动作title仅支持NSString，如果需要支持NSAttributedString等，请使用FWAlertController
*/
@interface UIAlertAction (FWAlert)

// 自定义样式，默认为样式单例
@property (nonatomic, strong) FWAlertAppearance *fw_alertAppearance NS_REFINED_FOR_SWIFT;

// 指定标题颜色
@property (nonatomic, strong, nullable) UIColor *fw_titleColor NS_REFINED_FOR_SWIFT;

// 快速创建弹出动作，title仅支持NSString
+ (UIAlertAction *)fw_actionWithObject:(nullable id)object style:(UIAlertActionStyle)style handler:(void (^ __nullable)(UIAlertAction *action))handler NS_REFINED_FOR_SWIFT;

// 快速创建弹出动作，title仅支持NSString，支持appearance
+ (UIAlertAction *)fw_actionWithObject:(nullable id)object style:(UIAlertActionStyle)style appearance:(nullable FWAlertAppearance *)appearance handler:(void (^ __nullable)(UIAlertAction *action))handler NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIAlertController+FWAlert

/**
 系统弹出框控制器分类，自定义样式
 @note 系统弹出框title和message仅支持NSString，如果需要支持NSAttributedString等，请使用FWAlertController
*/
@interface UIAlertController (FWAlert)

// 自定义样式，默认为样式单例
@property (nonatomic, strong) FWAlertAppearance *fw_alertAppearance NS_REFINED_FOR_SWIFT;

// 当前弹窗样式，默认为Default样式
@property (nonatomic, assign) FWAlertStyle fw_alertStyle NS_REFINED_FOR_SWIFT;

// 设置属性标题
@property (nonatomic, copy, nullable) NSAttributedString *fw_attributedTitle NS_REFINED_FOR_SWIFT;

// 设置属性消息
@property (nonatomic, copy, nullable) NSAttributedString *fw_attributedMessage NS_REFINED_FOR_SWIFT;

// 快速创建弹出控制器，title和message仅支持NSString
+ (UIAlertController *)fw_alertControllerWithTitle:(nullable id)title message:(nullable id)message preferredStyle:(UIAlertControllerStyle)preferredStyle NS_REFINED_FOR_SWIFT;

// 快速创建弹出控制器，title和message仅支持NSString，支持自定义样式
+ (UIAlertController *)fw_alertControllerWithTitle:(nullable id)title message:(nullable id)message preferredStyle:(UIAlertControllerStyle)preferredStyle appearance:(nullable FWAlertAppearance *)appearance NS_REFINED_FOR_SWIFT;

@end

#pragma mark - FWAlertPluginImpl

/// 默认弹窗插件
NS_SWIFT_NAME(AlertPluginImpl)
@interface FWAlertPluginImpl : NSObject <FWAlertPlugin>

/// 单例模式对象
@property (class, nonatomic, readonly) FWAlertPluginImpl *sharedInstance;

/// 自定义Alert弹窗样式，nil时使用单例
@property (nonatomic, strong, nullable) FWAlertAppearance *customAlertAppearance;

/// 自定义ActionSheet弹窗样式，nil时使用单例
@property (nonatomic, strong, nullable) FWAlertAppearance *customSheetAppearance;

/// 自定义弹窗类数组，默认nil时查找UIAlertController|FWAlertController
@property (nonatomic, copy, nullable) NSArray<Class> *customAlertClasses;

/// 弹窗自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(UIAlertController *alertController);

/// 默认close按钮文本句柄，alert单按钮或sheet单取消生效。未设置时为关闭
@property (nonatomic, copy, nullable) NSString * _Nullable (^defaultCloseButton)(UIAlertControllerStyle style);
/// 默认cancel按钮文本句柄，alert多按钮或sheet生效。未设置时为取消
@property (nonatomic, copy, nullable) NSString * _Nullable (^defaultCancelButton)(UIAlertControllerStyle style);
/// 默认confirm按钮文本句柄，alert多按钮生效。未设置时为确定
@property (nonatomic, copy, nullable) NSString * _Nullable (^defaultConfirmButton)(void);

@end

NS_ASSUME_NONNULL_END
