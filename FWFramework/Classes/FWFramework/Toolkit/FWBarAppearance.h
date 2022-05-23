/**
 @header     FWBarAppearance.h
 @indexgroup FWFramework
      FWBarAppearance
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <UIKit/UIKit.h>
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWNavigationBarWrapper+FWBarAppearance

/**
 导航栏视图分类，全局设置用[UINavigationBar appearance]。iOS15+启用appearance，iOS14及以下使用旧版本api
 */
@interface FWNavigationBarWrapper (FWBarAppearance)

/// 导航栏iOS13+样式对象，用于自定义样式，默认透明
@property (nonatomic, strong, readonly) UINavigationBarAppearance *appearance API_AVAILABLE(ios(13.0));

/// 手工更新导航栏样式
- (void)updateAppearance API_AVAILABLE(ios(13.0));

/// 导航栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
@property (nonatomic, assign) BOOL isTranslucent UI_APPEARANCE_SELECTOR;

/// 设置前景颜色，包含文字和按钮等
@property (nonatomic, strong, nullable) UIColor *foregroundColor UI_APPEARANCE_SELECTOR;

/// 单独设置标题样式属性，nil时显示前景颜色
@property (nonatomic, copy, nullable) NSDictionary<NSAttributedStringKey, id> *titleAttributes UI_APPEARANCE_SELECTOR;

/// 设置背景颜色(nil时透明)，兼容主题颜色，后设置生效
@property (nonatomic, strong, nullable) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;

/// 设置背景图片(nil时透明)，兼容主题图片，后设置生效
@property (nonatomic, strong, nullable) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;

/// 设置背景是否全透明，默认NO，后设置生效
@property (nonatomic, assign) BOOL backgroundTransparent UI_APPEARANCE_SELECTOR;

/// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
@property (nonatomic, strong, nullable) UIColor *shadowColor UI_APPEARANCE_SELECTOR;

/// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
@property (nonatomic, strong, nullable) UIImage *shadowImage UI_APPEARANCE_SELECTOR;

/// 设置返回按钮图片，包含图片和转场Mask图片，自动偏移和系统左侧按钮位置保持一致
@property (nonatomic, strong, nullable) UIImage *backImage UI_APPEARANCE_SELECTOR;

@end

#pragma mark - FWTabBarWrapper+FWBarAppearance

/**
 标签栏视图分类，全局设置用[UITabBar appearance]。iOS15+启用appearance，iOS14及以下使用旧版本api
 */
@interface FWTabBarWrapper (FWBarAppearance)

/// 标签栏iOS13+样式对象，用于自定义样式，默认透明
@property (nonatomic, strong, readonly) UITabBarAppearance *appearance API_AVAILABLE(ios(13.0));

/// 手工更新标签栏样式
- (void)updateAppearance API_AVAILABLE(ios(13.0));

/// 标签栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
@property (nonatomic, assign) BOOL isTranslucent UI_APPEARANCE_SELECTOR;

/// 设置前景颜色，包含文字和按钮等
@property (nonatomic, strong, nullable) UIColor *foregroundColor UI_APPEARANCE_SELECTOR;

/// 设置背景颜色，兼容主题颜色，后设置生效
@property (nonatomic, strong, nullable) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;

/// 设置背景图片，兼容主题图片，后设置生效
@property (nonatomic, strong, nullable) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;

/// 设置背景是否全透明，默认NO，后设置生效
@property (nonatomic, assign) BOOL backgroundTransparent UI_APPEARANCE_SELECTOR;

/// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
@property (nonatomic, strong, nullable) UIColor *shadowColor UI_APPEARANCE_SELECTOR;

/// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
@property (nonatomic, strong, nullable) UIImage *shadowImage UI_APPEARANCE_SELECTOR;

@end

#pragma mark - FWToolbarWrapper+FWBarAppearance

/**
 工具栏样式分类，全局设置用[UIToolbar appearance]。iOS15+启用appearance，iOS14及以下使用旧版本api
 @note 工具栏高度建议用sizeToFit自动获取(示例44)，contentView为内容视图(示例44)，backgroundView为背景视图(示例78)
 */
@interface FWToolbarWrapper (FWBarAppearance)

/// 工具栏iOS13+样式对象，用于自定义样式，默认透明
@property (nonatomic, strong, readonly) UIToolbarAppearance *appearance API_AVAILABLE(ios(13.0));

/// 手工更新工具栏样式
- (void)updateAppearance API_AVAILABLE(ios(13.0));

/// 工具栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
@property (nonatomic, assign) BOOL isTranslucent UI_APPEARANCE_SELECTOR;

/// 设置前景颜色，包含文字和按钮等
@property (nonatomic, strong, nullable) UIColor *foregroundColor UI_APPEARANCE_SELECTOR;

/// 设置背景颜色，兼容主题颜色，后设置生效
@property (nonatomic, strong, nullable) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;

/// 设置背景图片，兼容主题图片，后设置生效
@property (nonatomic, strong, nullable) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;

/// 设置背景是否全透明，默认NO，后设置生效
@property (nonatomic, assign) BOOL backgroundTransparent UI_APPEARANCE_SELECTOR;

/// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
@property (nonatomic, strong, nullable) UIColor *shadowColor UI_APPEARANCE_SELECTOR;

/// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
@property (nonatomic, strong, nullable) UIImage *shadowImage UI_APPEARANCE_SELECTOR;

/// 自定义工具栏位置，调用后才生效，会自动设置delegate。Bottom时背景自动向下延伸，TopAttached时背景自动向上延伸
@property (nonatomic, assign) UIBarPosition barPosition;

@end

NS_ASSUME_NONNULL_END
