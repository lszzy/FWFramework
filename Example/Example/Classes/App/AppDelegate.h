//
//  AppDelegate.h
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#if APP_TARGET == 2

#import <Flutter/Flutter.h>

@interface AppDelegate : FlutterAppDelegate

@end

#else

#import <UIKit/UIKit.h>

@interface AppDelegate : FWAppDelegate

@end

#endif
