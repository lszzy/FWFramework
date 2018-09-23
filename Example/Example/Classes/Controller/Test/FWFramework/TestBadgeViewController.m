/*!
 @header     TestBadgeViewController.m
 @indexgroup Example
 @brief      TestBadgeViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "TestBadgeViewController.h"

@implementation TestBadgeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fwTabBarHidden = NO;
    
    [self fwSetLeftBarItem:[UIImage imageNamed:@"public_back"] target:self action:@selector(fwOnClose)];
    [self.navigationItem.leftBarButtonItem fwShowBadgeWithStyle:FWBadgeStyleDot badgeValue:nil];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithFWObject:[UIImage imageNamed:@"public_back"] target:self action:@selector(onClick:)];
    [rightItem fwShowBadgeWithStyle:FWBadgeStyleSmall badgeValue:@"1"];
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    customView.backgroundColor = [UIColor grayColor];
    UIBarButtonItem *customItem = [[UIBarButtonItem alloc] initWithFWObject:customView target:self action:@selector(onClick:)];
    [customItem fwShowBadgeWithStyle:FWBadgeStyleSmall badgeValue:@"1"];
    self.navigationItem.rightBarButtonItems = @[rightItem, customItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tabBarController.tabBar.items[0] fwShowBadgeWithStyle:FWBadgeStyleDot badgeValue:nil];
    [self.tabBarController.tabBar.items[1] fwShowBadgeWithStyle:FWBadgeStyleSmall badgeValue:@"99"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.tabBarController.tabBar.items[0] fwHideBadge];
    [self.tabBarController.tabBar.items[1] fwHideBadge];
}

- (void)renderView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    view.backgroundColor = [UIColor grayColor];
    [view fwShowBadgeWithStyle:FWBadgeStyleDot badgeValue:nil];
    [self.view addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(20, 90, 50, 50)];
    view.backgroundColor = [UIColor grayColor];
    [view fwShowBadgeWithStyle:FWBadgeStyleSmall badgeValue:@"9"];
    [self.view addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(90, 90, 50, 50)];
    view.backgroundColor = [UIColor grayColor];
    [view fwShowBadgeWithStyle:FWBadgeStyleSmall badgeValue:@"99"];
    [self.view addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(160, 90, 50, 50)];
    view.backgroundColor = [UIColor grayColor];
    [view fwShowBadgeWithStyle:FWBadgeStyleSmall badgeValue:@"99+"];
    [self.view addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(20, 160, 50, 50)];
    view.backgroundColor = [UIColor grayColor];
    [view fwShowBadgeWithStyle:FWBadgeStyleBig badgeValue:@"9"];
    [self.view addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(90, 160, 50, 50)];
    view.backgroundColor = [UIColor grayColor];
    [view fwShowBadgeWithStyle:FWBadgeStyleBig badgeValue:@"99"];
    [self.view addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(160, 160, 50, 50)];
    view.backgroundColor = [UIColor grayColor];
    [view fwShowBadgeWithStyle:FWBadgeStyleBig badgeValue:@"99+"];
    [self.view addSubview:view];
}

#pragma mark - Action

- (void)onClick:(UIBarButtonItem *)sender
{
    [sender fwHideBadge];
}

@end
