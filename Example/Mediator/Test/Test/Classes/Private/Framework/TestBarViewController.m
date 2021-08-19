//
//  TestBarViewController.m
//  Example
//
//  Created by wuyong on 2019/1/17.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestBarViewController.h"

@interface TestBarSubViewController : TestViewController

@property (nonatomic, assign) NSInteger index;

@end

@implementation TestBarSubViewController

- (FWNavigationBarAppearance *)fwNavigationBarAppearance
{
    FWNavigationBarAppearance *appearance = [FWNavigationBarAppearance new];
    appearance.isHidden = NO;
    appearance.isTransparent = NO;
    return appearance;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fwForcePopGesture = YES;
    if (self.index < 2) {
        self.fwNavigationBarStyle = FWNavigationBarStyleDefault;
    } else if (self.index < 4) {
        self.fwNavigationBarStyle = FWNavigationBarStyleWhite;
    } else {
        self.fwNavigationBarStyle = [[@[@(FWNavigationBarStyleDefault), @(FWNavigationBarStyleWhite), @(FWNavigationBarStyleHidden)] fwRandomObject] integerValue];
    }
    self.fwNavigationItem.title = [NSString stringWithFormat:@"标题:%@ 样式:%@", @(self.index + 1), @(self.fwNavigationBarStyle)];
    
    FWWeakifySelf();
    [self fwSetRightBarItem:@"打开界面" block:^(id sender) {
        FWStrongifySelf();
        TestBarSubViewController *viewController = [TestBarSubViewController new];
        viewController.index = self.index + 1;
        [self.navigationController pushViewController:viewController animated:YES];
    }];
    [self.view fwAddTapGestureWithBlock:^(id sender) {
        FWStrongifySelf();
        TestBarSubViewController *viewController = [TestBarSubViewController new];
        viewController.index = self.index + 1;
        [self.navigationController pushViewController:viewController animated:YES];
    }];
}

@end

@interface TestBarViewController () <FWTableViewController>

FWPropertyWeak(UILabel *, frameLabel);
FWPropertyAssign(BOOL, hideToast);

@end

@implementation TestBarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fwNavigationBar.fwBackgroundView.backgroundColor = Theme.backgroundColor;
    self.fwTabBarHidden = YES;
    [self fwObserveNotification:UIDeviceOrientationDidChangeNotification target:self action:@selector(refreshBarFrame)];
    
    if (!self.hideToast) {
        [self fwSetRightBarItem:@"启用" block:^(id sender) {
            [UINavigationController fwEnableBarTransition];
        }];
    } else {
        [self fwSetLeftBarItem:FWIcon.closeImage block:^(id  _Nonnull sender) {
            [FWRouter closeViewControllerAnimated:YES];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.hideToast) {
        [UIWindow.fwMainWindow fwShowMessageWithText:[NSString stringWithFormat:@"viewWillAppear:%@", @(animated)]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (!self.hideToast) {
        [UIWindow.fwMainWindow fwShowMessageWithText:[NSString stringWithFormat:@"viewWillDisappear:%@", @(animated)]];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self refreshBarFrame];
}

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderTableLayout
{
    UILabel *frameLabel = [UILabel fwAutoLayoutView];
    self.frameLabel = frameLabel;
    frameLabel.numberOfLines = 0;
    frameLabel.textColor = [Theme textColor];
    frameLabel.font = [UIFont fwFontOfSize:15];
    frameLabel.textAlignment = NSTextAlignmentCenter;
    [self.fwView addSubview:frameLabel]; {
        frameLabel.fwLayoutChain.leftWithInset(10).rightWithInset(10)
            .bottomWithInset(FWTabBarHeight + 10);
    }
    
    self.tableView.backgroundColor = [Theme tableColor];
    self.tableView.fwLayoutChain.edgesHorizontal().top()
        .bottomToTopOfViewWithOffset(self.frameLabel, -10);
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                         @[@"状态栏切换", @"onStatusBar"],
                                         @[@"状态栏样式", @"onStatusStyle"],
                                         @[@"导航栏切换", @"onNavigationBar"],
                                         @[@"导航栏样式", @"onNavigationStyle"],
                                         @[@"标题栏颜色", @"onTitleColor"],
                                         @[@"大标题切换", @"onLargeTitle"],
                                         @[@"标签栏切换", @"onTabBar"],
                                         @[@"工具栏切换", @"onToolBar"],
                                         @[@"导航栏转场", @"onTransitionBar"],
                                         ]];
    if (!self.hideToast) {
        [self.tableData addObject:@[@"Present(默认)", @"onPresent"]];
        [self.tableData addObject:@[@"Present(FullScreen)", @"onPresent2"]];
        [self.tableData addObject:@[@"Present(PageSheet)", @"onPresent3"]];
        [self.tableData addObject:@[@"Present(默认带导航栏)", @"onPresent4"]];
        [self.tableData addObject:@[@"Present(Popover)", @"onPresent5:"]];
    } else {
        [self.tableData addObject:@[@"Dismiss", @"onDismiss"]];
    }
    [self.tableData addObject:@[@"设备转向", @"onOrientation"]];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    SEL selector = NSSelectorFromString([rowData objectAtIndex:1]);
    if ([self respondsToSelector:selector]) {
        FWIgnoredBegin();
        [self performSelector:selector withObject:indexPath];
        FWIgnoredEnd();
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self refreshBarFrame];
}

#pragma mark - Protected

- (BOOL)prefersStatusBarHidden
{
    return self.fwStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.fwStatusBarStyle;
}

#pragma mark - Action

- (void)refreshBarFrame
{
    self.frameLabel.text = [NSString stringWithFormat:@"全局状态栏：%.0f 当前状态栏：%.0f\n全局导航栏：%.0f 当前导航栏：%.0f\n全局顶部栏：%.0f 当前顶部栏：%.0f\n全局标签栏：%.0f 当前标签栏：%.0f\n全局工具栏：%.0f 当前工具栏：%.0f\n全局安全区域：%@",
                            [UIScreen fwStatusBarHeight], [self fwStatusBarHeight],
                            [UIScreen fwNavigationBarHeight], [self fwNavigationBarHeight],
                            [UIScreen fwTopBarHeight], [self fwTopBarHeight],
                            [UIScreen fwTabBarHeight], [self fwTabBarHeight],
                            [UIScreen fwToolBarHeight], [self fwToolBarHeight],
                            NSStringFromUIEdgeInsets([UIScreen fwSafeAreaInsets])];
}

- (void)onStatusBar
{
    self.fwStatusBarHidden = !self.fwStatusBarHidden;
    [self refreshBarFrame];
}

- (void)onStatusStyle
{
    if (self.fwStatusBarStyle == UIStatusBarStyleDefault) {
        self.fwStatusBarStyle = UIStatusBarStyleLightContent;
    } else {
        self.fwStatusBarStyle = UIStatusBarStyleDefault;
    }
    [self refreshBarFrame];
}

- (void)onNavigationBar
{
    self.fwNavigationBarHidden = !self.fwNavigationBarHidden;
    [self refreshBarFrame];
}

- (void)onNavigationStyle
{
    if (self.fwNavigationBarStyle == FWNavigationBarStyleDefault) {
        self.fwNavigationBarStyle = FWNavigationBarStyleWhite;
    } else {
        self.fwNavigationBarStyle = FWNavigationBarStyleDefault;
    }
    [self refreshBarFrame];
}

- (void)onTitleColor
{
    self.fwNavigationBar.fwTitleColor = self.fwNavigationBar.fwTitleColor ? nil : Theme.buttonColor;
}

- (void)onLargeTitle
{
    if (@available(iOS 11.0, *)) {
        self.fwNavigationBar.prefersLargeTitles = !self.fwNavigationBar.prefersLargeTitles;
        [self refreshBarFrame];
    }
}

- (void)onTabBar
{
    self.fwTabBarHidden = !self.fwTabBarHidden;
    [self refreshBarFrame];
}

- (void)onToolBar
{
    if (self.fwToolBarHidden) {
        UIBarButtonItem *item = [UIBarButtonItem fwBarItemWithObject:@(UIBarButtonSystemItemCancel) target:self action:@selector(onToolBar)];
        UIBarButtonItem *item2 = [UIBarButtonItem fwBarItemWithObject:@(UIBarButtonSystemItemDone) target:self action:@selector(onPresent)];
        self.toolbarItems = @[item, item2];
        self.fwToolBarHidden = NO;
    } else {
        self.fwToolBarHidden = YES;
    }
    [self refreshBarFrame];
}

- (void)onPresent
{
    TestBarViewController *viewController = [[TestBarViewController alloc] init];
    viewController.fwPresentationDidDismiss = ^{
        [UIWindow.fwMainWindow fwShowMessageWithText:@"fwPresentationDidDismiss"];
    };
    viewController.fwDismissBlock = ^{
        [UIWindow.fwMainWindow fwShowMessageWithText:@"fwDismissBlock"];
    };
    viewController.hideToast = YES;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)onPresent2
{
    TestBarViewController *viewController = [[TestBarViewController alloc] init];
    viewController.hideToast = YES;
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)onPresent3
{
    TestBarViewController *viewController = [[TestBarViewController alloc] init];
    viewController.fwPresentationDidDismiss = ^{
        [UIWindow.fwMainWindow fwShowMessageWithText:@"fwPresentationDidDismiss"];
    };
    viewController.fwDismissBlock = ^{
        [UIWindow.fwMainWindow fwShowMessageWithText:@"fwDismissBlock"];
    };
    viewController.hideToast = YES;
    viewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)onPresent4
{
    TestBarViewController *viewController = [[TestBarViewController alloc] init];
    viewController.hideToast = YES;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.fwPresentationDidDismiss = ^{
        [UIWindow.fwMainWindow fwShowMessageWithText:@"fwPresentationDidDismiss"];
    };
    navController.fwDismissBlock = ^{
        [UIWindow.fwMainWindow fwShowMessageWithText:@"fwDismissBlock"];
    };
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)onPresent5:(NSIndexPath *)indexPath
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    TestBarViewController *viewController = [[TestBarViewController alloc] init];
    viewController.hideToast = YES;
    viewController.preferredContentSize = CGSizeMake(FWScreenWidth / 2, FWScreenHeight / 2);
    [viewController fwSetPopoverPresentation:^(UIPopoverPresentationController *controller) {
        controller.barButtonItem = self.fwNavigationItem.rightBarButtonItem;
        controller.permittedArrowDirections = UIPopoverArrowDirectionUp;
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        controller.passthroughViews = [NSArray arrayWithObjects:cell, nil];
    } shouldDismiss:[@[@0, @1].fwRandomObject fwAsBool]];
    viewController.fwPresentationDidDismiss = ^{
        [UIWindow.fwMainWindow fwShowMessageWithText:@"fwPresentationDidDismiss"];
    };
    viewController.fwDismissBlock = ^{
        [UIWindow.fwMainWindow fwShowMessageWithText:@"fwDismissBlock"];
    };
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)onDismiss
{
    FWWeakifySelf();
    [self fwDismissAnimated:YES completion:^{
        FWStrongifySelf();
        NSLog(@"self: %@", self);
    }];
}

- (void)onTransitionBar
{
    [self.navigationController pushViewController:[TestBarSubViewController new] animated:YES];
}

- (void)onOrientation
{
    if ([UIDevice fwIsDeviceLandscape]) {
        [UIDevice fwSetDeviceOrientation:UIDeviceOrientationPortrait];
    } else {
        [UIDevice fwSetDeviceOrientation:UIDeviceOrientationLandscapeLeft];
    }
    [self refreshBarFrame];
}

@end
