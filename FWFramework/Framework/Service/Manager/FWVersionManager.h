//
//  FWVersionManager.h
//  FWFramework
//
//  Created by wuyong on 2017/10/24.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <Foundation/Foundation.h>

// 版本状态
typedef NS_ENUM(NSInteger, FWVersionStatus) {
    // 已发布
    FWVersionStatusPublish = 0,
    // 需要更新
    FWVersionStatusUpdate,
    // 正在审核
    FWVersionStatusAudit,
};

// 版本管理器
@interface FWVersionManager : NSObject

// 当前版本号。小于最新版本号表示需要更新，大于最新版本号表示正在审核
@property (nonatomic, copy, readonly) NSString *currentVersion;

// 数据版本号。当数据版本号小于当前版本号时，会依次执行数据更新句柄
@property (nonatomic, copy, readonly) NSString *dataVersion;

// 最新版本号。可自定义。默认从AppStore获取
@property (nonatomic, copy) NSString *latestVersion;

// 当前版本状态。可自定义。根据最新版本号和当前版本号比较获得
@property (nonatomic, assign) FWVersionStatus status;

// 应用Id，可选，默认自动根据BundleId获取
@property (nonatomic, copy) NSString *appId;

// 地区码，可选，仅当app不能在美区访问时提供
@property (nonatomic, copy) NSString *countryCode;

// 版本发布延迟检测天数，可选，默认1天，防止上架后AppStore缓存用户无法立即更新
@property (nonatomic, assign) NSInteger delayDays;

// 单例对象
+ (instancetype)sharedInstance;

// 检查应用版本号并进行比较，检查成功时回调。interval为频率(天)，0立即检查，1一天一次，7一周一次
- (void)checkVersion:(NSInteger)interval completion:(void (^)(void))completion;

// 跳转AppStore更新页
- (void)openStore;

// 设置数据指定版本更新句柄，调用updateData之前生效，仅会调用一次
- (void)dataHandler:(NSString *)version handler:(void (^)(void))handler;

// 比较数据版本号并依次进行数据更新，更新成功时回调
- (void)updateData:(void (^)(void))completion;

@end
