//
//  TestDrawerViewController.m
//  Example
//
//  Created by wuyong on 2019/5/6.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestDrawerViewController.h"
#import <objc/runtime.h>

#define TotalHeight (FWScreenHeight - FWStatusBarHeight - FWNavigationBarHeight)
#define TopHeight (TotalHeight / 4 * 3)
#define BottomHeight (TotalHeight / 4)

@interface UIPanGestureRecognizer (Test)

@end

@implementation UIPanGestureRecognizer (Test)

- (CGFloat)fwDrawerViewStartPosition
{
    return [objc_getAssociatedObject(self, @selector(fwDrawerViewStartPosition)) doubleValue];
}

- (void)setFwDrawerViewStartPosition:(CGFloat)position
{
    objc_setAssociatedObject(self, @selector(fwDrawerViewStartPosition), @(position), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwDrawerView:(UIView *)view
           direction:(UISwipeGestureRecognizerDirection)direction
        fromPosition:(CGFloat)fromPosition
          toPosition:(CGFloat)toPosition
      kickbackHeight:(CGFloat)kickbackHeight
{
    UIScrollView *scrollView = [view isKindOfClass:[UIScrollView class]] ? (UIScrollView *)view : nil;
    
    if (self.state == UIGestureRecognizerStateBegan) {
        self.fwDrawerViewStartPosition = view.frame.origin.y;
    }
    
    CGFloat transition = [self translationInView:view.superview].y;
    [self setTranslation:CGPointZero inView:view.superview];
    
    CGFloat target = view.frame.origin.y - scrollView.contentOffset.y + transition;
    if (target < fromPosition) {
        view.fwY = fromPosition;
        scrollView.fwContentOffsetY = fromPosition - target;
    } else {
        view.fwY = target;
        scrollView.fwContentOffsetY = 0;
    }
        
    if (self.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.1 animations:^{
            CGFloat baselineY;
            if (self.fwDrawerViewStartPosition == fromPosition) {
                baselineY = fromPosition + kickbackHeight;
            } else {
                baselineY = toPosition - kickbackHeight;
            }
            if (view.fwY < baselineY) {
                view.fwY = fromPosition;
            } else {
                view.fwY = toPosition;
            }
        } completion:^(BOOL finished) {}];
    }
}

@end

@interface TestDrawerViewController () <UIScrollViewDelegate>

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIView *contentView;

@end

@implementation TestDrawerViewController

- (void)renderView
{
    self.view.backgroundColor = [UIColor brownColor];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, TopHeight, self.view.fwWidth, TotalHeight)];
    _scrollView = scrollView;
    [scrollView fwContentInsetNever];
    scrollView.delegate = self;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor whiteColor];
    // 预留TopHeight空白，否则contentView拉不上来
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
    [gesture fwDrawerView:self.scrollView direction:UISwipeGestureRecognizerDirectionUp fromPosition:0 toPosition:TopHeight kickbackHeight:25];
}

@end

