//
//  FWVersion.h
//  FWFramework
//
//  Created by wuyong on 2017/10/24.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 版本状态
typedef NS_ENUM(NSInteger, FWVersionStatus) {
    /// 已发布
    FWVersionStatusPublish = 0,
    /// 需要更新
    FWVersionStatusUpdate,
    /// 正在审核
    FWVersionStatusAudit,
};

/// 版本管理器
@interface FWVersionManager : NSObject

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWVersionManager *sharedInstance;

#pragma mark - Store

/// 当前版本号。小于最新版本号表示需要更新，大于最新版本号表示正在审核
@property (nonatomic, copy, readonly) NSString *currentVersion;

/// 最新版本号。可自定义。默认从AppStore获取
@property (nonatomic, copy, nullable) NSString *latestVersion;

/// 当前版本状态。可自定义。根据最新版本号和当前版本号比较获得
@property (nonatomic, assign) FWVersionStatus status;

/// 最新版本更新备注。可自定义。默认从AppStore获取
@property (nonatomic, copy, nullable) NSString *releaseNotes;

/// 应用Id，可选，默认自动根据BundleId获取
@property (nonatomic, copy, nullable) NSString *appId;

/// 地区码，可选，仅当app不能在美区访问时提供。示例：中国-cn
@property (nonatomic, copy, nullable) NSString *countryCode;

/// 版本发布延迟检测天数，可选，默认1天，防止上架后AppStore缓存用户无法立即更新
@property (nonatomic, assign) NSInteger delayDays;

/// 检查应用版本号并进行比较，检查成功时回调。interval为频率(天)，0立即检查，1一天一次，7一周一次
- (BOOL)checkVersion:(NSInteger)interval completion:(nullable void (^)(void))completion;

/// 跳转AppStore更新页
- (void)openAppStore;

#pragma mark - Data

/// 数据版本号。当数据版本号小于当前版本号时，会依次执行数据更新句柄
@property (nonatomic, copy, readonly, nullable) NSString *dataVersion;

/// 检查数据版本号并指定版本迁移方法，调用migrateData之前生效，仅会调用一次
- (BOOL)checkDataVersion:(NSString *)version migrator:(void (^)(void))migrator;

/// 比较数据版本号并依次进行数据迁移，迁移完成时回调(不执行迁移不回调)
- (BOOL)migrateData:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
