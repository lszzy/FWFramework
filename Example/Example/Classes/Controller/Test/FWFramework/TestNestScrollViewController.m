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

@end

@implementation TestNestChildController

- (void)renderData
{
    for (int i = 0; i < self.rows; i++) {
        [self.dataList addObject:[NSString stringWithFormat:@"我是测试数据%@", @(i)]];
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
#define NavigationViewHeight FWTopBarHeight
#define CartViewHeight FWTabBarHeight
#define HoverMaxY (HeaderViewHeight - NavigationViewHeight)
#define ChildViewHeight (FWScreenHeight - NavigationViewHeight - SegmentViewHeight)

@interface TestNestScrollViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController.navigationBar fwSetBackgroundClear];
}

- (void)renderScrollLayout
{
    [super renderScrollLayout];

    self.scrollView.delegate = self;
    self.scrollView.fwPanGestureRecognizerDelegate = self;
    
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
    [self addChildViewController:self.orderController];
    [self.nestView addSubview:self.orderController.view];
    self.orderController.view.frame = CGRectMake(0, 0, FWScreenWidth, ChildViewHeight - CartViewHeight);
    
    self.reviewController = [TestNestChildController new];
    self.reviewController.rows = 50;
    [self addChildViewController:self.reviewController];
    [self.nestView addSubview:self.reviewController.view];
    self.reviewController.view.frame = CGRectMake(FWScreenWidth, 0, FWScreenWidth, ChildViewHeight);
    
    self.shopController = [TestNestChildController new];
    self.shopController.rows = 5;
    [self addChildViewController:self.shopController];
    [self.nestView addSubview:self.shopController.view];
    self.shopController.view.frame = CGRectMake(FWScreenWidth * 2, 0, FWScreenWidth, ChildViewHeight);
    
    // 默认选中第一个
    _segmentIndex = -1;
    self.segmentIndex = 0;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
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
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // 主视图
    if (scrollView == self.scrollView) {
        // 导航栏透明度
        CGFloat progress = scrollView.contentOffset.y / (HeaderViewHeight - NavigationViewHeight);
        if (progress >= 1) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor whiteColor]];
        } else if (progress >= 0 && progress < 1) {
            [self.navigationController.navigationBar fwSetBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:progress]];
        }
        
        // 不能滚动时固定顶部
        if (scrollView.contentOffset.y < 0) {
            scrollView.contentOffset = CGPointMake(0, 0);
        // 固定在悬停位置
        } else if (scrollView.contentOffset.y > HoverMaxY) {
            scrollView.contentOffset = CGPointMake(0, HoverMaxY);
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
    } else if (segmentIndex == 1) {
        self.cartView.hidden = YES;
        self.orderButton.selected = NO;
        self.shopButton.selected = NO;
        self.reviewButton.selected = YES;
    } else {
        self.cartView.hidden = YES;
        self.orderButton.selected = NO;
        self.reviewButton.selected = NO;
        self.shopButton.selected = YES;
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
