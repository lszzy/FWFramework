/*!
 @header     NSURL+FWFramework.h
 @indexgroup FWFramework
 @brief      NSURL+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/3
 */

#import <Foundation/Foundation.h>
#import "NSURL+FWVendor.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSURL+FWFramework
 */
@interface NSURL (FWFramework)

// 生成URL，中文自动URL编码
+ (nullable instancetype)fwURLWithString:(NSString *)URLString;

// 生成URL，中文自动URL编码
+ (nullable instancetype)fwURLWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL;

// 获取当前query的参数列表，不含空值
- (nullable NSDictionary *)fwQueryParams;

@end

NS_ASSUME_NONNULL_END
