//
//  AppDelegate.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>
#import "AppBundle.h"
#import "SceneDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 AppDelegate基类
 */
NS_SWIFT_NAME(AppResponder)
@interface __FWAppDelegate : UIResponder <UIApplicationDelegate>

/// 应用主window
@property (nullable, nonatomic, strong) UIWindow *window;

#pragma mark - Protected

/// 初始化应用配置，子类重写
- (void)setupApplication:(UIApplication *)application options:(nullable NSDictionary<UIApplicationLaunchOptionsKey,id> *)options;

/// 初始化根控制器，子类重写
- (void)setupController;

@end

NS_ASSUME_NONNULL_END
