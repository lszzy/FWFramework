/*!
 @header     NSString+FWEncode.m
 @indexgroup FWFramework
 @brief      NSString+FWEncode
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "NSString+FWEncode.h"

@implementation NSString (FWEncode)

#pragma mark - Json

+ (NSString *)fwJsonEncode:(id)object
{
    NSError *err = nil;
    id data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&err];
    if (err) {
        return nil;
    }
    
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}

- (id)fwJsonDecode
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
    if (err) {
        return nil;
    }
    return obj;
}

#pragma mark - Unicode

- (NSUInteger)fwUnicodeLength
{
    NSUInteger strLength = 0;
    
    for (int i = 0; i < self.length; i++) {
        if ([self characterAtIndex:i] > 0xff) {
            strLength += 2;
        } else {
            strLength ++;
        }
    }
    
    return ceil(strLength / 2.0);
}

- (NSString *)fwUnicodeSubstring:(NSUInteger)length
{
    length = length * 2;
    
    int i = 0;
    int len = 0;
    while (i < self.length) {
        if ([self characterAtIndex:i] > 0xff) {
            len += 2;
        } else {
            len++;
        }
        
        i++;
        if (i >= self.length) {
            return self;
        }
        
        if (len == length) {
            return [self substringToIndex:i];
        } else if (len > length) {
            if (i - 1 <= 0) {
                return @"";
            }
            
            return [self substringToIndex:i - 1];
        }
    }
    
    return self;
}

- (NSString *)fwUnicodeEncode
{
    NSUInteger length = [self length];
    NSMutableString *retStr = [NSMutableString stringWithCapacity:0];
    for (int i = 0; i < length; i++) {
        unichar character = [self characterAtIndex:i];
        // 判断是否为英文或数字
        if ((character <= '9' && character >= '0') ||
            (character >= 'a' && character <= 'z') ||
            (character >= 'A' && character <= 'Z')) {
            [retStr appendFormat:@"%@", [self substringWithRange:NSMakeRange(i, 1)]];
        } else {
            [retStr appendFormat:@"\\u%.4x", [self characterAtIndex:i]];
        }
    }
    return retStr;
}

- (NSString *)fwUnicodeDecode
{
    NSString *tempStr = [self stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    tempStr = [tempStr stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    tempStr = [[@"\"" stringByAppendingString:tempStr] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr dataUsingEncoding:NSUTF8StringEncoding];
    
    // NSString *retStr = [NSPropertyListSerialization propertyListFromData:tempData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    NSString *retStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];
    return [retStr stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
}

#pragma mark - Base64

- (NSString *)fwBase64Encode
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    
    data = [data base64EncodedDataWithOptions:0];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return ret;
}

- (NSString *)fwBase64Decode
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) {
        return nil;
    }
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return ret;
}

#pragma mark - Url

- (NSString *)fwUrlEncodeComponent
{
    CFStringEncoding cfEncoding = kCFStringEncodingUTF8;
    NSString *str = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                 cfEncoding
                                                                                 );
    return str;
}

- (NSString *)fwUrlDecodeComponent
{
    CFStringEncoding cfEncoding = kCFStringEncodingUTF8;
    NSString *str = (__bridge NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                                                 NULL,
                                                                                                 (CFStringRef)self,
                                                                                                 CFSTR(""),
                                                                                                 cfEncoding
                                                                                                 );
    return str;
}

- (NSString *)fwUrlEncode
{
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

- (NSString *)fwUrlDecode
{
    return [self stringByRemovingPercentEncoding];
}

#pragma mark - Query

+ (NSString *)fwQueryEncode:(NSDictionary *)dictionary
{
    NSMutableString *string = [NSMutableString string];
    for (NSString *key in [dictionary allKeys]) {
        if ([string length]) {
            [string appendString:@"&"];
        }
        CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)[[dictionary objectForKey:key] description],
                                                                      NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                      kCFStringEncodingUTF8);
        [string appendFormat:@"%@=%@", key, escaped];
        CFRelease(escaped);
    }
    return string;
}

- (NSDictionary *)fwQueryDecode
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *parameters = [self componentsSeparatedByString:@"&"];
    for(NSString *parameter in parameters) {
        NSArray *contents = [parameter componentsSeparatedByString:@"="];
        if([contents count] == 2) {
            NSString *key = [contents objectAtIndex:0];
            NSString *value = [contents objectAtIndex:1];
            value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if (key && value) {
                [dict setObject:value forKey:key];
            }
        }
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
