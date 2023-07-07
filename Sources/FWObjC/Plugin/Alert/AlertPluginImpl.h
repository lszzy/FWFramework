//
//  AlertPluginImpl.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "AlertPlugin.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWAlertAppearance

/**
 系统弹出框样式配置类，由于系统兼容性，建议优先使用__FWAlertController
 @note 如果未自定义样式，显示效果和系统一致，不会产生任何影响；框架会先渲染actions动作再渲染cancel动作
*/
NS_SWIFT_NAME(AlertAppearance)
@interface __FWAlertAppearance : NSObject

// 单例模式，统一设置样式
@property (class, nonatomic, readonly) __FWAlertAppearance *appearance;

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

#pragma mark - __FWAlertPluginImpl

/// 默认弹窗插件
NS_SWIFT_NAME(AlertPluginImpl)
@interface __FWAlertPluginImpl : NSObject <__FWAlertPlugin>

/// 单例模式对象
@property (class, nonatomic, readonly) __FWAlertPluginImpl *sharedInstance NS_SWIFT_NAME(shared);

/// 自定义Alert弹窗样式，nil时使用单例
@property (nonatomic, strong, nullable) __FWAlertAppearance *customAlertAppearance;

/// 自定义ActionSheet弹窗样式，nil时使用单例
@property (nonatomic, strong, nullable) __FWAlertAppearance *customSheetAppearance;

/// 自定义弹窗类数组，默认nil时查找UIAlertController|__FWAlertController
@property (nonatomic, copy, nullable) NSArray<Class> *customAlertClasses;

/// 弹窗自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(UIAlertController *alertController);

/// 默认close按钮文本句柄，alert单按钮或sheet单取消生效。未设置时为关闭
@property (nonatomic, copy, nullable) id _Nullable (^defaultCloseButton)(UIAlertControllerStyle style);
/// 默认cancel按钮文本句柄，alert多按钮或sheet生效。未设置时为取消
@property (nonatomic, copy, nullable) id _Nullable (^defaultCancelButton)(UIAlertControllerStyle style);
/// 默认confirm按钮文本句柄，alert多按钮生效。未设置时为确定
@property (nonatomic, copy, nullable) id _Nullable (^defaultConfirmButton)(void);

/// 错误标题格式化句柄，error生效，默认nil
@property (nonatomic, copy, nullable) id _Nullable (^errorTitleFormatter)(NSError * _Nullable error);
/// 错误消息格式化句柄，error生效，默认nil
@property (nonatomic, copy, nullable) id _Nullable (^errorMessageFormatter)(NSError * _Nullable error);
/// 错误样式格式化句柄，error生效，默认nil
@property (nonatomic, copy, nullable) __FWAlertStyle (^errorStyleFormatter)(NSError * _Nullable error);
/// 错误按钮格式化句柄，error生效，默认nil
@property (nonatomic, copy, nullable) id _Nullable (^errorButtonFormatter)(NSError * _Nullable error);

@end

NS_ASSUME_NONNULL_END
