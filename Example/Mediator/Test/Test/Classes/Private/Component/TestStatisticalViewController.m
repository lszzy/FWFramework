//
//  TestStatisticalViewController.m
//  Example
//
//  Created by wuyong on 2020/1/16.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestStatisticalViewController.h"
#import "TestWebViewController.h"

@interface TestStatisticalCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation TestStatisticalCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *textLabel = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:[Theme textColor] text:nil];
        _textLabel = textLabel;
        [self.contentView addSubview:textLabel];
        textLabel.fwLayoutChain.center();
    }
    return self;
}

@end

@interface TestStatisticalViewController () <FWTableViewController, FWCollectionViewController>

FWPropertyWeak(UIView *, shieldView);
FWPropertyWeak(FWBannerView *, bannerView);
FWPropertyWeak(UIView *, testView);
FWPropertyWeak(UIButton *, testButton);
FWPropertyWeak(UISwitch *, testSwitch);
FWPropertyWeak(FWSegmentedControl *, segmentedControl);
FWPropertyWeak(FWTextTagCollectionView *, tagCollectionView);

@end

@implementation TestStatisticalViewController

- (void)renderTableView
{
    UIView *headerView = [UIView new];
    
    FWBannerView *bannerView = [FWBannerView new];
    _bannerView = bannerView;
    bannerView.autoScroll = YES;
    bannerView.autoScrollTimeInterval = 6;
    bannerView.placeholderImage = [TestBundle imageNamed:@"public_icon"];
    [headerView addSubview:bannerView];
    bannerView.fwLayoutChain.leftWithInset(10).topWithInset(50).rightWithInset(10).height(100);
    
    UIView *testView = [UIView fwAutoLayoutView];
    _testView = testView;
    testView.backgroundColor = [UIColor fwRandomColor];
    [headerView addSubview:testView];
    testView.fwLayoutChain.width(100).height(30).centerX().topToBottomOfViewWithOffset(bannerView, 50);
    
    UILabel *testLabel = [UILabel fwAutoLayoutView];
    testLabel.text = @"Banner";
    testLabel.textAlignment = NSTextAlignmentCenter;
    [testView addSubview:testLabel];
    testLabel.fwLayoutChain.edges();
    
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _testButton = testButton;
    [testButton setTitle:@"Button" forState:UIControlStateNormal];
    [testButton fwSetBackgroundColor:[UIColor fwRandomColor] forState:UIControlStateNormal];
    [headerView addSubview:testButton];
    testButton.fwLayoutChain.width(100).height(30).centerX().topToBottomOfViewWithOffset(testView, 50);
    
    UISwitch *testSwitch = [UISwitch new];
    _testSwitch = testSwitch;
    testSwitch.thumbTintColor = [UIColor fwRandomColor];
    testSwitch.onTintColor = testSwitch.thumbTintColor;
    [headerView addSubview:testSwitch];
    testSwitch.fwLayoutChain.centerX().topToBottomOfViewWithOffset(testButton, 50);
    
    FWSegmentedControl *segmentedControl = [FWSegmentedControl new];
    self.segmentedControl = segmentedControl;
    self.segmentedControl.backgroundColor = Theme.cellColor;
    self.segmentedControl.selectedSegmentIndex = 1;
    self.segmentedControl.selectionStyle = FWSegmentedControlSelectionStyleBox;
    self.segmentedControl.segmentEdgeInset = UIEdgeInsetsMake(0, 30, 0, 5);
    self.segmentedControl.selectionIndicatorEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.segmentedControl.segmentWidthStyle = FWSegmentedControlSegmentWidthStyleDynamic;
    self.segmentedControl.selectionIndicatorLocation = FWSegmentedControlSelectionIndicatorLocationBottom;
    self.segmentedControl.titleTextAttributes = @{NSFontAttributeName: [UIFont fwFontOfSize:16], NSForegroundColorAttributeName: Theme.textColor};
    self.segmentedControl.selectedTitleTextAttributes = @{NSFontAttributeName: [UIFont fwBoldFontOfSize:18], NSForegroundColorAttributeName: Theme.textColor};
    [headerView addSubview:self.segmentedControl];
    segmentedControl.fwLayoutChain.leftWithInset(10).rightWithInset(10).topToBottomOfViewWithOffset(testSwitch, 50).height(50);
    
    FWTextTagCollectionView *tagCollectionView = [FWTextTagCollectionView new];
    _tagCollectionView = tagCollectionView;
    tagCollectionView.verticalSpacing = 10;
    tagCollectionView.horizontalSpacing = 10;
    [headerView addSubview:tagCollectionView];
    tagCollectionView.fwLayoutChain.leftWithInset(10).rightWithInset(10).topToBottomOfViewWithOffset(segmentedControl, 50).height(100).bottomWithInset(50);
    
    self.tableView.tableHeaderView = headerView;
    [headerView fwAutoLayoutSubviews];
}

- (void)renderTableLayout
{
    self.tableView.fwLayoutChain.edges();
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

- (UICollectionViewLayout *)renderCollectionViewLayout
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake((FWScreenWidth - 10) / 2.f, 100);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    return layout;
}

- (void)renderCollectionView
{
    [self.collectionView registerClass:[TestStatisticalCell class] forCellWithReuseIdentifier:@"cell"];
}

- (void)renderCollectionLayout
{
    self.collectionView.fwLayoutChain.edges();
}

- (void)renderView
{
    // 设置遮挡视图
    UIView *shieldView = [UIView new];
    self.shieldView = shieldView;
    shieldView.backgroundColor = [Theme tableColor];
    FWWeakifySelf();
    [shieldView fwAddTapGestureWithBlock:^(UITapGestureRecognizer *sender) {
        FWStrongifySelf();
        [self.shieldView removeFromSuperview];
        self.shieldView = nil;
        // 手工触发曝光计算
        self.view.hidden = self.view.hidden;
    }];
    [[UIWindow fwMainWindow] addSubview:shieldView];
    [shieldView fwPinEdgesToSuperview];
    
    UILabel *shieldLabel = [UILabel fwAutoLayoutView];
    shieldLabel.text = @"点击关闭";
    shieldLabel.textAlignment = NSTextAlignmentCenter;
    [shieldView addSubview:shieldLabel];
    shieldLabel.fwLayoutChain.edges();
    
    [self.testView fwAddTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.testView.backgroundColor = [UIColor fwRandomColor];
        [self.bannerView makeScrollViewScrollToIndex:0];
    }];
    
    [self.testButton fwAddTouchBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self.testButton fwSetBackgroundColor:[UIColor fwRandomColor] forState:UIControlStateNormal];
    }];
    
    [self.testSwitch fwAddBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.testSwitch.thumbTintColor = [UIColor fwRandomColor];
        self.testSwitch.onTintColor = self.testSwitch.thumbTintColor;
    } forControlEvents:UIControlEventValueChanged];
    
    self.bannerView.clickItemOperationBlock = ^(NSInteger currentIndex) {
        FWStrongifySelf();
        [self clickHandler:currentIndex];
    };
    
    self.segmentedControl.indexChangeBlock = ^(NSUInteger index) {
        FWStrongifySelf();
        self.segmentedControl.selectionIndicatorBoxColor = [UIColor fwRandomColor];
    };
}

- (void)renderModel
{
    self.collectionView.hidden = YES;
    FWWeakifySelf();
    [self fwSetRightBarItem:FWIcon.refreshImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if (self.collectionView.hidden) {
            self.collectionView.hidden = NO;
            self.tableView.hidden = YES;
        } else {
            self.collectionView.hidden = YES;
            self.tableView.hidden = NO;
        }
    }];
    
    NSArray *imageUrls = @[@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg", [TestBundle imageNamed:@"public_picture"], @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp", @"http://littlesvr.ca/apng/images/SteamEngine.webp", @"not_found.jpg", @"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    self.bannerView.imageURLStringsGroup = imageUrls;
    NSArray *sectionTitles = @[@"Section0", @"Section1", @"Section2", @"Section3", @"Section4", @"Section5", @"Section6", @"Section7", @"Section8"];
    self.segmentedControl.sectionTitles = sectionTitles;
    [self.tagCollectionView addTags:@[@"标签0", @"标签1", @"标签2", @"标签3", @"标签4", @"标签5"]];
    [self.tagCollectionView removeTag:@"标签4"];
    [self.tagCollectionView removeTag:@"标签5"];
    [self.tagCollectionView addTags:@[@"标签4", @"标签5", @"标签6", @"标签7"]];
}

- (void)renderData
{
    FWWeakifySelf();
    [FWStatisticalManager sharedInstance].globalHandler = ^(FWStatisticalObject *object) {
        BOOL isExposure = [object.name containsString:@"exposure"] ? YES : NO;
        NSString *type = isExposure ? @"曝光" : ([object.view isKindOfClass:[UISwitch class]] ? @"改变" : @"点击");
        if (isExposure) {
            FWLogDebug(@"%@%@通知: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@", NSStringFromClass(object.view.class), type, [NSString stringWithFormat:@"%@.%@", @(object.indexPath.section), @(object.indexPath.row)], @(object.triggerCount), object.name, object.object, object.userInfo);
        } else {
            FWStrongifySelf();
            [self showToast:[NSString stringWithFormat:@"%@%@事件: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@", NSStringFromClass(object.view.class), [object.view isKindOfClass:[UISwitch class]] ? @"改变" : @"点击", [NSString stringWithFormat:@"%@.%@", @(object.indexPath.section), @(object.indexPath.row)], @(object.triggerCount), object.name, object.object, object.userInfo]];
        }
    };
    
    // Click
    self.testView.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_view" object:@"view"];
    self.testButton.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_button" object:@"button"];
    self.testSwitch.fwStatisticalChanged = [[FWStatisticalObject alloc] initWithName:@"click_switch" object:@"switch"];
    self.tableView.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_tableView" object:@"table"];
    self.bannerView.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_banner" object:@"banner"];
    self.segmentedControl.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_segment" object:@"segment"];
    self.tagCollectionView.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_tag" object:@"tag"];
    
    // Exposure
    self.testView.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_view" object:@"view"];
    [self configShieldView:self.testView.fwStatisticalExposure];
    self.testButton.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_button" object:@"button"];
    self.testButton.fwStatisticalExposure.triggerOnce = YES;
    [self configShieldView:self.testButton.fwStatisticalExposure];
    self.testSwitch.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_switch" object:@"switch"];
    [self configShieldView:self.testSwitch.fwStatisticalExposure];
    self.tableView.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_tableView" object:@"table"];
    [self configShieldView:self.tableView.fwStatisticalExposure];
    self.bannerView.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_banner" object:@"banner"];
    [self configShieldView:self.bannerView.fwStatisticalExposure];
    self.segmentedControl.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_segment" object:@"segment"];
    [self configShieldView:self.segmentedControl.fwStatisticalExposure];
    self.tagCollectionView.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_tag" object:@"tag"];
    [self configShieldView:self.tagCollectionView.fwStatisticalExposure];
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
    [self fwShowMessageWithText:toast];
}

- (void)clickHandler:(NSInteger)index
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TestWebViewController *viewController = [TestWebViewController new];
        viewController.requestUrl = @"http://kvm.wuyong.site/test.php";
        if (index % 2 == 0) {
            [self.navigationController pushViewController:viewController animated:YES];
        } else {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            [self.navigationController presentViewController:navigationController animated:YES completion:nil];
        }
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
    cell.contentView.backgroundColor = [UIColor fwRandomColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor fwRandomColor];
    
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
    cell.contentView.backgroundColor = [UIColor fwRandomColor];
    cell.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_collectionView" object:@"cell"];
    cell.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_collectionView" object:@"cell"];
    cell.fwStatisticalExposure.triggerOnce = YES;
    [self configShieldView:cell.fwStatisticalExposure];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor fwRandomColor];
    
    [self clickHandler:indexPath.row];
}

@end
