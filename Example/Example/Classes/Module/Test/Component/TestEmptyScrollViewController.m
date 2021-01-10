//
//  TestEmptyScrollViewController.m
//  Example
//
//  Created by wuyong on 2020/9/3.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestEmptyScrollViewController.h"

@interface TestEmptyScrollViewController () <FWEmptyViewDataSource, FWEmptyViewDelegate>

@end

@implementation TestEmptyScrollViewController

- (void)renderView
{
    self.tableView.fwEmptyViewDataSource = self;
    self.tableView.fwEmptyViewDelegate = self;
    [self.tableView reloadData];
}

#pragma mark - FWEmptyViewDataSource

- (NSAttributedString *)fwTitleForEmptyView:(UIScrollView *)scrollView
{
    return [[NSAttributedString alloc] initWithString:@"暂无数据"];
}

- (NSAttributedString *)fwDescriptionForEmptyView:(UIScrollView *)scrollView
{
    return [[NSAttributedString alloc] initWithString:@"请稍候再试"];
}

- (UIImage *)fwImageForEmptyView:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"loading"];
}

- (CAAnimation *)fwImageAnimationForEmptyView:(UIScrollView *)scrollView
{
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.duration = 2.5;
    return transition;
}

- (NSAttributedString *)fwButtonTitleForEmptyView:(UIScrollView *)scrollView forState:(UIControlState)state
{
    return [[NSAttributedString alloc] initWithString:@"再试一次"];
}

- (UIColor *)fwBackgroundColorForEmptyView:(UIScrollView *)scrollView
{
    return [UIColor whiteColor];
}

- (CGFloat)fwVerticalOffsetForEmptyView:(UIScrollView *)scrollView
{
    return -50;
}

- (CGFloat)fwSpaceHeightForEmptyView:(UIScrollView *)scrollView
{
    return 15;
}

- (BOOL)fwEmptyViewShouldFadeIn:(UIScrollView *)scrollView
{
    return YES;
}

- (BOOL)fwEmptyViewShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

- (BOOL)fwEmptyViewShouldAnimateImageView:(UIScrollView *)scrollView
{
    return YES;
}

- (void)fwEmptyView:(UIScrollView *)scrollView didTapView:(UIView *)view
{
    NSLog(@"fwEmptyView:%@ didTapView:%@", scrollView, view);
}

- (void)fwEmptyView:(UIScrollView *)scrollView didTapButton:(UIButton *)button
{
    NSLog(@"fwEmptyView:%@ didTapButton:%@", scrollView, button);
}

@end
