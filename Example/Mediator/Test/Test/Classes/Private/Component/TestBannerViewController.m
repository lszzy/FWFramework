//
//  TestBannerViewController.m
//  Example
//
//  Created by wuyong on 2018/12/13.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestBannerViewController.h"
#import "TestWebViewController.h"

@interface TestBannerViewController () <FWBannerViewDelegate>

@property (nonatomic, weak) UIView *previousView;

@end

@implementation TestBannerViewController

- (void)renderView
{
    [self renderCycleView1];
    [self renderCycleView2];
    [self renderCycleView3];
    [self renderCycleView4];
    [self renderCycleView5];
    [self renderCycleView6];
}

- (void)renderCycleView1
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.delegate = self;
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    cycleView.placeholderImage = [TestBundle imageNamed:@"test.gif"];
    [self.fwView addSubview:cycleView];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:10];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    
    NSMutableArray *imageUrls = [NSMutableArray array];
    [imageUrls addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls addObject:[TestBundle imageNamed:@"LoadingPlaceholder.gif"]];
    [imageUrls addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls addObject:@"not_found.jpg"];
    [imageUrls addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4"];
    
    self.previousView = cycleView;
}

- (void)renderCycleView2
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.delegate = self;
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    cycleView.placeholderImage = [TestBundle imageNamed:@"public_icon"];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleCustom;
    cycleView.pageDotViewClass = [FWDotView class];
    cycleView.pageControlDotSize = CGSizeMake(10, 1);
    cycleView.pageControlDotSpacing = 4;
    [self.fwView addSubview:cycleView];
    [cycleView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    // 看起来不会连在一起
    cycleView.contentViewInset = UIEdgeInsetsMake(0, 0, 0, 10);
    [cycleView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth + 10];
    
    NSMutableArray *imageUrls = [NSMutableArray array];
    [imageUrls addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    [imageUrls addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    [imageUrls addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    [imageUrls addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4"];
    
    self.previousView = cycleView;
}

- (void)renderCycleView3
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.contentViewInset = UIEdgeInsetsMake(0, 10, 0, 10);
    cycleView.contentViewCornerRadius = 5;
    cycleView.delegate = self;
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.placeholderImage = [TestBundle imageNamed:@"public_icon"];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleNone;
    [self.fwView addSubview:cycleView];
    [cycleView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    
    NSMutableArray *imageUrls2 = [NSMutableArray array];
    [imageUrls2 addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls2 addObject:[TestBundle imageNamed:@"public_picture"]];
    [imageUrls2 addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls2 addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls2 addObject:@"not_found.jpg"];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls2 copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4"];
    
    self.previousView = cycleView;
}

- (void)renderCycleView4
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.contentViewCornerRadius = 5;
    cycleView.delegate = self;
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.placeholderImage = [TestBundle imageNamed:@"public_icon"];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleNone;
    cycleView.itemPagingEnabled = YES;
    cycleView.itemSpacing = 10;
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    [self.fwView addSubview:cycleView];
    [cycleView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    
    NSMutableArray *imageUrls2 = [NSMutableArray array];
    [imageUrls2 addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls2 addObject:[TestBundle imageNamed:@"public_picture"]];
    [imageUrls2 addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls2 addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls2 addObject:@"not_found.jpg"];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls2 copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4"];
    
    self.previousView = cycleView;
}

- (void)renderCycleView5
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.contentViewCornerRadius = 5;
    cycleView.delegate = self;
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.placeholderImage = [TestBundle imageNamed:@"public_icon"];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleNone;
    cycleView.itemSpacing = 10;
    cycleView.itemPagingEnabled = YES;
    cycleView.itemSize = CGSizeMake(FWScreenWidth - 30, 100);
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    [self.fwView addSubview:cycleView];
    [cycleView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    
    NSMutableArray *imageUrls2 = [NSMutableArray array];
    [imageUrls2 addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls2 addObject:[TestBundle imageNamed:@"public_picture"]];
    [imageUrls2 addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls2 addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls2 addObject:@"not_found.jpg"];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls2 copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4"];
    
    self.previousView = cycleView;
}

- (void)renderCycleView6
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.contentViewCornerRadius = 5;
    cycleView.delegate = self;
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.placeholderImage = [TestBundle imageNamed:@"public_icon"];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleNone;
    cycleView.itemSpacing = 10;
    cycleView.itemPagingEnabled = YES;
    cycleView.itemPagingCenter = YES;
    cycleView.itemSize = CGSizeMake(FWScreenWidth - 40, 100);
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    [self.fwView addSubview:cycleView];
    [cycleView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    
    NSMutableArray *imageUrls2 = [NSMutableArray array];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls2 copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4"];
    
    self.previousView = cycleView;
}

#pragma mark - FWBannerViewDelegate

- (void)bannerView:(FWBannerView *)bannerView didSelectItemAtIndex:(NSInteger)index
{
    FWLogDebug(@"index: %@", @(index));
    
    TestWebViewController *viewController = [TestWebViewController new];
    viewController.requestUrl = @"http://kvm.wuyong.site/test.php";
    if (index % 2 == 0) {
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

@end
