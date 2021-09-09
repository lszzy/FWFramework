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

- (void)renderInit
{
    self.hidesBottomBarWhenPushed = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fwTabBarHidden = NO;
    
    [self fwSetLeftBarItem:FWIcon.backImage target:self action:@selector(onClose)];
    FWBadgeView *badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleDot];
    [self.fwNavigationItem.leftBarButtonItem fwShowBadgeView:badgeView badgeValue:nil];
    
    UIBarButtonItem *rightItem = [UIBarButtonItem fwBarItemWithObject:FWIcon.backImage target:self action:@selector(onClick:)];
    badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleSmall];
    [rightItem fwShowBadgeView:badgeView badgeValue:@"1"];
    
    UIButton *customView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    customView.backgroundColor = [Theme textColor];
    UIBarButtonItem *customItem = [UIBarButtonItem fwBarItemWithObject:customView target:self action:@selector(onClick:)];
    badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleSmall];
    [customItem fwShowBadgeView:badgeView badgeValue:@"1"];
    self.fwNavigationItem.rightBarButtonItems = @[rightItem, customItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    FWBadgeView *badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleDot];
    [self.tabBarController.tabBar.items[0] fwShowBadgeView:badgeView badgeValue:nil];
    badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleSmall];
    [self.tabBarController.tabBar.items[1] fwShowBadgeView:badgeView badgeValue:@"99"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.tabBarController.tabBar.items[0] fwHideBadgeView];
    [self.tabBarController.tabBar.items[1] fwHideBadgeView];
}

- (void)renderView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    view.backgroundColor = [Theme textColor];
    FWBadgeView *badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleDot];
    [view fwShowBadgeView:badgeView badgeValue:nil];
    [self.fwView addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(20, 90, 50, 50)];
    view.backgroundColor = [Theme textColor];
    badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleSmall];
    [view fwShowBadgeView:badgeView badgeValue:@"9"];
    [self.fwView addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(90, 90, 50, 50)];
    view.backgroundColor = [Theme textColor];
    badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleSmall];
    [view fwShowBadgeView:badgeView badgeValue:@"99"];
    [self.fwView addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(160, 90, 50, 50)];
    view.backgroundColor = [Theme textColor];
    badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleSmall];
    [view fwShowBadgeView:badgeView badgeValue:@"99+"];
    [self.fwView addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(20, 160, 50, 50)];
    view.backgroundColor = [Theme textColor];
    badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleBig];
    [view fwShowBadgeView:badgeView badgeValue:@"9"];
    [self.fwView addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(90, 160, 50, 50)];
    view.backgroundColor = [Theme textColor];
    badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleBig];
    [view fwShowBadgeView:badgeView badgeValue:@"99"];
    [self.fwView addSubview:view];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(160, 160, 50, 50)];
    view.backgroundColor = [Theme textColor];
    badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleBig];
    [view fwShowBadgeView:badgeView badgeValue:@"99+"];
    [self.fwView addSubview:view];
}

#pragma mark - Action

- (BOOL)fwForcePopGesture
{
    return YES;
}

- (BOOL)fwPopBackBarItem
{
    [self onClose];
    return NO;
}

- (void)onClose
{
    FWWeakifySelf();
    [self fwShowConfirmWithTitle:nil message:@"是否关闭" cancel:nil confirm:nil confirmBlock:^{
        FWStrongifySelf();
        [self fwCloseViewControllerAnimated:YES];
    }];
}

- (void)onClick:(UIBarButtonItem *)sender
{
    [sender fwHideBadgeView];
}

@end
