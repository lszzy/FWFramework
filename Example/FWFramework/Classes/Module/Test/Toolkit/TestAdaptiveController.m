//
//  TestAdaptiveController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestAdaptiveController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestAdaptiveChildController : UIViewController <FWViewController>

@property (nonatomic, assign) NSInteger index;

@end

@implementation TestAdaptiveChildController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fw_extendedLayoutEdge = UIRectEdgeAll;
    if (self.index < 1) {
        self.fw_navigationBarStyle = FWNavigationBarStyleDefault;
    } else if (self.index < 2) {
        self.fw_navigationBarStyle = 1;
    } else if (self.index < 3) {
        self.fw_navigationBarStyle = 2;
    } else {
        self.fw_navigationBarStyle = [[@[@(-1), @(0), @(1), @(2)] fw_randomObject] integerValue];
        self.fw_navigationBarHidden = self.fw_navigationBarStyle == -1;
    }
    self.navigationItem.title = [NSString stringWithFormat:@"标题:%@ 样式:%@", @(self.index + 1), @(self.fw_navigationBarStyle)];
    
    FWWeakifySelf();
    [self fw_setRightBarItem:@"打开界面" block:^(id sender) {
        FWStrongifySelf();
        TestAdaptiveChildController *viewController = [TestAdaptiveChildController new];
        viewController.index = self.index + 1;
        [self.navigationController pushViewController:viewController animated:YES];
    }];
    [self.view fw_addTapGestureWithBlock:^(id sender) {
        FWStrongifySelf();
        TestAdaptiveChildController *viewController = [TestAdaptiveChildController new];
        viewController.index = self.index + 1;
        [self.navigationController pushViewController:viewController animated:YES];
    }];
}

@end

@interface TestAdaptiveController () <FWTableViewController>

FWPropertyWeak(UILabel *, frameLabel);
FWPropertyAssign(BOOL, hideToast);

@end

@implementation TestAdaptiveController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fw_tabBarHidden = YES;
    [self fw_observeNotification:UIDeviceOrientationDidChangeNotification target:self action:@selector(refreshBarFrame)];
    
    if (!self.hideToast) {
        [self fw_setRightBarItem:@"启用" block:^(id sender) {
            [UINavigationController fw_enableBarTransition];
        }];
    } else {
        FWWeakifySelf();
        [self fw_setLeftBarItem:FWIcon.closeImage block:^(id  _Nonnull sender) {
            FWStrongifySelf();
            [self fw_closeViewControllerAnimated:YES];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.hideToast) {
        [UIWindow fw_showMessageWithText:[NSString stringWithFormat:@"viewWillAppear:%@", @(animated)]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (!self.hideToast) {
        [UIWindow fw_showMessageWithText:[NSString stringWithFormat:@"viewWillDisappear:%@", @(animated)]];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self refreshBarFrame];
}

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupTableLayout
{
    UILabel *frameLabel = [UILabel new];
    self.frameLabel = frameLabel;
    frameLabel.numberOfLines = 0;
    frameLabel.textColor = [AppTheme textColor];
    frameLabel.font = [UIFont fw_fontOfSize:15];
    frameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:frameLabel]; {
        frameLabel.fw_layoutChain.leftWithInset(10).rightWithInset(10)
            .bottomWithInset(FWTabBarHeight + 10);
    }
    
    self.tableView.backgroundColor = [AppTheme tableColor];
    self.tableView.fw_layoutChain.horizontal().top()
        .bottomToViewTopWithOffset(self.frameLabel, -10);
}

- (void)setupSubviews
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
    UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView];
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
    return self.fw_statusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.fw_statusBarStyle;
}

#pragma mark - Action

- (void)refreshBarFrame
{
    self.frameLabel.text = [NSString stringWithFormat:@"全局状态栏：%.0f 当前状态栏：%.0f\n全局导航栏：%.0f 当前导航栏：%.0f\n全局顶部栏：%.0f 当前顶部栏：%.0f\n全局标签栏：%.0f 当前标签栏：%.0f\n全局工具栏：%.0f 当前工具栏：%.0f\n全局安全区域：%@",
                            [UIScreen fw_statusBarHeight], [self fw_statusBarHeight],
                            [UIScreen fw_navigationBarHeight], [self fw_navigationBarHeight],
                            [UIScreen fw_topBarHeight], [self fw_topBarHeight],
                            [UIScreen fw_tabBarHeight], [self fw_tabBarHeight],
                            [UIScreen fw_toolBarHeight], [self fw_toolBarHeight],
                            NSStringFromUIEdgeInsets([UIScreen fw_safeAreaInsets])];
}

- (void)onStatusBar
{
    self.fw_statusBarHidden = !self.fw_statusBarHidden;
    [self refreshBarFrame];
}

- (void)onStatusStyle
{
    if (self.fw_statusBarStyle == UIStatusBarStyleDefault) {
        self.fw_statusBarStyle = UIStatusBarStyleLightContent;
    } else {
        self.fw_statusBarStyle = UIStatusBarStyleDefault;
    }
    [self refreshBarFrame];
}

- (void)onNavigationBar
{
    self.fw_navigationBarHidden = !self.fw_navigationBarHidden;
    [self refreshBarFrame];
}

- (void)onNavigationStyle
{
    if (self.fw_navigationBarStyle == FWNavigationBarStyleDefault) {
        self.fw_navigationBarStyle = 1;
    } else {
        self.fw_navigationBarStyle = FWNavigationBarStyleDefault;
    }
    [self refreshBarFrame];
}

- (void)onTitleColor
{
    self.navigationController.navigationBar.fw_titleAttributes = self.navigationController.navigationBar.fw_titleAttributes ? nil : @{NSForegroundColorAttributeName: AppTheme.buttonColor};
}

- (void)onLargeTitle
{
    self.navigationController.navigationBar.prefersLargeTitles = !self.navigationController.navigationBar.prefersLargeTitles;
    [self refreshBarFrame];
}

- (void)onTabBar
{
    self.fw_tabBarHidden = !self.fw_tabBarHidden;
    [self refreshBarFrame];
}

- (void)onToolBar
{
    if (self.fw_toolBarHidden) {
        UIBarButtonItem *item = [UIBarButtonItem fw_itemWithObject:@(UIBarButtonSystemItemCancel) target:self action:@selector(onToolBar)];
        UIBarButtonItem *item2 = [UIBarButtonItem fw_itemWithObject:@(UIBarButtonSystemItemDone) target:self action:@selector(onPresent)];
        self.toolbarItems = @[item, item2];
        self.fw_toolBarHidden = NO;
    } else {
        self.fw_toolBarHidden = YES;
    }
    [self refreshBarFrame];
}

- (void)onPresent
{
    TestAdaptiveController *viewController = [[TestAdaptiveController alloc] init];
    viewController.fw_presentationDidDismiss = ^{
        [UIWindow fw_showMessageWithText:@"fwPresentationDidDismiss"];
    };
    viewController.fw_completionHandler = ^(id  _Nullable result) {
        [UIWindow fw_showMessageWithText:@"fwCompletionHandler"];
    };
    viewController.hideToast = YES;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)onPresent2
{
    TestAdaptiveController *viewController = [[TestAdaptiveController alloc] init];
    viewController.hideToast = YES;
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)onPresent3
{
    TestAdaptiveController *viewController = [[TestAdaptiveController alloc] init];
    viewController.fw_presentationDidDismiss = ^{
        [UIWindow fw_showMessageWithText:@"fwPresentationDidDismiss"];
    };
    viewController.fw_completionHandler = ^(id  _Nullable result) {
        [UIWindow fw_showMessageWithText:@"fwCompletionHandler"];
    };
    viewController.hideToast = YES;
    viewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)onPresent4
{
    TestAdaptiveController *viewController = [[TestAdaptiveController alloc] init];
    viewController.hideToast = YES;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.fw_presentationDidDismiss = ^{
        [UIWindow fw_showMessageWithText:@"fwPresentationDidDismiss"];
    };
    navController.fw_completionHandler = ^(id  _Nullable result) {
        [UIWindow fw_showMessageWithText:@"fwCompletionHandler"];
    };
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)onPresent5:(NSIndexPath *)indexPath
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    TestAdaptiveController *viewController = [[TestAdaptiveController alloc] init];
    viewController.hideToast = YES;
    viewController.preferredContentSize = CGSizeMake(FWScreenWidth / 2, FWScreenHeight / 2);
    [viewController fw_setPopoverPresentation:^(UIPopoverPresentationController *controller) {
        controller.barButtonItem = self.navigationItem.rightBarButtonItem;
        controller.permittedArrowDirections = UIPopoverArrowDirectionUp;
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        controller.passthroughViews = [NSArray arrayWithObjects:cell, nil];
    } shouldDismiss:[@[@0, @1].fw_randomObject fw_safeBool]];
    viewController.fw_presentationDidDismiss = ^{
        [UIWindow fw_showMessageWithText:@"fwPresentationDidDismiss"];
    };
    viewController.fw_completionHandler = ^(id  _Nullable result) {
        [UIWindow fw_showMessageWithText:@"fwCompletionHandler"];
    };
    [self presentViewController:viewController animated:YES completion:nil];
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
    [self.navigationController pushViewController:[TestAdaptiveChildController new] animated:YES];
}

- (void)onOrientation
{
    if ([UIDevice fw_isDeviceLandscape]) {
        [UIDevice fw_setDeviceOrientation:UIDeviceOrientationPortrait];
    } else {
        [UIDevice fw_setDeviceOrientation:UIDeviceOrientationLandscapeLeft];
    }
    [self refreshBarFrame];
}

@end
