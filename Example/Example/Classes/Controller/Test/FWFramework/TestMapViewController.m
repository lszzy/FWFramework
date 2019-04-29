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
    CLLocationManager *locationManager = [CLLocationManager new];
    _locationManager = locationManager;
    [locationManager requestWhenInUseAuthorization];
    
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView = mapView;
    mapView.delegate = self;
    mapView.userTrackingMode = MKUserTrackingModeFollow;
    mapView.showsUserLocation = YES;
    mapView.showsCompass = YES;
    [self.view addSubview:mapView];
    
    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(29.602118, 106.502537), MKCoordinateSpanMake(0.01, 0.01));
    [mapView setRegion:region animated:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    self.mapView.centerCoordinate = userLocation.location.coordinate;
}

@end
