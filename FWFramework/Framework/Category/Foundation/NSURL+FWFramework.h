/*!
 @header     NSURL+FWFramework.h
 @indexgroup FWFramework
 @brief      NSURL+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/3
 */

#import <Foundation/Foundation.h>

/*!
 @brief NSURL+FWFramework
 */
@interface NSURL (FWFramework)

// 生成URL，中文自动URL编码
+ (instancetype)fwURLWithString:(NSString *)URLString;

// 生成URL，中文自动URL编码
+ (instancetype)fwURLWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL;

@end
