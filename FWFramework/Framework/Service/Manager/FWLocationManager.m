//
//  FWLocationManager.m
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWLocationManager.h"

NSString *const FWLocationUpdatedNotification = @"FWLocationUpdatedNotification";
NSString *const FWLocationFailedNotification = @"FWLocationFailedNotification";
NSString *const FWHeadingUpdatedNotification = @"FWHeadingUpdatedNotification";

@interface FWLocationManager () <CLLocationManagerDelegate>

@end

@implementation FWLocationManager

+ (instancetype)sharedInstance
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
    if (self.alwaysEnabled) {
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
        if (@available(iOS 9.0, *)) {
            [self.locationManager setAllowsBackgroundLocationUpdates:YES];
        }
    } else {
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
    }
    
    [self.locationManager startUpdatingLocation];
    if (self.headingEnabled) {
        [self.locationManager startUpdatingHeading];
    }
}

- (void)stopUpdateLocation
{
    if (self.alwaysEnabled) {
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
