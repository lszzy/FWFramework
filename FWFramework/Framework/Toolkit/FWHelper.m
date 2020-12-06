/*!
 @header     FWHelper.m
 @indexgroup FWFramework
 @brief      FWHelper
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/11/30
 */

#import "FWHelper.h"
#import "FWKeychain.h"
#import <sys/sysctl.h>
#if FWCOMPONENT_TRACKING_ENABLED
#import <AdSupport/ASIdentifierManager.h>
#endif

#pragma mark - NSAttributedString+FWHelper

@implementation NSAttributedString (FWHelper)

+ (instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString
{
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[self alloc] initWithData:htmlData options:@{
        NSDocumentTypeDocumentOption: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding),
    } documentAttributes:nil error:nil];
}

- (NSString *)fwHtmlString
{
    NSData *htmlData = [self dataFromRange:NSMakeRange(0, self.length) documentAttributes:@{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
    } error:nil];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - NSDate+FWHelper

// 当前基准时间值
static NSTimeInterval fwStaticCurrentBaseTime = 0;
// 本地基准时间值
static NSTimeInterval fwStaticLocalBaseTime = 0;

@implementation NSDate (FWHelper)

+ (NSTimeInterval)fwCurrentTime
{
    // 没有同步过返回本地时间
    if (fwStaticCurrentBaseTime == 0) {
        // 是否本地有服务器时间
        NSNumber *preCurrentTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWCurrentTime"];
        NSNumber *preLocalTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalTime"];
        if (preCurrentTime && preLocalTime) {
            // 计算当前服务器时间
            NSTimeInterval offsetTime = [[NSDate date] timeIntervalSince1970] - preLocalTime.doubleValue;
            return preCurrentTime.doubleValue + offsetTime;
        } else {
            return [[NSDate date] timeIntervalSince1970];
        }
    // 同步过计算当前服务器时间
    } else {
        NSTimeInterval offsetTime = [self fwCurrentSystemUptime] - fwStaticLocalBaseTime;
        return fwStaticCurrentBaseTime + offsetTime;
    }
}

+ (void)setFwCurrentTime:(NSTimeInterval)currentTime
{
    fwStaticCurrentBaseTime = currentTime;
    // 取运行时间，调整系统时间不会影响
    fwStaticLocalBaseTime = [self fwCurrentSystemUptime];
    
    // 保存当前服务器时间到本地
    [[NSUserDefaults standardUserDefaults] setObject:@(currentTime) forKey:@"FWCurrentTime"];
    [[NSUserDefaults standardUserDefaults] setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"FWLocalTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (long long)fwCurrentSystemUptime
{
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    time_t now;
    time_t uptime = -1;
    (void)time(&now);
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0) {
        uptime = now - boottime.tv_sec;
    }
    return uptime;
}

@end

#pragma mark - UIDevice+FWHelper

static NSString *fwStaticDeviceUUID = nil;

@implementation UIDevice (FWHelper)

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

+ (void)fwSetDeviceTokenData:(NSData *)tokenData
{
    if (tokenData) {
        NSMutableString *deviceToken = [NSMutableString string];
        const char *bytes = tokenData.bytes;
        NSInteger count = tokenData.length;
        for (int i = 0; i < count; i++) {
            [deviceToken appendFormat:@"%02x", bytes[i] & 0x000000FF];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[deviceToken copy] forKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSString *)fwDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDeviceToken"];
}

+ (NSString *)fwDeviceModel
{
    static NSString *model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        model = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    return model;
}

+ (NSString *)fwDeviceIDFV
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+ (NSString *)fwDeviceIDFA
{
#if FWCOMPONENT_TRACKING_ENABLED
    return [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
#else
    return nil;
#endif
}

@end

#pragma mark - UIView+FWHelper

@implementation UIView (FWHelper)

- (UIViewController *)fwViewController
{
    UIResponder *responder = [self nextResponder];
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

@end
