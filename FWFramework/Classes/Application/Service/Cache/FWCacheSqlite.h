//
//  FWCacheFile.h
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheAbstract.h"

NS_ASSUME_NONNULL_BEGIN

/// Sqlite缓存
@interface FWCacheSqlite : FWCacheAbstract

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWCacheSqlite *sharedInstance;

/// 指定路径
- (instancetype)initWithPath:(nullable NSString *)path;

@end

NS_ASSUME_NONNULL_END
