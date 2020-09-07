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

- (NSDictionary *)fwQueryParams
{
    if (!self.absoluteString.length) {
        return nil;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:self.absoluteString];
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.name && obj.value) {
            [params setObject:obj.value forKey:obj.name];
        }
    }];
    return [params copy];
}

#pragma mark - Map

+ (instancetype)fwMapsURLWithString:(NSString *)string params:(NSDictionary *)params
{
    NSMutableString *urlString = [[NSMutableString alloc] initWithString:string];
    [urlString appendString:@"?"];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *valueStr = [[[NSString stringWithFormat:@"%@", value] stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendFormat:@"%@=%@&", key, valueStr];
    }];
    return [self URLWithString:[urlString substringToIndex:urlString.length - 1]];
}

+ (instancetype)fwAppleMapsURLWithAddr:(NSString *)addr options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (addr.length > 0) {
        [params setObject:addr forKey:@"q"];
    }
    return [self fwMapsURLWithString:@"http://maps.apple.com/" params:params];
}

+ (instancetype)fwAppleMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (saddr.length > 0) {
        [params setObject:saddr forKey:@"saddr"];
    }
    if (daddr.length > 0) {
        [params setObject:daddr forKey:@"daddr"];
    }
    return [self fwMapsURLWithString:@"http://maps.apple.com/" params:params];
}

+ (instancetype)fwGoogleMapsURLWithAddr:(NSString *)addr options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (addr.length > 0) {
        [params setObject:addr forKey:@"q"];
    }
    return [self fwMapsURLWithString:@"comgooglemaps://" params:params];
}

+ (instancetype)fwGoogleMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr mode:(NSString *)mode options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (saddr.length > 0) {
        [params setObject:saddr forKey:@"saddr"];
    }
    if (daddr.length > 0) {
        [params setObject:daddr forKey:@"daddr"];
    }
    [params setObject:(mode.length > 0 ? mode : @"driving") forKey:@"directionsmode"];
    return [self fwMapsURLWithString:@"comgooglemaps://" params:params];
}

+ (instancetype)fwBaiduMapsURLWithAddr:(NSString *)addr options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (addr.length > 0) {
        if ([addr fwIsFormatCoordinate]) {
            [params setObject:addr forKey:@"location"];
        } else {
            [params setObject:addr forKey:@"address"];
        }
    }
    if (![params objectForKey:@"coord_type"]) {
        [params setObject:@"gcj02" forKey:@"coord_type"];
    }
    if (![params objectForKey:@"src"]) {
        [params setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] forKey:@"src"];
    }
    return [self fwMapsURLWithString:@"baidumap://map/geocoder" params:params];
}

+ (instancetype)fwBaiduMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr mode:(NSString *)mode options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (saddr.length > 0) {
        [params setObject:saddr forKey:@"origin"];
    }
    if (daddr.length > 0) {
        [params setObject:daddr forKey:@"destination"];
    }
    [params setObject:(mode.length > 0 ? mode : @"driving") forKey:@"mode"];
    if (![params objectForKey:@"coord_type"]) {
        [params setObject:@"gcj02" forKey:@"coord_type"];
    }
    if (![params objectForKey:@"src"]) {
        [params setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] forKey:@"src"];
    }
    return [self fwMapsURLWithString:@"baidumap://map/direction" params:params];
}

@end
