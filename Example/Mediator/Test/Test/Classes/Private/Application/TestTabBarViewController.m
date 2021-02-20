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
        self.tabBar.backgroundView.backgroundColor = [Theme barColor];
        [self setupViewControllers];
    }
    return self;
}

- (void)setupViewControllers
{
    UIViewController *firstController = [[TestRouterViewController alloc] init];
    UIViewController *secondController = [[TestModuleController alloc] init];
    UIViewController *thirdController = [[TestWebViewController alloc] initWithRequestUrl:@"http://kvm.wuyong.site/test.php"];
    [self setViewControllers:@[firstController, secondController, thirdController]];
    
    firstController.fwTabBarItem.title = FWLocalizedString(@"homeTitle");
    firstController.fwTabBarItem.badgeValue = @"99";
    secondController.fwTabBarItem.title = FWLocalizedString(@"testTitle");
    thirdController.fwTabBarItem.title = FWLocalizedString(@"settingTitle");
    thirdController.fwTabBarItem.badgeDot = YES;
    
    [self setupItemImages];
    FWWeakifySelf();
    [self fwAddThemeListener:^(FWThemeStyle style) {
        FWStrongifySelf();
        [self setupItemImages];
    }];
}

- (void)setupItemImages
{
    [self.viewControllers[0].fwTabBarItem setFinishedSelectedImage:[[TestBundle imageNamed:@"tabbar_home"] fwImageWithTintColor:[Theme textColor]] withFinishedUnselectedImage:[[TestBundle imageNamed:@"tabbar_home"] fwImageWithTintColor:[Theme detailColor]]];
    [self.viewControllers[1].fwTabBarItem setFinishedSelectedImage:[[TestBundle imageNamed:@"tabbar_test"] fwImageWithTintColor:[Theme textColor]] withFinishedUnselectedImage:[[TestBundle imageNamed:@"tabbar_test"] fwImageWithTintColor:[Theme detailColor]]];
    [self.viewControllers[2].fwTabBarItem setFinishedSelectedImage:[[TestBundle imageNamed:@"tabbar_settings"] fwImageWithTintColor:[Theme textColor]] withFinishedUnselectedImage:[[TestBundle imageNamed:@"tabbar_settings"] fwImageWithTintColor:[Theme detailColor]]];
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
