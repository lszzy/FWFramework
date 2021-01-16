//
//  AppConfig.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "AppConfig.h"

@implementation AppConfig

+ (void)refreshController
{
    if (@available(iOS 13.0, *)) {
        FWSceneDelegate *sceneDelegete = (FWSceneDelegate *)UIWindow.fwMainScene.delegate;
        [sceneDelegete setupController];
    } else {
        FWAppDelegate *appDelegate = (FWAppDelegate *)UIApplication.sharedApplication.delegate;
        [appDelegate setupController];
    }
}

@end
