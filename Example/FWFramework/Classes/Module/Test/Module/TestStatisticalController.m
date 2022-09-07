//
//  TestStatisticalController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestStatisticalController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestStatisticalCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation TestStatisticalCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *textLabel = [UILabel fw_labelWithFont:[UIFont fw_fontOfSize:15] textColor:[AppTheme textColor]];
        _textLabel = textLabel;
        [self.contentView addSubview:textLabel];
        textLabel.fw_layoutChain.center();
    }
    return self;
}

@end

@interface TestStatisticalController () <FWTableViewController, FWCollectionViewController>

FWPropertyWeak(UIView *, shieldView);
FWPropertyWeak(FWBannerView *, bannerView);
FWPropertyWeak(UIView *, testView);
FWPropertyWeak(UIButton *, testButton);
FWPropertyWeak(UISwitch *, testSwitch);
FWPropertyWeak(FWSegmentedControl *, segmentedControl);
FWPropertyWeak(FWTextTagCollectionView *, tagCollectionView);

@end

@implementation TestStatisticalController

+ (void)initialize
{
    FWStatisticalManager.sharedInstance.statisticalEnabled = YES;
}

- (void)setupTableView
{
    UIView *headerView = [UIView new];
    
    FWBannerView *bannerView = [FWBannerView new];
    _bannerView = bannerView;
    bannerView.autoScroll = YES;
    bannerView.autoScrollTimeInterval = 6;
    bannerView.placeholderImage = [UIImage fw_appIconImage];
    bannerView.itemDidScrollOperationBlock = ^(NSInteger currentIndex) {
        FWLogDebug(@"currentIndex: %@", @(currentIndex));
    };
    [headerView addSubview:bannerView];
    bannerView.fw_layoutChain.leftWithInset(10).topWithInset(50).rightWithInset(10).height(100);
    
    UIView *testView = [UIView new];
    _testView = testView;
    testView.backgroundColor = UIColor.fw_randomColor;
    [headerView addSubview:testView];
    testView.fw_layoutChain.width(100).height(30).centerX().topToViewBottomWithOffset(bannerView, 50);
    
    UILabel *testLabel = [UILabel new];
    testLabel.text = @"Banner";
    testLabel.textAlignment = NSTextAlignmentCenter;
    [testView addSubview:testLabel];
    testLabel.fw_layoutChain.edges();
    
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _testButton = testButton;
    [testButton setTitle:@"Button" forState:UIControlStateNormal];
    [testButton fw_setBackgroundColor:[UIColor fw_randomColor] forState:UIControlStateNormal];
    [headerView addSubview:testButton];
    testButton.fw_layoutChain.width(100).height(30).centerX().topToViewBottomWithOffset(testView, 50);
    
    UISwitch *testSwitch = [UISwitch new];
    _testSwitch = testSwitch;
    testSwitch.thumbTintColor = [UIColor fw_randomColor];
    testSwitch.onTintColor = testSwitch.thumbTintColor;
    [headerView addSubview:testSwitch];
    testSwitch.fw_layoutChain.centerX().topToViewBottomWithOffset(testButton, 50);
    
    FWSegmentedControl *segmentedControl = [FWSegmentedControl new];
    self.segmentedControl = segmentedControl;
    self.segmentedControl.backgroundColor = AppTheme.cellColor;
    self.segmentedControl.selectedSegmentIndex = 1;
    self.segmentedControl.selectionStyle = FWSegmentedControlSelectionStyleBox;
    self.segmentedControl.segmentEdgeInset = UIEdgeInsetsMake(0, 30, 0, 5);
    self.segmentedControl.selectionIndicatorEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.segmentedControl.segmentWidthStyle = FWSegmentedControlSegmentWidthStyleDynamic;
    self.segmentedControl.selectionIndicatorLocation = FWSegmentedControlSelectionIndicatorLocationBottom;
    self.segmentedControl.titleTextAttributes = @{NSFontAttributeName: [UIFont fw_fontOfSize:16], NSForegroundColorAttributeName: AppTheme.textColor};
    self.segmentedControl.selectedTitleTextAttributes = @{NSFontAttributeName: [UIFont fw_boldFontOfSize:18], NSForegroundColorAttributeName: AppTheme.textColor};
    [headerView addSubview:self.segmentedControl];
    segmentedControl.fw_layoutChain.leftWithInset(10).rightWithInset(10).topToViewBottomWithOffset(testSwitch, 50).height(50);
    
    FWTextTagCollectionView *tagCollectionView = [FWTextTagCollectionView new];
    _tagCollectionView = tagCollectionView;
    tagCollectionView.verticalSpacing = 10;
    tagCollectionView.horizontalSpacing = 10;
    [headerView addSubview:tagCollectionView];
    tagCollectionView.fw_layoutChain.leftWithInset(10).rightWithInset(10).topToViewBottomWithOffset(segmentedControl, 50).height(100).bottomWithInset(50);
    
    self.tableView.tableHeaderView = headerView;
    [headerView fw_autoLayoutSubviews];
}

- (void)setupTableLayout
{
    self.tableView.fw_layoutChain.edges();
}

- (UICollectionView *)collectionView
{
    UICollectionView *collectionView = objc_getAssociatedObject(self, _cmd);
    if (!collectionView) {
        collectionView = [[FWViewControllerManager sharedInstance] performIntercepter:_cmd withObject:self];
        objc_setAssociatedObject(self, _cmd, collectionView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return collectionView;
}

- (UICollectionViewLayout *)setupCollectionViewLayout
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake((FWScreenWidth - 10) / 2.f, 100);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    return layout;
}

- (void)setupCollectionView
{
    [self.collectionView registerClass:[TestStatisticalCell class] forCellWithReuseIdentifier:@"cell"];
}

- (void)setupCollectionLayout
{
    self.collectionView.fw_layoutChain.edges();
}

- (void)setupSubviews
{
    // 设置遮挡视图
    UIView *shieldView = [UIView new];
    self.shieldView = shieldView;
    shieldView.backgroundColor = [AppTheme tableColor];
    FWWeakifySelf();
    [shieldView fw_addTapGestureWithBlock:^(UITapGestureRecognizer *sender) {
        FWStrongifySelf();
        [self.shieldView removeFromSuperview];
        self.shieldView = nil;
        // 手工触发曝光计算
        self.view.hidden = self.view.hidden;
    }];
    [UIWindow.fw_mainWindow addSubview:shieldView];
    [shieldView fw_pinEdgesToSuperview];
    
    UILabel *shieldLabel = [UILabel new];
    shieldLabel.text = @"点击关闭";
    shieldLabel.textAlignment = NSTextAlignmentCenter;
    [shieldView addSubview:shieldLabel];
    shieldLabel.fw_layoutChain.edges();
    
    [self.testView fw_addTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.testView.backgroundColor = UIColor.fw_randomColor;
        [self.bannerView makeScrollViewScrollToIndex:0];
    }];
    
    [self.testButton fw_addTouchBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self.testButton fw_setBackgroundColor:UIColor.fw_randomColor forState:UIControlStateNormal];
    }];
    
    [self.testSwitch fw_addBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.testSwitch.thumbTintColor = UIColor.fw_randomColor;
        self.testSwitch.onTintColor = self.testSwitch.thumbTintColor;
    } forControlEvents:UIControlEventValueChanged];
    
    self.bannerView.clickItemOperationBlock = ^(NSInteger currentIndex) {
        FWStrongifySelf();
        [self clickHandler:currentIndex];
    };
    
    self.segmentedControl.indexChangeBlock = ^(NSUInteger index) {
        FWStrongifySelf();
        self.segmentedControl.selectionIndicatorBoxColor = UIColor.fw_randomColor;
    };
}

- (void)setupLayout
{
    self.collectionView.hidden = YES;
    FWWeakifySelf();
    [self fw_setRightBarItem:@(UIBarButtonSystemItemRefresh) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if (self.collectionView.hidden) {
            self.collectionView.hidden = NO;
            self.tableView.hidden = YES;
        } else {
            self.collectionView.hidden = YES;
            self.tableView.hidden = NO;
        }
    }];
    
    NSArray *imageUrls = @[@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg", [UIImage fw_appIconImage], @"http://kvm.wuyong.site/images/images/animation.png", @"http://littlesvr.ca/apng/images/SteamEngine.webp", @"not_found.jpg", @"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    self.bannerView.imageURLStringsGroup = imageUrls;
    NSArray *sectionTitles = @[@"Section0", @"Section1", @"Section2", @"Section3", @"Section4", @"Section5", @"Section6", @"Section7", @"Section8"];
    self.segmentedControl.sectionTitles = sectionTitles;
    [self.tagCollectionView addTags:@[@"标签0", @"标签1", @"标签2", @"标签3", @"标签4", @"标签5"]];
    [self.tagCollectionView removeTag:@"标签4"];
    [self.tagCollectionView removeTag:@"标签5"];
    [self.tagCollectionView addTags:@[@"标签4", @"标签5", @"标签6", @"标签7"]];
    
    [self renderData];
}

- (void)renderData
{
    FWWeakifySelf();
    [FWStatisticalManager sharedInstance].globalHandler = ^(FWStatisticalObject *object) {
        if (object.isExposure) {
            FWLogDebug(@"%@曝光通知: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@\nduration: %@\ntotalDuration: %@", NSStringFromClass(object.view.class), [NSString stringWithFormat:@"%@.%@", @(object.indexPath.section), @(object.indexPath.row)], @(object.triggerCount), object.name, object.object, object.userInfo, @(object.triggerDuration), @(object.totalDuration));
        } else {
            FWStrongifySelf();
            [self showToast:[NSString stringWithFormat:@"%@点击事件: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@", NSStringFromClass(object.view.class), [NSString stringWithFormat:@"%@.%@", @(object.indexPath.section), @(object.indexPath.row)], @(object.triggerCount), object.name, object.object, object.userInfo]];
        }
    };
    
    // Click
    self.testView.fw_statisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_view" object:@"view"];
    self.testButton.fw_statisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_button" object:@"button"];
    self.testSwitch.fw_statisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_switch" object:@"switch"];
    self.tableView.fw_statisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_tableView" object:@"table"];
    self.bannerView.fw_statisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_banner" object:@"banner"];
    self.segmentedControl.fw_statisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_segment" object:@"segment"];
    self.tagCollectionView.fw_statisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_tag" object:@"tag"];
    
    // Exposure
    self.testView.fw_statisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_view" object:@"view"];
    [self configShieldView:self.testView.fw_statisticalExposure];
    self.testButton.fw_statisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_button" object:@"button"];
    self.testButton.fw_statisticalExposure.triggerOnce = YES;
    [self configShieldView:self.testButton.fw_statisticalExposure];
    self.testSwitch.fw_statisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_switch" object:@"switch"];
    [self configShieldView:self.testSwitch.fw_statisticalExposure];
    self.tableView.fw_statisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_tableView" object:@"table"];
    [self configShieldView:self.tableView.fw_statisticalExposure];
    self.bannerView.fw_statisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_banner" object:@"banner"];
    [self configShieldView:self.bannerView.fw_statisticalExposure];
    self.segmentedControl.fw_statisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_segment" object:@"segment"];
    [self configShieldView:self.segmentedControl.fw_statisticalExposure];
    self.tagCollectionView.fw_statisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_tag" object:@"tag"];
    [self configShieldView:self.tagCollectionView.fw_statisticalExposure];
}

- (void)configShieldView:(FWStatisticalObject *)object
{
    FWWeakifySelf();
    // 动态设置，调用时判断
    object.shieldViewBlock = ^UIView * _Nullable{
        FWStrongifySelf();
        return self.shieldView;
    };
    // weak引用，固定设置
    // object.shieldView = self.shieldView;
}

- (void)showToast:(NSString *)toast
{
    [self fw_showMessageWithText:toast];
}

- (void)clickHandler:(NSInteger)index
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [FWRouter openURL:@"http://kvm.wuyong.site/test.php"];
    });
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@", @(indexPath.row)];
    cell.contentView.backgroundColor = UIColor.fw_randomColor;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.backgroundColor = UIColor.fw_randomColor;
    
    [self clickHandler:indexPath.row];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 50;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TestStatisticalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", @(indexPath.row)];
    cell.contentView.backgroundColor = UIColor.fw_randomColor;
    cell.fw_statisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_collectionView" object:@"cell"];
    cell.fw_statisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_collectionView" object:@"cell"];
    cell.fw_statisticalExposure.triggerOnce = YES;
    [self configShieldView:cell.fw_statisticalExposure];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = UIColor.fw_randomColor;
    
    [self clickHandler:indexPath.row];
}

@end
