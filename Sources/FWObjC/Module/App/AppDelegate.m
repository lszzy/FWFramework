//
//  AppDelegate.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "AppDelegate.h"

#if FWMacroSPM

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#define __FWSafeArgument(obj) obj ? obj : [NSNull null]

@interface __FWAppDelegate ()

@end

@implementation __FWAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    [__FWMediator setupAllModules];
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application), __FWSafeArgument(launchOptions)]];
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application), __FWSafeArgument(launchOptions)]];
    [self setupApplication:application options:launchOptions];
    [self setupController];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application)]];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application)]];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application)]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application)]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application)]];
}

#pragma mark - Notification

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application), __FWSafeArgument(deviceToken)]];
    /*
    [UIDevice fwSetDeviceTokenData:tokenData];
     */
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application), __FWSafeArgument(error)]];
    /*
    [UIDevice fwSetDeviceTokenData:nil];
     */
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application), __FWSafeArgument(userInfo), completionHandler]];
    /*
    [[FWNotificationManager sharedInstance] handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
     */
}

#pragma mark - openURL

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(app), __FWSafeArgument(url), __FWSafeArgument(options)]];
    /*
    [FWRouter openURL:url.absoluteString];
    return YES;
     */
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    return [__FWMediator checkAllModulesWithSelector:_cmd arguments:@[__FWSafeArgument(application), __FWSafeArgument(userActivity), restorationHandler]];
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

+ (UIImage *)imageNamed:(NSString *)name
{
    if ([name isEqualToString:@"fw.navBack"]) {
        CGSize size = CGSizeMake(12, 20);
        return [UIImage __fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGFloat lineWidth = 2;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(size.width - lineWidth / 2, lineWidth / 2)];
            [path addLineToPoint:CGPointMake(0 + lineWidth / 2, size.height / 2.0)];
            [path addLineToPoint:CGPointMake(size.width - lineWidth / 2, size.height - lineWidth / 2)];
            [path setLineWidth:lineWidth];
            [path stroke];
        }];
    } else if ([name isEqualToString:@"fw.navClose"]) {
        CGSize size = CGSizeMake(16, 16);
        return [UIImage __fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGFloat lineWidth = 2;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(0, 0)];
            [path addLineToPoint:CGPointMake(size.width, size.height)];
            [path closePath];
            [path moveToPoint:CGPointMake(size.width, 0)];
            [path addLineToPoint:CGPointMake(0, size.height)];
            [path closePath];
            [path setLineWidth:lineWidth];
            [path setLineCapStyle:kCGLineCapRound];
            [path stroke];
        }];
    } else if ([name isEqualToString:@"fw.videoPlay"]) {
        CGSize size = CGSizeMake(60, 60);
        return [UIImage __fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            UIColor *fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.25];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
            CGFloat lineWidth = 1;
            UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(lineWidth / 2, lineWidth / 2, size.width - lineWidth, size.width - lineWidth)];
            [circle setLineWidth:lineWidth];
            [circle stroke];
            [circle fill];
            
            CGContextSetFillColorWithColor(contextRef, color.CGColor);
            CGFloat triangleLength = size.width / 2.5;
            UIBezierPath *triangle = [UIBezierPath bezierPath];
            [triangle moveToPoint:CGPointZero];
            [triangle addLineToPoint:CGPointMake(triangleLength * cos(M_PI / 6), triangleLength / 2)];
            [triangle addLineToPoint:CGPointMake(0, triangleLength)];
            [triangle closePath];
            UIOffset offset = UIOffsetMake(size.width / 2 - triangleLength * tan(M_PI / 6) / 2, size.width / 2 - triangleLength / 2);
            [triangle applyTransform:CGAffineTransformMakeTranslation(offset.horizontal, offset.vertical)];
            [triangle fill];
        }];
    } else if ([name isEqualToString:@"fw.videoPause"]) {
        CGSize size = CGSizeMake(12, 18);
        return [UIImage __fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGFloat lineWidth = 2;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(lineWidth / 2, 0)];
            [path addLineToPoint:CGPointMake(lineWidth / 2, size.height)];
            [path moveToPoint:CGPointMake(size.width - lineWidth / 2, 0)];
            [path addLineToPoint:CGPointMake(size.width - lineWidth / 2, size.height)];
            [path setLineWidth:lineWidth];
            [path stroke];
        }];
    } else if ([name isEqualToString:@"fw.videoStart"]) {
        CGSize size = CGSizeMake(17, 17);
        return [UIImage __fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            CGContextSetFillColorWithColor(contextRef, color.CGColor);
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointZero];
            [path addLineToPoint:CGPointMake(size.width * cos(M_PI / 6), size.width / 2)];
            [path addLineToPoint:CGPointMake(0, size.width)];
            [path closePath];
            [path fill];
        }];
    } else if ([name isEqualToString:@"fw.pickerCheck"]) {
        CGSize size = CGSizeMake(20, 20);
        return [UIImage __fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            UIColor *fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.25];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
            CGFloat lineWidth = 2;
            UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(lineWidth / 2, lineWidth / 2, size.width - lineWidth, size.width - lineWidth)];
            [circle setLineWidth:lineWidth];
            [circle stroke];
            [circle fill];
        }];
    } else if ([name isEqualToString:@"fw.pickerChecked"]) {
        CGSize size = CGSizeMake(20, 20);
        return [UIImage __fw_imageWithSize:size block:^(CGContextRef contextRef) {
            UIColor *color = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
            UIColor *fillColor = [UIColor colorWithRed:7/255.f green:193/255.f blue:96/255.f alpha:1.0];
            CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
            CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
            UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, size.width, size.width)];
            [circle fill];
            
            CGSize checkSize = CGSizeMake(9, 7);
            CGPoint checkOrigin = CGPointMake((size.width - checkSize.width) / 2.0, (size.height - checkSize.height) / 2.0);
            CGFloat lineWidth = 1;
            CGFloat lineAngle = M_PI_4;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(checkOrigin.x, checkOrigin.y + checkSize.height / 2)];
            [path addLineToPoint:CGPointMake(checkOrigin.x + checkSize.width / 3, checkOrigin.y + checkSize.height)];
            [path addLineToPoint:CGPointMake(checkOrigin.x + checkSize.width, checkOrigin.y + lineWidth * sin(lineAngle))];
            [path addLineToPoint:CGPointMake(checkOrigin.x + checkSize.width - lineWidth * cos(lineAngle), checkOrigin.y + 0)];
            [path addLineToPoint:CGPointMake(checkOrigin.x + checkSize.width / 3, checkOrigin.y + checkSize.height - lineWidth / sin(lineAngle))];
            [path addLineToPoint:CGPointMake(checkOrigin.x + lineWidth * sin(lineAngle), checkOrigin.y + checkSize.height / 2 - lineWidth * sin(lineAngle))];
            [path closePath];
            [path setLineWidth:lineWidth];
            [path stroke];
        }];
    }
    return nil;
}

@end
