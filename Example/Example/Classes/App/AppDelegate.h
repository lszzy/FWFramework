//
//  AppDelegate.h
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#if APP_TARGET == 2

#pragma mark - Flutter

@import UIKit;
@import Flutter;

@interface AppDelegate : FlutterAppDelegate

@property (nonatomic, strong) FlutterEngine *flutterEngine;

@end

#else

#pragma mark - Native

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@end

#endif
