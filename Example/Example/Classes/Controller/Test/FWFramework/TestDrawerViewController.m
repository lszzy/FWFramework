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

- (void)renderView
{
    self.view.backgroundColor = [UIColor brownColor];
    
    [self renderViewUp];
    [self renderViewDown];
}

- (void)renderViewUp
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, ViewHeight / 4 * 3, self.view.fwWidth, ViewHeight)];
    [scrollView fwContentInsetNever];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.contentSize = CGSizeMake(self.view.fwWidth, 2000);
    [self.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 2000)];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 50)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"I am top";
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 975, self.view.fwWidth, 50)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.text = @"I am middle";
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 1950, self.view.fwWidth, 50)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"I am bottom";
    [contentView addSubview:bottomLabel];
    [scrollView addSubview:contentView];
    
    scrollView.bounces = NO;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] init];
    FWWeakifySelf();
    [panGesture fwDrawerView:scrollView topPosition:0 bottomPosition:ViewHeight / 4 * 3 kickbackHeight:25 callback:^(CGFloat position) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:scrollView];
        if (position == 0) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor brownColor]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
    [scrollView addGestureRecognizer:panGesture];
}

- (void)renderViewDown
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, -ViewHeight / 4 * 3, self.view.fwWidth, ViewHeight)];
    [scrollView fwContentInsetNever];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor redColor];
    scrollView.contentSize = CGSizeMake(self.view.fwWidth, 2000);
    [self.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 2000)];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 50)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"I am top";
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 975, self.view.fwWidth, 50)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.text = @"I am middle";
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 1950, self.view.fwWidth, 50)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"I am bottom";
    [contentView addSubview:bottomLabel];
    [scrollView addSubview:contentView];
    
    scrollView.bounces = NO;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] init];
    FWWeakifySelf();
    [panGesture fwDrawerView:scrollView topPosition:-ViewHeight / 4 * 3 bottomPosition:0 kickbackHeight:25 callback:^(CGFloat position) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:scrollView];
        if (position == 0) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor brownColor]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
    [scrollView addGestureRecognizer:panGesture];
}

@end

