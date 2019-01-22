//
//  TestBannerViewController.m
//  Example
//
//  Created by wuyong on 2018/12/13.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestBannerViewController.h"
#import "DZNWebViewController.h"

@interface TestBannerViewController () <FWBannerViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) FWTextTagCollectionView *tagCollectionView;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) FWSegmentedControl *segmentedControl;

@end

@implementation TestBannerViewController

- (void)renderView
{
    FWBannerView *cycleView = [FWBannerView new];
    cycleView.delegate = self;
    cycleView.autoScroll = YES;
    cycleView.autoScrollTimeInterval = 6;
    cycleView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    cycleView.placeholderImage = [UIImage imageNamed:@"public_picture"];
    cycleView.pageControlStyle = FWBannerViewPageControlStyleCustom;
    cycleView.pageDotViewClass = [FWAnimatedDotView class];
    cycleView.pageControlDotSize = CGSizeMake(15, 15);
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
    
    CGSize activitySize = CGSizeMake(30, 30);
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityView fwSetIndicatorSize:activitySize];
    [activityView startAnimating];
    [self.view addSubview:activityView];
    [activityView fwAlignAxis:NSLayoutAttributeCenterX toView:self.view];
    [activityView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:cycleView withOffset:10];
    [activityView fwSetDimensionsToSize:activitySize];
    
    UILabel *textLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor appColorBlack] text:nil];
    textLabel.numberOfLines = 0;
    textLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:textLabel];
    [textLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    [textLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:activityView withOffset:10];
    
    NSMutableAttributedString *attrStr = [NSMutableAttributedString new];
    UIFont *attrFont = [UIFont fwLightSystemFontOfSize:16];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"细体16 " withFont:attrFont]];
    attrFont = [UIFont fwSystemFontOfSize:16];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"常规16 " withFont:attrFont]];
    attrFont = [UIFont fwBoldSystemFontOfSize:16];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"粗体16 " withFont:attrFont]];
    attrFont = [UIFont fwItalicSystemFontOfSize:16];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"斜体16 " withFont:attrFont]];
    attrFont = [[UIFont fwItalicSystemFontOfSize:16] fwBoldFont];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"粗斜体16 " withFont:attrFont]];
    
    attrFont = [UIFont fwSystemFontOfSize:16 weight:FWFontWeightLight];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"\n细体16 " withFont:attrFont]];
    attrFont = [UIFont fwSystemFontOfSize:16 weight:FWFontWeightNormal];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"常规16 " withFont:attrFont]];
    attrFont = [UIFont fwSystemFontOfSize:16 weight:FWFontWeightBold];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"粗体16 " withFont:attrFont]];
    attrFont = [UIFont fwSystemFontOfSize:16 weight:FWFontWeightNormal italic:YES];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"斜体16 " withFont:attrFont]];
    attrFont = [[[[[UIFont fwSystemFontOfSize:16 weight:FWFontWeightBold italic:YES] fwNormalFont] fwBoldFont] fwRegularFont] fwItalicFont];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"粗斜体16 " withFont:attrFont]];
    textLabel.attributedText = attrStr;
    
    FWAttributedLabel *label = [FWAttributedLabel new];
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = [UIColor fwColorWithHex:0x111111];
    label.textAlignment = kCTTextAlignmentCenter;
    [self.view addSubview:label];
    [label fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [label fwPinEdgeToSuperview:NSLayoutAttributeRight];
    [label fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textLabel withOffset:10];
    [label fwSetDimension:NSLayoutAttributeHeight toSize:30];
    
    [label setText:@"文本 "];
    UIView *labelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    labelView.backgroundColor = [UIColor redColor];
    [labelView fwSetCornerRadius:15];
    [label appendView:labelView margin:UIEdgeInsetsZero alignment:FWAttributedAlignmentCenter];
    [label appendText:@" "];
    UIImage *image = [UIImage fwImageWithColor:[UIColor blueColor] size:CGSizeMake(30, 30)];
    [label appendImage:image maxSize:image.size margin:UIEdgeInsetsZero alignment:FWAttributedAlignmentCenter];
    [label appendText:@" 结束"];
    
    FWTextTagCollectionView *tagCollectionView = [FWTextTagCollectionView new];
    _tagCollectionView = tagCollectionView;
    tagCollectionView.verticalSpacing = 5;
    tagCollectionView.horizontalSpacing = 5;
    [self.view addSubview:tagCollectionView];
    [tagCollectionView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:10];
    [tagCollectionView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:10];
    [tagCollectionView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:label withOffset:10];
    
    [self.tagCollectionView removeAllTags];
    NSArray *testTags = @[@"80减12", @"首单减15", @"在线支付", @"支持自提", @"26减3", @"80减12", @"首单减15", @"在线支付", @"支持自提", @"26减3"];
    for (NSString *tagName in testTags) {
        [self.tagCollectionView addTag:tagName withConfig:self.textTagConfig];
    }
    
    FWMarqueeLabel *marqueeLabel = [FWMarqueeLabel fwLabelWithFont:FWFontNormal(16) textColor:[UIColor blackColor] text:@"FWMarqueeLabel 会在添加到界面上后，并且文字超过 label 宽度时自动滚动"];
    [self.view addSubview:marqueeLabel];
    [marqueeLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:10];
    [marqueeLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:10];
    [marqueeLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.tagCollectionView withOffset:10];
    [marqueeLabel fwSetDimension:NSLayoutAttributeHeight toSize:20];
    // 自动布局需调用此方法初始化frame
    [marqueeLabel setNeedsLayout];
    [marqueeLabel layoutIfNeeded];
    
    self.segmentedControl = [FWSegmentedControl new];
    self.segmentedControl.sectionTitles = @[@"Worldwide Text", @"Local Long Text", @"Headlines Long Text"];
    self.segmentedControl.selectedSegmentIndex = 1;
    self.segmentedControl.selectionStyle = FWSegmentedControlSelectionStyleBox;
    self.segmentedControl.selectionIndicatorLocation = FWSegmentedControlSelectionIndicatorLocationDown;
    [self.view addSubview:self.segmentedControl];
    [self.segmentedControl fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [self.segmentedControl fwPinEdgeToSuperview:NSLayoutAttributeRight];
    [self.segmentedControl fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:marqueeLabel withOffset:10];
    [self.segmentedControl fwSetDimension:NSLayoutAttributeHeight toSize:50];
    FWWeakifySelf();
    self.segmentedControl.indexChangeBlock = ^(NSInteger index) {
        FWStrongifySelf();
        [self.scrollView scrollRectToVisible:CGRectMake(FWScreenWidth * index, 0, FWScreenWidth, 100) animated:YES];
    };
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.contentSize = CGSizeMake(FWScreenWidth * 3, 100);
    self.scrollView.delegate = self;
    [self.scrollView scrollRectToVisible:CGRectMake(FWScreenWidth, 0, FWScreenWidth, 100) animated:NO];
    [self.view addSubview:self.scrollView];
    [self.scrollView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [self.scrollView fwPinEdgeToSuperview:NSLayoutAttributeRight];
    [self.scrollView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.segmentedControl];
    [self.scrollView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 100)];
    label1.text = @"Worldwide Text";
    [self.scrollView addSubview:label1];
    
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(FWScreenWidth, 0, FWScreenWidth, 100)];
    label2.text = @"Local Long Text";
    [self.scrollView addSubview:label2];
    
    UILabel *label3 = [[UILabel alloc] initWithFrame:CGRectMake(FWScreenWidth * 2, 0, FWScreenWidth, 100)];
    label3.text = @"Headlines Long Text";
    [self.scrollView addSubview:label3];
}

- (FWTextTagConfig *)textTagConfig
{
    FWTextTagConfig *tagConfig = [[FWTextTagConfig alloc] init];
    tagConfig.textFont = [UIFont systemFontOfSize:10];
    tagConfig.textColor = [UIColor blackColor];
    tagConfig.selectedTextColor = [UIColor blackColor];
    tagConfig.backgroundColor = [UIColor appColorBg];
    tagConfig.selectedBackgroundColor = [UIColor appColorBg];
    tagConfig.cornerRadius = 2;
    tagConfig.selectedCornerRadius = 2;
    tagConfig.borderWidth = 1;
    tagConfig.selectedBorderWidth = 1;
    tagConfig.borderColor = [UIColor appColorHex:0xF3B2AF];
    tagConfig.selectedBorderColor = [UIColor appColorHex:0xF3B2AF];
    tagConfig.extraSpace = CGSizeMake(10, 6);
    tagConfig.enableGradientBackground = NO;
    return tagConfig;
}

#pragma mark - SDCycleScrollViewDelegate

- (void)bannerView:(FWBannerView *)bannerView didSelectItemAtIndex:(NSInteger)index
{
    FWLogDebug(@"index: %@", @(index));
    
    DZNWebViewController *viewController = [[DZNWebViewController alloc] initWithURL:[NSURL URLWithString:@"https://www.baidu.com"]];
    [self fwOpenViewController:viewController animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    NSInteger page = scrollView.contentOffset.x / pageWidth;
    
    [self.segmentedControl setSelectedSegmentIndex:page animated:YES];
}

@end
