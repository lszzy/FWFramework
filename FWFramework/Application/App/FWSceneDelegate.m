/*!
 @header     FWSceneDelegate.m
 @indexgroup FWFramework
 @brief      FWSceneDelegate
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/12
 */

#import "FWSceneDelegate.h"

@interface FWSceneDelegate ()

@end

@implementation FWSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
        [self setupController];
        [self.window makeKeyAndVisible];
    }
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    
}

- (void)sceneWillResignActive:(UIScene *)scene {
    
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    
}

#pragma mark - Protected

- (void)setupController
{
    // self.window.rootViewController = [TabBarController new];
}

@end
