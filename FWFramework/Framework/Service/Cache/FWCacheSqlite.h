//
//  FWCacheFile.h
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheAbstract.h"

// Sqlite缓存
@interface FWCacheSqlite : FWCacheAbstract

// 单例对象
+ (instancetype)sharedInstance;

// 指定路径
- (instancetype)initWithPath:(NSString *)path;

@end
