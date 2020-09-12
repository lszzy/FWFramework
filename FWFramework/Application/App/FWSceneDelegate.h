/*!
 @header     FWSceneDelegate.h
 @indexgroup FWFramework
 @brief      FWSceneDelegate
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/12
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief SceneDelegate基类
 */
@interface FWSceneDelegate : UIResponder <UIWindowSceneDelegate>

/// 场景主window
@property (strong, nonatomic) UIWindow * window;

/// 初始化根控制器，子类重写
- (void)setupController;

@end

NS_ASSUME_NONNULL_END
