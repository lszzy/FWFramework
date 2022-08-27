//
//  TestTransitionController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestTransitionController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestFullScreenViewController : UIViewController <FWScrollViewController>

@property (nonatomic, assign) BOOL canScroll;
@property (nonatomic, weak) UILabel *frameLabel;
@property (nonatomic, assign) BOOL noAnimate;

@end

@implementation TestFullScreenViewController

- (void)setupSubviews
{
    if (self.canScroll) {
        FWPanGestureRecognizer *modalRecognizer = self.navigationController.fw_modalTransition.gestureRecognizer;
        if ([modalRecognizer isKindOfClass:[FWPanGestureRecognizer class]]) {
            modalRecognizer.scrollView = self.scrollView;
        }
        FWPanGestureRecognizer *navRecognizer = self.navigationController.fw_navigationTransition.gestureRecognizer;
        if ([navRecognizer isKindOfClass:[FWPanGestureRecognizer class]]) {
            navRecognizer.scrollView = self.scrollView;
        }
    }
    
    self.scrollView.scrollEnabled = self.canScroll;
    
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    cycleView.placeholderImage = [UIImage fw_appIconImage];
    [self.contentView addSubview:cycleView];
    cycleView.fw_layoutChain.left().top().width(FWScreenWidth).height(200);
    
    NSMutableArray *imageUrls = [NSMutableArray array];
    [imageUrls addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls addObject:[UIImage fw_appIconImage]];
    [imageUrls addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls addObject:@"not_found.jpg"];
    [imageUrls addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4"];
    
    UIView *footerView = [[UIView alloc] init];
    footerView.backgroundColor = [AppTheme tableColor];
    [self.contentView addSubview:footerView];
    footerView.fw_layoutChain.left().bottom().topToViewBottom(cycleView).width(FWScreenWidth).height(1000);
    
    UILabel *frameLabel = [[UILabel alloc] init];
    _frameLabel = frameLabel;
    frameLabel.textColor = [AppTheme textColor];
    frameLabel.text = NSStringFromCGRect(self.view.frame);
    [footerView addSubview:frameLabel];
    frameLabel.fw_layoutChain.centerX().topWithInset(50);
    
    // 添加视图
    UIButton *button = [[UIButton alloc] init];
    button.backgroundColor = [AppTheme cellColor];
    button.titleLabel.font = [UIFont fw_fontOfSize:15];
    [button setTitleColor:[AppTheme textColor] forState:UIControlStateNormal];
    [button setTitle:@"点击背景关闭" forState:UIControlStateNormal];
    [footerView addSubview:button];
    [button fw_setDimensionsToSize:CGSizeMake(200, 100)];
    [button fw_alignCenterToSuperview];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"全屏弹出框";
    
    // 视图延伸到导航栏
    self.fw_extendedLayoutEdge = UIRectEdgeNone;
    
    // 自定义关闭按钮
    FWWeakifySelf();
    [self fw_setLeftBarItem:FWIcon.closeImage block:^(id sender) {
        FWStrongifySelf();
        [self fw_closeViewControllerAnimated:!self.noAnimate];
    }];
    
    // 设置背景(present时透明，push时不透明)
    self.view.backgroundColor = self.navigationController ? [AppTheme tableColor] : [[AppTheme tableColor] colorWithAlphaComponent:0.9];
    
    // 点击背景关闭，默认子视图也会响应，解决方法：子视图设为UIButton或子视图添加空手势事件
    [self.view fw_addTapGestureWithBlock:^(id sender) {
        FWStrongifySelf();
        [self fw_closeViewControllerAnimated:!self.noAnimate];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.frameLabel.text = NSStringFromCGRect(self.view.frame);
    if (!self.fw_isPresented) {
        self.fw_navigationBarHidden = YES;
    }
}

@end

@interface TestTransitionAlertViewController : UIViewController <FWViewController>

@property (nonatomic, assign) BOOL useAnimator;
@property (nonatomic, strong) UIDynamicAnimator *animator;

@property (nonatomic, weak) UIView *contentView;

@end

@implementation TestTransitionAlertViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        
        // 也可以封装present方法，手工指定UIPresentationController，无需使用block
        FWTransformAnimatedTransition *transition = [FWTransformAnimatedTransition transitionWithInTransform:CGAffineTransformMakeScale(1.1, 1.1) outTransform:CGAffineTransformIdentity];
        // FWTransformAnimatedTransition *transition = [FWTransformAnimatedTransition transitionWithInTransform:CGAffineTransformMakeScale(0.9, 0.9) outTransform:CGAffineTransformMakeScale(0.9, 0.9)];
        FWWeakifySelf();
        transition.presentationBlock = ^UIPresentationController * _Nonnull(UIViewController * _Nonnull presented, UIViewController * _Nonnull presenting) {
            FWStrongifySelf();
            FWPresentationController *presentation = [[FWPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
            presentation.cornerRadius = 10;
            presentation.rectCorner = UIRectCornerAllCorners;
            // 方式1：自动布局view，更新frame
            [presented.view setNeedsLayout];
            [presented.view layoutIfNeeded];
            presentation.presentedFrame = self.contentView.frame;
            return presentation;
        };
        self.fw_modalTransition = transition;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 方式2：不指定presentedFrame，背景手势不生效，自己添加手势和圆角即可
    UIView *contentView = [[UIView alloc] init];
    _contentView = contentView;
    contentView.backgroundColor = AppTheme.cellColor;
    [self.view addSubview:contentView];
    contentView.fw_layoutChain.center();
    
    UIView *childView = [[UIView alloc] init];
    [contentView addSubview:childView];
    childView.fw_layoutChain.edges().size(CGSizeMake(300, 250));
    
    FWWeakifySelf();
    [contentView fw_addTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if (self.useAnimator) {
            [self configAnimator];
        }
        [self fw_closeViewControllerAnimated:YES];
    }];
    
    // 方式3：手工指定动画参数
    // [self.view setNeedsLayout];
    // [self.view layoutIfNeeded];
    // FWPresentationController *presentation = (FWPresentationController *)self.fw.modalTransition.presentationController;
    // presentation.presentedSize = centerView.bounds.size;
}

- (void)configAnimator
{
    self.fw_modalTransition = nil;
    
    // 测试仿真动画
    static int index = 0;
    double radian = M_PI;
    if (index++ % 2 == 0) {
        radian = 2 * radian;
    } else {
        radian = -1 * radian;
    }
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.contentView];
    
    UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.contentView]];
    gravityBehavior.gravityDirection = CGVectorMake(0, 10);
    [self.animator addBehavior:gravityBehavior];
    
    UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.contentView]];
    [itemBehavior addAngularVelocity:radian forItem:self.view];
    [self.animator addBehavior:itemBehavior];
}

@end

@interface TestTransitionCustomViewController : UIViewController <FWViewController>

@property (nonatomic, weak) UIView *contentView;

@end

@implementation TestTransitionCustomViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *contentView = [[UIView alloc] init];
    _contentView = contentView;
    contentView.layer.masksToBounds = YES;
    contentView.layer.cornerRadius = 10;
    contentView.backgroundColor = AppTheme.cellColor;
    [self.view addSubview:contentView];
    contentView.fw_layoutChain.center();
    
    UIView *childView = [[UIView alloc] init];
    [contentView addSubview:childView];
    childView.fw_layoutChain.edges().size(CGSizeMake(300, 250));
    
    FWWeakifySelf();
    self.view.backgroundColor = [[AppTheme backgroundColor] colorWithAlphaComponent:0.5];
    [self.view fw_addTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self dismiss];
    }];
}

- (void)presentInViewController:(UIViewController *)viewController
{
    [viewController presentViewController:self animated:NO completion:^{
        self.view.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [UIView animateWithDuration:0.35 animations:^{
            self.view.alpha = 1;
            self.contentView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }];
}

- (void)dismiss
{
    [UIView animateWithDuration:0.35 animations:^{
        self.view.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

@end

#define TestTransitinDuration 0.35

@interface TestTransitionController () <FWTableViewController>

@end

@implementation TestTransitionController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.fw_navigationBarHidden = NO;
    
    [UIWindow fw_showMessageWithText:[NSString stringWithFormat:@"viewWillAppear:%@", @(animated)]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 自动还原动画
    self.navigationController.fw_navigationTransition = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [UIWindow fw_showMessageWithText:[NSString stringWithFormat:@"viewWillDisappear:%@", @(animated)]];
}

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupTableView
{
    [self.tableData addObjectsFromArray:@[
        @[@"默认Present", @"onPresent"],
        @[@"全屏Present", @"onPresentFullScreen"],
        @[@"转场present", @"onPresentTransition"],
        @[@"自定义present", @"onPresentAnimation"],
        @[@"swipe present", @"onPresentSwipe"],
        @[@"自定义controller", @"onPresentController"],
        @[@"自定义alert", @"onPresentAlert"],
        @[@"自定义animator", @"onPresentAnimator"],
        @[@"自定义custom", @"onPresentCustom"],
        @[@"interactive present", @"onPresentInteractive"],
        @[@"present without animation", @"onPresentNoAnimate"],
        @[@"System Push", @"onPush"],
        @[@"Block Push", @"onPushBlock"],
        @[@"Option Push", @"onPushOption"],
        @[@"Animation Push", @"onPushAnimation"],
        @[@"Custom Push", @"onPushCustom"],
        @[@"Swipe Push", @"onPushSwipe"],
        @[@"Proxy Push", @"onPushProxy"],
        @[@"interactive Push", @"onPushInteractive"],
        @[@"push without animation", @"onPushNoAnimate"],
    ]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView];
    NSArray *cellData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [cellData objectAtIndex:0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *cellData = [self.tableData objectAtIndex:indexPath.row];
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
    vc.canScroll = YES;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentFullScreen
{
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.canScroll = YES;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentTransition
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.transitionBlock = ^(FWAnimatedTransition *transition){
        if (transition.transitionType == FWAnimatedTransitionTypePresent) {
            [transition start];
            [transition.transitionContext viewForKey:UITransitionContextToViewKey].transform = CGAffineTransformMakeScale(0.0, 0.0);
            [transition.transitionContext viewForKey:UITransitionContextToViewKey].alpha = 0.0;
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 [transition.transitionContext viewForKey:UITransitionContextToViewKey].transform = CGAffineTransformMakeScale(1.0, 1.0);
                                 [transition.transitionContext viewForKey:UITransitionContextToViewKey].alpha = 1.0;
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        } else if (transition.transitionType == FWAnimatedTransitionTypeDismiss) {
            [transition start];
            [transition.transitionContext viewForKey:UITransitionContextFromViewKey].transform = CGAffineTransformMakeScale(1.0, 1.0);
            [transition.transitionContext viewForKey:UITransitionContextFromViewKey].alpha = 1.0;
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 [transition.transitionContext viewForKey:UITransitionContextFromViewKey].transform = CGAffineTransformMakeScale(0.01, 0.01);
                                 [transition.transitionContext viewForKey:UITransitionContextFromViewKey].alpha = 0.0;
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fw_modalTransition = transition;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentAnimation
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.transitionBlock = ^(FWAnimatedTransition *transition){
        if (transition.transitionType == FWAnimatedTransitionTypePresent) {
            [transition start];
            [[transition.transitionContext viewForKey:UITransitionContextToViewKey] fw_addTransitionWithType:kCATransitionMoveIn
                                               subtype:kCATransitionFromTop
                                        timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                              duration:[transition transitionDuration:transition.transitionContext]
                                            completion:^(BOOL finished) {
                                                [transition complete];
                                            }];
        } else if (transition.transitionType == FWAnimatedTransitionTypeDismiss) {
            [transition start];
            // 这种转场动画需要先隐藏目标视图
            [transition.transitionContext viewForKey:UITransitionContextFromViewKey].hidden = YES;
            [[transition.transitionContext viewForKey:UITransitionContextFromViewKey] fw_addTransitionWithType:kCATransitionReveal
                                                 subtype:kCATransitionFromBottom
                                          timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                                duration:[transition transitionDuration:transition.transitionContext]
                                              completion:^(BOOL finished) {
                                                  [transition complete];
                                              }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fw_modalTransition = transition;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentSwipe
{
    FWSwipeAnimatedTransition *transition = [[FWSwipeAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.inDirection = UISwipeGestureRecognizerDirectionLeft;
    transition.outDirection = UISwipeGestureRecognizerDirectionRight;
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fw_modalTransition = transition;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentController
{
    FWSwipeAnimatedTransition *transition = [[FWSwipeAnimatedTransition alloc] init];
    transition.interactEnabled = YES;
    transition.interactScreenEdge = YES;
    FWPanGestureRecognizer *gestureRecognizer = transition.gestureRecognizer;
    if ([gestureRecognizer isKindOfClass:[FWPanGestureRecognizer class]]) {
        gestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        gestureRecognizer.maximumDistance = 44;
    }
    transition.presentationBlock = ^UIPresentationController * _Nonnull(UIViewController * _Nonnull presented, UIViewController * _Nonnull presenting) {
        FWPresentationController *presentation = [[FWPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
        presentation.verticalInset = 200;
        presentation.cornerRadius = 10;
        return presentation;
    };
    FWWeakifySelf();
    transition.dismissCompletion = ^{
        FWStrongifySelf();
        [self fw_showMessageWithText:@"dismiss完成"];
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[TestFullScreenViewController alloc] init]];
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.fw_modalTransition = transition;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onPresentAlert
{
    TestTransitionAlertViewController *vc = [TestTransitionAlertViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentAnimator
{
    TestTransitionAlertViewController *vc = [TestTransitionAlertViewController new];
    vc.useAnimator = YES;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentCustom
{
    TestTransitionCustomViewController *vc = [TestTransitionCustomViewController new];
    [vc presentInViewController:self];
}

- (void)onPresentInteractive
{
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    FWSwipeAnimatedTransition *transition = [FWSwipeAnimatedTransition transitionWithInDirection:UISwipeGestureRecognizerDirectionUp outDirection:UISwipeGestureRecognizerDirectionDown];
    transition.transitionDuration = TestTransitinDuration;
    transition.interactEnabled = YES;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    vc.canScroll = YES;
    nav.fw_modalTransition = transition;
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onPresentNoAnimate
{
    FWSwipeAnimatedTransition *transition = [[FWSwipeAnimatedTransition alloc] init];
    transition.interactEnabled = YES;
    transition.presentationBlock = ^UIPresentationController * _Nonnull(UIViewController * _Nonnull presented, UIViewController * _Nonnull presenting) {
        FWPresentationController *presentation = [[FWPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
        presentation.verticalInset = 200;
        presentation.cornerRadius = 10;
        return presentation;
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.canScroll = YES;
    vc.noAnimate = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationCustom;
    
    transition.interactBlock = ^BOOL(FWPanGestureRecognizer * _Nonnull gestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            [vc dismissViewControllerAnimated:YES completion:nil];
            return NO;
        }
        return YES;
    };
    [transition interactWith:nav];
    nav.fw_modalTransition = transition;
    [self presentViewController:nav animated:NO completion:nil];
}

- (void)onPush
{
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushOption
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.transitionBlock = ^(FWAnimatedTransition *transition){
        if (transition.transitionType == FWAnimatedTransitionTypePush) {
            [transition start];
            [UIView transitionFromView:[transition.transitionContext viewForKey:UITransitionContextFromViewKey]
                                toView:[transition.transitionContext viewForKey:UITransitionContextToViewKey]
                              duration:[transition transitionDuration:transition.transitionContext]
                               options:UIViewAnimationOptionTransitionCurlUp
                            completion:^(BOOL finished) {
                                [transition complete];
                            }];
        } else if (transition.transitionType == FWAnimatedTransitionTypePop) {
            [transition start];
            [UIView transitionFromView:[transition.transitionContext viewForKey:UITransitionContextFromViewKey]
                                toView:[transition.transitionContext viewForKey:UITransitionContextToViewKey]
                              duration:[transition transitionDuration:transition.transitionContext]
                               options:UIViewAnimationOptionTransitionCurlDown
                            completion:^(BOOL finished) {
                                [transition complete];
                            }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fw_navigationTransition = transition;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushBlock
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.transitionBlock = ^(FWAnimatedTransition *transition){
        if (transition.transitionType == FWAnimatedTransitionTypePush) {
            [transition start];
            [transition.transitionContext viewForKey:UITransitionContextToViewKey].frame = CGRectMake(0, FWScreenHeight, FWScreenWidth, FWScreenHeight);
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 [transition.transitionContext viewForKey:UITransitionContextToViewKey].frame = CGRectMake(0, 0, FWScreenWidth, FWScreenHeight);
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        } else if (transition.transitionType == FWAnimatedTransitionTypePop) {
            [transition start];
            [transition.transitionContext viewForKey:UITransitionContextFromViewKey].frame = CGRectMake(0, 0, FWScreenWidth, FWScreenHeight);
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 [transition.transitionContext viewForKey:UITransitionContextFromViewKey].frame = CGRectMake(0, FWScreenHeight, FWScreenWidth, FWScreenHeight);
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fw_navigationTransition = transition;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushAnimation
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.transitionBlock = ^(FWAnimatedTransition *transition){
        if (transition.transitionType == FWAnimatedTransitionTypePush) {
            [transition start];
            // 使用navigationController.view做动画，而非containerView做动画，下同
            [self.navigationController.view fw_addTransitionWithType:kCATransitionMoveIn
                                                            subtype:kCATransitionFromTop
                                                     timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished) {
                                                             [transition complete];
                                                         }];
        } else if (transition.transitionType == FWAnimatedTransitionTypePop) {
            [transition start];
            // 这种转场动画需要先隐藏目标视图
            [transition.transitionContext viewForKey:UITransitionContextFromViewKey].hidden = YES;
            [self.navigationController.view fw_addTransitionWithType:kCATransitionReveal
                                                            subtype:kCATransitionFromBottom
                                                     timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished) {
                                                             [transition complete];
                                                         }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fw_navigationTransition = transition;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushCustom
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.transitionBlock = ^(FWAnimatedTransition *transition){
        if (transition.transitionType == FWAnimatedTransitionTypePush) {
            [transition start];
            [self.navigationController.view fw_addAnimationWithCurve:UIViewAnimationCurveEaseInOut
                                                         transition:UIViewAnimationTransitionCurlUp
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished){
                                                             [transition complete];
                                                         }];
        } else if (transition.transitionType == FWAnimatedTransitionTypePop) {
            [transition start];
            // 这种转场动画需要先隐藏目标视图
            [transition.transitionContext viewForKey:UITransitionContextFromViewKey].hidden = YES;
            [self.navigationController.view fw_addAnimationWithCurve:UIViewAnimationCurveEaseInOut
                                                         transition:UIViewAnimationTransitionCurlDown
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished){
                                                             [transition complete];
                                                         }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fw_navigationTransition = transition;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushSwipe
{
    FWSwipeAnimatedTransition *transition = [[FWSwipeAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.inDirection = UISwipeGestureRecognizerDirectionUp;
    transition.outDirection = UISwipeGestureRecognizerDirectionDown;
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fw_navigationTransition = transition;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushProxy
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.transitionBlock = ^(FWAnimatedTransition *transition){
        if (transition.transitionType == FWAnimatedTransitionTypePush) {
            [transition start];
            [transition.transitionContext viewForKey:UITransitionContextToViewKey].frame = CGRectMake(0, FWScreenHeight, FWScreenWidth, FWScreenHeight);
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 [transition.transitionContext viewForKey:UITransitionContextToViewKey].frame = CGRectMake(0, 0, FWScreenWidth, FWScreenHeight);
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        } else if (transition.transitionType == FWAnimatedTransitionTypePop) {
            [transition start];
            [transition.transitionContext viewForKey:UITransitionContextFromViewKey].frame = CGRectMake(0, 0, FWScreenWidth, FWScreenHeight);
            [UIView animateWithDuration:[transition transitionDuration:transition.transitionContext]
                             animations:^{
                                 [transition.transitionContext viewForKey:UITransitionContextFromViewKey].frame = CGRectMake(0, FWScreenHeight, FWScreenWidth, FWScreenHeight);
                             }
                             completion:^(BOOL finished) {
                                 [transition complete];
                             }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fw_viewTransition = transition;
    self.navigationController.fw_navigationTransition = [FWAnimatedTransition systemTransition];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushInteractive
{
    FWSwipeAnimatedTransition *transition = [[FWSwipeAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.inDirection = UISwipeGestureRecognizerDirectionUp;
    transition.outDirection = UISwipeGestureRecognizerDirectionDown;
    transition.interactEnabled = YES;
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.canScroll = YES;
    self.navigationController.fw_navigationTransition = transition;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushNoAnimate
{
    FWSwipeAnimatedTransition *transition = [[FWSwipeAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.inDirection = UISwipeGestureRecognizerDirectionUp;
    transition.outDirection = UISwipeGestureRecognizerDirectionDown;
    transition.interactEnabled = YES;
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.canScroll = YES;
    vc.noAnimate = YES;
    
    FWWeakifySelf();
    transition.interactBlock = ^BOOL(FWPanGestureRecognizer * _Nonnull gestureRecognizer) {
        FWStrongifySelf();
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            [self.navigationController popViewControllerAnimated:YES];
            return NO;
        }
        return YES;
    };
    [transition interactWith:vc];
    self.navigationController.fw_navigationTransition = transition;
    [self.navigationController pushViewController:vc animated:NO];
}

@end
