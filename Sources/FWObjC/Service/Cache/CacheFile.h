//
//  CacheFile.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "CacheEngine.h"

NS_ASSUME_NONNULL_BEGIN

/// 文件缓存
NS_SWIFT_NAME(CacheFile)
@interface __FWCacheFile : __FWCacheEngine

/** 单例模式 */
@property (class, nonatomic, readonly) __FWCacheFile *sharedInstance NS_SWIFT_NAME(shared);

/// 指定路径
- (instancetype)initWithPath:(nullable NSString *)path;

@end

NS_ASSUME_NONNULL_END
