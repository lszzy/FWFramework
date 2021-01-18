//
//  TestTabBarViewController.m
//  Example
//
//  Created by wuyong on 2020/12/21.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestTabBarViewController.h"
#import "TestRouterViewController.h"
#import "TestModuleController.h"
#import "TestWebViewController.h"
@import Core;

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
    UIViewController *firstViewController = [[TestRouterViewController alloc] init];
    UIViewController *secondViewController = [[TestModuleController alloc] init];
    TestWebViewController *thirdViewController = [[TestWebViewController alloc] init];
    thirdViewController.requestUrl = @"http://kvm.wuyong.site/test.php";
    [self setViewControllers:@[firstViewController, secondViewController, thirdViewController]];
    [self customizeTabBar];
}

- (void)customizeTabBar
{
    NSArray *tabBarItemTitles = @[FWLocalizedString(@"homeTitle"), FWLocalizedString(@"testTitle"), FWLocalizedString(@"settingTitle")];
    NSArray *tabBarItemImages = @[@"tabbar_home", @"tabbar_test", @"tabbar_settings"];
    NSInteger index = 0;
    for (FWTabBarItem *item in [[self tabBar] items]) {
        item.title = [tabBarItemTitles objectAtIndex:index];
        UIImage *selectedimage = [[TestBundle imageNamed:[tabBarItemImages objectAtIndex:index]] fwImageWithTintColor:[Theme textColor]];
        UIImage *unselectedimage = [TestBundle imageNamed:[tabBarItemImages objectAtIndex:index]];
        [item setFinishedSelectedImage:selectedimage withFinishedUnselectedImage:unselectedimage];
        if (index == 0) {
            item.badgeValue = @"1";
        }
        index++;
    }
}

#pragma mark - Public

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
