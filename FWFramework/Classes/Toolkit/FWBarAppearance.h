/*!
 @header     FWBarAppearance.h
 @indexgroup FWFramework
 @brief      FWBarAppearance
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UINavigationBar+FWBarAppearance

/*!
 @brief 导航栏视图分类，全局设置用[UINavigationBar appearance]。iOS13+启用appearance(iOS15+必须)，iOS12及以下使用旧版本api
 */
@interface UINavigationBar (FWBarAppearance)

/// 导航栏iOS13+样式对象，用于自定义样式
@property (nonatomic, strong, readonly) UINavigationBarAppearance *fwAppearance API_AVAILABLE(ios(13.0));

/// 手工更新导航栏样式
- (void)fwUpdateAppearance API_AVAILABLE(ios(13.0));

/// 导航栏是否半透明，需先于背景色设置，默认NO。注意启用iOS13+样式后，背景色需带有alpha时半透明才会生效
@property (nonatomic, assign) BOOL fwIsTranslucent UI_APPEARANCE_SELECTOR;

/// 设置前景颜色，包含文字和按钮等
@property (nonatomic, strong, nullable) UIColor *fwForegroundColor UI_APPEARANCE_SELECTOR;

/// 单独设置标题颜色，nil时显示前景颜色
@property (nonatomic, strong, nullable) UIColor *fwTitleColor UI_APPEARANCE_SELECTOR;

/// 设置背景颜色(nil时透明)，兼容主题颜色
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor UI_APPEARANCE_SELECTOR;

/// 设置背景图片(nil时透明)，兼容主题图片
@property (nonatomic, strong, nullable) UIImage *fwBackgroundImage UI_APPEARANCE_SELECTOR;

/// 设置阴影图片(nil时透明)，兼容主题图片
@property (nonatomic, strong, nullable) UIImage *fwShadowImage UI_APPEARANCE_SELECTOR;

/// 设置透明背景并隐藏底部线条，自动清空主题背景
- (void)fwSetBackgroundTransparent UI_APPEARANCE_SELECTOR;

/// 设置返回按钮图片，包含图片和转场Mask图片
@property (nonatomic, strong, nullable) UIImage *fwBackImage UI_APPEARANCE_SELECTOR;

/// 设置返回按钮图片并自动偏移，和系统左侧按钮位置保持一致
- (void)fwSetOffsetBackImage:(nullable UIImage *)backImage;

@end

#pragma mark - UITabBar+FWBarAppearance

/*!
 @brief 标签栏视图分类，全局设置用[UITabBar appearance]。iOS13+启用appearance(iOS15+必须)，iOS12及以下使用旧版本api
 */
@interface UITabBar (FWBarAppearance)

/// 标签栏iOS13+样式对象，用于自定义样式
@property (nonatomic, strong, readonly) UITabBarAppearance *fwAppearance API_AVAILABLE(ios(13.0));

/// 手工更新标签栏样式
- (void)fwUpdateAppearance API_AVAILABLE(ios(13.0));

/// 标签栏是否半透明，需先于背景色设置，默认NO。注意启用iOS13+样式后，背景色需带有alpha时半透明才会生效
@property (nonatomic, assign) BOOL fwIsTranslucent;

/// 设置前景颜色，包含文字和按钮等
@property (nonatomic, strong, nullable) UIColor *fwForegroundColor;

/// 设置背景颜色，兼容主题颜色
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor;

/// 设置背景图片，兼容主题图片
@property (nonatomic, strong, nullable) UIImage *fwBackgroundImage;

/// 设置阴影图片(nil时透明)，兼容主题图片
@property (nonatomic, strong, nullable) UIImage *fwShadowImage;

@end

#pragma mark - UIToolbar+FWBarAppearance

/*!
 @brief 工具栏样式分类，全局设置用[UIToolbar appearance]。iOS13+启用appearance(iOS15+必须)，iOS12及以下使用旧版本api
 @discussion 工具栏高度建议用sizeToFit自动获取(示例44)，contentView为内容视图(示例44)，backgroundView为背景视图(示例78)
 */
@interface UIToolbar (FWBarAppearance)

/// 工具栏iOS13+样式对象，用于自定义样式
@property (nonatomic, strong, readonly) UIToolbarAppearance *fwAppearance API_AVAILABLE(ios(13.0));

/// 手工更新工具栏样式
- (void)fwUpdateAppearance API_AVAILABLE(ios(13.0));

/// 工具栏是否半透明，需先于背景色设置，默认NO。注意启用iOS13+样式后，背景色需带有alpha时半透明才会生效
@property (nonatomic, assign) BOOL fwIsTranslucent UI_APPEARANCE_SELECTOR;

/// 设置前景颜色，包含文字和按钮等
@property (nonatomic, strong, nullable) UIColor *fwForegroundColor UI_APPEARANCE_SELECTOR;

/// 设置背景颜色，兼容主题颜色
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor UI_APPEARANCE_SELECTOR;

/// 设置背景图片，兼容主题图片
@property (nonatomic, strong, nullable) UIImage *fwBackgroundImage UI_APPEARANCE_SELECTOR;

/// 设置阴影图片(nil时透明)，兼容主题图片
@property (nonatomic, strong, nullable) UIImage *fwShadowImage UI_APPEARANCE_SELECTOR;

/// 自定义工具栏位置，调用后才生效，会自动设置delegate。Bottom时背景自动向下延伸，TopAttached时背景自动向上延伸
@property (nonatomic, assign) UIBarPosition fwBarPosition;

@end

NS_ASSUME_NONNULL_END