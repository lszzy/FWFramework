//
//  FWSceneDelegate.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWSceneDelegate.h"

@interface FWSceneDelegate ()

@end

@implementation FWSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
        [self.window makeKeyAndVisible];
        [self setupController];
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

- (void)setupController {
    /*
    self.window.rootViewController = [TabBarController new];
     */
}

@end
