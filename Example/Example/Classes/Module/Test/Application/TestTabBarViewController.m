//
//  TestTabBarViewController.m
//  Example
//
//  Created by wuyong on 2020/12/21.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestTabBarViewController.h"
#import "ObjcController.h"
#import "TestViewController.h"
#import "SettingsViewController.h"

@interface TestTabBarViewController () <FWViewController>

@end

@implementation TestTabBarViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        [self setupViewControllers];
    }
    return self;
}

- (void)setupViewControllers
{
    UIViewController *firstViewController = [[ObjcController alloc] init];
    UIViewController *secondViewController = [[TestViewController alloc] init];
    UIViewController *thirdViewController = [[SettingsViewController alloc] init];
    [self setViewControllers:@[firstViewController, secondViewController, thirdViewController]];
    [self customizeTabBar];
}

- (void)customizeTabBar
{
    [self.tabBar.backgroundView fwSetShadowColor:[UIColor appColorHex:0x040000 alpha:0.15] offset:CGSizeMake(0, 1) radius:3];
    NSArray *tabBarItemTitles = @[FWLocalizedString(@"homeTitle"), FWLocalizedString(@"testTitle"), FWLocalizedString(@"settingTitle")];
    NSArray *tabBarItemImages = @[@"tabbar_home", @"tabbar_test", @"tabbar_settings"];
    NSInteger index = 0;
    for (FWTabBarItem *item in [[self tabBar] items]) {
        item.title = [tabBarItemTitles objectAtIndex:index];
        UIImage *selectedimage = [[UIImage imageNamed:[tabBarItemImages objectAtIndex:index]] fwImageWithTintColor:[UIColor appColorMain]];
        UIImage *unselectedimage = [UIImage imageNamed:[tabBarItemImages objectAtIndex:index]];
        [item setFinishedSelectedImage:selectedimage withFinishedUnselectedImage:unselectedimage];
        if (index == 0) {
            item.badgeValue = @"1";
        }
        index++;
    }
}

@end
