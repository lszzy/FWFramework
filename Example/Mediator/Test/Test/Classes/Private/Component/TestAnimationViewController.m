//
//  TestAnimationViewController.m
//  Example
//
//  Created by wuyong on 16/11/29.
//  Copyright © 2016年 ocphp.com. All rights reserved.
//

#import "TestAnimationViewController.h"

@interface TestAnimationView : UIView

@property (nonatomic, strong) UIView *bottomView;

@end

@implementation TestAnimationView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor fwColorWithHex:0x000000 alpha:0.5];
        
        self.bottomView = [UIView new];
        self.bottomView.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.bottomView];
        self.bottomView.fwLayoutChain.left().right().bottom().height(FWScreenHeight / 2);
        
        FWWeakifySelf();
        [self fwAddTapGestureWithBlock:^(id  _Nonnull sender) {
            FWStrongifySelf();
            [self hideAnimatedFromBottom:self.bottomView];
        }];
    }
    return self;
}

- (void)showAnimatedFromBottom:(nullable UIView *)contentView
{
    self.alpha = 0;
    contentView.transform = CGAffineTransformMakeTranslation(0, contentView.frame.size.height);
    [UIView animateWithDuration:0.25 animations:^{
        contentView.transform = CGAffineTransformIdentity;
        self.alpha = 1;
    }];
}

- (void)hideAnimatedFromBottom:(nullable UIView *)contentView
{
    [UIView animateWithDuration:0.25 animations:^{
        contentView.transform = CGAffineTransformMakeTranslation(0, contentView.frame.size.height);
        self.alpha = 0;
    } completion:^(BOOL finished) {
        contentView.transform = CGAffineTransformIdentity;
        [self removeFromSuperview];
    }];
}

@end

@interface TestAnimationViewController ()

FWLazyProperty(UIView *, animationView);

@end

@implementation TestAnimationViewController {
    NSInteger animationIndex_;
}

FWDefLazyProperty(UIView *, animationView, {
    _animationView = [[UIView alloc] initWithFrame:CGRectMake(FWScreenWidth / 2.0 - 75.0, 20, 150, 200)];
    _animationView.backgroundColor = [UIColor redColor];
    [self.view addSubview:_animationView];
});

- (void)renderView
{
    UIButton *button = [Theme largeButton];
    [button setTitle:@"切换拖动" forState:UIControlStateNormal];
    [button fwAddTouchTarget:self action:@selector(onDrag:)];
    [self.view addSubview:button];
    [button fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:15];
    [button fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UIButton *button2 = [Theme largeButton];
    [button2 setTitle:@"切换动画" forState:UIControlStateNormal];
    [button2 fwAddTouchTarget:self action:@selector(onAnimation:)];
    [self.view addSubview:button2];
    [button2 fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:button withOffset:-15];
    [button2 fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
}

- (void)renderModel
{
    if (@available(iOS 11.0, *)) {
        FWWeakifySelf();
        [self fwSetRightBarItem:@("More") block:^(id  _Nonnull sender) {
            FWStrongifySelf();
            [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"Animator", @"Present"] actionBlock:^(NSInteger index) {
                FWStrongifySelf();
                if (index == 0) {
                    UIViewController *viewController = [NSClassFromString(@"Test.TestPropertyAnimatorViewController") new];
                    [self.navigationController pushViewController:viewController animated:true];
                } else {
                    [self onPresent];
                }
            }];
        }];
    }
}

#pragma mark - Action

- (void)onPresent
{
    TestAnimationView *view = [TestAnimationView new];
    [self.view addSubview:view];
    view.fwLayoutChain.edges();
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [view showAnimatedFromBottom:view.bottomView];
}

- (void)onAnimation:(UIButton *)sender
{
    animationIndex_++;
    
    NSString *title = nil;
    if (animationIndex_ == 1) {
        title = @"Push.FromTop";
        [self.animationView fwAddTransitionWithType:kCATransitionPush
                                            subtype:kCATransitionFromTop
                                     timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                           duration:1.0
                                         completion:NULL];
    }
    
    if (animationIndex_ == 2) {
        title = @"CurlUp";
        [self.animationView fwAddAnimationWithCurve:UIViewAnimationCurveEaseInOut
                                         transition:UIViewAnimationTransitionCurlUp
                                           duration:1.0
                                         completion:NULL];
    }
    
    if (animationIndex_ == 3) {
        title = @"transform.rotation.y";
        [self.animationView fwAddAnimationWithKeyPath:@"transform.rotation.y"
                                            fromValue:@(0)
                                              toValue:@(M_PI)
                                             duration:1.0
                                           completion:NULL];
    }
    
    if (animationIndex_ == 4) {
        title = @"Shake";
        [self.animationView fwShakeWithTimes:10 delta:0 duration:0.1 completion:NULL];
    }
    
    if (animationIndex_ == 5) {
        title = @"Alpha";
        [self.animationView fwFadeWithAlpha:0.0 duration:1.0 completion:^(BOOL finished) {
            [self.animationView fwFadeWithAlpha:1.0 duration:1.0 completion:NULL];
        }];
    }
    
    if (animationIndex_ == 6) {
        title = @"Rotate";
        [self.animationView fwRotateWithDegree:180 duration:1.0 completion:NULL];
    }
    
    if (animationIndex_ == 7) {
        title = @"Scale";
        [self.animationView fwScaleWithScaleX:0.5 scaleY:0.5 duration:1.0 completion:^(BOOL finished) {
            [self.animationView fwScaleWithScaleX:2.0 scaleY:2.0 duration:1.0 completion:NULL];
        }];
    }
    
    if (animationIndex_ == 8) {
        title = @"Move";
        CGPoint point = self.animationView.frame.origin;
        [self.animationView fwMoveWithPoint:CGPointMake(10, 10) duration:1.0 completion:^(BOOL finished) {
            [self.animationView fwMoveWithPoint:point duration:1.0 completion:NULL];
        }];
    }
    
    if (animationIndex_ == 9) {
        title = @"Frame";
        CGRect frame = self.animationView.frame;
        [self.animationView fwMoveWithFrame:CGRectMake(10, 10, 50, 50) duration:1.0 completion:^(BOOL finished) {
            [self.animationView fwMoveWithFrame:frame duration:1.0 completion:NULL];
        }];
    }
    
    if (animationIndex_ == 10) {
        title = @"切换动画";
        animationIndex_ = 0;
    }
    
    if (title) {
        [sender setTitle:title forState:UIControlStateNormal];
    }
}

- (void)onDrag:(UIButton *)sender
{
    if (!self.animationView.fwDragEnabled) {
        self.animationView.fwDragEnabled = YES;
        self.animationView.fwDragLimit = CGRectMake(0, 0, FWScreenWidth, FWScreenHeight - FWNavigationBarHeight - FWStatusBarHeight);
    } else {
        self.animationView.fwDragEnabled = NO;
    }
}

@end
