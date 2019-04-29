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

@interface TestMapViewController () <MKMapViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIView *contentView;

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
    
    CGFloat viewHeight = FWScreenHeight - FWStatusBarHeight - FWNavigationBarHeight;
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, viewHeight / 4 * 3, self.view.fwWidth, viewHeight / 4)];
    _scrollView = scrollView;
    [scrollView fwContentInsetNever];
    scrollView.delegate = self;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.contentSize = CGSizeMake(self.view.fwWidth, 1000);
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
