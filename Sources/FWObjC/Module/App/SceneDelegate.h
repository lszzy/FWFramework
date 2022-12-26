//
//  SceneDelegate.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 SceneDelegate基类
 */
API_AVAILABLE(ios(13.0))
NS_SWIFT_NAME(SceneResponder)
@interface __FWSceneDelegate : UIResponder <UIWindowSceneDelegate>

/// 场景主window
@property (nullable, nonatomic, strong) UIWindow * window;

/// 初始化根控制器，子类重写
- (void)setupController;

@end

NS_ASSUME_NONNULL_END
