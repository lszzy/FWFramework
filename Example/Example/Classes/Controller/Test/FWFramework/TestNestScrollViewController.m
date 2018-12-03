//
//  TestNestScrollViewController.m
//  Example
//
//  Created by wuyong on 2018/11/16.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestNestScrollViewController.h"
#import "BaseTableViewController.h"

@interface TestNestChildController : BaseTableViewController

@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, assign) BOOL section;
@property (nonatomic, copy) void (^scrollViewDidScrollBlock)(UIScrollView *scrollView);

@end

@implementation TestNestChildController

- (void)renderData
{
    for (int i = 0; i < self.rows; i++) {
        [self.dataList addObject:[NSString stringWithFormat:@"我是测试数据%@", @(i)]];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.scrollViewDidScrollBlock) {
        self.scrollViewDidScrollBlock(scrollView);
    }
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

@end

#define HeaderViewHeight 150
#define SegmentViewHeight 50
#define NavigationViewHeight (FWStatusBarHeight + FWNavigationBarHeight)
#define CartViewHeight FWTabBarHeight
#define HoverMaxY (self.isTop ? (HeaderViewHeight - NavigationViewHeight) : HeaderViewHeight)
#define ChildViewHeight (FWScreenHeight - NavigationViewHeight - SegmentViewHeight)

@interface TestNestScrollViewController () <UIScrollViewDelegate>

@property (nonatomic, assign) BOOL isTop;

@property (nonatomic, strong) UIView *segmentView;
@property (nonatomic, strong) UIView *hoverView;
@property (nonatomic, strong) UIScrollView *nestView;
@property (nonatomic, strong) UIView *cartView;

@property (nonatomic, strong) UIButton *orderButton;
@property (nonatomic, strong) UIButton *reviewButton;
@property (nonatomic, strong) UIButton *shopButton;

@property (nonatomic, strong) TestNestChildController *orderController;
@property (nonatomic, strong) TestNestChildController *reviewController;
@property (nonatomic, strong) TestNestChildController *shopController;

@property (nonatomic, assign) NSInteger segmentIndex;
@property (nonatomic, strong) UIScrollView *segmentScrollView;

@end

@implementation TestNestScrollViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        [self fwSetBackBarTitle:@""];
    }
    return self;
}

- (void)setIsTop:(BOOL)isTop
{
    _isTop = isTop;
    
    if (isTop) {
        [self fwSetBarExtendEdge:UIRectEdgeTop];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FWWeakifySelf();
    [self fwSetRightBarItem:@"切换" block:^(id sender) {
        FWStrongifySelf();
        
        TestNestScrollViewController *viewController = [TestNestScrollViewController new];
        viewController.isTop = !self.isTop;
        [self fwOpenViewController:viewController animated:YES];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar fwSetBackgroundClear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar fwResetBackground];
}

- (void)renderScrollLayout
{
    [super renderScrollLayout];
    
    self.scrollView.delegate = self;
    self.scrollView.fwTempObject = @YES;
    FWWeakifySelf();
    self.scrollView.fwShouldRecognizeSimultaneously = ^BOOL(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer) {
        FWStrongifySelf();
        /*
        // nestView左右滚动时禁止同时响应手势，不能同时上下滚动
        UISwipeGestureRecognizerDirection direction = self.nestView.fwScrollDirection;
        if (direction == UISwipeGestureRecognizerDirectionLeft ||
            direction == UISwipeGestureRecognizerDirectionRight) {
            return NO;
        }*/
        // nestView拖动中不能同时响应手势
        UIGestureRecognizerState state = self.nestView.panGestureRecognizer.state;
        if (state != UIGestureRecognizerStatePossible) {
            return NO;
        }
        return YES;
    };
    
    UIImageView *imageView = [UIImageView fwAutoLayoutView];
    imageView.image = [UIImage imageNamed:@"public_picture"];
    [self.contentView addSubview:imageView]; {
        [imageView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
        [imageView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
        [imageView fwSetDimension:NSLayoutAttributeHeight toSize:HeaderViewHeight];
    }
    
    UIView *segmentView = [UIView fwAutoLayoutView];
    _segmentView = segmentView;
    segmentView.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:segmentView]; {
        [segmentView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
        [segmentView fwPinEdgeToSuperview:NSLayoutAttributeRight];
        [segmentView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:imageView];
        [segmentView fwSetDimension:NSLayoutAttributeHeight toSize:SegmentViewHeight];
    }
    
    UIView *hoverView = [UIView fwAutoLayoutView];
    _hoverView = hoverView;
    hoverView.backgroundColor = [UIColor whiteColor];
    [hoverView fwSetBorderView:UIRectEdgeBottom color:[UIColor appColorHex:0xDDDDDD] width:1];
    [segmentView addSubview:hoverView]; {
        [hoverView fwPinEdgesToSuperview];
    }
    
    UIButton *orderButton = [UIButton fwButtonWithFont:[UIFont appFontNormal] titleColor:[UIColor appColorHex:0x111111] title:@"下单"];
    _orderButton = orderButton;
    [orderButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    orderButton.tag = 0;
    [orderButton fwAddTouchTarget:self action:@selector(onSegmentChanged:)];
    [hoverView addSubview:orderButton];
    [orderButton fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeRight];
    [orderButton fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:hoverView withMultiplier:1 / 3.f];
    
    UIButton *reviewButton = [UIButton fwButtonWithFont:[UIFont appFontNormal] titleColor:[UIColor appColorHex:0x111111] title:@"评价"];
    _reviewButton = reviewButton;
    [reviewButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    reviewButton.tag = 1;
    [reviewButton fwAddTouchTarget:self action:@selector(onSegmentChanged:)];
    [hoverView addSubview:reviewButton];
    [reviewButton fwPinEdgeToSuperview:NSLayoutAttributeTop];
    [reviewButton fwPinEdgeToSuperview:NSLayoutAttributeBottom];
    [reviewButton fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:orderButton];
    [reviewButton fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:hoverView withMultiplier:1
     / 3.f];
    
    UIButton *shopButton = [UIButton fwButtonWithFont:[UIFont appFontNormal] titleColor:[UIColor appColorHex:0x111111] title:@"商家"];
    _shopButton = shopButton;
    [shopButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    shopButton.tag = 2;
    [shopButton fwAddTouchTarget:self action:@selector(onSegmentChanged:)];
    [hoverView addSubview:shopButton];
    [shopButton fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeLeft];
    [shopButton fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:hoverView withMultiplier:1 / 3.f];
    
    UIScrollView *nestView = [UIScrollView fwAutoLayoutView];
    _nestView = nestView;
    nestView.delegate = self;
    nestView.backgroundColor = [UIColor appColorBg];
    nestView.pagingEnabled = YES;
    nestView.bounces = NO;
    nestView.showsVerticalScrollIndicator = NO;
    nestView.showsHorizontalScrollIndicator = NO;
    nestView.contentSize = CGSizeMake(FWScreenWidth * 3, ChildViewHeight);
    [self.contentView addSubview:nestView]; {
        [nestView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
        [nestView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:segmentView];
        [nestView fwSetDimension:NSLayoutAttributeHeight toSize:ChildViewHeight];
    }
    
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

- (void)renderView
{
    self.orderController = [TestNestChildController new];
    self.orderController.rows = 30;
    self.orderController.section = YES;
    FWWeakifySelf();
    self.orderController.scrollViewDidScrollBlock = ^(UIScrollView *scrollView) {
        FWStrongifySelf();
        [self scrollViewDidScroll:scrollView];
    };
    [self addChildViewController:self.orderController];
    [self.nestView addSubview:self.orderController.view];
    self.orderController.view.frame = CGRectMake(0, 0, FWScreenWidth, ChildViewHeight - CartViewHeight);
    
    self.reviewController = [TestNestChildController new];
    self.reviewController.rows = 50;
    self.reviewController.scrollViewDidScrollBlock = ^(UIScrollView *scrollView) {
        FWStrongifySelf();
        [self scrollViewDidScroll:scrollView];
    };
    [self addChildViewController:self.reviewController];
    [self.nestView addSubview:self.reviewController.view];
    self.reviewController.view.frame = CGRectMake(FWScreenWidth, 0, FWScreenWidth, ChildViewHeight);
    
    self.shopController = [TestNestChildController new];
    self.shopController.rows = 5;
    self.shopController.scrollViewDidScrollBlock = ^(UIScrollView *scrollView) {
        FWStrongifySelf();
        [self scrollViewDidScroll:scrollView];
    };
    [self addChildViewController:self.shopController];
    [self.nestView addSubview:self.shopController.view];
    self.shopController.view.frame = CGRectMake(FWScreenWidth * 2, 0, FWScreenWidth, ChildViewHeight);
    
    // 默认选中第一个
    _segmentIndex = -1;
    self.segmentIndex = 0;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // 主视图
    if (scrollView == self.scrollView) {
        // 导航栏透明度
        CGFloat progress = scrollView.contentOffset.y / (HeaderViewHeight - (self.isTop ? NavigationViewHeight : 0));
        if (progress >= 1) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor whiteColor]];
        } else if (progress >= 0 && progress < 1) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:progress]];
        }
        
        // 不能滚动时固定顶部
        if (![scrollView.fwTempObject boolValue]) {
            scrollView.contentOffset = CGPointMake(0, HoverMaxY);
        // 固定在悬停位置
        } else if (scrollView.contentOffset.y >= HoverMaxY) {
            scrollView.contentOffset = CGPointMake(0, HoverMaxY);
            scrollView.fwTempObject = @NO;
            self.segmentScrollView.fwTempObject = @YES;
        }
    }
    
    // 子视图
    if (scrollView == self.segmentScrollView) {
        // 子视图不可滚动时，固定在顶部
        if (![scrollView.fwTempObject boolValue]) {
            scrollView.contentOffset = CGPointZero;
        // 子视图滚动到顶部时固定，标记主视图可滚动
        } else if (scrollView.contentOffset.y <= 0) {
            scrollView.contentOffset = CGPointZero;
            self.scrollView.fwTempObject = @YES;
            scrollView.fwTempObject = @NO;
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // 子视图容器
    if (scrollView == self.nestView) {
        // 左右滚动切换segmentIndex
        NSInteger selectedIndex = scrollView.contentOffset.x / FWScreenWidth;
        self.segmentIndex = selectedIndex;
    }
}

#pragma mark - Action

- (void)setSegmentIndex:(NSInteger)segmentIndex
{
    if (_segmentIndex == segmentIndex) {
        return;
    }
    
    _segmentIndex = segmentIndex;
    if (segmentIndex == 0) {
        self.cartView.hidden = NO;
        self.reviewButton.selected = NO;
        self.shopButton.selected = NO;
        self.orderButton.selected = YES;
        self.segmentScrollView = self.orderController.tableView;
    } else if (segmentIndex == 1) {
        self.cartView.hidden = YES;
        self.orderButton.selected = NO;
        self.shopButton.selected = NO;
        self.reviewButton.selected = YES;
        self.segmentScrollView = self.reviewController.tableView;
    } else {
        self.cartView.hidden = YES;
        self.orderButton.selected = NO;
        self.reviewButton.selected = NO;
        self.shopButton.selected = YES;
        self.segmentScrollView = self.shopController.tableView;
    }
}

- (void)onSegmentChanged:(UIButton *)sender
{
    if (sender.tag == self.segmentIndex) {
        return;
    }
    
    self.segmentIndex = sender.tag;
    [self.nestView setContentOffset:CGPointMake(FWScreenWidth * self.segmentIndex, 0) animated:YES];
}

@end
