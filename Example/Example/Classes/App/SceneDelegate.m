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
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [TabBarController new];
}

@end
