//
//  TestTransitionViewController.m
//  Example
//
//  Created by wuyong on 16/11/11.
//  Copyright © 2016年 ocphp.com. All rights reserved.
//

#import "TestTransitionViewController.h"
#import "TestViewController.h"

@interface TestFullScreenViewController : TestViewController <FWScrollViewController>

@property (nonatomic, assign) BOOL canScroll;
@property (nonatomic, weak) UILabel *frameLabel;
@property (nonatomic, assign) BOOL noAnimate;

@end

@implementation TestFullScreenViewController

- (void)renderView
{
    if (self.canScroll) {
        self.navigationController.fwModalTransition.gestureRecognizer.scrollView = self.scrollView;
        self.navigationController.fwNavigationTransition.gestureRecognizer.scrollView = self.scrollView;
    }
    
    self.scrollView.scrollEnabled = self.canScroll;
    
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    cycleView.placeholderImage = [TestBundle imageNamed:@"public_icon"];
    [self.contentView addSubview:cycleView];
    cycleView.fwLayoutChain.left().top().width(FWScreenWidth).height(200);
    
    NSMutableArray *imageUrls = [NSMutableArray array];
    [imageUrls addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls addObject:[TestBundle imageNamed:@"public_picture"]];
    [imageUrls addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls addObject:@"not_found.jpg"];
    [imageUrls addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4"];
    
    UIView *footerView = [UIView fwAutoLayoutView];
    footerView.backgroundColor = [Theme tableColor];
    [self.contentView addSubview:footerView];
    footerView.fwLayoutChain.left().bottom().topToBottomOfView(cycleView).width(FWScreenWidth).height(1000);
    
    UILabel *frameLabel = [[UILabel alloc] init];
    _frameLabel = frameLabel;
    frameLabel.textColor = [Theme textColor];
    frameLabel.text = NSStringFromCGRect(self.view.frame);
    [footerView addSubview:frameLabel];
    frameLabel.fwLayoutChain.centerX().topWithInset(50);
    
    // 添加视图
    UIButton *button = [UIButton fwAutoLayoutView];
    button.backgroundColor = [Theme cellColor];
    button.titleLabel.font = [UIFont fwFontOfSize:15];
    [button setTitleColor:[Theme textColor] forState:UIControlStateNormal];
    [button setTitle:@"点击背景关闭" forState:UIControlStateNormal];
    [footerView addSubview:button];
    [button fwSetDimensionsToSize:CGSizeMake(200, 100)];
    [button fwAlignCenterToSuperview];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fwNavigationItem.title = @"全屏弹出框";
    
    // 视图延伸到导航栏
    self.fwForcePopGesture = YES;
    self.fwExtendedLayoutEdge = UIRectEdgeNone;
    
    // 自定义关闭按钮
    FWWeakifySelf();
    [self fwSetLeftBarItem:FWIcon.closeImage block:^(id sender) {
        FWStrongifySelf();
        [self fwCloseViewControllerAnimated:!self.noAnimate];
    }];
    
    // 设置背景(present时透明，push时不透明)
    self.fwView.backgroundColor = self.navigationController ? [Theme tableColor] : [[Theme tableColor] colorWithAlphaComponent:0.9];
    
    // 点击背景关闭，默认子视图也会响应，解决方法：子视图设为UIButton或子视图添加空手势事件
    [self.fwView fwAddTapGestureWithBlock:^(id sender) {
        FWStrongifySelf();
        [self fwCloseViewControllerAnimated:!self.noAnimate];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.frameLabel.text = NSStringFromCGRect(self.view.frame);
    if (!self.fwIsPresented) {
        self.fwNavigationBarHidden = YES;
    }
}

@end

@interface TestTransitionAlertViewController : UIViewController

@property (nonatomic, assign) BOOL useAnimator;
@property (nonatomic, strong) UIDynamicAnimator *animator;

@property (nonatomic, weak) UIView *contentView;

@end

@implementation TestTransitionAlertViewController

FWDealloc();

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
        self.fwModalTransition = transition;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 方式2：不指定presentedFrame，背景手势不生效，自己添加手势和圆角即可
    UIView *contentView = [UIView fwAutoLayoutView];
    _contentView = contentView;
    contentView.backgroundColor = Theme.cellColor;
    [self.fwView addSubview:contentView];
    contentView.fwLayoutChain.center();
    
    UIView *childView = [UIView fwAutoLayoutView];
    [contentView addSubview:childView];
    childView.fwLayoutChain.edges().size(CGSizeMake(300, 250));
    
    FWWeakifySelf();
    [contentView fwAddTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if (self.useAnimator) {
            [self configAnimator];
        }
        [self fwCloseViewControllerAnimated:YES];
    }];
    
    // 方式3：手工指定动画参数
    // [self.view setNeedsLayout];
    // [self.view layoutIfNeeded];
    // FWPresentationController *presentation = (FWPresentationController *)self.fwModalTransition.presentationController;
    // presentation.presentedSize = centerView.bounds.size;
}

- (void)configAnimator
{
    self.fwModalTransition = nil;
    
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

@interface TestTransitionCustomViewController : UIViewController

@property (nonatomic, weak) UIView *contentView;

@end

@implementation TestTransitionCustomViewController

FWDealloc();

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
    
    UIView *contentView = [UIView fwAutoLayoutView];
    _contentView = contentView;
    contentView.layer.masksToBounds = YES;
    contentView.layer.cornerRadius = 10;
    contentView.backgroundColor = Theme.cellColor;
    [self.fwView addSubview:contentView];
    contentView.fwLayoutChain.center();
    
    UIView *childView = [UIView fwAutoLayoutView];
    [contentView addSubview:childView];
    childView.fwLayoutChain.edges().size(CGSizeMake(300, 250));
    
    FWWeakifySelf();
    self.fwView.backgroundColor = [[Theme backgroundColor] colorWithAlphaComponent:0.5];
    [self.fwView fwAddTapGestureWithBlock:^(id  _Nonnull sender) {
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

@interface TestTransitionViewController () <FWTableViewController>

@end

@implementation TestTransitionViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.fwNavigationBarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 自动还原动画
    self.navigationController.fwNavigationTransition = nil;
}

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                          @[@"默认Present", @"onPresent"],
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
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
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
    vc.fwModalTransition = transition;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentAnimation
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.transitionBlock = ^(FWAnimatedTransition *transition){
        if (transition.transitionType == FWAnimatedTransitionTypePresent) {
            [transition start];
            [[transition.transitionContext viewForKey:UITransitionContextToViewKey] fwAddTransitionWithType:kCATransitionMoveIn
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
            [[transition.transitionContext viewForKey:UITransitionContextFromViewKey] fwAddTransitionWithType:kCATransitionReveal
                                                 subtype:kCATransitionFromBottom
                                          timingFunction:kCAMediaTimingFunctionEaseInEaseOut
                                                duration:[transition transitionDuration:transition.transitionContext]
                                              completion:^(BOOL finished) {
                                                  [transition complete];
                                              }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fwModalTransition = transition;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentSwipe
{
    FWSwipeAnimatedTransition *transition = [[FWSwipeAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.inDirection = UISwipeGestureRecognizerDirectionLeft;
    transition.outDirection = UISwipeGestureRecognizerDirectionRight;
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    vc.fwModalTransition = transition;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onPresentController
{
    FWSwipeAnimatedTransition *transition = [[FWSwipeAnimatedTransition alloc] init];
    transition.interactEnabled = YES;
    transition.presentationBlock = ^UIPresentationController * _Nonnull(UIViewController * _Nonnull presented, UIViewController * _Nonnull presenting) {
        FWPresentationController *presentation = [[FWPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
        presentation.verticalInset = 200;
        presentation.cornerRadius = 10;
        return presentation;
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[TestFullScreenViewController alloc] init]];
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.fwModalTransition = transition;
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
    nav.fwModalTransition = transition;
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
    nav.fwModalTransition = transition;
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
    self.navigationController.fwNavigationTransition = transition;
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
    self.navigationController.fwNavigationTransition = transition;
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
            [self.navigationController.view fwAddTransitionWithType:kCATransitionMoveIn
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
    self.navigationController.fwNavigationTransition = transition;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushCustom
{
    FWAnimatedTransition *transition = [[FWAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.transitionBlock = ^(FWAnimatedTransition *transition){
        if (transition.transitionType == FWAnimatedTransitionTypePush) {
            [transition start];
            [self.navigationController.view fwAddAnimationWithCurve:UIViewAnimationCurveEaseInOut
                                                         transition:UIViewAnimationTransitionCurlUp
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished){
                                                             [transition complete];
                                                         }];
        } else if (transition.transitionType == FWAnimatedTransitionTypePop) {
            [transition start];
            // 这种转场动画需要先隐藏目标视图
            [transition.transitionContext viewForKey:UITransitionContextFromViewKey].hidden = YES;
            [self.navigationController.view fwAddAnimationWithCurve:UIViewAnimationCurveEaseInOut
                                                         transition:UIViewAnimationTransitionCurlDown
                                                           duration:[transition transitionDuration:transition.transitionContext]
                                                         completion:^(BOOL finished){
                                                             [transition complete];
                                                         }];
        }
    };
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fwNavigationTransition = transition;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPushSwipe
{
    FWSwipeAnimatedTransition *transition = [[FWSwipeAnimatedTransition alloc] init];
    transition.transitionDuration = TestTransitinDuration;
    transition.inDirection = UISwipeGestureRecognizerDirectionUp;
    transition.outDirection = UISwipeGestureRecognizerDirectionDown;
    
    TestFullScreenViewController *vc = [[TestFullScreenViewController alloc] init];
    self.navigationController.fwNavigationTransition = transition;
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
    vc.fwViewTransition = transition;
    self.navigationController.fwNavigationTransition = [FWAnimatedTransition systemTransition];
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
    self.navigationController.fwNavigationTransition = transition;
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
    self.navigationController.fwNavigationTransition = transition;
    [self.navigationController pushViewController:vc animated:NO];
}

@end
