//
//  TestEmptyViewController.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestEmptyViewController.h"

@interface TestEmptyViewController () <FWEmptyViewDataSource, FWEmptyViewDelegate>

@end

@implementation TestEmptyViewController

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
    return [UIImage fwGifImageWithName:@"loading"];
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
