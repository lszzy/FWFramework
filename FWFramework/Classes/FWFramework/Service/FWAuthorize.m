//
//  FWAuthorize.m
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWAuthorize.h"
#import <UIKit/UIKit.h>

#pragma mark - FWAuthorizeLocation

#import <CoreLocation/CoreLocation.h>

@interface FWAuthorizeLocation : NSObject <FWAuthorizeProtocol, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, copy) void (^completionBlock)(FWAuthorizeStatus status);

@property (nonatomic, assign) BOOL changeIgnored;

@property (nonatomic, readonly) BOOL isAlways;

- (instancetype)initWithIsAlways:(BOOL)isAlways;

@end

@implementation FWAuthorizeLocation

- (instancetype)initWithIsAlways:(BOOL)isAlways
{
    self = [super init];
    if (self) {
        _isAlways = isAlways;
    }
    return self;
}

- (CLLocationManager *)locationManager
{
    // 需要强引用CLLocationManager，否则授权弹出框会自动消失
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (FWAuthorizeStatus)authorizeStatus
{
    // 定位功能未打开时返回Denied，可自行调用[CLLocationManager locationServicesEnabled]判断
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch (status) {
        case kCLAuthorizationStatusRestricted:
            return FWAuthorizeStatusRestricted;
        case kCLAuthorizationStatusDenied:
            return FWAuthorizeStatusDenied;
        case kCLAuthorizationStatusAuthorizedAlways:
            return FWAuthorizeStatusAuthorized;
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            if (self.isAlways) {
                NSNumber *isAuthorized = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWAuthorizeLocation"];
                return isAuthorized != nil ? FWAuthorizeStatusDenied : FWAuthorizeStatusNotDetermined;
            } else {
                return FWAuthorizeStatusAuthorized;
            }
        }
        case kCLAuthorizationStatusNotDetermined:
        default:
            return FWAuthorizeStatusNotDetermined;
    }
}

- (void)authorize:(void (^)(FWAuthorizeStatus))completion
{
    self.completionBlock = completion;
    
    if (self.isAlways) {
        [self.locationManager requestAlwaysAuthorization];
        
        // 标记已请求授权
        [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:@"FWAuthorizeLocation"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // 如果请求always权限且当前已经是WhenInUse权限，系统会先回调此方法一次，忽略之
    if (self.isAlways && !self.changeIgnored) {
        if (status == kCLAuthorizationStatusNotDetermined ||
            status == kCLAuthorizationStatusAuthorizedWhenInUse) {
            self.changeIgnored = YES;
            return;
        }
    }
    
    // 主线程回调，仅一次
    if (self.completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(self.authorizeStatus);
            self.completionBlock = nil;
        });
    }
}

@end

#pragma mark - FWAuthorizePhotoLibrary

#import <Photos/Photos.h>

@interface FWAuthorizePhotoLibrary : NSObject <FWAuthorizeProtocol>

@end

@implementation FWAuthorizePhotoLibrary

- (FWAuthorizeStatus)authorizeStatus
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusRestricted:
            return FWAuthorizeStatusRestricted;
        case PHAuthorizationStatusDenied:
            return FWAuthorizeStatusDenied;
        case PHAuthorizationStatusAuthorized:
            return FWAuthorizeStatusAuthorized;
        case PHAuthorizationStatusNotDetermined:
        default:
            return FWAuthorizeStatusNotDetermined;
    }
}

- (void)authorize:(void (^)(FWAuthorizeStatus status))completion
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self.authorizeStatus);
            });
        }
    }];
}

@end

#pragma mark - FWAuthorizeCamera

#import <AVFoundation/AVFoundation.h>

@interface FWAuthorizeCamera : NSObject <FWAuthorizeProtocol>

@end

@implementation FWAuthorizeCamera

- (FWAuthorizeStatus)authorizeStatus
{
    // 模拟器不支持照相机，返回受限制
    NSString *mediaType = AVMediaTypeVideo;
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:mediaType];
    if (![inputDevice hasMediaType:mediaType]) {
        return FWAuthorizeStatusRestricted;
    }
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    switch (status) {
        case AVAuthorizationStatusRestricted:
            return FWAuthorizeStatusRestricted;
        case AVAuthorizationStatusDenied:
            return FWAuthorizeStatusDenied;
        case AVAuthorizationStatusAuthorized:
            return FWAuthorizeStatusAuthorized;
        case AVAuthorizationStatusNotDetermined:
        default:
            return FWAuthorizeStatusNotDetermined;
    }
}

- (void)authorize:(void (^)(FWAuthorizeStatus))completion
{
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self.authorizeStatus);
            });
        }
    }];
}

@end

#pragma mark - FWAuthorizeNotifications

#import <UserNotifications/UserNotifications.h>

// iOS10+使用UNUserNotificationCenter
@interface FWAuthorizeNotifications : NSObject <FWAuthorizeProtocol>

@end

@implementation FWAuthorizeNotifications

- (FWAuthorizeStatus)authorizeStatus
{
    __block FWAuthorizeStatus status = FWAuthorizeStatusNotDetermined;
    // 由于查询授权为异步方法，此处使用信号量阻塞当前线程，同步返回查询结果
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        switch (settings.authorizationStatus) {
            case UNAuthorizationStatusDenied:
                status = FWAuthorizeStatusDenied;
                break;
            case UNAuthorizationStatusAuthorized:
            case UNAuthorizationStatusProvisional:
                status = FWAuthorizeStatusAuthorized;
                break;
            case UNAuthorizationStatusNotDetermined:
            default:
                status = FWAuthorizeStatusNotDetermined;
                break;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return status;
}

- (void)authorizeStatus:(void (^)(FWAuthorizeStatus))completion
{
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        FWAuthorizeStatus status;
        switch (settings.authorizationStatus) {
            case UNAuthorizationStatusDenied:
                status = FWAuthorizeStatusDenied;
                break;
            case UNAuthorizationStatusAuthorized:
            case UNAuthorizationStatusProvisional:
                status = FWAuthorizeStatusAuthorized;
                break;
            case UNAuthorizationStatusNotDetermined:
            default:
                status = FWAuthorizeStatusNotDetermined;
                break;
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    }];
}

- (void)authorize:(void (^)(FWAuthorizeStatus status))completion
{
    UNAuthorizationOptions options = (UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert);
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
        FWAuthorizeStatus status = granted ? FWAuthorizeStatusAuthorized : FWAuthorizeStatusDenied;
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    }];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

@end

#pragma mark - FWAuthorizeManager

@interface FWAuthorizeManager ()

@property (class, nonatomic, readonly) FWAuthorizeManager *sharedInstance;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id<FWAuthorizeProtocol>> *managers;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id<FWAuthorizeProtocol> (^)(void)> *blocks;

@end

@implementation FWAuthorizeManager

+ (FWAuthorizeManager *)sharedInstance
{
    static FWAuthorizeManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWAuthorizeManager alloc] init];
        instance.managers = [NSMutableDictionary new];
        instance.blocks = [NSMutableDictionary new];
    });
    return instance;
}

+ (id<FWAuthorizeProtocol>)managerWithType:(FWAuthorizeType)type
{
    id<FWAuthorizeProtocol> manager = [FWAuthorizeManager.sharedInstance.managers objectForKey:@(type)];
    if (!manager) {
        manager = [self factory:type];
        if (manager) [FWAuthorizeManager.sharedInstance.managers setObject:manager forKey:@(type)];
    }
    return manager;
}

+ (void)registerAuthorize:(FWAuthorizeType)type withBlock:(id<FWAuthorizeProtocol> (^)(void))block
{
    [FWAuthorizeManager.sharedInstance.blocks setObject:block forKey:@(type)];
}

+ (id<FWAuthorizeProtocol>)factory:(FWAuthorizeType)type
{
    id<FWAuthorizeProtocol> (^block)(void) = [FWAuthorizeManager.sharedInstance.blocks objectForKey:@(type)];
    if (block) return block();
    
    id<FWAuthorizeProtocol> object = nil;
    switch (type) {
        case FWAuthorizeTypeLocationWhenInUse:
            object = [[FWAuthorizeLocation alloc] initWithIsAlways:NO];
            break;
        case FWAuthorizeTypeLocationAlways:
            object = [[FWAuthorizeLocation alloc] initWithIsAlways:YES];
            break;
        case FWAuthorizeTypePhotoLibrary:
            object = [[FWAuthorizePhotoLibrary alloc] init];
            break;
        case FWAuthorizeTypeCamera:
            object = [[FWAuthorizeCamera alloc] init];
            break;
        case FWAuthorizeTypeNotifications:
            object = [[FWAuthorizeNotifications alloc] init];
            break;
        default:
            break;
    }
    return object;
}

@end
