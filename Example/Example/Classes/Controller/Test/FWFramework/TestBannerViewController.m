//
//  TestBannerViewController.m
//  Example
//
//  Created by wuyong on 2018/12/13.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestBannerViewController.h"
#import "M80AttributedLabel.h"

@interface TestBannerViewController () <FWBannerViewDelegate>

@property (nonatomic, strong) FWTextTagCollectionView *tagCollectionView;

@end

@implementation TestBannerViewController

- (void)renderView
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 6;
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.placeholderImage = [UIImage imageNamed:@"public_picture"];
    cycleView.pageControlDotSize = CGSizeMake(6, 6);
    cycleView.pageDotColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    cycleView.currentPageDotColor = [UIColor whiteColor];
    [self.view addSubview:cycleView];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeTop];
    [cycleView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [cycleView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth];
    [cycleView fwSetDimension:NSLayoutAttributeHeight toSize:135];
    
    NSMutableArray *imageUrls = [NSMutableArray array];
    [imageUrls addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls addObject:@"not_exist.jpg"];
    [imageUrls addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    cycleView.imageURLStringsGroup = [imageUrls copy];
    
    M80AttributedLabel *label = [M80AttributedLabel new];
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = [UIColor fwColorWithHex:0x111111];
    label.textAlignment = kCTTextAlignmentCenter;
    [self.view addSubview:label];
    [label fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [label fwPinEdgeToSuperview:NSLayoutAttributeRight];
    [label fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:cycleView withOffset:10];
    [label fwSetDimension:NSLayoutAttributeHeight toSize:30];
    
    [label setText:@"文本 "];
    UIView *labelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    labelView.backgroundColor = [UIColor redColor];
    [labelView fwSetCornerRadius:15];
    [label appendView:labelView margin:UIEdgeInsetsZero alignment:M80ImageAlignmentCenter];
    [label appendText:@" "];
    UIImage *image = [UIImage fwImageWithColor:[UIColor blueColor] size:CGSizeMake(30, 30)];
    [label appendImage:image maxSize:image.size margin:UIEdgeInsetsZero alignment:M80ImageAlignmentCenter];
    [label appendText:@" 结束"];
    
    FWTextTagCollectionView *tagCollectionView = [FWTextTagCollectionView new];
    _tagCollectionView = tagCollectionView;
    tagCollectionView.verticalSpacing = 5;
    tagCollectionView.horizontalSpacing = 5;
    tagCollectionView.contentInset = UIEdgeInsetsZero;
    [self.view addSubview:tagCollectionView];
    [tagCollectionView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:10];
    [tagCollectionView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:10];
    [tagCollectionView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:label withOffset:10];
    
    [self.tagCollectionView removeAllTags];
    NSArray *testTags = @[@"80减12", @"首单减15", @"在线支付", @"支持自提", @"26减3", @"80减12", @"首单减15", @"在线支付", @"支持自提", @"26减3"];
    for (NSString *tagName in testTags) {
        [self.tagCollectionView addTag:tagName withConfig:self.textTagConfig];
    }
}

- (FWTextTagConfig *)textTagConfig
{
    FWTextTagConfig *tagConfig = [[FWTextTagConfig alloc] init];
    tagConfig.tagTextFont = [UIFont systemFontOfSize:10];
    tagConfig.tagTextColor = [UIColor blackColor];
    tagConfig.tagSelectedTextColor = [UIColor blackColor];
    tagConfig.tagBackgroundColor = [UIColor appColorBg];
    tagConfig.tagSelectedBackgroundColor = [UIColor appColorBg];
    tagConfig.tagCornerRadius = 2;
    tagConfig.tagSelectedCornerRadius = 2;
    tagConfig.tagBorderWidth = 1;
    tagConfig.tagSelectedBorderWidth = 1;
    tagConfig.tagBorderColor = [UIColor appColorHex:0xF3B2AF];
    tagConfig.tagSelectedBorderColor = [UIColor appColorHex:0xF3B2AF];
    tagConfig.tagExtraSpace = CGSizeMake(10, 6);
    tagConfig.tagShouldUseGradientBackgrounds = NO;
    return tagConfig;
}

#pragma mark - SDCycleScrollViewDelegate

- (void)bannerView:(FWBannerView *)bannerView didSelectItemAtIndex:(NSInteger)index
{
    FWLogDebug(@"index: %@", index);
}

@end
