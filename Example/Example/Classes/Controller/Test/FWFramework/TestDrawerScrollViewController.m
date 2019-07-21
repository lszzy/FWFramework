//
//  TestDrawerScrollViewController.m
//  Example
//
//  Created by wuyong on 2019/7/20.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestDrawerScrollViewController.h"
#import <MapKit/MapKit.h>

#define ViewHeight (FWScreenHeight - FWStatusBarHeight - FWNavigationBarHeight)

@interface TestDrawerScrollViewController () <FWDrawerViewDelegate>

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, weak) FWDrawerView *drawerView;

@end

@implementation TestDrawerScrollViewController

- (void)renderView
{
    // 因为显示了导航栏，去掉self.view多出来的高度
    self.view.fwHeight -= FWTopBarHeight;
    
    [self renderMapView];
    [self renderScrollView];
    [self renderDrawerView];
}

- (void)renderMapView
{
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView = mapView;
    mapView.showsUserLocation = YES;
    mapView.userInteractionEnabled = YES;
    mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
    [self.view addSubview:mapView];
}

- (void)renderScrollView
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scrollView = scrollView;
    [scrollView fwContentInsetAdjustmentNever];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.contentSize = CGSizeMake(self.view.fwWidth, 2000);
    scrollView.contentInset = UIEdgeInsetsMake(50, 0, 100, 0);
    scrollView.contentOffset = CGPointMake(0, -50);
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 2000)];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 50)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"I am top";
    topLabel.numberOfLines = 0;
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 975, self.view.fwWidth, 50)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.text = @"I am middle";
    middleLabel.numberOfLines = 0;
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 1950, self.view.fwWidth, 50)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"I am bottom";
    bottomLabel.numberOfLines = 0;
    [contentView addSubview:bottomLabel];
    [scrollView addSubview:contentView];
}

- (void)renderDrawerView
{
    // scrollView无需添加到self.view，DrawerView会自动添加scrollView
    FWDrawerView *drawerView = [[FWDrawerView alloc] initWithEmbedView:self.scrollView];
    _drawerView = drawerView;
    drawerView.delegate = self;
    // 无需添加到self.view，调用attachTo即可
    [drawerView attachTo:self.view];
}

#pragma mark - FWDrawerViewDelegate

- (void)drawerView:(FWDrawerView *)drawerView willTransitionFrom:(FWDrawerViewPosition)startPosition to:(FWDrawerViewPosition)targetPosition
{
    FWLogDebug(@"drawerViewWillTransitionFrom: %@ to: %@", @(startPosition), @(targetPosition));
}

- (void)drawerView:(FWDrawerView *)drawerView didTransitionTo:(FWDrawerViewPosition)position
{
    FWLogDebug(@"drawerViewDidTransitionTo: %@", @(position));
}

- (void)drawerView:(FWDrawerView *)drawerView didMoveTo:(CGFloat)drawerOffset
{
    FWLogDebug(@"drawerViewDidMoveTo: %@", @(drawerOffset));
    
    CGFloat openOffset = [drawerView drawerOffsetWithPosition:FWDrawerViewPositionOpen];
    CGFloat partiallyOpenOffset = [drawerView drawerOffsetWithPosition:FWDrawerViewPositionPartiallyOpen];
    if (drawerOffset > partiallyOpenOffset) {
        CGFloat targetDistance = openOffset - partiallyOpenOffset;
        CGFloat distance = drawerOffset - partiallyOpenOffset;
        CGFloat progress = MIN(distance / targetDistance, 1);
        [self.navigationController.navigationBar fwSetBackgroundColor:[[UIColor brownColor] colorWithAlphaComponent:progress]];
    } else {
        [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
    }
}

- (void)drawerViewWillBeginDragging:(FWDrawerView *)drawerView
{
    FWLogDebug(@"drawerViewWillBeginDragging");
}

- (void)drawerViewWillEndDragging:(FWDrawerView *)drawerView
{
    FWLogDebug(@"drawerViewWillEndDragging");
}

@end
