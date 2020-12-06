/*!
 @header     UIDevice+FWFramework.m
 @indexgroup FWFramework
 @brief      UIDevice+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "UIDevice+FWFramework.h"
#import "FWKeychain.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>

static NSString *fwStaticDeviceUUID = nil;

@implementation UIDevice (FWFramework)

#pragma mark - UUID

+ (NSString *)fwDeviceUUID
{
    if (!fwStaticDeviceUUID) {
        @synchronized ([self class]) {
            NSString *deviceUUID = [[FWKeychainManager sharedInstance] passwordForService:@"FWDeviceUUID" account:NSBundle.mainBundle.bundleIdentifier];
            if (deviceUUID.length > 0) {
                fwStaticDeviceUUID = deviceUUID;
            } else {
                deviceUUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
                if (deviceUUID.length < 1) {
                    deviceUUID = [[NSUUID UUID] UUIDString];
                }
                [self setFwDeviceUUID:deviceUUID];
            }
        }
    }
    
    return fwStaticDeviceUUID;
}

+ (void)setFwDeviceUUID:(NSString *)fwDeviceUUID
{
    fwStaticDeviceUUID = fwDeviceUUID;
    
    [[FWKeychainManager sharedInstance] setPassword:fwDeviceUUID forService:@"FWDeviceUUID" account:NSBundle.mainBundle.bundleIdentifier];
}

#pragma mark - Jailbroken

+ (BOOL)fwIsJailbroken
{
#if TARGET_OS_SIMULATOR
    return NO;
#else
    // 1
    NSArray *paths = @[@"/Applications/Cydia.app",
                       @"/private/var/lib/apt/",
                       @"/private/var/lib/cydia",
                       @"/private/var/stash"];
    for (NSString *path in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return YES;
        }
    }
    
    // 2
    FILE *bash = fopen("/bin/bash", "r");
    if (bash != NULL) {
        fclose(bash);
        return YES;
    }
    
    // 3
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    NSString *uuidString = (__bridge_transfer NSString *)string;
    NSString *path = [NSString stringWithFormat:@"/private/%@", uuidString];
    if ([@"test" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return YES;
    }
    
    return NO;
#endif
}

#pragma mark - Landscape

+ (BOOL)fwIsInterfaceLandscape
{
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

+ (BOOL)fwIsDeviceLandscape
{
    return UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);
}

+ (BOOL)fwSetDeviceOrientation:(UIDeviceOrientation)orientation
{
    if ([UIDevice currentDevice].orientation == orientation) {
        [UIViewController attemptRotationToDeviceOrientation];
        return NO;
    }
    
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];
    return YES;
}

#pragma mark - Network

+ (NSString *)fwIpAddress
{
    NSString *ipAddr = nil;
    struct ifaddrs *addrs = NULL;
    
    int ret = getifaddrs(&addrs);
    if (0 == ret) {
        const struct ifaddrs * cursor = addrs;
        
        while (cursor) {
            if (AF_INET == cursor->ifa_addr->sa_family && 0 == (cursor->ifa_flags & IFF_LOOPBACK)) {
                ipAddr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                break;
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    return ipAddr;
}

+ (NSString *)fwHostName
{
    char hostName[256];
    int success = gethostname(hostName, 255);
    if (success != 0) return nil;
    hostName[255] = '\0';
    
#if TARGET_OS_SIMULATOR
    return [NSString stringWithFormat:@"%s", hostName];
#else
    return [NSString stringWithFormat:@"%s.local", hostName];
#endif
}

+ (NSString *)fwCarrierName
{
    CTCarrier *carrier = [[CTTelephonyNetworkInfo new] subscriberCellularProvider];
    return carrier.isoCountryCode ? carrier.carrierName : nil;
}

@end
