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
@property (nonatomic, assign) NSInteger transitionType;

@end

@implementation TestAnimationView

- (instancetype)initWithTransitionType:(NSInteger)transitionType
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.transitionType = transitionType;
        if (self.transitionType > 5) {
            self.backgroundColor = [UIColor clearColor];
        } else {
            self.backgroundColor = [UIColor fwColorWithHex:0x000000 alpha:0.5];
        }
        
        self.bottomView = [UIView new];
        self.bottomView.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.bottomView];
        if (self.transitionType == 3 || self.transitionType == 6) {
            self.bottomView.fwLayoutChain.left().right().bottom().height(FWScreenHeight / 2);
        } else {
            self.bottomView.fwLayoutChain.center().width(300).height(200);
        }
        
        FWWeakifySelf();
        [self fwAddTapGestureWithBlock:^(id  _Nonnull sender) {
            FWStrongifySelf();
            if (self.transitionType > 5) {
                [self.fwViewController dismissViewControllerAnimated:YES completion:nil];
                return;
            }
            
            if (self.transitionType == 3) {
                [self fwSetPresentTransition:FWAnimatedTransitionTypeDismiss contentView:self.bottomView completion:nil];
            } else if (self.transitionType == 4) {
                [self fwSetAlertTransition:FWAnimatedTransitionTypeDismiss completion:nil];
            } else {
                [self fwSetFadeTransition:FWAnimatedTransitionTypeDismiss completion:nil];
            }
        }];
    }
    return self;
}

- (void)showInViewController:(UIViewController *)viewController
{
    if (self.transitionType > 5) {
        UIViewController *wrappedController = [self fwWrappedTransitionController:YES];
        if (self.transitionType == 6) {
            [wrappedController fwSetPresentTransition:nil];
        } else if (self.transitionType == 7) {
            [wrappedController fwSetAlertTransition:nil];
        } else {
            [wrappedController fwSetFadeTransition:nil];
        }
        [viewController presentViewController:wrappedController animated:YES completion:nil];
        return;
    }
    
    [self fwTransitionToController:viewController pinEdges:YES];
    if (self.transitionType == 3) {
        [self fwSetPresentTransition:FWAnimatedTransitionTypePresent contentView:self.bottomView completion:nil];
    } else if (self.transitionType == 4) {
        [self fwSetAlertTransition:FWAnimatedTransitionTypePresent completion:nil];
    } else {
        [self fwSetFadeTransition:FWAnimatedTransitionTypePresent completion:nil];
    }
}

@end

@interface TestAnimationChildController : UIViewController

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, assign) NSInteger transitionType;

@end

@implementation TestAnimationChildController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    FWWeakifySelf();
    [self.view fwAddTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    self.bottomView = [UIView new];
    self.bottomView.backgroundColor = [UIColor whiteColor];
    [self.fwView addSubview:self.bottomView];
    if (self.transitionType == 0) {
        self.bottomView.fwLayoutChain.left().right().bottom().height(FWScreenHeight / 2);
    } else {
        self.bottomView.fwLayoutChain.center().width(300).height(200);
    }
}

- (void)showInViewController:(UIViewController *)viewController
{
    if (self.transitionType == 0) {
        [self fwSetPresentTransition:nil];
    } else if (self.transitionType == 1) {
        [self fwSetAlertTransition:nil];
    } else {
        [self fwSetFadeTransition:nil];
    }
    [viewController presentViewController:self animated:YES completion:nil];
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
    [self.fwView addSubview:_animationView];
});

- (void)renderView
{
    UIButton *button = [Theme largeButton];
    [button setTitle:@"转场动画" forState:UIControlStateNormal];
    [button fwAddTouchTarget:self action:@selector(onPresent)];
    [self.fwView addSubview:button];
    [button fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:15];
    [button fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UIButton *button2 = [Theme largeButton];
    [button2 setTitle:@"切换拖动" forState:UIControlStateNormal];
    [button2 fwAddTouchTarget:self action:@selector(onDrag:)];
    [self.fwView addSubview:button2];
    [button2 fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:button withOffset:-15];
    [button2 fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UIButton *button3 = [Theme largeButton];
    [button3 setTitle:@"切换动画" forState:UIControlStateNormal];
    [button3 fwAddTouchTarget:self action:@selector(onAnimation:)];
    [self.fwView addSubview:button3];
    [button3 fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:button2 withOffset:-15];
    [button3 fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
}

- (void)renderModel
{
    if (@available(iOS 11.0, *)) {
        FWWeakifySelf();
        [self fwSetRightBarItem:@("Animator") block:^(id  _Nonnull sender) {
            FWStrongifySelf();
            UIViewController *viewController = [NSClassFromString(@"Test.TestPropertyAnimatorViewController") new];
            [self.navigationController pushViewController:viewController animated:true];
        }];
    }
}

#pragma mark - Action

- (void)onPresent
{
    FWWeakifySelf();
    [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"VC present", @"VC alert", @"VC fade", @"view present", @"view alert", @"view fade", @"wrapped present", @"wrapped alert", @"wrapped fade"] actionBlock:^(NSInteger index) {
        FWStrongifySelf();
        if (index < 3) {
            TestAnimationChildController *animationController = [TestAnimationChildController new];
            animationController.transitionType = index;
            [animationController showInViewController:self];
        } else {
            TestAnimationView *animationView = [[TestAnimationView alloc] initWithTransitionType:index];
            [animationView showInViewController:self];
        }
    }];
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
