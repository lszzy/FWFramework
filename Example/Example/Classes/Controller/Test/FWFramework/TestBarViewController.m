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
    return @(self.index < 3 ? 1 : self.index);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:@"标题:%@", @(self.index + 1)];
    self.fwForcePopGesture = YES;
    
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.index < 3) {
        [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor greenColor]];
        [self.navigationController.navigationBar fwSetLineHidden:YES];
    } else {
        if (!self.fwTempObject) {
            self.fwTempObject = @[[UIColor fwRandomColor], [@[@0, @1] fwRandomObject], (self.index < 6 ? @0 : [@[@0, @1] fwRandomObject])];
        }
        [self.navigationController.navigationBar fwSetBackgroundColor:self.fwTempObject[0]];
        [self.navigationController.navigationBar fwSetLineHidden:[self.fwTempObject[1] boolValue]];
        [self fwSetNavigationBarHidden:[self.fwTempObject[2] boolValue] animated:animated];
    }
}

@end

@interface TestBarViewController ()

FWPropertyWeak(UILabel *, frameLabel);

@end

@implementation TestBarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fwTabBarHidden = YES;
    [self refreshBarFrame];
    
    [self fwSetRightBarItem:@"启用" block:^(id sender) {
        [UINavigationController fwEnableNavigationBarTransition];
    }];
}

- (void)renderView
{
    UILabel *frameLabel = [UILabel fwAutoLayoutView];
    self.frameLabel = frameLabel;
    frameLabel.numberOfLines = 0;
    frameLabel.textColor = [UIColor appColorBlack];
    frameLabel.font = [UIFont appFontNormal];
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
    [self.dataList addObjectsFromArray:@[
                                         @[@"状态栏切换", @"onStatusBar"],
                                         @[@"状态栏样式", @"onStatusStyle"],
                                         @[@"导航栏切换", @"onNavigationBar"],
                                         @[@"标签栏切换", @"onTabBar"],
                                         @[@"导航栏转场", @"onTransitionBar"],
                                         ]];
    if (self.navigationController) {
        [self.dataList addObject:@[@"Present", @"onPresent"]];
    } else {
        [self.dataList addObject:@[@"Dismiss", @"onDismiss"]];
    }
}

#pragma mark - TableView

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.dataList objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.dataList objectAtIndex:indexPath.row];
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
    self.frameLabel.text = [NSString stringWithFormat:@"全局状态栏：%@\n全局导航栏：%@\n全局标签栏：%@\n当前状态栏：%@\n当前导航栏：%@\n当前标签栏：%@",
                            @([UIScreen fwStatusBarHeight]),
                            @([UIScreen fwNavigationBarHeight]),
                            @([UIScreen fwTabBarHeight]),
                            @([self fwStatusBarHeight]),
                            @([self fwNavigationBarHeight]),
                            @([self fwTabBarHeight])];
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

- (void)onTabBar
{
    self.fwTabBarHidden = !self.fwTabBarHidden;
    [self refreshBarFrame];
}

- (void)onPresent
{
    TestBarViewController *viewController = [[TestBarViewController alloc] init];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)onDismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onTransitionBar
{
    [self.navigationController pushViewController:[TestBarSubViewController new] animated:YES];
}

@end
