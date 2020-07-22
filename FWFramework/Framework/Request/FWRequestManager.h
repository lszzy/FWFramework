/*!
 @header     FWRequestManager.h
 @indexgroup FWFramework
 @brief      FWRequestManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/7/18
 */

#import "FWRequest.h"
#import "FWNetworkAgent.h"
#import "FWBatchRequest.h"
#import "FWBatchRequestAgent.h"
#import "FWChainRequest.h"
#import "FWChainRequestAgent.h"
#import "FWNetworkConfig.h"
#import "FWNetworkPrivate.h"
#import "FWCoroutine.h"

NS_ASSUME_NONNULL_BEGIN

// TODO: FWRequestManager

#pragma mark - FWRequest+FWPromise

@class FWPromise;

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
