//
//  FWAppDelegate.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWAppDelegate.h"
#import "Mediator.h"

#define FWSafeArgument(obj) obj ? obj : [NSNull null]

@interface FWAppDelegate ()

@end

@implementation FWAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    [__FWMediator setupAllModules];
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application), FWSafeArgument(launchOptions)]];
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application), FWSafeArgument(launchOptions)]];
    [self setupApplication:application options:launchOptions];
    [self setupController];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application)]];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application)]];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application)]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application)]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application)]];
}

#pragma mark - Notification

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application), FWSafeArgument(deviceToken)]];
    /*
    [UIDevice fwSetDeviceTokenData:tokenData];
     */
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application), FWSafeArgument(error)]];
    /*
    [UIDevice fwSetDeviceTokenData:nil];
     */
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application), FWSafeArgument(userInfo), completionHandler]];
    /*
    [[FWNotificationManager sharedInstance] handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
     */
}

#pragma mark - openURL

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(app), FWSafeArgument(url), FWSafeArgument(options)]];
    /*
    [FWRouter openURL:url.absoluteString];
    return YES;
     */
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    return [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[FWSafeArgument(application), FWSafeArgument(userActivity), restorationHandler]];
    /*
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] &&
        userActivity.webpageURL != nil) {
        [FWRouter openURL:userActivity.webpageURL.absoluteString];
        return YES;
    }
    return NO;
     */
}

#pragma mark - Protected

- (void)setupApplication:(UIApplication *)application options:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)options
{
    /*
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
     */
    
    /*
    [[FWNotificationManager sharedInstance] clearNotificationBadges];
    NSDictionary *remoteNotification = (NSDictionary *)[options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification) {
        [[FWNotificationManager sharedInstance] handleRemoteNotification:remoteNotification];
    }
    NSDictionary *localNotification = (NSDictionary *)[options objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        [[FWNotificationManager sharedInstance] handleLocalNotification:localNotification];
    }
     */
    
    /*
    [[FWNotificationManager sharedInstance] registerNotificationHandler];
    [[FWNotificationManager sharedInstance] requestAuthorize:nil];
     */
}

- (void)setupController
{
    /*
    self.window.rootViewController = [TabBarController new];
     */
}

@end
