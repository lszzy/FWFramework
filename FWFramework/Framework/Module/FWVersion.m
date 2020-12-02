//
//  FWVersion.m
//  FWFramework
//
//  Created by wuyong on 2017/10/24.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWVersion.h"
#import <UIKit/UIKit.h>

@interface FWVersionManager ()

@property (nonatomic, strong) NSDate *checkDate;

@property (nonatomic, assign) BOOL hasResult;

@property (nonatomic, strong) NSMutableDictionary *dataMigrators;

@end

@implementation FWVersionManager

+ (FWVersionManager *)sharedInstance
{
    static FWVersionManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWVersionManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        _status = FWVersionStatusPublish;
        _delayDays = 1;
        _checkDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWVersionManagerCheckDate"];
        
        _dataVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWVersionManagerDataVersion"];
        _dataMigrators = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Store

- (BOOL)checkVersion:(NSInteger)interval completion:(void (^)(void))completion
{
    if (interval > 0) {
        if (!self.checkDate) {
            self.checkDate = [self toCheckDate:[NSDate date]];
            [self requestVersion:completion];
            return YES;
        } else {
            // 根据当天0点时间和缓存0点时间计算间隔天数，大于等于interval需要请求。效果为每隔N天第一次运行时检查更新
            NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:self.checkDate toDate:[self toCheckDate:[NSDate date]] options:0];
            if (components.day >= interval) {
                [self requestVersion:completion];
                return YES;
            }
        }
    } else {
        [self requestVersion:completion];
        return YES;
    }
    return NO;
}

- (void)openAppStore
{
    NSString *storeString = [NSString stringWithFormat:@"https://apps.apple.com/app/id%@", self.appId];
    NSURL *storeUrl = [NSURL URLWithString:storeString];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:storeUrl options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:storeUrl];
        }
    });
}

#pragma mark - Data

- (BOOL)checkDataVersion:(NSString *)version migrator:(void (^)(void))migrator
{
    // 需要执行时才放到队列中
    if ([self checkDataVersion:version]) {
        [self.dataMigrators setObject:migrator forKey:version];
        return YES;
    }
    return NO;
}

- (BOOL)migrateData:(void (^)(void))completion
{
    // 版本号从低到高排序
    NSArray *versions = [self.dataMigrators.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    // 是否需要执行迁移
    BOOL result = NO;
    for (NSString *version in versions) {
        if ([self checkDataVersion:version]) {
            void (^migrator)(void) = [self.dataMigrators objectForKey:version];
            if (migrator) {
                // 执行并从队列移除
                migrator();
                [self.dataMigrators removeObjectForKey:version];
                result = YES;
                
                // 保存当前数据版本
                _dataVersion = version;
                [[NSUserDefaults standardUserDefaults] setObject:self.dataVersion forKey:@"FWVersionManagerDataVersion"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
    
    // 执行迁移完成主线程回调
    if (result && completion) {
        dispatch_async(dispatch_get_main_queue(), completion);
    }
    return result;
}

#pragma mark - Private

- (void)requestVersion:(void (^)(void))completion
{
    NSMutableString *requestUrl = [[NSMutableString alloc] initWithString:@"https://itunes.apple.com/lookup"];
    if (self.appId.length > 0) {
        [requestUrl appendFormat:@"?id=%@", self.appId];
    } else {
        [requestUrl appendFormat:@"?bundleId=%@", [NSBundle mainBundle].bundleIdentifier];
    }
    if (self.countryCode.length > 0) {
        [requestUrl appendFormat:@"&country=%@", self.countryCode];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestUrl] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data.length > 0 && !error) {
            [self parseResponse:data completion:completion];
        }
    }];
    [task resume];
}

- (void)parseResponse:(NSData *)data completion:(void (^)(void))completion
{
    // 解析数据错误
    NSDictionary<NSString *, id> *dataDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray<NSDictionary<NSString *, id> *> *results = dataDict ? dataDict[@"results"] : nil;
    if (!dataDict || !results) {
        return;
    }
    
    // 第一个版本审核中查询不到结果
    self.hasResult = (results.count > 0);
    if (!self.hasResult) {
        [self checkCallback:completion];
        return;
    }

    // 是否兼容当前iOS系统版本
    NSDictionary<NSString *, id> *appData = [results firstObject];
    if (![self isOsCompatible:appData]) {
        [self checkCallback:completion];
        return;
    }
    
    // 请求成功更新检查日期
    self.checkDate = [self toCheckDate:[NSDate date]];
    [[NSUserDefaults standardUserDefaults] setObject:self.checkDate forKey:@"FWVersionManagerCheckDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 检查发布日期是否满足条件(当前时间比发布时间间隔delayDays及以上)
    NSString *releaseDateString = appData[@"currentVersionReleaseDate"];
    if (releaseDateString == nil) {
        [self checkCallback:completion];
        return;
    }
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    NSDate *releaseDate = [dateFormatter dateFromString:releaseDateString];
    NSDateComponents *components = [NSCalendar.currentCalendar components:NSCalendarUnitDay fromDate:releaseDate toDate:[NSDate date] options:0];
    if (components.day < self.delayDays) {
        [self checkCallback:completion];
        return;
    }
    
    // 间隔day大于等于delayDays说明满足条件则获取版本信息
    if (self.latestVersion.length < 1) {
        _latestVersion = appData[@"version"];
    }
    if (self.releaseNotes.length < 1) {
        _releaseNotes = appData[@"releaseNotes"];
    }
    if (self.appId.length < 1) {
        self.appId = appData[@"trackId"];
    }
    [self checkCallback:completion];
}

- (void)checkCallback:(void (^)(void))completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.latestVersion.length > 0) {
            NSComparisonResult result = [self.currentVersion compare:self.latestVersion options:NSNumericSearch];
            // 当前版本小于最新版本，需要更新
            if (result == NSOrderedAscending) {
                self.status = FWVersionStatusUpdate;
            // 当前版本大于最新版本，正在审核
            } else if (result == NSOrderedDescending) {
                self.status = FWVersionStatusAudit;
            // 当前版本等于最新版本，已发布
            } else {
                self.status = FWVersionStatusPublish;
            }
        } else {
            // 有结果，但不符合条件，不需要更新
            if (self.hasResult) {
                self.status = FWVersionStatusPublish;
            // 第一次审核查询不到结果，正在审核
            } else {
                self.status = FWVersionStatusAudit;
            }
        }
        
        if (completion) {
            completion();
        }
    });
}

- (BOOL)isOsCompatible:(NSDictionary<NSString *, id> *)appData
{
    NSString *requiresOSVersion = appData[@"minimumOsVersion"];
    if (requiresOSVersion != nil) {
        NSString *systemVersion = [UIDevice currentDevice].systemVersion;
        if (([systemVersion compare:requiresOSVersion options:NSNumericSearch] == NSOrderedDescending) ||
            ([systemVersion compare:requiresOSVersion options:NSNumericSearch] == NSOrderedSame)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)checkDataVersion:(NSString *)version
{
    // 指定版本大于当前版本不执行
    if ([version compare:self.currentVersion options:NSNumericSearch] == NSOrderedDescending) {
        return NO;
    }
    // 第一次需要执行
    if (!self.dataVersion) {
        return YES;
    }
    // 当前数据版本小于指定版本需要执行
    if ([self.dataVersion compare:version options:NSNumericSearch] == NSOrderedAscending) {
        return YES;
    }
    return NO;
}

- (NSDate *)toCheckDate:(NSDate *)date
{
    // 转换为当天0点时间
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    return [calendar dateFromComponents:components];
}

@end
