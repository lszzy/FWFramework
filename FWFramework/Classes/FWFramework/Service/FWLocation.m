//
//  FWLocation.m
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWLocation.h"

NSString * FWLocationStringWithCoordinate(CLLocationCoordinate2D coordinate) {
    return [NSString stringWithFormat:@"%@,%@", @(coordinate.latitude), @(coordinate.longitude)];
}

CLLocationCoordinate2D FWLocationCoordinateWithString(NSString *string) {
    NSArray<NSString *> *degrees = [string componentsSeparatedByString:@","];
    return CLLocationCoordinate2DMake(degrees.firstObject.doubleValue, degrees.lastObject.doubleValue);
}

#pragma mark - FWLocationManager

NSString *const FWLocationUpdatedNotification = @"FWLocationUpdatedNotification";
NSString *const FWLocationFailedNotification = @"FWLocationFailedNotification";
NSString *const FWHeadingUpdatedNotification = @"FWHeadingUpdatedNotification";

@interface FWLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, assign) BOOL isCompleted;

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
        // _locationManager.showsBackgroundLocationIndicator = YES;
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
    if (self.stopWhenCompleted) {
        self.isCompleted = NO;
    }
    
    if (self.alwaysLocation) {
        [self.locationManager requestAlwaysAuthorization];
    } else {
        [self.locationManager requestWhenInUseAuthorization];
    }
    if (self.backgroundLocation) {
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    }
    
    [self.locationManager startUpdatingLocation];
    if (self.headingEnabled) {
        [self.locationManager startUpdatingHeading];
    }
}

- (void)stopUpdateLocation
{
    if (self.stopWhenCompleted) {
        self.isCompleted = YES;
    }
    
    if (self.backgroundLocation) {
        [self.locationManager setAllowsBackgroundLocationUpdates:NO];
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
    if (self.stopWhenCompleted) {
        if (self.isCompleted) return;
        self.isCompleted = YES;
    }
    
    CLLocation *oldLocation = _location;
    CLLocation *newLocation = locations.lastObject;
    _location = newLocation;
    _error = nil;
    
    if (self.locationChanged) {
        self.locationChanged(self);
    }
    if (self.notificationEnabled) {
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        if (oldLocation) [userInfo setObject:oldLocation forKey:NSKeyValueChangeOldKey];
        if (newLocation) [userInfo setObject:newLocation forKey:NSKeyValueChangeNewKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:FWLocationUpdatedNotification object:self userInfo:userInfo.copy];
    }
    
    if (self.stopWhenCompleted) {
        [self stopUpdateLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (self.stopWhenCompleted) {
        if (self.isCompleted) return;
        self.isCompleted = YES;
    }
    
    CLHeading *oldHeading = _heading;
    _heading = newHeading;
    _error = nil;
    
    if (self.locationChanged) {
        self.locationChanged(self);
    }
    if (self.notificationEnabled) {
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        if (oldHeading) [userInfo setObject:oldHeading forKey:NSKeyValueChangeOldKey];
        if (newHeading) [userInfo setObject:newHeading forKey:NSKeyValueChangeNewKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:FWHeadingUpdatedNotification object:self userInfo:userInfo.copy];
    }
    
    if (self.stopWhenCompleted) {
        [self stopUpdateLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if (self.stopWhenCompleted) {
        if (self.isCompleted) return;
        self.isCompleted = YES;
    }
    
    _error = error;
    
    if (self.locationChanged) {
        self.locationChanged(self);
    }
    if (self.notificationEnabled) {
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        if (error) [userInfo setObject:error forKey:NSUnderlyingErrorKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:FWLocationFailedNotification object:self userInfo:userInfo.copy];
    }
    
    if (self.stopWhenCompleted) {
        [self stopUpdateLocation];
    }
}

@end
