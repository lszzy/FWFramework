//
//  TestNestScrollViewController.m
//  Example
//
//  Created by wuyong on 2018/11/16.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestNestScrollViewController.h"
#import "TestViewController.h"

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
        _textLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:nil];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_textLabel];
        [_textLabel fwPinEdgesToSuperview];
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.contentView.backgroundColor = selected ? [UIColor grayColor] : [Theme cellColor];
}

@end

@interface TestNestChildController : TestViewController <FWTableViewController, FWCollectionViewController, FWPagingViewListViewDelegate>

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

- (void)renderTableLayout
{
    [self.tableView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsMake(0, self.cart ? CategoryViewWidth : 0, self.cart ? CartViewHeight : 0, 0)];
}

- (UICollectionViewLayout *)renderCollectionViewLayout
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(CategoryViewWidth, ItemViewHeight);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.sectionInset = UIEdgeInsetsZero;
    return layout;
}

- (void)renderCollectionLayout
{
    self.collectionView.backgroundColor = [Theme backgroundColor];
    [self.collectionView registerClass:[TestNestCollectionCell class] forCellWithReuseIdentifier:kTestNestCollectionCellID];
    [self.collectionView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsMake(0, 0, self.cart ? CartViewHeight : 0, 0) excludingEdge:NSLayoutAttributeRight];
    [self.collectionView fwSetDimension:NSLayoutAttributeWidth toSize:self.cart ? CategoryViewWidth : 0];
}

- (void)renderView
{
    if (self.refreshList) {
        [self.tableView fwSetRefreshingTarget:self action:@selector(onRefreshing)];
    }
    [self.tableView fwSetLoadingTarget:self action:@selector(onLoading)];
}

- (void)renderData
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
    [self.tableView fwReloadDataWithCompletion:^{
        FWStrongifySelf();
        [self selectCollectionViewWithOffset:self.tableView.contentOffset.y];
    }];
}

- (void)onRefreshing
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView fwEndRefreshing];
        if (self.refreshList && self.section && !self.isInserted) {
            self.isInserted = YES;
            for (int i = 0; i < 5; i++) {
                [self.tableData insertObject:[NSString stringWithFormat:@"我是插入的测试数据%@", @(4-i)] atIndex:0];
            }
        } else {
            [self.tableData removeAllObjects];
            [self renderData];
        }
        [self.collectionView reloadData];
        FWWeakifySelf();
        [self.tableView fwReloadDataWithCompletion:^{
            FWStrongifySelf();
            [self selectCollectionViewWithOffset:self.tableView.contentOffset.y];
        }];
    });
}

- (void)onLoading
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView fwEndLoading];
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
        [self.tableView fwReloadDataWithCompletion:^{
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
    cell.textLabel.text = [@(indexPath.row) fwAsNSString];
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
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
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
    view.backgroundColor = [Theme cellColor];
    
    UILabel *headerLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:[NSString stringWithFormat:@"Header%@", @(section)]];
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
    [self fwShowAlertWithTitle:[NSString stringWithFormat:@"点击%@", @(indexPath.row)] message:nil cancel:nil cancelBlock:nil];
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

@interface TestNestScrollViewController () <FWPagingViewDelegate>

@property (nonatomic, assign) BOOL refreshList;
@property (nonatomic, strong) FWPagingView *pagerView;
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
        self.fwExtendedLayoutEdge = UIRectEdgeTop;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.refreshList) {
        [self.pagerView.mainTableView fwSetRefreshingTarget:self action:@selector(onRefreshing)];
        
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
    [self.fwNavigationBar fwSetBackgroundTransparent];
}

- (void)onRefreshing
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isRefreshed = !self.isRefreshed;
        [self.pagerView reloadData];
        [self.pagerView.mainTableView fwEndRefreshing];
    });
}

#pragma mark - Protected

- (void)renderView
{
    self.headerView = [[UIImageView alloc] init];
    self.headerView.image = [TestBundle imageNamed:@"public_picture"];
    
    self.segmentedControl = [FWSegmentedControl new];
    self.segmentedControl.backgroundColor = Theme.cellColor;
    self.segmentedControl.titleTextAttributes = @{NSForegroundColorAttributeName: Theme.textColor};
    self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName: Theme.textColor};
    self.segmentedControl.sectionTitles = @[@"下单", @"评价", @"商家"];
    FWWeakifySelf();
    self.segmentedControl.indexChangeBlock = ^(NSUInteger index) {
        FWStrongifySelf();
        [self.pagerView scrollToIndex:index animated:YES];
    };
    
    if (self.refreshList) {
        FWPagingListRefreshView *pagerView = [[FWPagingListRefreshView alloc] initWithDelegate:self listContainerType:FWPagingListContainerTypeScrollView];
        pagerView.listScrollViewPinContentInsetBlock = ^CGFloat(UIScrollView *scrollView) {
            TestNestChildController *viewController = scrollView.fwViewController;
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
    [self.fwView addSubview:self.pagerView];
    [self.pagerView fwPinEdgesToSuperview];
    
    UIView *cartView = [UIView fwAutoLayoutView];
    _cartView = cartView;
    cartView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:cartView];
    [cartView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
    [cartView fwSetDimension:NSLayoutAttributeHeight toSize:CartViewHeight];
    UILabel *cartLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[UIColor blackColor] text:@"我是购物车"];
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
        self.fwNavigationBar.fwBackgroundColor = [Theme barColor];
        self.fwNavigationBar.fwForegroundColor = [Theme textColor];
    } else if (progress >= 0 && progress < 1) {
        self.fwNavigationBar.fwBackgroundColor = [[Theme barColor] colorWithAlphaComponent:progress];
        if (progress <= 0.5) {
            self.fwNavigationBar.fwForegroundColor = [[Theme textColor] colorWithAlphaComponent:1 - progress];
        } else {
            self.fwNavigationBar.fwForegroundColor = [[Theme textColor] colorWithAlphaComponent:progress];
        }
    }
}

- (void)pagingView:(FWPagingView *)pagingView didScrollToIndex:(NSInteger)index
{
    self.segmentedControl.selectedSegmentIndex = index;
    self.cartView.hidden = (index != 0);
}

@end
