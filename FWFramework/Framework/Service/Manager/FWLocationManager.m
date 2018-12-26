//
//  FWLocationManager.m
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWLocationManager.h"

NSString *const FWLocationUpdatedNotification = @"FWLocationUpdatedNotification";
NSString *const FWLocationFailedNotification = @"FWLocationFailedNotification";

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
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.delegate = self;
        if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_locationManager requestWhenInUseAuthorization];
        }
    }
    return self;
}

#pragma mark - Public

- (void)startNotifier
{
    [self.locationManager startUpdatingLocation];
}

- (void)stopNotifier
{
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

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    // 发送位置失败通知
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    if (error) [userInfo setObject:error forKey:NSUnderlyingErrorKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:FWLocationFailedNotification object:self userInfo:userInfo.copy];
}

@end
