//
//  TestDrawerViewController.m
//  Example
//
//  Created by wuyong on 2019/5/6.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestDrawerViewController.h"

#define ViewHeight (FWScreenHeight - FWStatusBarHeight - FWNavigationBarHeight)

@interface TestDrawerViewController ()

@end

@implementation TestDrawerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    
    FWWeakifySelf();
    [self fwSetLeftBarItem:[UIImage imageNamed:@"public_back"] block:^(id sender) {
        FWStrongifySelf();
        [self fwCloseViewControllerAnimated:YES];
    }];
}

- (void)renderView
{
    self.view.backgroundColor = [UIColor brownColor];
    
    [self renderViewUp];
    [self renderViewDown];
    [self renderViewLeft];
    [self renderViewRight];
}

- (void)renderViewUp
{
    UIView *drawerView = [[UIView alloc] initWithFrame:CGRectMake(0, ViewHeight / 4 * 3, self.view.fwWidth, ViewHeight)];
    drawerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:drawerView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] init];
    FWWeakifySelf();
    [panGesture fwDrawerView:drawerView direction:UISwipeGestureRecognizerDirectionUp fromPosition:0 toPosition:ViewHeight / 4 * 3 kickbackHeight:25 callback:^(CGFloat position, BOOL finished) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:drawerView];
        if (position < FWTopBarHeight) {
            CGFloat progress = MIN(1 - position / FWTopBarHeight, 1);
            [self.navigationController.navigationBar fwSetBackgroundColor:[[UIColor brownColor] colorWithAlphaComponent:progress]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
    [drawerView addGestureRecognizer:panGesture];
}

- (void)renderViewDown
{
    UIScrollView *drawerView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, -ViewHeight / 4 * 3, self.view.fwWidth, ViewHeight)];
    drawerView.backgroundColor = [UIColor redColor];
    [self.view addSubview:drawerView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] init];
    FWWeakifySelf();
    [panGesture fwDrawerView:drawerView direction:UISwipeGestureRecognizerDirectionDown fromPosition:-ViewHeight / 4 * 3 toPosition:0 kickbackHeight:25 callback:^(CGFloat position, BOOL finished) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:drawerView];
        if (position == 0) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor brownColor]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
    [drawerView addGestureRecognizer:panGesture];
}

- (void)renderViewLeft
{
    UIScrollView *drawerView = [[UIScrollView alloc] initWithFrame:CGRectMake(FWScreenWidth / 4 * 3, 0, self.view.fwWidth, ViewHeight)];
    drawerView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:drawerView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] init];
    FWWeakifySelf();
    [panGesture fwDrawerView:drawerView direction:UISwipeGestureRecognizerDirectionLeft fromPosition:0 toPosition:FWScreenWidth / 4 * 3 kickbackHeight:25 callback:^(CGFloat position, BOOL finished) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:drawerView];
        if (position == 0) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor brownColor]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
    [drawerView addGestureRecognizer:panGesture];
}

- (void)renderViewRight
{
    UIView *drawerView = [[UIView alloc] initWithFrame:CGRectMake(-FWScreenWidth / 4 * 3, 0, self.view.fwWidth, ViewHeight)];
    drawerView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:drawerView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] init];
    FWWeakifySelf();
    [panGesture fwDrawerView:drawerView direction:UISwipeGestureRecognizerDirectionRight fromPosition:-FWScreenWidth / 4 * 3 toPosition:0 kickbackHeight:25 callback:^(CGFloat position, BOOL finished) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:drawerView];
        if (position == 0) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor brownColor]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
    [drawerView addGestureRecognizer:panGesture];
}

@end
