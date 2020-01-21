//
//  TestStatisticalViewController.m
//  Example
//
//  Created by wuyong on 2020/1/16.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestStatisticalViewController.h"

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

@interface TestStatisticalViewController () <FWCollectionViewController>

FWPropertyWeak(UIView *, testView);
FWPropertyWeak(UIButton *, testButton);
FWPropertyWeak(UISwitch *, testSwitch);

@end

@implementation TestStatisticalViewController

- (void)renderTableView
{
    UIView *headerView = [UIView new];
    
    UIView *testView = [UIView fwAutoLayoutView];
    _testView = testView;
    testView.backgroundColor = [UIColor fwRandomColor];
    [headerView addSubview:testView];
    testView.fwLayoutChain.width(100).height(30).centerX().topWithInset(10);
    
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _testButton = testButton;
    testButton.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_button" object:@(1)];
    testButton.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_button" object:@(1)];
    [testButton setTitle:@"Button" forState:UIControlStateNormal];
    [testButton fwSetBackgroundColor:[UIColor fwRandomColor] forState:UIControlStateNormal];
    [headerView addSubview:testButton];
    testButton.fwLayoutChain.width(100).height(30).centerX().topToBottomOfViewWithOffset(testView, 10);
    
    UISwitch *testSwitch = [UISwitch new];
    _testSwitch = testSwitch;
    testSwitch.fwStatisticalChanged = [[FWStatisticalObject alloc] initWithName:@"click_switch" object:@(2) userInfo:@{@"type": @(3)}];
    testSwitch.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_switch" object:@(2) userInfo:@{@"type": @(3)}];
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
    self.tableView.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_tableView" object:@(4)];
    self.tableView.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_tableView" object:@(4)];
    self.collectionView.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_collectionView" object:@5 userInfo:@{@"type": @6}];
    self.collectionView.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_collectionView" object:@5 userInfo:@{@"type": @6}];
    
    FWWeakifySelf();
    [self.testView fwAddTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.testView.backgroundColor = [UIColor fwRandomColor];
    }];
    self.testView.fwStatisticalClick = [[FWStatisticalObject alloc] initWithName:@"click_view"];
    self.testView.fwStatisticalExposure = [[FWStatisticalObject alloc] initWithName:@"exposure_view"];
    
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
    // Notification
    [self fwObserveNotification:FWStatisticalEventTriggeredNotification block:^(NSNotification *notification) {
        FWStatisticalObject *object = notification.object;
        NSString *type = [object.name containsString:@"exposure"] ? @"曝光" : ([object.view isKindOfClass:[UISwitch class]] ? @"改变" : @"点击");
        FWLogDebug(@"%@%@通知: \nindexPath: %@\nname: %@\nobject: %@\nuserInfo: %@", NSStringFromClass(object.view.class), type, [NSString stringWithFormat:@"%@.%@", @(object.indexPath.section), @(object.indexPath.row)], object.name, object.object, object.userInfo);
    }];
    
    // Click
    FWWeakifySelf();
    FWStatisticalBlock clickBlock = ^(FWStatisticalObject *object){
        FWStrongifySelf();
        [self showToast:[NSString stringWithFormat:@"%@%@事件: \nindexPath: %@\nname: %@\nobject: %@\nuserInfo: %@", NSStringFromClass(object.view.class), [object.view isKindOfClass:[UISwitch class]] ? @"改变" : @"点击", [NSString stringWithFormat:@"%@.%@", @(object.indexPath.section), @(object.indexPath.row)], object.name, object.object, object.userInfo]];
    };
    self.testView.fwStatisticalClickBlock = clickBlock;
    self.testButton.fwStatisticalClickBlock = clickBlock;
    self.testSwitch.fwStatisticalChangedBlock = clickBlock;
    self.tableView.fwStatisticalClickBlock = clickBlock;
    self.collectionView.fwStatisticalClickBlock = clickBlock;
    
    // Exposure
    FWStatisticalBlock exposureBlock = ^(FWStatisticalObject *object){
        FWLogDebug(@"%@曝光事件: \nindexPath: %@\nname: %@\nobject: %@\nuserInfo: %@", NSStringFromClass(object.view.class), [NSString stringWithFormat:@"%@.%@", @(object.indexPath.section), @(object.indexPath.row)], object.name, object.object, object.userInfo);
    };
    self.testView.fwStatisticalExposureBlock = exposureBlock;
    self.testButton.fwStatisticalExposureBlock = exposureBlock;
    self.testSwitch.fwStatisticalExposureBlock = exposureBlock;
    self.tableView.fwStatisticalExposureBlock = exposureBlock;
    self.collectionView.fwStatisticalExposureBlock = exposureBlock;
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
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor fwRandomColor];
}

@end
