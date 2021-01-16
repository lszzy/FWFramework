//
//  TestBarViewController.m
//  Example
//
//  Created by wuyong on 2019/1/17.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestBarViewController.h"

@interface TestBarSubViewController : BaseViewController

@property (nonatomic, assign) NSInteger index;

@end

@implementation TestBarSubViewController

- (id)fwNavigationBarTransitionIdentifier
{
    return @(self.fwNavigationBarStyle);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:@"标题:%@", @(self.index + 1)];
    self.fwForcePopGesture = YES;
    if (self.index < 2) {
        self.fwNavigationBarStyle = FWNavigationBarStyleDefault;
    } else if (self.index < 4) {
        self.fwNavigationBarStyle = FWNavigationBarStyleRandom;
    } else {
        self.fwNavigationBarStyle = [[@[@(FWNavigationBarStyleRandom), @(FWNavigationBarStyleHidden)] fwRandomObject] integerValue];
    }
    
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
    
    self.fwTabBarHidden = YES;
    [self refreshBarFrame];
    [self fwObserveNotification:UIDeviceOrientationDidChangeNotification target:self action:@selector(refreshBarFrame)];
    
    if (!self.hideToast) {
        [self fwSetRightBarItem:@"启用" block:^(id sender) {
            [UINavigationController fwEnableNavigationBarTransition];
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

- (void)renderView
{
    UILabel *frameLabel = [UILabel fwAutoLayoutView];
    self.frameLabel = frameLabel;
    frameLabel.numberOfLines = 0;
    frameLabel.textColor = [UIColor blackColor];
    frameLabel.font = [UIFont fwFontOfSize:15];
    frameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:frameLabel]; {
        [frameLabel fwPinEdgesToSuperviewSafeAreaWithInsets:UIEdgeInsetsMake(0, 10, 100, 10) excludingEdge:NSLayoutAttributeTop];
    }
}

- (void)renderTableLayout
{
    [self.tableView fwPinEdgesToSuperviewSafeArea];
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                         @[@"状态栏切换", @"onStatusBar"],
                                         @[@"状态栏样式", @"onStatusStyle"],
                                         @[@"导航栏切换", @"onNavigationBar"],
                                         @[@"导航栏样式", @"onNavigationStyle"],
                                         @[@"标签栏切换", @"onTabBar"],
                                         @[@"工具栏切换", @"onToolBar"],
                                         @[@"导航栏转场", @"onTransitionBar"],
                                         ]];
    if (!self.hideToast) {
        [self.tableData addObject:@[@"Present(默认)", @"onPresent"]];
        [self.tableData addObject:@[@"Present(FullScreen)", @"onPresent2"]];
        [self.tableData addObject:@[@"Present(PageSheet)", @"onPresent3"]];
        [self.tableData addObject:@[@"Present(默认带导航栏)", @"onPresent4"]];
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
        [self performSelector:selector];
        FWIgnoredEnd();
    }
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
    self.frameLabel.text = [NSString stringWithFormat:@"全局状态栏：%@ 当前状态栏：%@\n全局导航栏：%@ 当前导航栏：%@\n全局标签栏：%@ 当前标签栏：%@\n全局工具栏：%@ 当前工具栏：%@\n安全区域：%@",
                            @([UIScreen fwStatusBarHeight]), @([self fwStatusBarHeight]),
                            @([UIScreen fwNavigationBarHeight]), @([self fwNavigationBarHeight]),
                            @([UIScreen fwTabBarHeight]), @([self fwTabBarHeight]),
                            @([UIScreen fwToolBarHeight]), @([self fwToolBarHeight]),
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
        self.fwNavigationBarStyle = FWNavigationBarStyleRandom;
    } else {
        self.fwNavigationBarStyle = FWNavigationBarStyleDefault;
    }
    [self refreshBarFrame];
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

- (void)onDismiss
{
    FWWeakifySelf();
    [self dismissViewControllerAnimated:YES completion:^{
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
