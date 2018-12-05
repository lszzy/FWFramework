/*!
 @header     NSURL+FWFramework.m
 @indexgroup FWFramework
 @brief      NSURL+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/3
 */

#import "NSURL+FWFramework.h"

@implementation NSURL (FWFramework)

+ (instancetype)fwURLWithString:(NSString *)URLString
{
    NSURL *url = [self URLWithString:URLString];
    // 如果生成失败，自动URL编码再试
    if (!url && URLString.length > 0) {
        url = [self URLWithString:[URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    return url;
}

+ (instancetype)fwURLWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL
{
    NSURL *url = [self URLWithString:URLString relativeToURL:baseURL];
    // 如果生成失败，自动URL编码再试
    if (!url && URLString.length > 0) {
        url = [self URLWithString:[URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] relativeToURL:baseURL];
    }
    return url;
}

@end
