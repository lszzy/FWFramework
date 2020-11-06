/*!
 @header     NSBundle+FWFramework.m
 @indexgroup FWFramework
 @brief      NSBundle分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import "NSBundle+FWFramework.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

@implementation NSBundle (FWFramework)

+ (instancetype)fwBundleWithName:(NSString *)name
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:([name hasSuffix:@".bundle"] ? nil : @"bundle")];
    return path ? [NSBundle bundleWithPath:path] : nil;
}

#pragma mark - Vendor

+ (void)fwSetGooglePlacesLanguage:(NSString *)language
{
    static NSString *customLanguage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleMethod(objc_getClass("GMSPabloClient"), NSSelectorFromString(@"URLComponentsForPath:sessionToken:"), nil, FWSwizzleType(id), FWSwizzleReturn(id), FWSwizzleArgs(id path, id token), FWSwizzleCode({
            id result = FWSwizzleOriginal(path, token);
            
            if (customLanguage && [result isKindOfClass:[NSURLComponents class]]) {
                NSURLComponents *components = (NSURLComponents *)result;
                NSMutableArray<NSURLQueryItem *> *queryItems = [components.queryItems mutableCopy];
                [queryItems addObject:[NSURLQueryItem queryItemWithName:@"language" value:customLanguage]];
                components.queryItems = queryItems;
            }
            
            return result;
        }));
    });
    
    customLanguage = language;
}

@end
