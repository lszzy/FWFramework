//
//  TestDrawerViewController.m
//  Example
//
//  Created by wuyong on 2019/5/6.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestDrawerViewController.h"
#import <objc/runtime.h>

#define ViewHeight (FWScreenHeight - FWStatusBarHeight - FWNavigationBarHeight)

@interface TestDrawerViewController () <UIScrollViewDelegate>

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIView *contentView;

@end

@implementation TestDrawerViewController

- (void)renderView
{
    self.view.backgroundColor = [UIColor brownColor];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, ViewHeight / 4 * 3, self.view.fwWidth, ViewHeight)];
    _scrollView = scrollView;
    [scrollView fwContentInsetNever];
    scrollView.delegate = self;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.contentSize = CGSizeMake(self.view.fwWidth, 1000);
    [self.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 1000)];
    _contentView = contentView;
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 50)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"I am top";
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 475, self.view.fwWidth, 50)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.text = @"I am middle";
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 950, self.view.fwWidth, 50)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"I am bottom";
    [contentView addSubview:bottomLabel];
    [scrollView addSubview:contentView];
    
    UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewPanAction:)];
    [self.scrollView addGestureRecognizer:gesture];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewPanAction:(UIPanGestureRecognizer *)gesture
{
    [gesture fwDrawerView:self.scrollView fromPosition:0 toPosition:ViewHeight / 4 * 3 kickbackHeight:25];
}

@end

