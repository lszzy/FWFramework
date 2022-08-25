//
//  TestPagingController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestPagingController.h"
#import "AppSwift.h"
@import FWFramework;

#define HeaderViewHeight 150
#define SegmentViewHeight 50
#define NavigationViewHeight FWTopBarHeight
#define CartViewHeight FWTabBarHeight
#define CategoryViewWidth 84
#define ItemViewHeight 40

static NSString * const kTestNestCollectionCellID = @"kTestNestCollectionCellID";

@interface TestNestCollectionCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation TestNestCollectionCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _textLabel = [UILabel fw_labelWithFont:[UIFont fw_fontOfSize:15] textColor:[AppTheme textColor]];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_textLabel];
        [_textLabel fw_pinEdgesToSuperview];
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.contentView.backgroundColor = selected ? [UIColor grayColor] : [AppTheme cellColor];
}

@end

@interface TestNestChildController : UIViewController <FWTableViewController, FWCollectionViewController, FWPagingViewListViewDelegate>

@property (nonatomic, assign) BOOL refreshList;
@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, assign) BOOL section;
@property (nonatomic, assign) BOOL cart;
@property (nonatomic, assign) BOOL isRefreshed;
@property (nonatomic, assign) BOOL isInserted;
@property (nonatomic, weak) FWPagingView *pagerView;

@property (nonatomic, copy) void(^scrollCallback)(UIScrollView *scrollView);

@end

@implementation TestNestChildController

- (void)setupTableLayout
{
    [self.tableView fw_pinEdgesToSuperviewWithInsets:UIEdgeInsetsMake(0, self.cart ? CategoryViewWidth : 0, self.cart ? CartViewHeight : 0, 0)];
}

- (UICollectionViewLayout *)setupCollectionViewLayout
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(CategoryViewWidth, ItemViewHeight);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.sectionInset = UIEdgeInsetsZero;
    return layout;
}

- (void)setupCollectionLayout
{
    self.collectionView.backgroundColor = [AppTheme backgroundColor];
    [self.collectionView registerClass:[TestNestCollectionCell class] forCellWithReuseIdentifier:kTestNestCollectionCellID];
    [self.collectionView fw_pinEdgesToSuperviewWithInsets:UIEdgeInsetsMake(0, 0, self.cart ? CartViewHeight : 0, 0) excludingEdge:NSLayoutAttributeRight];
    [self.collectionView fw_setDimension:NSLayoutAttributeWidth toSize:self.cart ? CategoryViewWidth : 0];
}

- (void)setupSubviews
{
    if (self.refreshList) {
        [self.tableView fw_setRefreshingTarget:self action:@selector(onRefreshing)];
    }
    [self.tableView fw_setLoadingTarget:self action:@selector(onLoading)];
}

- (void)setupLayout
{
    for (int i = 0; i < self.rows; i++) {
        if (self.isRefreshed) {
            [self.tableData addObject:[NSString stringWithFormat:@"我是刷新的测试数据%@", @(i)]];
        } else {
            [self.tableData addObject:[NSString stringWithFormat:@"我是测试数据%@", @(i)]];
        }
    }
    [self.collectionView reloadData];
    FWWeakifySelf();
    [self.tableView fw_reloadDataWithCompletion:^{
        FWStrongifySelf();
        [self selectCollectionViewWithOffset:self.tableView.contentOffset.y];
    }];
}

- (void)onRefreshing
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView fw_endRefreshing];
        if (self.refreshList && self.section && !self.isInserted) {
            self.isInserted = YES;
            for (int i = 0; i < 5; i++) {
                [self.tableData insertObject:[NSString stringWithFormat:@"我是插入的测试数据%@", @(4-i)] atIndex:0];
            }
        } else {
            [self.tableData removeAllObjects];
            [self setupLayout];
        }
        [self.collectionView reloadData];
        FWWeakifySelf();
        [self.tableView fw_reloadDataWithCompletion:^{
            FWStrongifySelf();
            [self selectCollectionViewWithOffset:self.tableView.contentOffset.y];
        }];
    });
}

- (void)onLoading
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView fw_endLoading];
        NSInteger rows = self.tableData.count;
        for (int i = 0; i < 5; i++) {
            if (self.isRefreshed) {
                [self.tableData addObject:[NSString stringWithFormat:@"我是刷新的测试数据%@", @(rows + i)]];
            } else {
                [self.tableData addObject:[NSString stringWithFormat:@"我是测试数据%@", @(rows + i)]];
            }
        }
        [self.collectionView reloadData];
        FWWeakifySelf();
        [self.tableView fw_reloadDataWithCompletion:^{
            FWStrongifySelf();
            [self selectCollectionViewWithOffset:self.tableView.contentOffset.y];
        }];
    });
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ceil(self.tableData.count / 5);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TestNestCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTestNestCollectionCellID forIndexPath:indexPath];
    cell.textLabel.text = [@(indexPath.row) fw_safeString];
    cell.selected = NO;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.pagerView setMainTableViewToMaxContentOffsetY];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.row] animated:YES scrollPosition:UITableViewScrollPositionTop];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ceil(self.tableData.count / 5);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView];
    NSInteger index = indexPath.section * 5 + indexPath.row;
    cell.textLabel.text = [self.tableData objectAtIndex:index];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.section ? ItemViewHeight : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [UIView new];
    view.backgroundColor = [AppTheme cellColor];
    
    UILabel *headerLabel = [UILabel fw_labelWithFont:[UIFont fw_fontOfSize:15] textColor:[AppTheme textColor] text:[NSString stringWithFormat:@"Header%@", @(section)]];
    headerLabel.frame = CGRectMake(0, 0, FWScreenWidth, ItemViewHeight);
    [view addSubview:headerLabel];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ItemViewHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self fw_showAlertWithTitle:[NSString stringWithFormat:@"点击%@", @(indexPath.row)] message:nil cancel:nil cancelBlock:nil];
}

- (void)selectCollectionViewWithOffset:(CGFloat)contentOffsetY
{
    if (!self.cart) return;
    
    for (int i = 0; i < self.tableData.count; i++) {
        CGFloat sectionOffsetY = ItemViewHeight * (i + 1) + (i / 5 + 1) * ItemViewHeight;
        if (contentOffsetY < sectionOffsetY) {
            [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:(i / 5) inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionTop];
            break;
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        // 拖动或减速时选中左侧菜单
        if (self.tableView.isDragging || self.tableView.isDecelerating) {
            [self selectCollectionViewWithOffset:scrollView.contentOffset.y];
        }
        
        if (self.scrollCallback) {
            self.scrollCallback(scrollView);
        }
    }
}

#pragma mark - FWPagingViewListViewDelegate

- (UIView *)listView
{
    return self.view;
}

- (UIScrollView *)listScrollView
{
    return self.tableView;
}

- (void)listViewDidScrollCallbackWithCallback:(void (^)(UIScrollView * _Nonnull))callback
{
    self.scrollCallback = callback;
}

@end

@interface TestPagingController () <FWViewController, FWPagingViewDelegate>

@property (nonatomic, assign) BOOL refreshList;
@property (nonatomic, strong) FWPagingView *pagerView;
@property (nonatomic, strong) UIImageView *headerView;
@property (nonatomic, strong) FWSegmentedControl *segmentedControl;
@property (nonatomic, strong) UIView *cartView;
@property (nonatomic, assign) BOOL isRefreshed;

@end

@implementation TestPagingController

- (void)didInitialize
{
    self.fw_extendedLayoutEdge = UIRectEdgeTop;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.refreshList) {
        [self.pagerView.mainTableView fw_setRefreshingTarget:self action:@selector(onRefreshing)];
        
        FWWeakifySelf();
        [self fw_setRightBarItem:@"测试" block:^(id  _Nonnull sender) {
            FWStrongifySelf();
            TestPagingController *viewController = [TestPagingController new];
            viewController.refreshList = YES;
            [self fw_openViewController:viewController animated:YES];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.fw_backgroundTransparent = YES;
}

- (void)onRefreshing
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isRefreshed = !self.isRefreshed;
        [self.pagerView reloadData];
        [self.pagerView.mainTableView fw_endRefreshing];
    });
}

#pragma mark - Protected

- (void)setupSubviews
{
    self.headerView = [[UIImageView alloc] init];
    self.headerView.image = [UIImage fw_appIconImage];
    
    self.segmentedControl = [FWSegmentedControl new];
    self.segmentedControl.backgroundColor = AppTheme.cellColor;
    self.segmentedControl.titleTextAttributes = @{NSForegroundColorAttributeName: AppTheme.textColor};
    self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName: AppTheme.textColor};
    self.segmentedControl.sectionTitles = @[@"下单", @"评价", @"商家"];
    FWWeakifySelf();
    self.segmentedControl.indexChangeBlock = ^(NSUInteger index) {
        FWStrongifySelf();
        [self.pagerView scrollToIndex:index animated:YES];
    };
    
    if (self.refreshList) {
        FWPagingListRefreshView *pagerView = [[FWPagingListRefreshView alloc] initWithDelegate:self listContainerType:FWPagingListContainerTypeScrollView];
        pagerView.listScrollViewPinContentInsetBlock = ^CGFloat(UIScrollView *scrollView) {
            TestNestChildController *viewController = scrollView.fw_viewController;
            if (viewController.refreshList && viewController.section && !viewController.isInserted) {
                return FWScreenHeight;
            }
            return 0;
        };
        self.pagerView = pagerView;
    } else {
        self.pagerView = [[FWPagingView alloc] initWithDelegate:self listContainerType:FWPagingListContainerTypeScrollView];
    }
    self.pagerView.pinSectionHeaderVerticalOffset = FWTopBarHeight;
    [self.view addSubview:self.pagerView];
    [self.pagerView fw_pinEdgesToSuperview];
    
    UIView *cartView = [UIView new];
    _cartView = cartView;
    cartView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:cartView];
    [cartView fw_pinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
    [cartView fw_setDimension:NSLayoutAttributeHeight toSize:CartViewHeight];
    UILabel *cartLabel = [UILabel fw_labelWithFont:[UIFont fw_fontOfSize:15] textColor:[UIColor blackColor] text:@"我是购物车"];
    cartLabel.textAlignment = NSTextAlignmentCenter;
    cartLabel.frame = CGRectMake(0, 0, FWScreenWidth, CartViewHeight);
    [cartView addSubview:cartLabel];
}

#pragma mark - FWPagingViewDelegate

-(NSInteger)tableHeaderViewHeightIn:(FWPagingView *)pagingView
{
    return HeaderViewHeight;
}

- (UIView *)tableHeaderViewIn:(FWPagingView *)pagingView
{
    return self.headerView;
}

- (NSInteger)heightForPinSectionHeaderIn:(FWPagingView *)pagingView
{
    return SegmentViewHeight;
}

- (UIView *)viewForPinSectionHeaderIn:(FWPagingView *)pagingView
{
    return self.segmentedControl;
}

- (NSInteger)numberOfListsIn:(FWPagingView *)pagingView
{
    return self.segmentedControl.sectionTitles.count;
}

- (id<FWPagingViewListViewDelegate>)pagingView:(FWPagingView *)pagingView initListAtIndex:(NSInteger)index
{
    TestNestChildController *listView = [TestNestChildController new];
    listView.pagerView = pagingView;
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

- (void)pagingView:(FWPagingView *)pagingView mainTableViewDidScroll:(UIScrollView *)scrollView
{
    // 导航栏透明度
    CGFloat progress = scrollView.contentOffset.y / (HeaderViewHeight - NavigationViewHeight);
    if (progress >= 1) {
        self.navigationController.navigationBar.fw_backgroundColor = [AppTheme barColor];
        self.navigationController.navigationBar.fw_foregroundColor = [AppTheme textColor];
    } else if (progress >= 0 && progress < 1) {
        self.navigationController.navigationBar.fw_backgroundColor = [[AppTheme barColor] colorWithAlphaComponent:progress];
        if (progress <= 0.5) {
            self.navigationController.navigationBar.fw_foregroundColor = [[AppTheme textColor] colorWithAlphaComponent:1 - progress];
        } else {
            self.navigationController.navigationBar.fw_foregroundColor = [[AppTheme textColor] colorWithAlphaComponent:progress];
        }
    }
}

- (void)pagingView:(FWPagingView *)pagingView didScrollToIndex:(NSInteger)index
{
    self.segmentedControl.selectedSegmentIndex = index;
    self.cartView.hidden = (index != 0);
}

@end
