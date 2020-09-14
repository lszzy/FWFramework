//
//  SceneDelegate.m
//  Example
//
//  Created by wuyong on 2020/9/12.
//

#import "SceneDelegate.h"
#import "TabBarController.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate

- (void)setupController
{
    // iOS13使用新的方式
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [TabBarController new];
}

@end
