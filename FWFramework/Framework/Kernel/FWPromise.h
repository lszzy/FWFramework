/*!
 @header     FWPromise.h
 @indexgroup FWFramework
 @brief      FWPromise约定类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-07-18
 */

#import "FWRequest.h"
#import "FWCoroutine.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWPromise

/*! @brief Resolve代码块，标记完成value|失败error|进度progress */
typedef void (^FWPromiseBlock)(id _Nullable);

/*! @brief Then代码块，支持返回value|error|promise */
typedef id _Nullable (^FWThenBlock)(id _Nullable);

/*! @brief Promise代码块，按条件触发resolve|reject */
typedef void (^FWPromiseConstructor)(FWPromiseBlock resolve, FWPromiseBlock reject);

/*! @brief ProgressPromise代码块，按条件触发resolve|reject|progress */
typedef void (^FWProgressPromiseConstructor)(FWPromiseBlock resolve, FWPromiseBlock reject, FWPromiseBlock progress);

/*!
 @brief FWPromise约定类，参考自RWPromiseKit
 
 @see https://github.com/deput/RWPromiseKit
 */
@interface FWPromise : NSObject

/*! @brief 当前约定标记完成时触发的代码块，支持返回value|error|promise */
@property (nonatomic, readonly) FWPromise *(^then)(FWThenBlock);

/*! @brief 当前约定标记完成时触发的代码块，无返回值 */
@property (nonatomic, readonly) FWPromise *(^done)(FWPromiseBlock);

/*! @brief 当前约定标记失败时触发的代码块，错误处理 */
@property (nonatomic, readonly) FWPromise *(^catch)(FWPromiseBlock);

/*! @brief 当前约定完成或失败时都会触发的代码块，回收处理 */
@property (nonatomic, readonly) void (^finally)(dispatch_block_t);

/*! @brief 当前约定进行时触发的代码块，仅progress创建的约定生效 */
@property (nonatomic, readonly) FWPromise *(^progress)(FWPromiseBlock);

/*! @brief 超时约定，当前约定超时触发时仍未完成则标记失败 */
@property (nonatomic, readonly) FWPromise *(^timeout)(NSTimeInterval);

/*! @brief 重试约定，当前约定失败时重试N次，仍然失败则标记失败 */
@property (nonatomic, readonly) FWPromise *(^retry)(NSUInteger);

/*!
 @brief 创建约定
 
 @return 约定
 */
+ (FWPromise *)promise;

/*!
 @brief 创建标准约定
 
 @param block 约定代码块
 @return 标准约定
 */
+ (FWPromise *)promise:(FWPromiseConstructor)block;

/*!
 @brief 快速创建标记完成的约定
 
 @param value 完成值
 @return 完成约定
 */
+ (FWPromise *)resolve:(nullable id)value;

/*!
 @brief 快速创建标记失败的约定
 
 @param error 错误信息
 @return 失败约定
 */
+ (FWPromise *)reject:(nullable id)error;

/*!
 @brief 标记约定已完成
 
 @param value 完成值
 */
- (void)resolve:(nullable id)value;

/*!
 @brief 标记约定已失败
 
 @param error 错误信息
 */
- (void)reject:(nullable id)error;

/*!
 @brief 标记约定进行中，仅progress创建的约定生效
 
 @param percent 进行比率
 */
- (void)progress:(nullable id)percent;

/*!
 @brief 创建支持进度的约定
 
 @param block 约定block
 @return 进度约定
 */
+ (FWPromise *)progress:(FWProgressPromiseConstructor)block;

/*!
 @brief 创建定时约定，当定时触发时标记完成
 
 @param interval 约定时间
 @return 定时约定
 */
+ (FWPromise *)timer:(NSTimeInterval)interval;

/*!
 @brief 创建一组约定的合集约定，当组内所有约定完成时标记完成，任一约定失败时标记失败
 
 @param promises 一组约定
 @return 合集约定
 */
+ (FWPromise *)all:(NSArray<FWPromise *> *)promises;

/*!
 @brief 创建一组约定的竞速约定，当组内任一约定完成时标记完成，所有约定失败时标记失败
 
 @param promises 一组约定
 @return 竞速约定
 */
+ (FWPromise *)race:(NSArray<FWPromise *> *)promises;

@end

#pragma mark - FWRequest+FWPromise

/*!
 @brief FWRequest约定分类
 */
@interface FWBaseRequest (FWPromise)

// 创建promise对象并开始请求，参数为request|error
- (FWPromise *)promise;

// 创建coroutine对象并开始请求，参数为request|error
- (FWCoroutineClosure)coroutine;

@end

@interface FWBatchRequest (FWPromise)

// 创建promise对象并开始请求，参数为request|error
- (FWPromise *)promise;

// 创建coroutine对象并开始请求，参数为request|error
- (FWCoroutineClosure)coroutine;

@end

NS_ASSUME_NONNULL_END
