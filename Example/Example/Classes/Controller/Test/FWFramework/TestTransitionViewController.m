//
//  TestTransitionViewController.m
//  Example
//
//  Created by wuyong on 16/11/11.
//  Copyright © 2016年 ocphp.com. All rights reserved.
//

#import "TestTransitionViewController.h"

@interface TestFullScreenViewController : BaseViewController

@property (nonatomic, assign) BOOL interactive;

@end

@implementation TestFullScreenViewController

- (void)renderInit
{
    // 设置present半透明，init中生效
    self.modalPresentationStyle = UIModalPresentationCustom;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"全屏弹出框";
    
    // 视图延伸到导航栏
    self.fwForcePopGesture = YES;
    [self fwSetBarExtendEdge:UIRectEdgeAll];
    
    // 自定义关闭按钮
    FWWeakifySelf();
    [self fwSetLeftBarItem:[UIImage imageNamed:@"public_close"] block:^(id sender) {
        FWStrongifySelf();
        [self fwCloseViewControllerAnimated:YES];
    }];
    
    // 设置背景(present时透明，push时不透明)
    self.view.backgroundColor = self.navigationController ? [UIColor appColorBlack] : [UIColor appColorCover];
    
    if (self.interactive) {
        FWPercentInteractiveTransition *transition = [[FWPercentInteractiveTransition alloc] init];
        FWWeakifySelf();
        transition.interactiveBlock = ^{
            FWStrongifySelf();
            [self fwCloseViewControllerAnimated:YES];
        };
        [transition addGestureToViewController:self];
        ((FWTransitionDelegate *)self.fwModalTransitionDelegate).outInteractiveTransition = transition;
    } else {
        // 点击背景关闭，默认子视图也会响应，解决方法：子视图设为UIButton或子视图添加空手势事件
        [self.view fwAddTapGestureWithBlock:^(id sender) {
            FWStrongifySelf();
            [self fwCloseViewControllerAnimated:YES];
        }];
    }
    
    // 添加视图
    UIButton *button = [UIButton fwAutoLayoutView];
    button.backgroundColor = [UIColor appColorWhite];
    button.titleLabel.font = [UIFont appFontNormal];
    [button setTitleColor:[UIColor appColorBlackOpacityLarge] forState:UIControlStateNormal];
    [button setTitle:@"点击背景关闭" forState:UIControlStateNormal];
    [self.view addSubview:button];
    [button fwSetDimensionsToSize:CGSizeMake(200, 100)];
    [button fwAlignCenterToSuperview];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self fwSetNavigationBarHidden:YES animated:animated];
}

@end

#define TestTransitinDuration 0

@interface TestTransitionViewController ()

@end

@implementation TestTransitionViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self fwSetNavigationBarHidden:NO animated:animated];
    
    // 自动还原动画
    self.navigationController.fwNavigationTransitionDelegate = nil;
}

- (void)renderData
{
    [self.dataList addObjectsFromArray:@[
                                          @[@"默认Present", @"onPresent"],
                                          @[@"转场present", @"onPresentTransition"],
                                          @[@"自定义present", @"onPresentAnimation"],
                                          @[@"swipe present", @"onPresentSwipe"],
                                          @[@"interactive present", @"onPresentInteractive"],
                                          @[@"System Push", @"onPush"],
                                          @[@"Block Push", @"onPushBlock"],
                                          @[@"Option Push", @"onPushOption"],
                                          @[@"Animation Push", @"onPushAnimation"],
                                          @[@"Custom Push", @"onPushCustom"],
                                          @[@"Swipe Push", @"onPushSwipe"],
                                          @[@"Proxy Push", @"onPushProxy"],
                                          ]];
}

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *cellData = [self.dataList objectAtIndex:indexPath.row];
    cell.textLabel.text = [cellData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *cellData = [self.dataList objectAtIndex:indexPath.row];
    SEL selector = NSSelectorFromString([cellData objectAtIndex:1]);
    if ([self respondsToSelector:selector]) {
        FWIgnoredBegin();
        [self performSelector:selector];
        FWIgnoredEnd();
    }
}

#pragma mark - Action

- (void)onPresent
{
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentTransition
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.duration = TestTransitinDuration;
    transition.block = ^(FWAnimatedTransition *transition){
        if (transition.type == FWAnimatedTransitionTypePresent) {
            [transition start];
            transition.toView.transform = CGAffineTransformMakeScale(0.0, 0.0);
            transition.toView.alpha = 0.0;
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 transition.toView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                                 transition.toView.alpha = 1.0;
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        } else if (transition.type == FWAnimatedTransitionTypeDismiss) {
            [transition start];
            transition.fromView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            transition.fromView.alpha = 1.0;
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 transition.fromView.transform = CGAffineTransformMakeScale(0.01, 0.01);
                                 transition.fromView.alpha = 0.0;
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fwModalTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentAnimation
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.duration = TestTransitinDuration;
    transition.block = ^(FWAnimatedTransition *transition){
        if (transition.type == FWAnimatedTransitionTypePresent) {
            [transition start];
            [transition.toView fwAddTransitionWithType:kCATransitionMoveIn
                                               subtype:kCATransitionFromTop
                                        timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                              duration:[transition transitionDuration:transition.transitionContext]
                                            completion:^(BOOL finished) {
                                                [transition complete];
                                            }];
        } else if (transition.type == FWAnimatedTransitionTypeDismiss) {
            [transition start];
            // 这种转场动画需要先隐藏目标视图
            transition.fromView.hidden = YES;
            [transition.fromView fwAddTransitionWithType:kCATransitionReveal
                                                 subtype:kCATransitionFromBottom
                                          timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                                duration:[transition transitionDuration:transition.transitionContext]
                                              completion:^(BOOL finished) {
                                                  [transition complete];
                                              }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fwModalTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentSwipe
{
    FWSwipeAnimationTransition *transition = [[FWSwipeAnimationTransition alloc] init];
    transition.duration = TestTransitinDuration;
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fwModalTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentInteractive
{
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.interactive = YES;
    
    FWSwipeAnimationTransition *transition = [FWSwipeAnimationTransition transitionWithInDirection:UISwipeGestureRecognizerDirectionUp outDirection:UISwipeGestureRecognizerDirectionDown];
    transition.duration = TestTransitinDuration;
    vc.fwModalTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPush
{
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushOption
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.duration = TestTransitinDuration;
    transition.block = ^(FWAnimatedTransition *transition){
        if (transition.type == FWAnimatedTransitionTypePush) {
            [transition start];
            [UIView transitionFromView:transition.fromView
                                toView:transition.toView
                              duration:[transition transitionDuration:transition.transitionContext]
                               options:UIViewAnimationOptionTransitionCurlUp
                            completion:^(BOOL finished) {
                                [transition complete];
                            }];
        } else if (transition.type == FWAnimatedTransitionTypePop) {
            [transition start];
            [UIView transitionFromView:transition.fromView
                                toView:transition.toView
                              duration:[transition transitionDuration:transition.transitionContext]
                               options:UIViewAnimationOptionTransitionCurlDown
                            completion:^(BOOL finished) {
                                [transition complete];
                            }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fwNavigationTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushBlock
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.duration = TestTransitinDuration;
    transition.block = ^(FWAnimatedTransition *transition){
        if (transition.type == FWAnimatedTransitionTypePush) {
            [transition start];
            transition.toView.frame = CGRectMake(0, FWScreenHeight, FWScreenWidth, FWScreenHeight);
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 transition.toView.frame = CGRectMake(0, 0, FWScreenWidth, FWScreenHeight);
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        } else if (transition.type == FWAnimatedTransitionTypePop) {
            [transition start];
            transition.fromView.frame = CGRectMake(0, 0, FWScreenWidth, FWScreenHeight);
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 transition.fromView.frame = CGRectMake(0, FWScreenHeight, FWScreenWidth, FWScreenHeight);
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fwNavigationTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushAnimation
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.duration = TestTransitinDuration;
    transition.block = ^(FWAnimatedTransition *transition){
        if (transition.type == FWAnimatedTransitionTypePush) {
            [transition start];
            // 使用navigationController.view做动画，而非containerView做动画，下同
            [self.navigationController.view fwAddTransitionWithType:kCATransitionMoveIn
                                                            subtype:kCATransitionFromTop
                                                     timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished) {
                                                             [transition complete];
                                                         }];
        } else if (transition.type == FWAnimatedTransitionTypePop) {
            [transition start];
            // 这种转场动画需要先隐藏目标视图
            transition.fromView.hidden = YES;
            [self.navigationController.view fwAddTransitionWithType:kCATransitionReveal
                                                            subtype:kCATransitionFromBottom
                                                     timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished) {
                                                             [transition complete];
                                                         }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fwNavigationTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushCustom
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.duration = TestTransitinDuration;
    transition.block = ^(FWAnimatedTransition *transition){
        if (transition.type == FWAnimatedTransitionTypePush) {
            [transition start];
            [self.navigationController.view fwAddAnimationWithCurve:UIViewAnimationCurveEaseInOut
                                                         transition:UIViewAnimationTransitionCurlUp
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished){
                                                             [transition complete];
                                                         }];
        } else if (transition.type == FWAnimatedTransitionTypePop) {
            [transition start];
            // 这种转场动画需要先隐藏目标视图
            transition.fromView.hidden = YES;
            [self.navigationController.view fwAddAnimationWithCurve:UIViewAnimationCurveEaseInOut
                                                         transition:UIViewAnimationTransitionCurlDown
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished){
                                                             [transition complete];
                                                         }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fwNavigationTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushSwipe
{
    FWSwipeAnimationTransition *transition = [[FWSwipeAnimationTransition alloc] init];
    transition.duration = TestTransitinDuration;
    transition.inDirection = UISwipeGestureRecognizerDirectionUp;
    transition.outDirection = UISwipeGestureRecognizerDirectionDown;
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fwNavigationTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushProxy
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.duration = TestTransitinDuration;
    transition.block = ^(FWAnimatedTransition *transition){
        if (transition.type == FWAnimatedTransitionTypePush) {
            [transition start];
            transition.toView.frame = CGRectMake(0, FWScreenHeight, FWScreenWidth, FWScreenHeight);
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 transition.toView.frame = CGRectMake(0, 0, FWScreenWidth, FWScreenHeight);
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        } else if (transition.type == FWAnimatedTransitionTypePop) {
            [transition start];
            transition.fromView.frame = CGRectMake(0, 0, FWScreenWidth, FWScreenHeight);
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 transition.fromView.frame = CGRectMake(0, FWScreenHeight, FWScreenWidth, FWScreenHeight);
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fwViewTransitionDelegate = [FWTransitionDelegate delegateWithTransition:transition];
    self.navigationController.fwNavigationTransitionDelegate = [FWTransitionDelegate delegateWithTransition:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
