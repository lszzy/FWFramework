/*!
 @header     NSDictionary+FWFramework.m
 @indexgroup FWFramework
 @brief      NSDictionary分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import "NSDictionary+FWFramework.h"

@implementation NSDictionary (FWFramework)

- (BOOL)fwIncludeNull
{
    __block BOOL includeNull = NO;
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSNull class]]) {
            includeNull = YES;
            *stop = YES;
        }
    }];
    return includeNull;
}

@end
