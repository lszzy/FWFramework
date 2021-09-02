//
//  TestSegmentViewController.m
//  Example
//
//  Created by wuyong on 2018/12/13.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestSegmentViewController.h"

@interface TestSegmentViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) FWTextTagCollectionView *tagCollectionView;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) FWSegmentedControl *segmentedControl;

@property (nonatomic, strong) UIImageView *gifImageView;

@end

@implementation TestSegmentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    FWWeakifySelf();
    [self fwSetRightBarItem:@"Save" block:^(id sender) {
        FWStrongifySelf();
        [self.gifImageView.image fwSaveImageWithBlock:nil];
    }];
}

- (void)renderView
{
    UIImageView *imageView = [UIImageView new];
    _gifImageView = imageView;
    imageView.backgroundColor = [Theme cellColor];
    [self.fwView addSubview:imageView];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.masksToBounds = YES;
    [imageView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
    [imageView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    imageView.userInteractionEnabled = YES;
    
    FWProgressView *progressView = [FWProgressView new];
    [imageView addSubview:progressView];
    [progressView fwSetDimensionsToSize:CGSizeMake(40, 40)];
    [progressView fwAlignCenterToSuperview];
    
    BOOL useTimestamp = YES;
    NSString *timestampStr = useTimestamp ? [NSString stringWithFormat:@"?t=%@", @([NSDate fwCurrentTime])] : @"";
    NSString *gifImageUrl = [NSString stringWithFormat:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif%@", timestampStr];
    progressView.progress = 0;
    progressView.hidden = NO;
    [imageView fwSetImageWithURL:gifImageUrl placeholderImage:nil options:0 completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
        progressView.hidden = YES;
        if (image) {
            imageView.image = image;
        }
    } progress:^(double progress) {
        progressView.progress = progress;
    }];
    
    CGSize activitySize = CGSizeMake(30, 30);
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.color = Theme.textColor;
    activityView.size = activitySize;
    [activityView startAnimating];
    [self.fwView addSubview:activityView];
    [activityView fwAlignAxis:NSLayoutAttributeCenterX toView:self.view];
    [activityView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:imageView withOffset:10];
    [activityView fwSetDimensionsToSize:activitySize];
    
    UILabel *textLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:nil];
    textLabel.numberOfLines = 0;
    textLabel.textAlignment = NSTextAlignmentCenter;
    [self.fwView addSubview:textLabel];
    [textLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    [textLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:activityView withOffset:10];
    
    NSMutableAttributedString *attrStr = [NSMutableAttributedString new];
    UIFont *attrFont = FWFontLight(16);
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"细体16 " withFont:attrFont]];
    attrFont = FWFontRegular(16);
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"常规16 " withFont:attrFont]];
    attrFont = FWFontBold(16);
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"粗体16 " withFont:attrFont]];
    attrFont = FWFontItalic(16);
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"斜体16 " withFont:attrFont]];
    attrFont = [FWFontItalic(16) fwBoldFont];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"粗斜体16 " withFont:attrFont]];
    
    attrFont = [UIFont fwFontOfSize:16 weight:UIFontWeightLight];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"\n细体16 " withFont:attrFont]];
    attrFont = [UIFont fwFontOfSize:16 weight:UIFontWeightRegular];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"常规16 " withFont:attrFont]];
    attrFont = [UIFont fwFontOfSize:16 weight:UIFontWeightBold];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"粗体16 " withFont:attrFont]];
    attrFont = [[UIFont fwFontOfSize:16 weight:UIFontWeightRegular] fwItalicFont];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"斜体16 " withFont:attrFont]];
    attrFont = [[[[[[UIFont fwFontOfSize:16 weight:UIFontWeightBold] fwItalicFont] fwNonBoldFont] fwBoldFont] fwNonItalicFont] fwItalicFont];
    [attrStr appendAttributedString:[NSAttributedString fwAttributedString:@"粗斜体16 " withFont:attrFont]];
    textLabel.attributedText = attrStr;
    
    FWAttributedLabel *label = [FWAttributedLabel new];
    label.backgroundColor = Theme.cellColor;
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = [Theme textColor];
    label.textAlignment = kCTTextAlignmentCenter;
    [self.fwView addSubview:label];
    [label fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [label fwPinEdgeToSuperview:NSLayoutAttributeRight];
    [label fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textLabel withOffset:10];
    [label fwSetDimension:NSLayoutAttributeHeight toSize:30];
    
    [label appendText:@"文本 "];
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
    [self.fwView addSubview:tagCollectionView];
    [tagCollectionView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:10];
    [tagCollectionView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:10];
    [tagCollectionView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:label withOffset:10];
    
    [self.tagCollectionView removeAllTags];
    NSArray *testTags = @[@"80减12", @"首单减15", @"在线支付", @"支持自提", @"26减3", @"80减12", @"首单减15", @"在线支付", @"支持自提", @"26减3"];
    for (NSString *tagName in testTags) {
        [self.tagCollectionView addTag:tagName withConfig:self.textTagConfig];
    }
    
    FWMarqueeLabel *marqueeLabel = [FWMarqueeLabel fwLabelWithFont:FWFontRegular(16) textColor:[Theme textColor] text:@"FWMarqueeLabel 会在添加到界面上后，并且文字超过 label 宽度时自动滚动"];
    [self.fwView addSubview:marqueeLabel];
    [marqueeLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:10];
    [marqueeLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:10];
    [marqueeLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.tagCollectionView withOffset:10];
    [marqueeLabel fwSetDimension:NSLayoutAttributeHeight toSize:20];
    // 自动布局需调用此方法初始化frame
    [marqueeLabel setNeedsLayout];
    [marqueeLabel layoutIfNeeded];
    
    NSArray *sectionTitles = @[@"菜单一", @"菜单二", @"长的菜单三", @"菜单四", @"菜单五", @"菜单六"];
    NSArray *sectionContents = @[@"我是内容一", @"我是内容二", @"我是长的内容三", @"我是内容四", @"我是内容五", @"我是内容六"];
    self.segmentedControl = [[FWSegmentedControl alloc] initWithSectionTitles:@[]];
    self.segmentedControl.backgroundColor = Theme.cellColor;
    self.segmentedControl.selectionStyle = FWSegmentedControlSelectionStyleTextWidthStripe;
    self.segmentedControl.segmentEdgeInset = UIEdgeInsetsMake(0, 10, 0, 10);
    self.segmentedControl.segmentWidthStyle = FWSegmentedControlSegmentWidthStyleDynamic;
    self.segmentedControl.selectionIndicatorLocation = FWSegmentedControlSelectionIndicatorLocationBottom;
    self.segmentedControl.selectionIndicatorCornerRadius = 2.5f;
    self.segmentedControl.titleTextAttributes = @{NSFontAttributeName: [UIFont fwFontOfSize:16], NSForegroundColorAttributeName: Theme.textColor};
    self.segmentedControl.selectedTitleTextAttributes = @{NSFontAttributeName: [UIFont fwBoldFontOfSize:16], NSForegroundColorAttributeName: Theme.textColor};
    [self.fwView addSubview:self.segmentedControl];
    [self.segmentedControl fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [self.segmentedControl fwPinEdgeToSuperview:NSLayoutAttributeRight];
    [self.segmentedControl fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:marqueeLabel withOffset:10];
    [self.segmentedControl fwSetDimension:NSLayoutAttributeHeight toSize:50];
    self.segmentedControl.sectionTitles = sectionTitles;
    self.segmentedControl.selectedSegmentIndex = 5;
    FWWeakifySelf();
    self.segmentedControl.indexChangeBlock = ^(NSUInteger index) {
        FWStrongifySelf();
        [self.scrollView scrollRectToVisible:CGRectMake(FWScreenWidth * index, 0, FWScreenWidth, 100) animated:YES];
    };
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.contentSize = CGSizeMake(FWScreenWidth * sectionTitles.count, 100);
    self.scrollView.delegate = self;
    [self.scrollView scrollRectToVisible:CGRectMake(FWScreenWidth * self.segmentedControl.selectedSegmentIndex, 0, FWScreenWidth, 100) animated:NO];
    [self.fwView addSubview:self.scrollView];
    [self.scrollView fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [self.scrollView fwPinEdgeToSuperview:NSLayoutAttributeRight];
    [self.scrollView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.segmentedControl];
    [self.scrollView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    
    for (NSInteger i = 0; i < sectionContents.count; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(FWScreenWidth * i, 0, FWScreenWidth, 100)];
        label.text = sectionContents[i];
        label.numberOfLines = 0;
        [self.scrollView addSubview:label];
    }
}

- (FWTextTagConfig *)textTagConfig
{
    FWTextTagConfig *tagConfig = [[FWTextTagConfig alloc] init];
    tagConfig.textFont = [UIFont systemFontOfSize:10];
    tagConfig.textColor = [Theme textColor];
    tagConfig.selectedTextColor = [Theme textColor];
    tagConfig.backgroundColor = [Theme cellColor];
    tagConfig.selectedBackgroundColor = [Theme cellColor];
    tagConfig.cornerRadius = 2;
    tagConfig.selectedCornerRadius = 2;
    tagConfig.borderWidth = 1;
    tagConfig.selectedBorderWidth = 1;
    tagConfig.borderColor = [UIColor fwColorWithHex:0xF3B2AF];
    tagConfig.selectedBorderColor = [UIColor fwColorWithHex:0xF3B2AF];
    tagConfig.extraSpace = CGSizeMake(10, 6);
    tagConfig.enableGradientBackground = NO;
    return tagConfig;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    NSInteger page = scrollView.contentOffset.x / pageWidth;
    
    [self.segmentedControl setSelectedSegmentIndex:page animated:YES];
}

@end
