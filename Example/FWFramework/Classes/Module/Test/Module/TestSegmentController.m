//
//  TestSegmentController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestSegmentController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestSegmentController () <FWViewController, UIScrollViewDelegate>

@property (nonatomic, strong) FWTextTagCollectionView *tagCollectionView;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) FWSegmentedControl *segmentedControl;

@property (nonatomic, strong) UIImageView *gifImageView;

@end

@implementation TestSegmentController

- (void)viewDidLoad
{
    [super viewDidLoad];
    FWWeakifySelf();
    [self fw_setRightBarItem:@"Save" block:^(id sender) {
        FWStrongifySelf();
        [self.gifImageView.image fw_saveImageWithCompletion:nil];
    }];
}

- (void)setupSubviews
{
    UIImageView *imageView = [UIImageView new];
    _gifImageView = imageView;
    imageView.backgroundColor = [AppTheme cellColor];
    [self.view addSubview:imageView];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.masksToBounds = YES;
    [imageView fw_pinEdgesToSafeAreaWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
    [imageView fw_setDimension:NSLayoutAttributeHeight toSize:100];
    imageView.userInteractionEnabled = YES;
    
    FWProgressView *progressView = [FWProgressView new];
    [imageView addSubview:progressView];
    [progressView fw_setDimensionsToSize:CGSizeMake(40, 40)];
    [progressView fw_alignCenterToSuperview];
    
    NSString *gifImageUrl = @"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif";
    progressView.progress = 0;
    progressView.hidden = NO;
    FWWeakifySelf();
    [imageView fw_setImageWithURL:gifImageUrl placeholderImage:nil options:FWWebImageOptionIgnoreCache context:nil completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
        FWStrongifySelf();
        progressView.hidden = YES;
        if (image) {
            self.gifImageView.image = image;
        }
    } progress:^(double progress) {
        progressView.progress = progress;
    }];
    
    CGSize activitySize = CGSizeMake(30, 30);
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.color = AppTheme.textColor;
    activityView.size = activitySize;
    [activityView startAnimating];
    [self.view addSubview:activityView];
    [activityView fw_alignAxis:NSLayoutAttributeCenterX toView:self.view];
    [activityView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:imageView withOffset:10];
    [activityView fw_setDimensionsToSize:activitySize];
    
    UILabel *textLabel = [UILabel fw_labelWithFont:[UIFont fw_fontOfSize:15] textColor:[AppTheme textColor]];
    textLabel.numberOfLines = 0;
    textLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:textLabel];
    [textLabel fw_alignAxisToSuperview:NSLayoutAttributeCenterX];
    [textLabel fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:activityView withOffset:10];
    
    NSMutableAttributedString *attrStr = [NSMutableAttributedString new];
    UIFont *attrFont = FWFontLight(16);
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"细体16 " withFont:attrFont]];
    attrFont = FWFontRegular(16);
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"常规16 " withFont:attrFont]];
    attrFont = FWFontBold(16);
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"粗体16 " withFont:attrFont]];
    attrFont = [UIFont italicSystemFontOfSize:16];
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"斜体16 " withFont:attrFont]];
    attrFont = [[UIFont italicSystemFontOfSize:16] fw_boldFont];
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"粗斜体16 " withFont:attrFont]];
    
    attrFont = [UIFont fw_fontOfSize:16 weight:UIFontWeightLight];
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"\n细体16 " withFont:attrFont]];
    attrFont = [UIFont fw_fontOfSize:16 weight:UIFontWeightRegular];
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"常规16 " withFont:attrFont]];
    attrFont = [UIFont fw_fontOfSize:16 weight:UIFontWeightBold];
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"粗体16 " withFont:attrFont]];
    attrFont = [[UIFont fw_fontOfSize:16 weight:UIFontWeightRegular] fw_italicFont];
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"斜体16 " withFont:attrFont]];
    attrFont = [[[[[[UIFont fw_fontOfSize:16 weight:UIFontWeightBold] fw_italicFont] fw_nonBoldFont] fw_boldFont] fw_nonItalicFont] fw_italicFont];
    [attrStr appendAttributedString:[NSAttributedString fw_attributedString:@"粗斜体16 " withFont:attrFont]];
    textLabel.attributedText = attrStr;
    
    FWAttributedLabel *label = [FWAttributedLabel new];
    label.backgroundColor = AppTheme.cellColor;
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = [AppTheme textColor];
    label.textAlignment = kCTTextAlignmentCenter;
    [self.view addSubview:label];
    [label fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
    [label fw_pinEdgeToSuperview:NSLayoutAttributeRight];
    [label fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textLabel withOffset:10];
    [label fw_setDimension:NSLayoutAttributeHeight toSize:30];
    
    [label appendText:@"文本 "];
    UIView *labelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    labelView.backgroundColor = [UIColor redColor];
    [labelView fw_setCornerRadius:15];
    [label appendView:labelView margin:UIEdgeInsetsZero alignment:FWAttributedAlignmentCenter];
    [label appendText:@" "];
    UIImage *image = [UIImage fw_imageWithColor:[UIColor blueColor] size:CGSizeMake(30, 30)];
    [label appendImage:image maxSize:image.size margin:UIEdgeInsetsZero alignment:FWAttributedAlignmentCenter];
    [label appendText:@" 结束"];
    
    FWTextTagCollectionView *tagCollectionView = [FWTextTagCollectionView new];
    _tagCollectionView = tagCollectionView;
    tagCollectionView.verticalSpacing = 5;
    tagCollectionView.horizontalSpacing = 5;
    [self.view addSubview:tagCollectionView];
    [tagCollectionView fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:10];
    [tagCollectionView fw_pinEdgeToSuperview:NSLayoutAttributeRight withInset:10];
    [tagCollectionView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:label withOffset:10];
    
    [self.tagCollectionView removeAllTags];
    NSArray *testTags = @[@"80减12", @"首单减15", @"在线支付", @"支持自提", @"26减3", @"80减12", @"首单减15", @"在线支付", @"支持自提", @"26减3"];
    for (NSString *tagName in testTags) {
        [self.tagCollectionView addTag:tagName withConfig:self.textTagConfig];
    }
    
    FWMarqueeLabel *marqueeLabel = [FWMarqueeLabel fw_labelWithFont:FWFontRegular(16) textColor:[AppTheme textColor] text:@"FWMarqueeLabel 会在添加到界面上后，并且文字超过 label 宽度时自动滚动"];
    [self.view addSubview:marqueeLabel];
    [marqueeLabel fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:10];
    [marqueeLabel fw_pinEdgeToSuperview:NSLayoutAttributeRight withInset:10];
    [marqueeLabel fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.tagCollectionView withOffset:10];
    [marqueeLabel fw_setDimension:NSLayoutAttributeHeight toSize:20];
    // 自动布局需调用此方法初始化frame
    [marqueeLabel setNeedsLayout];
    [marqueeLabel layoutIfNeeded];
    
    NSArray *sectionTitles = @[@"菜单一", @"菜单二", @"长的菜单三", @"菜单四", @"菜单五", @"菜单六"];
    NSArray *sectionContents = @[@"我是内容一", @"我是内容二", @"我是长的内容三", @"我是内容四", @"我是内容五", @"我是内容六"];
    self.segmentedControl = [[FWSegmentedControl alloc] initWithSectionTitles:@[]];
    self.segmentedControl.backgroundColor = AppTheme.cellColor;
    self.segmentedControl.selectionStyle = FWSegmentedControlSelectionStyleTextWidthStripe;
    self.segmentedControl.segmentEdgeInset = UIEdgeInsetsMake(0, 10, 0, 10);
    self.segmentedControl.segmentWidthStyle = FWSegmentedControlSegmentWidthStyleDynamic;
    self.segmentedControl.selectionIndicatorLocation = FWSegmentedControlSelectionIndicatorLocationBottom;
    self.segmentedControl.selectionIndicatorCornerRadius = 2.5f;
    self.segmentedControl.titleTextAttributes = @{NSFontAttributeName: [UIFont fw_fontOfSize:16], NSForegroundColorAttributeName: AppTheme.textColor};
    self.segmentedControl.selectedTitleTextAttributes = @{NSFontAttributeName: [UIFont fw_boldFontOfSize:16], NSForegroundColorAttributeName: AppTheme.textColor};
    [self.view addSubview:self.segmentedControl];
    [self.segmentedControl fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
    [self.segmentedControl fw_pinEdgeToSuperview:NSLayoutAttributeRight];
    [self.segmentedControl fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:marqueeLabel withOffset:10];
    [self.segmentedControl fw_setDimension:NSLayoutAttributeHeight toSize:50];
    self.segmentedControl.sectionTitles = sectionTitles;
    self.segmentedControl.selectedSegmentIndex = 5;
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
    [self.view addSubview:self.scrollView];
    [self.scrollView fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
    [self.scrollView fw_pinEdgeToSuperview:NSLayoutAttributeRight];
    [self.scrollView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.segmentedControl];
    [self.scrollView fw_setDimension:NSLayoutAttributeHeight toSize:100];
    
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
    tagConfig.textColor = [AppTheme textColor];
    tagConfig.selectedTextColor = [AppTheme textColor];
    tagConfig.backgroundColor = [AppTheme cellColor];
    tagConfig.selectedBackgroundColor = [AppTheme cellColor];
    tagConfig.cornerRadius = 2;
    tagConfig.selectedCornerRadius = 2;
    tagConfig.borderWidth = 1;
    tagConfig.selectedBorderWidth = 1;
    tagConfig.borderColor = [UIColor fw_colorWithHex:0xF3B2AF];
    tagConfig.selectedBorderColor = [UIColor fw_colorWithHex:0xF3B2AF];
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
