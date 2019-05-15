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

@interface TestMapViewController () <MKMapViewDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) MKMapView *mapView;

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
