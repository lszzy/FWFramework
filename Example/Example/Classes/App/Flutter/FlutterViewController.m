//
//  FlutterViewController.m
//  Example2
//
//  Created by wuyong on 2019/10/17.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "FlutterViewController.h"
@import FlutterPluginRegistrant;

@implementation FlutterViewController (AppDelegate)

+ (instancetype)sharedInstance
{
    static FlutterViewController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FlutterViewController alloc] initWithEngine:[self flutterEngine] nibName:nil bundle:nil];
    });
    return instance;
}

+ (FlutterEngine *)flutterEngine
{
    static FlutterEngine *flutterEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        flutterEngine = [[FlutterEngine alloc] initWithName:@"io.flutter" project:nil];
        [flutterEngine runWithEntrypoint:nil];
        [GeneratedPluginRegistrant registerWithRegistry:flutterEngine];
    });
    return flutterEngine;
}

@end
