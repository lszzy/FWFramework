//
//  TestMapViewController.m
//  Example
//
//  Created by wuyong on 2019/4/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#define TotalHeight (FWScreenHeight - FWStatusBarHeight - FWNavigationBarHeight)
#define TopHeight (TotalHeight / 4 * 3)
#define BottomHeight (TotalHeight / 4)

@interface TestMapViewController () <MKMapViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIView *contentView;
@property (nonatomic, assign) CGPoint currentPoint;

@end

@implementation TestMapViewController

- (void)renderView
{
    _locationManager = [CLLocationManager new];
    [_locationManager requestWhenInUseAuthorization];
    
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView = mapView;
    mapView.delegate = self;
    mapView.showsUserLocation = YES;
    [self.view addSubview:mapView];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, TopHeight, self.view.fwWidth, TotalHeight)];
    _scrollView = scrollView;
    [scrollView fwContentInsetNever];
    scrollView.delegate = self;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor whiteColor];
    // 预留TopHeight空白，否则contentView拉不上来
    scrollView.contentSize = CGSizeMake(self.view.fwWidth, 1000 + TopHeight);
    [self.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 1000)];
    _contentView = contentView;
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.fwWidth, 50)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"I am top";
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 475, self.view.fwWidth, 50)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.text = @"I am middle";
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 950, self.view.fwWidth, 50)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"I am bottom";
    [contentView addSubview:bottomLabel];
    [scrollView addSubview:contentView];
    
    [self.scrollView.panGestureRecognizer addTarget:self action:@selector(scrollViewPanAction:)];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewPanAction:(UIPanGestureRecognizer *)gesture
{
    CGPoint point = [gesture translationInView:self.view];
    CGPoint velocity = [gesture velocityInView:self.view];
    CGFloat time = velocity.y != 0 ? fabs(point.y / velocity.y) : 0;
    if (point.y != 0) {
        self.scrollView.fwTempObject = point.y > 0 ? @1 : @-1;
    }
    CGFloat target = self.scrollView.fwY + point.y;
    if (target < 0) {
        target = 0;
    }
    [ gesture setTranslation: CGPointMake(0, 0) inView: self.view ];
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.25 animations:^{
            if ([self.scrollView.fwTempObject integerValue] == 1) {
                self.scrollView.fwY = TopHeight;
            } else {
                self.scrollView.fwY = 0;
            }
        }];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        [UIView animateWithDuration:time animations:^{
            self.scrollView.fwY = target;
        }];
        
    } else if (gesture.state == UIGestureRecognizerStateBegan) {
        
    }
    return;
    
    
    CGPoint pointInSuperview = [gesture locationInView:gesture.view.superview];
    CGPoint pointVelocity = [gesture velocityInView:gesture.view];
    CGFloat distance = pointInSuperview.y - self.currentPoint.y;
    CGFloat afterY = gesture.view.fwY + distance;
    if (afterY <= 0) {
        afterY = 0;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.currentPoint = pointInSuperview;
    }else if (gesture.state == UIGestureRecognizerStateChanged) {
        gesture.view.fwY = afterY;
        self.currentPoint = pointInSuperview;
    }else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.currentPoint = pointInSuperview;
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!mapView.fwTempObject) {
        mapView.fwTempObject = @(YES);
        
        MKCoordinateRegion region = MKCoordinateRegionMake(userLocation.location.coordinate, MKCoordinateSpanMake(0.01, 0.01));
        mapView.region = region;
    }
}

@end
