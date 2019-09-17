//
//  FWLocationManager.m
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWLocationManager.h"
#import <tgmath.h>

NSString * FWLocationStringWithCoordinate(CLLocationCoordinate2D coordinate) {
    return [NSString stringWithFormat:@"%@,%@", @(coordinate.latitude), @(coordinate.longitude)];
}

CLLocationCoordinate2D FWLocationCoordinateWithString(NSString *string) {
    NSArray<NSString *> *degrees = [string componentsSeparatedByString:@","];
    return CLLocationCoordinate2DMake(degrees.firstObject.doubleValue, degrees.lastObject.doubleValue);
}

CLLocationDegrees FWLocationDegreeWithCoordinates(CLLocationCoordinate2D origin, CLLocationCoordinate2D destination) {
    // Taken from http://www.movable-type.co.uk/scripts/latlong.html the "Bearing" section
    double fromLat = origin.latitude * M_PI / 180;
    double fromLon = origin.longitude * M_PI / 180;
    double toLat = destination.latitude * M_PI / 180;
    double toLon = destination.longitude * M_PI / 180;
    
    double y = sin(toLon - fromLon) * cos(toLat);
    double x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(toLon - fromLon);
    double degree = atan2(y, x) * 180 / M_PI;
    return fmod(degree + 360, 360.0);
}

CLLocationCoordinate2D FWLocationCoordinateWithDistanceAndDegree(CLLocationCoordinate2D origin, CLLocationDistance distance, CLLocationDegrees degree) {
    // Taken from http://www.movable-type.co.uk/scripts/latlong.html the "Destination point given distance and bearing from start point" section
    const int radius = 6371000;
    double radian = degree * M_PI / 180;
    double scale = distance / radius;
    
    double currentLat = origin.latitude * M_PI / 180;
    double currentLon = origin.longitude * M_PI / 180;
    double toLat = asin(sin(currentLat) * cos(scale) + cos(currentLat) * sin(scale) * cos(radian));
    double toLon = currentLon + atan2(sin(radian) * sin(scale) * cos(currentLat), cos(scale) - sin(currentLat) * sin(toLat));
    return CLLocationCoordinate2DMake(toLat * 180 / M_PI, toLon * 180 / M_PI);
}

#pragma mark - FWLocationManager

NSString *const FWLocationUpdatedNotification = @"FWLocationUpdatedNotification";
NSString *const FWLocationFailedNotification = @"FWLocationFailedNotification";
NSString *const FWHeadingUpdatedNotification = @"FWHeadingUpdatedNotification";

@interface FWLocationManager () <CLLocationManagerDelegate>

@end

@implementation FWLocationManager

+ (FWLocationManager *)sharedInstance
{
    static FWLocationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWLocationManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        // _locationManager.distanceFilter = 50;
        /*
        if (@available(iOS 11.0, *)) {
            _locationManager.showsBackgroundLocationIndicator = YES;
        }
        */
    }
    return self;
}

#pragma mark - Accessor

- (void)setHeadingEnabled:(BOOL)headingEnabled
{
    // 不支持方向时，设置无效
    if (headingEnabled && ![CLLocationManager headingAvailable]) {
        headingEnabled = NO;
    }
    _headingEnabled = headingEnabled;
}

#pragma mark - Public

- (void)startUpdateLocation
{
    if (self.alwaysLocation) {
        [self.locationManager requestAlwaysAuthorization];
    } else {
        [self.locationManager requestWhenInUseAuthorization];
    }
    if (self.backgroundLocation) {
        if (@available(iOS 9.0, *)) {
            [self.locationManager setAllowsBackgroundLocationUpdates:YES];
        }
    }
    
    [self.locationManager startUpdatingLocation];
    if (self.headingEnabled) {
        [self.locationManager startUpdatingHeading];
    }
}

- (void)stopUpdateLocation
{
    if (self.backgroundLocation) {
        if (@available(iOS 9.0, *)) {
            [self.locationManager setAllowsBackgroundLocationUpdates:NO];
        }
    }
    
    if (self.headingEnabled) {
        [self.locationManager stopUpdatingHeading];
    }
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *oldLocation = _location;
    CLLocation *newLocation = locations.lastObject;
    _location = newLocation;
    
    // 发送位置改变通知
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    if (oldLocation) [userInfo setObject:oldLocation forKey:NSKeyValueChangeOldKey];
    if (newLocation) [userInfo setObject:newLocation forKey:NSKeyValueChangeNewKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:FWLocationUpdatedNotification object:self userInfo:userInfo.copy];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    CLHeading *oldHeading = _heading;
    _heading = newHeading;
    
    // 发送方向改变通知
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    if (oldHeading) [userInfo setObject:oldHeading forKey:NSKeyValueChangeOldKey];
    if (newHeading) [userInfo setObject:newHeading forKey:NSKeyValueChangeNewKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:FWHeadingUpdatedNotification object:self userInfo:userInfo.copy];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    // 发送位置失败通知
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    if (error) [userInfo setObject:error forKey:NSUnderlyingErrorKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:FWLocationFailedNotification object:self userInfo:userInfo.copy];
}

@end
