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
    [self fwSetLeftBarItem:[CoreBundle imageNamed:@"back"] block:^(id sender) {
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
    BOOL hasHeader = YES;
    UIView *containerView, *drawerView;
    if (hasHeader) {
        containerView = [[UIView alloc] initWithFrame:CGRectMake(0, ViewHeight / 4 * 3, self.view.fwWidth, ViewHeight)];
        containerView.backgroundColor = [UIColor grayColor];
        [self.view addSubview:containerView];
    } else {
        containerView = self.view;
    }
    
    UIScrollView *scrollView;
    if (hasHeader) {
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 30, self.view.fwWidth, ViewHeight - 30)];
        drawerView = containerView;
    } else {
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, ViewHeight / 4 * 3, self.view.fwWidth, ViewHeight)];
        drawerView = scrollView;
    }
    [scrollView fwContentInsetAdjustmentNever];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.contentSize = CGSizeMake(self.view.fwWidth, 2000);
    scrollView.contentInset = UIEdgeInsetsMake(50, 0, 100, 0);
    scrollView.contentOffset = CGPointMake(0, -50);
    [containerView addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 2000)];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 50)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"I am top";
    topLabel.numberOfLines = 0;
    topLabel.textColor = [UIColor blackColor];
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 975, self.view.fwWidth, 50)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.text = @"I am middle";
    middleLabel.numberOfLines = 0;
    middleLabel.textColor = [UIColor blackColor];
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 1950, self.view.fwWidth, 50)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"I am bottom";
    bottomLabel.numberOfLines = 0;
    bottomLabel.textColor = [UIColor blackColor];
    [contentView addSubview:bottomLabel];
    [scrollView addSubview:contentView];
    
    UIView *redLine = [[UIView alloc] initWithFrame:CGRectMake(0, ViewHeight / 4, self.view.fwWidth, 1)];
    redLine.backgroundColor = [UIColor redColor];
    [self.view addSubview:redLine];
    
    redLine = [[UIView alloc] initWithFrame:CGRectMake(0, ViewHeight / 2, self.view.fwWidth, 1)];
    redLine.backgroundColor = [UIColor redColor];
    [self.view addSubview:redLine];
    
    CGFloat fromPosition = 0;
    CGFloat toPosition = ViewHeight / 4 * 3;
    FWWeakifySelf();
    [drawerView fwDrawerView:0
                   positions:@[@(toPosition), @(ViewHeight / 4), @(ViewHeight / 2), @(fromPosition)]
              kickbackHeight:25
                    callback:^(CGFloat position, BOOL finished) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:drawerView];
        CGFloat targetDistance = toPosition - fromPosition;
        CGFloat distance = position - fromPosition;
        if (distance < targetDistance) {
            CGFloat progress = MIN(1 - distance / targetDistance, 1);
            [self.navigationController.navigationBar fwSetBackgroundColor:[[UIColor brownColor] colorWithAlphaComponent:progress]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
}

- (void)renderViewDown
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, -ViewHeight / 4 * 3, self.view.fwWidth, ViewHeight)];
    [scrollView fwContentInsetAdjustmentNever];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor redColor];
    scrollView.contentSize = CGSizeMake(self.view.fwWidth, 2000);
    scrollView.contentInset = UIEdgeInsetsMake(100, 0, 50, 0);
    scrollView.contentOffset = CGPointMake(0, 2000 - ViewHeight + 50);
    [self.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 2000)];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 1950, self.view.fwWidth, 50)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"I am top";
    topLabel.numberOfLines = 0;
    topLabel.textColor = [UIColor whiteColor];
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 975, self.view.fwWidth, 50)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.text = @"I am middle";
    middleLabel.numberOfLines = 0;
    middleLabel.textColor = [UIColor whiteColor];
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 50)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"I am bottom";
    bottomLabel.numberOfLines = 0;
    bottomLabel.textColor = [UIColor whiteColor];
    [contentView addSubview:bottomLabel];
    [scrollView addSubview:contentView];
    
    FWWeakifySelf();
    [scrollView fwDrawerView:UISwipeGestureRecognizerDirectionDown
                   positions:@[@(0), @(-ViewHeight / 4), @(-ViewHeight / 2), @(-ViewHeight / 4 * 3)]
              kickbackHeight:25
                    callback:^(CGFloat position, BOOL finished) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:scrollView];
        if (position == 0) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor brownColor]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
}

- (void)renderViewLeft
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(FWScreenWidth / 4 * 3, 0, self.view.fwWidth, ViewHeight)];
    [scrollView fwContentInsetAdjustmentNever];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor blueColor];
    scrollView.contentSize = CGSizeMake(2000, ViewHeight);
    scrollView.contentInset = UIEdgeInsetsMake(0, 50, 0, 100);
    scrollView.contentOffset = CGPointMake(-50, 0);
    [self.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2000, ViewHeight)];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, ViewHeight)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"I am top";
    topLabel.numberOfLines = 0;
    topLabel.textColor = [UIColor whiteColor];
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(975, 0, 50, ViewHeight)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.text = @"I am middle";
    middleLabel.numberOfLines = 0;
    middleLabel.textColor = [UIColor whiteColor];
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(1950, 0, 50, ViewHeight)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"I am bottom";
    bottomLabel.numberOfLines = 0;
    bottomLabel.textColor = [UIColor whiteColor];
    [contentView addSubview:bottomLabel];
    [scrollView addSubview:contentView];
    
    FWWeakifySelf();
    [scrollView fwDrawerView:UISwipeGestureRecognizerDirectionLeft
                   positions:@[@(FWScreenWidth / 4 * 3), @(0)]
              kickbackHeight:25
                    callback:^(CGFloat position, BOOL finished) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:scrollView];
        if (position == 0) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor brownColor]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
}

- (void)renderViewRight
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(-FWScreenWidth / 4 * 3, 0, self.view.fwWidth, ViewHeight)];
    [scrollView fwContentInsetAdjustmentNever];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor greenColor];
    scrollView.contentSize = CGSizeMake(2000, ViewHeight);
    scrollView.contentInset = UIEdgeInsetsMake(0, 100, 0, 50);
    scrollView.contentOffset = CGPointMake(2000 - FWScreenWidth + 50, 0);
    [self.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2000, ViewHeight)];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(1950, 0, 50, ViewHeight)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"I am top";
    topLabel.numberOfLines = 0;
    topLabel.textColor = [UIColor blackColor];
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(975, 0, 50, ViewHeight)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.text = @"I am middle";
    middleLabel.numberOfLines = 0;
    middleLabel.textColor = [UIColor blackColor];
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, ViewHeight)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"I am bottom";
    bottomLabel.numberOfLines = 0;
    bottomLabel.textColor = [UIColor blackColor];
    [contentView addSubview:bottomLabel];
    [scrollView addSubview:contentView];
    
    FWWeakifySelf();
    [scrollView fwDrawerView:UISwipeGestureRecognizerDirectionRight
                   positions:@[@(0), @(-FWScreenWidth / 4 * 3)]
              kickbackHeight:25
                    callback:^(CGFloat position, BOOL finished) {
        FWStrongifySelf();
        [self.view bringSubviewToFront:scrollView];
        if (position == 0) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor brownColor]];
        } else {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
        }
    }];
}

@end
