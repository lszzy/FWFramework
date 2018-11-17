//
//  TestNestScrollViewController.m
//  Example
//
//  Created by wuyong on 2018/11/16.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestNestScrollViewController.h"

#define HeaderViewHeight 150
#define SegmentViewHeight 50
#define NavigationViewHeight (FWStatusBarHeight + FWNavigationBarHeight)
#define CartViewHeight FWTabBarHeight
#define HoverMaxY (self.isTop ? (HeaderViewHeight - NavigationViewHeight) : HeaderViewHeight)

@interface TestNestScrollViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIView *segmentView;
@property (nonatomic, strong) UIView *hoverView;
@property (nonatomic, strong) UIView *nestView;
@property (nonatomic, strong) UIView *cartView;

@property (nonatomic, strong) UIScrollView *orderScrollView;
@property (nonatomic, strong) UIScrollView *reviewScrollView;
@property (nonatomic, strong) UIScrollView *shopScrollView;
@property (nonatomic, assign) NSInteger segmentIndex;

@property (nonatomic, assign) BOOL isTop;

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
        [self fwOnOpen:viewController];
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

- (void)renderView
{
    self.scrollView.delegate = self;
    self.scrollView.tag = -1;
    self.scrollView.fwTempObject = @1;
    self.scrollView.fwShouldRecognizeSimultaneously = ^BOOL(UIGestureRecognizer *gestureRecognizer, UIGestureRecognizer *otherGestureRecognizer) {
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
    orderButton.tag = 0;
    [orderButton fwAddTouchTarget:self action:@selector(onSegmentChanged:)];
    [hoverView addSubview:orderButton];
    [orderButton fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeRight];
    [orderButton fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:hoverView withMultiplier:1 / 3.f];
    
    UIButton *reviewButton = [UIButton fwButtonWithFont:[UIFont appFontNormal] titleColor:[UIColor appColorHex:0x111111] title:@"评价"];
    reviewButton.tag = 1;
    [reviewButton fwAddTouchTarget:self action:@selector(onSegmentChanged:)];
    [hoverView addSubview:reviewButton];
    [reviewButton fwPinEdgeToSuperview:NSLayoutAttributeTop];
    [reviewButton fwPinEdgeToSuperview:NSLayoutAttributeBottom];
    [reviewButton fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:orderButton];
    [reviewButton fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:hoverView withMultiplier:1
     / 3.f];
    
    UIButton *shopButton = [UIButton fwButtonWithFont:[UIFont appFontNormal] titleColor:[UIColor appColorHex:0x111111] title:@"商家"];
    shopButton.tag = 2;
    [shopButton fwAddTouchTarget:self action:@selector(onSegmentChanged:)];
    [hoverView addSubview:shopButton];
    [shopButton fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeLeft];
    [shopButton fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:hoverView withMultiplier:1 / 3.f];
    
    UIView *nestView = [UIView fwAutoLayoutView];
    nestView.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:nestView]; {
        [nestView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
        [nestView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:segmentView];
        CGFloat nestHeight = FWScreenHeight - NavigationViewHeight - SegmentViewHeight;
        [nestView fwSetDimension:NSLayoutAttributeHeight toSize:nestHeight];
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
    
    [nestView addSubview:self.orderScrollView];
    [self.orderScrollView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsMake(0, 0, CartViewHeight, 0)];
    
    self.reviewScrollView.hidden = YES;
    [nestView addSubview:self.reviewScrollView];
    [self.reviewScrollView fwPinEdgesToSuperview];
    
    self.shopScrollView.hidden = YES;
    [nestView addSubview:self.shopScrollView];
    [self.shopScrollView fwPinEdgesToSuperview];
}

#pragma mark - Private

- (UIScrollView *)orderScrollView
{
    if (!_orderScrollView) {
        _orderScrollView = [self renderScrollView];
        _orderScrollView.delegate = self;
        _orderScrollView.fwTempObject = @0;
        _orderScrollView.tag = 0;
        _orderScrollView.backgroundColor = [UIColor whiteColor];
        
        UILabel *headerLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor blackColor] text:@"我是下单开头"];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.frame = CGRectMake(0, 0, FWScreenWidth, 30);
        [_orderScrollView addSubview:headerLabel];
        
        UILabel *footerLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor blackColor] text:@"我是下单结尾"];
        footerLabel.textAlignment = NSTextAlignmentCenter;
        footerLabel.frame = CGRectMake(0, 1970, FWScreenWidth, 30);
        [_orderScrollView addSubview:footerLabel];
        
        _orderScrollView.contentSize = CGSizeMake(FWScreenWidth, 2000);
    }
    return _orderScrollView;
}

- (UIScrollView *)reviewScrollView
{
    if (!_reviewScrollView) {
        _reviewScrollView = [self renderScrollView];
        _reviewScrollView.delegate = self;
        _reviewScrollView.fwTempObject = @0;
        _reviewScrollView.tag = 1;
        _reviewScrollView.backgroundColor = [UIColor whiteColor];
        
        UILabel *headerLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor blackColor] text:@"我是评价开头"];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.frame = CGRectMake(0, 0, FWScreenWidth, 30);
        [_reviewScrollView addSubview:headerLabel];
        
        UILabel *footerLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor blackColor] text:@"我是评价结尾"];
        footerLabel.textAlignment = NSTextAlignmentCenter;
        footerLabel.frame = CGRectMake(0, 970, FWScreenWidth, 30);
        [_reviewScrollView addSubview:footerLabel];
        
        _reviewScrollView.contentSize = CGSizeMake(FWScreenWidth, 1000);
    }
    return _reviewScrollView;
}

- (UIScrollView *)shopScrollView
{
    if (!_shopScrollView) {
        _shopScrollView = [self renderScrollView];
        _shopScrollView.delegate = self;
        _shopScrollView.fwTempObject = @0;
        _shopScrollView.tag = 2;
        _shopScrollView.backgroundColor = [UIColor whiteColor];
        
        UILabel *headerLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor blackColor] text:@"我是商家开头"];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.frame = CGRectMake(0, 0, FWScreenWidth, 30);
        [_shopScrollView addSubview:headerLabel];
        
        UILabel *footerLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor blackColor] text:@"我是商家结尾"];
        footerLabel.textAlignment = NSTextAlignmentCenter;
        footerLabel.frame = CGRectMake(0, 270, FWScreenWidth, 30);
        [_shopScrollView addSubview:footerLabel];
        
        _shopScrollView.contentSize = CGSizeMake(FWScreenWidth, 300);
    }
    return _shopScrollView;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UIScrollView *childScrollView = nil;
    if (self.segmentIndex == 0) {
        childScrollView = self.orderScrollView;
    } else if (self.segmentIndex == 1) {
        childScrollView = self.reviewScrollView;
    } else {
        childScrollView = self.shopScrollView;
    }
    
    if (scrollView == self.scrollView) {
        if (self.isTop) {
            CGFloat progress = [scrollView fwHoverView:self.hoverView fromSuperview:self.segmentView toSuperview:self.view fromPosition:HeaderViewHeight toPosition:NavigationViewHeight];
            if (progress == 1) {
                [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor whiteColor]];
            } else if (progress >= 0 && progress < 1) {
                [self.navigationController.navigationBar fwSetBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:progress]];
            }
        } else {
            [scrollView fwHoverView:self.hoverView fromSuperview:self.segmentView toSuperview:self.view fromPosition:HeaderViewHeight toPosition:0];
        }
        
        if (scrollView.contentOffset.y >= HoverMaxY) {
            if ([scrollView.fwTempObject boolValue]) {
                scrollView.fwTempObject = @0;
                self.orderScrollView.fwTempObject = @1;
                self.reviewScrollView.fwTempObject = @1;
                self.shopScrollView.fwTempObject = @1;
            } else {
                if (scrollView.fwScrollDirection == UISwipeGestureRecognizerDirectionUp) {
                    [self scrollViewDidScroll:childScrollView];
                } else if (scrollView.fwScrollDirection == UISwipeGestureRecognizerDirectionDown) {
                    if (![childScrollView fwIsScrollToEdge:UIRectEdgeBottom]) {
                        scrollView.contentOffset = CGPointMake(0, HoverMaxY);
                    }
                }
            }
        } else {
            if (![scrollView.fwTempObject boolValue]) {
                scrollView.contentOffset = CGPointMake(0, HoverMaxY);
            }
        }
    }
    
    if (scrollView == childScrollView) {
        if (![scrollView.fwTempObject boolValue]) {
            scrollView.contentOffset = CGPointZero;
        } else if (scrollView.contentOffset.y <= 0) {
            self.scrollView.fwTempObject = @1;
            scrollView.fwTempObject = @0;
            scrollView.contentOffset = CGPointZero;
        }
    }
}

#pragma mark - Action

- (void)onSegmentChanged:(UIButton *)sender
{
    if (sender.tag == self.segmentIndex) {
        return;
    }
    
    self.segmentIndex = sender.tag;
    if (self.segmentIndex == 0) {
        self.orderScrollView.hidden = NO;
        self.reviewScrollView.hidden = YES;
        self.shopScrollView.hidden = YES;
        self.cartView.hidden = NO;
    } else if (self.segmentIndex == 1) {
        self.orderScrollView.hidden = YES;
        self.reviewScrollView.hidden = NO;
        self.shopScrollView.hidden = YES;
        self.cartView.hidden = YES;
    } else {
        self.orderScrollView.hidden = YES;
        self.reviewScrollView.hidden = YES;
        self.shopScrollView.hidden = NO;
        self.cartView.hidden = YES;
    }
}

@end
