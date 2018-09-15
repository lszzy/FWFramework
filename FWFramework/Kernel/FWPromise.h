/*!
 @header     FWPromise.h
 @indexgroup FWFramework
 @brief      FWPromise约定类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-07-18
 */

#import <Foundation/Foundation.h>

typedef void (^FWResolveBlock)(id value);

typedef void (^FWRejectBlock)(NSError *error);

typedef void (^FWProgressBlock)(double ratio, id value);

typedef id (^FWThenBlock)(id value);

typedef void (^FWPromiseBlock)(FWResolveBlock resolve, FWRejectBlock reject);

typedef void (^FWProgressPromiseBlock)(FWResolveBlock resolve, FWRejectBlock reject, FWProgressBlock progress);

/*!
 @brief FWPromise约定类，参考自RWPromiseKit
 
 @see https://github.com/deput/RWPromiseKit
 */
@interface FWPromise : NSObject

+ (FWPromise *)promise:(FWPromiseBlock)block;

+ (FWPromise *)progress:(FWProgressPromiseBlock)block;

+ (FWPromise *)resolve:(id)value;

+ (FWPromise *)reject:(NSError *)error;

- (FWPromise *(^)(FWThenBlock))then;

- (FWPromise *(^)(FWRejectBlock))catch;

- (FWPromise *(^)(FWProgressBlock))progress;

- (void (^)(dispatch_block_t))finally;

- (void)resolve:(id)value;

- (void)reject:(NSError *)error;

- (void)progress:(double)ratio value:(id)value;

+ (FWPromise *)all:(NSArray<FWPromise *> *)promises;

+ (FWPromise *)race:(NSArray<FWPromise *> *)promises;

+ (FWPromise *)timer:(NSTimeInterval)interval;

- (FWPromise *(^)(NSTimeInterval))timeout;

- (FWPromise *(^)(NSUInteger))retry;

@end
