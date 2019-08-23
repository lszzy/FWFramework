//
//  TestNestScrollViewController.m
//  Example
//
//  Created by wuyong on 2018/11/16.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestNestScrollViewController.h"
#import "BaseTableViewController.h"

#define HeaderViewHeight 150
#define SegmentViewHeight 50
#define NavigationViewHeight FWTopBarHeight
#define CartViewHeight FWTabBarHeight
#define HoverMaxY (HeaderViewHeight - NavigationViewHeight)
#define ChildViewHeight (FWScreenHeight - NavigationViewHeight - SegmentViewHeight)

@interface TestNestChildController : BaseTableViewController <FWPagerViewListViewDelegate>

@property (nonatomic, assign) BOOL refreshList;
@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, assign) BOOL section;
@property (nonatomic, assign) BOOL cart;
@property (nonatomic, assign) BOOL isRefreshed;

@property (nonatomic, copy) void(^scrollCallback)(UIScrollView *scrollView);

@end

@implementation TestNestChildController

- (void)renderTableLayout
{
    [self.tableView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsMake(0, 0, self.cart ? CartViewHeight : 0, 0)];
}

- (void)renderView
{
    if (self.refreshList) {
        [self.tableView fwAddPullRefreshWithTarget:self action:@selector(onRefreshing)];
    }
    [self.tableView fwAddInfiniteScrollWithTarget:self action:@selector(onLoading)];
}

- (void)renderData
{
    for (int i = 0; i < self.rows; i++) {
        if (self.isRefreshed) {
            [self.dataList addObject:[NSString stringWithFormat:@"我是刷新的测试数据%@", @(i)]];
        } else {
            [self.dataList addObject:[NSString stringWithFormat:@"我是测试数据%@", @(i)]];
        }
    }
}

- (void)onRefreshing
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isRefreshed = !self.isRefreshed;
        [self.dataList removeAllObjects];
        [self renderData];
        [self.tableView reloadData];
        [self.tableView.fwPullRefreshView stopAnimating];
    });
}

- (void)onLoading
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSInteger rows = self.dataList.count;
        for (int i = 0; i < 5; i++) {
            if (self.isRefreshed) {
                [self.dataList addObject:[NSString stringWithFormat:@"我是刷新的测试数据%@", @(rows + i)]];
            } else {
                [self.dataList addObject:[NSString stringWithFormat:@"我是测试数据%@", @(rows + i)]];
            }
        }
        [self.tableView reloadData];
        [self.tableView.fwInfiniteScrollView stopAnimating];
    });
}

#pragma mark - TableView

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = [self.dataList objectAtIndex:indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.section ? 40 : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor whiteColor];
    
    UILabel *headerLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor appColorBlackOpacityLarge] text:@"Header"];
    headerLabel.frame = CGRectMake(0, 0, FWScreenWidth, 40);
    [view addSubview:headerLabel];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self fwShowAlertWithTitle:[NSString stringWithFormat:@"点击%@", @(indexPath.row)] message:nil cancel:@"关闭" cancelBlock:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.scrollCallback) {
        self.scrollCallback(scrollView);
    }
}

#pragma mark - FWPagerViewListViewDelegate

- (UIView *)pagerListView
{
    return self.view;
}

- (UIScrollView *)pagerListScrollView
{
    return self.tableView;
}

- (void)pagerListViewDidScrollCallback:(void (^)(UIScrollView *))callback
{
    self.scrollCallback = callback;
}

@end

@interface TestNestScrollViewController () <FWPagerViewDelegate>

@property (nonatomic, assign) BOOL refreshList;
@property (nonatomic, strong) FWPagerView *pagerView;
@property (nonatomic, strong) UIImageView *headerView;
@property (nonatomic, strong) FWSegmentedControl *segmentedControl;
@property (nonatomic, strong) UIView *cartView;
@property (nonatomic, assign) BOOL isRefreshed;

@end

@implementation TestNestScrollViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self fwSetBarExtendEdge:UIRectEdgeTop];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.refreshList) {
        [self.pagerView.mainTableView fwAddPullRefreshWithTarget:self action:@selector(onRefreshing)];
        
        FWWeakifySelf();
        [self fwSetRightBarItem:@"测试" block:^(id  _Nonnull sender) {
            FWStrongifySelf();
            TestNestScrollViewController *viewController = [TestNestScrollViewController new];
            viewController.refreshList = YES;
            [self fwOpenViewController:viewController animated:YES];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar fwSetBackgroundClear];
}

- (void)onRefreshing
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isRefreshed = !self.isRefreshed;
        [self.pagerView reloadData];
        [self.pagerView.mainTableView.fwPullRefreshView stopAnimating];
    });
}

#pragma mark - Protected

- (void)renderView
{
    self.headerView = [[UIImageView alloc] init];
    self.headerView.image = [UIImage imageNamed:@"public_picture"];
    
    self.segmentedControl = [FWSegmentedControl new];
    self.segmentedControl.sectionTitles = @[@"下单", @"评价", @"商家"];
    FWWeakifySelf();
    self.segmentedControl.indexChangeBlock = ^(NSInteger index) {
        FWStrongifySelf();
        [self.pagerView scrollToIndex:index];
    };
    
    if (self.refreshList) {
        self.pagerView = [[FWPagerRefreshView alloc] initWithDelegate:self];
    } else {
        self.pagerView = [[FWPagerView alloc] initWithDelegate:self];
    }
    self.pagerView.pinSectionHeaderVerticalOffset = FWTopBarHeight;
    [self.view addSubview:self.pagerView];
    [self.pagerView fwPinEdgesToSuperview];
    
    UIView *cartView = [UIView fwAutoLayoutView];
    _cartView = cartView;
    cartView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:cartView];
    [cartView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
    [cartView fwSetDimension:NSLayoutAttributeHeight toSize:CartViewHeight];
    UILabel *cartLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor blackColor] text:@"我是购物车"];
    cartLabel.textAlignment = NSTextAlignmentCenter;
    cartLabel.frame = CGRectMake(0, 0, FWScreenWidth, CartViewHeight);
    [cartView addSubview:cartLabel];
}

#pragma mark - FWPagerViewDelegate

- (NSUInteger)tableHeaderViewHeightInPagerView:(FWPagerView *)pagerView
{
    return HeaderViewHeight;
}

- (UIView *)tableHeaderViewInPagerView:(FWPagerView *)pagerView
{
    return self.headerView;
}

- (NSUInteger)pinSectionHeaderHeightInPagerView:(FWPagerView *)pagerView
{
    return SegmentViewHeight;
}

- (UIView *)pinSectionHeaderInPagerView:(FWPagerView *)pagerView
{
    return self.segmentedControl;
}

- (NSInteger)numberOfListViewsInPagerView:(FWPagerView *)pagerView
{
    return self.segmentedControl.sectionTitles.count;
}

- (id<FWPagerViewListViewDelegate>)pagerView:(FWPagerView *)pagerView listViewAtIndex:(NSInteger)index
{
    TestNestChildController *listView = [TestNestChildController new];
    listView.refreshList = self.refreshList;
    listView.isRefreshed = self.isRefreshed;
    if (index == 0) {
        listView.rows = 30;
        listView.section = YES;
        listView.cart = YES;
    } else if (index == 1) {
        listView.rows = 50;
    } else {
        listView.rows = 5;
    }
    return listView;
}

- (void)pagerView:(FWPagerView *)pagerView mainTableViewDidScroll:(UIScrollView *)scrollView
{
    // 导航栏透明度
    CGFloat progress = scrollView.contentOffset.y / (HeaderViewHeight - NavigationViewHeight);
    if (progress >= 1) {
        [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor whiteColor]];
        [self.navigationController.navigationBar fwSetTextColor:[UIColor appColorHex:0x111111]];
    } else if (progress >= 0 && progress < 1) {
        [self.navigationController.navigationBar fwSetBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:progress]];
        if (progress <= 0.5) {
            [self.navigationController.navigationBar fwSetTextColor:[[UIColor whiteColor] colorWithAlphaComponent:1 - progress]];
        } else {
            [self.navigationController.navigationBar fwSetTextColor:[[UIColor appColorHex:0x111111] colorWithAlphaComponent:progress]];
        }
    }
}

- (void)pagerView:(FWPagerView *)pagerView didScrollToIndex:(NSInteger)index
{
    self.segmentedControl.selectedSegmentIndex = index;
    self.cartView.hidden = (index != 0);
}

@end
