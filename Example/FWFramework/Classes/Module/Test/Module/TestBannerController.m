//
//  TestBannerController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestBannerController.h"
@import FWFramework;

@interface TestBannerController () <FWViewController, FWBannerViewDelegate>

@property (nonatomic, weak) UIView *previousView;

@end

@implementation TestBannerController

- (void)setupSubviews
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
    cycleView.placeholderImage = [FWModuleBundle imageNamed:@"Loading.gif"];
    [self.view addSubview:cycleView];
    [cycleView fw_pinEdgeToSafeArea:NSLayoutAttributeTop withInset:10];
    [cycleView fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fw_setDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fw_setDimension:NSLayoutAttributeHeight toSize:100];
    
    NSMutableArray *imageUrls = [NSMutableArray array];
    [imageUrls addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls addObject:[FWModuleBundle imageNamed:@"Loading.gif"]];
    [imageUrls addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls addObject:@"not_found.jpg"];
    [imageUrls addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4", @"5", @"6"];
    
    self.previousView = cycleView;
}

- (void)renderCycleView2
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.delegate = self;
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    cycleView.placeholderImage = [UIImage fw_appIconImage];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleCustom;
    cycleView.pageDotViewClass = [FWDotView class];
    cycleView.pageControlDotSize = CGSizeMake(10, 1);
    cycleView.pageControlDotSpacing = 4;
    [self.view addSubview:cycleView];
    [cycleView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fw_setDimension:NSLayoutAttributeHeight toSize:100];
    // 看起来不会连在一起
    cycleView.contentViewInset = UIEdgeInsetsMake(0, 0, 0, 10);
    [cycleView fw_setDimension:NSLayoutAttributeWidth toSize:FWScreenWidth + 10];
    
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
    cycleView.placeholderImage = [UIImage fw_appIconImage];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleNone;
    [self.view addSubview:cycleView];
    [cycleView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fw_setDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fw_setDimension:NSLayoutAttributeHeight toSize:100];
    
    NSMutableArray *imageUrls2 = [NSMutableArray array];
    [imageUrls2 addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls2 addObject:[UIImage fw_appIconImage]];
    [imageUrls2 addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls2 addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls2 addObject:@"not_found.jpg"];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls2 copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4", @"5", @"6"];
    
    self.previousView = cycleView;
}

- (void)renderCycleView4
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.contentViewCornerRadius = 5;
    cycleView.delegate = self;
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.placeholderImage = [UIImage fw_appIconImage];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleNone;
    cycleView.itemPagingEnabled = YES;
    cycleView.itemSpacing = 10;
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    [self.view addSubview:cycleView];
    [cycleView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fw_setDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fw_setDimension:NSLayoutAttributeHeight toSize:100];
    
    NSMutableArray *imageUrls2 = [NSMutableArray array];
    [imageUrls2 addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls2 addObject:[UIImage fw_appIconImage]];
    [imageUrls2 addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls2 addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls2 addObject:@"not_found.jpg"];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls2 copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4", @"5", @"6"];
    
    self.previousView = cycleView;
}

- (void)renderCycleView5
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.contentViewCornerRadius = 5;
    cycleView.delegate = self;
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.placeholderImage = [UIImage fw_appIconImage];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleNone;
    cycleView.itemSpacing = 10;
    cycleView.itemPagingEnabled = YES;
    cycleView.itemSize = CGSizeMake(FWScreenWidth - 30, 100);
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    [self.view addSubview:cycleView];
    [cycleView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fw_setDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fw_setDimension:NSLayoutAttributeHeight toSize:100];
    
    NSMutableArray *imageUrls2 = [NSMutableArray array];
    [imageUrls2 addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls2 addObject:[UIImage fw_appIconImage]];
    [imageUrls2 addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [imageUrls2 addObject:@"http://littlesvr.ca/apng/images/SteamEngine.webp"];
    [imageUrls2 addObject:@"not_found.jpg"];
    [imageUrls2 addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    cycleView.imageURLStringsGroup = [imageUrls2 copy];
    cycleView.titlesGroup = @[@"1", @"2", @"3", @"4", @"5", @"6"];
    
    self.previousView = cycleView;
}

- (void)renderCycleView6
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.contentViewCornerRadius = 5;
    cycleView.delegate = self;
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.placeholderImage = [UIImage fw_appIconImage];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleNone;
    cycleView.itemSpacing = 10;
    cycleView.itemPagingEnabled = YES;
    cycleView.itemPagingCenter = YES;
    cycleView.itemSize = CGSizeMake(FWScreenWidth - 40, 100);
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 4;
    [self.view addSubview:cycleView];
    [cycleView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.previousView withOffset:10];
    [cycleView fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fw_setDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fw_setDimension:NSLayoutAttributeHeight toSize:100];
    
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
    [self fw_showMessageWithText:[NSString stringWithFormat:@"点击了: %@", @(index)]];
}

@end
