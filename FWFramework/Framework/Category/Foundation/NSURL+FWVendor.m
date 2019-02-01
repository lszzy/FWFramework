/*!
 @header     NSURL+FWVendor.m
 @indexgroup FWFramework
 @brief      NSURL+FWVendor
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/31
 */

#import "NSURL+FWVendor.h"
#import "NSURL+FWFramework.h"

@implementation NSURL (FWVendor)

+ (instancetype)fwGoogleMapsURLWithQuery:(NSString *)query options:(NSDictionary *)options
{
    NSMutableString *urlString = [[NSMutableString alloc] initWithFormat:@"comgooglemaps://"];
    // q
    NSString *queryStr = query.length > 0 ? [[query stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"";
    [urlString appendFormat:@"?q=%@", queryStr];
    // options
    [options enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [urlString appendFormat:@"&%@=%@", key, obj];
    }];
    return [NSURL fwURLWithString:urlString];
}

+ (instancetype)fwGoogleMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr directionsmode:(NSString *)directionsmode options:(NSDictionary *)options
{
    NSMutableString *urlString = [[NSMutableString alloc] initWithFormat:@"comgooglemaps://"];
    // saddr
    NSString *saddrStr = saddr.length > 0 ? [[saddr stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"";
    [urlString appendFormat:@"?saddr=%@", saddrStr];
    // daddr
    NSString *daddrStr = daddr.length > 0 ? [[daddr stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"";
    [urlString appendFormat:@"&daddr=%@", daddrStr];
    // directionsmode
    [urlString appendFormat:@"&directionsmode=%@", (directionsmode.length > 0 ? directionsmode : @"walking")];
    // options
    [options enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [urlString appendFormat:@"&%@=%@", key, obj];
    }];
    return [NSURL fwURLWithString:urlString];
}

@end
