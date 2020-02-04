//
//  TestStatisticalViewController.m
//  Example
//
//  Created by wuyong on 2020/1/16.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestStatisticalViewController.h"
#import "BaseWebViewController.h"

@interface TestStatisticalCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation TestStatisticalCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *textLabel = [UILabel fwLabelWithFont:[UIFont appFontNormal] textColor:[UIColor appColorBlack] text:nil];
        _textLabel = textLabel;
        [self.contentView addSubview:textLabel];
        textLabel.fwLayoutChain.center();
    }
    return self;
}

@end

@interface TestStatisticalViewController () <FWCollectionViewController, FWBannerViewDelegate>

FWPropertyWeak(FWBannerView *, bannerView);
FWPropertyWeak(UIView *, testView);
FWPropertyWeak(UIButton *, testButton);
FWPropertyWeak(UISwitch *, testSwitch);

@end

@implementation TestStatisticalViewController

- (void)renderTableView
{
    UIView *headerView = [UIView new];
    
    FWBannerView *bannerView = [FWBannerView new];
    _bannerView = bannerView;
    bannerView.delegate = self;
    bannerView.autoScroll = YES;
    bannerView.autoScrollTimeInterval = 6;
    bannerView.placeholderImage = [UIImage imageNamed:@"public_icon"];
    [headerView addSubview:bannerView];
    bannerView.fwLayoutChain.leftWithInset(10).topWithInset(10).rightWithInset(10).height(100);
    
    NSMutableArray *imageUrls = [NSMutableArray array];
    [imageUrls addObject:@"http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg"];
    [imageUrls addObject:@"public_picture"];
    [imageUrls addObject:@"not_found.jpg"];
    [imageUrls addObject:@"http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"];
    bannerView.imageURLStringsGroup = [imageUrls copy];
    bannerView.titlesGroup = @[@"1", @"2", @"3", @"4"];
    
    UIView *testView = [UIView fwAutoLayoutView];
    _testView = testView;
    testView.backgroundColor = [UIColor fwRandomColor];
    [headerView addSubview:testView];
    testView.fwLayoutChain.width(100).height(30).centerX().topToBottomOfViewWithOffset(bannerView, 10);
    
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _testButton = testButton;
    [testButton setTitle:@"Button" forState:UIControlStateNormal];
    [testButton fwSetBackgroundColor:[UIColor fwRandomColor] forState:UIControlStateNormal];
    [headerView addSubview:testButton];
    testButton.fwLayoutChain.width(100).height(30).centerX().topToBottomOfViewWithOffset(testView, 10);
    
    UISwitch *testSwitch = [UISwitch new];
    _testSwitch = testSwitch;
    testSwitch.thumbTintColor = [UIColor fwRandomColor];
    testSwitch.onTintColor = testSwitch.thumbTintColor;
    [headerView addSubview:testSwitch];
    testSwitch.fwLayoutChain.centerX().topToBottomOfViewWithOffset(testButton, 10).bottomWithInset(10);
    
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
    FWWeakifySelf();
    [self.testView fwAddTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.testView.backgroundColor = [UIColor fwRandomColor];
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
}

- (void)renderModel
{
    self.collectionView.hidden = YES;
    FWWeakifySelf();
    [self fwSetRightBarItem:@(UIBarButtonSystemItemRefresh) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if (self.collectionView.hidden) {
            self.collectionView.hidden = NO;
            self.tableView.hidden = YES;
        } else {
            self.collectionView.hidden = YES;
            self.tableView.hidden = NO;
        }
    }];
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
    self.bannerView.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_banner" object:@"banner"];
    self.tableView.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_tableView" object:@"table"];
    
    // Exposure
    self.testView.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_view" object:@"view"];
    self.testButton.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_button" object:@"button"];
    self.testButton.fwStatisticalExposure.triggerOnce = YES;
    self.testSwitch.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_switch" object:@"switch"];
    self.tableView.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_tableView" object:@"table"];
}

- (void)showToast:(NSString *)toast
{
    [self.view fwShowToastWithAttributedText:[[NSAttributedString alloc] initWithString:toast]];
    [self.view fwHideToastAfterDelay:2.0 completion:nil];
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
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor fwRandomColor];
}

#pragma mark - FWBannerViewDelegate

- (void)bannerView:(FWBannerView *)bannerView customCell:(UICollectionViewCell *)cell forIndex:(NSInteger)index
{
    cell.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_banner" object:@"cell"];
}

- (void)bannerView:(FWBannerView *)bannerView didSelectItemAtIndex:(NSInteger)index
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BaseWebViewController *viewController = [BaseWebViewController new];
        viewController.requestUrl = @"http://kvm.wuyong.site/test.php";
        if (index % 2 == 0) {
            [self.navigationController pushViewController:viewController animated:YES];
        } else {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            [self.navigationController presentViewController:navigationController animated:YES completion:nil];
        }
    });
}

@end
