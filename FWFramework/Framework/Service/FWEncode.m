/*!
 @header     FWEncode.m
 @indexgroup FWFramework
 @brief      FWEncode
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/19
 */

#import "FWEncode.h"
#import "FWSwizzle.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (FWEncode)

#pragma mark - Json

+ (NSString *)fwJsonEncode:(id)object
{
    if (!object) {
        return nil;
    }
    
    NSError *err = nil;
    id data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&err];
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

#pragma mark - Url

- (NSString *)fwUrlEncodeComponent
{
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"] invertedSet]];
}

- (NSString *)fwUrlDecodeComponent
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)self, CFSTR("")));
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

+ (NSString *)fwQueryEncode:(NSDictionary<NSString *,id> *)dictionary
{
    NSMutableString *string = [NSMutableString string];
    for (NSString *key in [dictionary allKeys]) {
        if ([string length]) {
            [string appendString:@"&"];
        }
        NSString *value = [[dictionary objectForKey:key] description];
        value = [value stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"] invertedSet]];
        [string appendFormat:@"%@=%@", key, value];
    }
    return string;
}

- (NSDictionary<NSString *,NSString *> *)fwQueryDecode
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *parameters = [self componentsSeparatedByString:@"&"];
    for (NSString *parameter in parameters) {
        NSArray<NSString *> *contents = [parameter componentsSeparatedByString:@"="];
        if ([contents count] == 2) {
            NSString *key = [contents objectAtIndex:0];
            NSString *value = [contents objectAtIndex:1];
            dict[key] = [value stringByRemovingPercentEncoding];
        }
    }
    return [dict copy];
}

#pragma mark - Md5

- (NSString *)fwMd5Encode
{
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

- (NSString *)fwMd5EncodeFile
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:self];
    if (!handle) {
        return nil;
    }
    
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    BOOL done = NO;
    while (!done) {
        NSData *fileData = [handle readDataOfLength:256];
        CC_MD5_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
        if ([fileData length] == 0) {
            done = YES;
        }
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSString *result = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                        digest[0], digest[1],
                        digest[2], digest[3],
                        digest[4], digest[5],
                        digest[6], digest[7],
                        digest[8], digest[9],
                        digest[10], digest[11],
                        digest[12], digest[13],
                        digest[14], digest[15]];
    return result;
}

@end

#pragma mark - NSData+FWEncode

@implementation NSData (FWEncode)

#pragma mark - Json

+ (NSData *)fwJsonEncode:(id)object
{
    if (!object) {
        return nil;
    }
    
    NSError *err = nil;
    id data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&err];
    if (err) {
        return nil;
    }
    return data;
}

- (id)fwJsonDecode
{
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:&err];
    if (err) {
        return nil;
    }
    return obj;
}

#pragma mark - Base64

- (NSData *)fwBase64Encode
{
    return [self base64EncodedDataWithOptions:0];
}

- (NSData *)fwBase64Decode
{
    return [[NSData alloc] initWithBase64EncodedData:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

@end

#pragma mark - FWSafeType

NSNumber * FWSafeNumber(id value) {
    if (!value) return @0;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    NSString *string = [NSString stringWithFormat:@"%@", value];
    return [NSNumber numberWithDouble:[string doubleValue]];
}

NSString * FWSafeString(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    return [NSString stringWithFormat:@"%@", value];
}

NSURL * FWSafeURL(id value) {
    if (!value) return [NSURL new];
    if ([value isKindOfClass:[NSURL class]]) return value;
    if ([value isKindOfClass:[NSURLRequest class]]) return [value URL] ?: [NSURL new];
    return [NSURL fwURLWithString:FWSafeString(value)] ?: [NSURL new];
}

#pragma mark - NSObject+FWSafeType

@implementation NSObject (FWSafeType)

- (BOOL)fwIsNotNull
{
    return !(self == nil ||
             [self isKindOfClass:[NSNull class]]);
}

- (BOOL)fwIsNotEmpty
{
    return !(self == nil ||
             [self isKindOfClass:[NSNull class]] ||
             ([self respondsToSelector:@selector(length)] && [(NSData *)self length] == 0) ||
             ([self respondsToSelector:@selector(count)] && [(NSArray *)self count] == 0));
}

- (NSInteger)fwAsInteger
{
    return [[self fwAsNSNumber] integerValue];
}

- (float)fwAsFloat
{
    return [[self fwAsNSNumber] floatValue];
}

- (double)fwAsDouble
{
    return [[self fwAsNSNumber] doubleValue];
}

- (BOOL)fwAsBool
{
    return [[self fwAsNSNumber] boolValue];
}

- (NSNumber *)fwAsNSNumber
{
    if ([self isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)self;
    } else if ([self isKindOfClass:[NSString class]]) {
        return [NSNumber numberWithDouble:[(NSString *)self doubleValue]];
    } else if ([self isKindOfClass:[NSDate class]]) {
        return [NSNumber numberWithDouble:[(NSDate *)self timeIntervalSince1970]];
    } else if ([self isKindOfClass:[NSNull class]]) {
        return [NSNumber numberWithInteger:0];
    } else {
        return nil;
    }
}

- (NSString *)fwAsNSString
{
    if ([self isKindOfClass:[NSNull class]]) {
        return nil;
    } else if ([self isKindOfClass:[NSString class]]) {
        return (NSString *)self;
    } else if ([self isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter stringFromDate:(NSDate *)self];
    } else if ([self isKindOfClass:[NSData class]]) {
        return [[NSString alloc] initWithData:(NSData *)self encoding:NSUTF8StringEncoding];
    } else {
        return [NSString stringWithFormat:@"%@", self];
    }
}

- (NSDate *)fwAsNSDate
{
    if ([self isKindOfClass:[NSDate class]]) {
        return (NSDate *)self;
    } else if ([self isKindOfClass:[NSString class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter dateFromString:(NSString *)self];
    } else if ([self isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)self doubleValue]];
    } else {
        return nil;
    }
}

- (NSData *)fwAsNSData
{
    if ([self isKindOfClass:[NSString class]]) {
        return [(NSString *)self dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([self isKindOfClass:[NSData class]]) {
        return (NSData *)self;
    } else {
        return nil;
    }
}

- (NSArray *)fwAsNSArray
{
    if ([self isKindOfClass:[NSArray class]]) {
        return (NSArray *)self;
    } else {
        return nil;
    }
}

- (NSMutableArray *)fwAsNSMutableArray
{
    if ([self isKindOfClass:[NSMutableArray class]]) {
        return (NSMutableArray *)self;
    } else if ([self isKindOfClass:[NSArray class]]) {
        return [NSMutableArray arrayWithArray:(NSArray *)self];
    } else {
        return nil;
    }
}

- (NSDictionary *)fwAsNSDictionary
{
    if ([self isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)self;
    } else {
        return nil;
    }
}

- (NSMutableDictionary *)fwAsNSMutableDictionary
{
    if ([self isKindOfClass:[NSMutableDictionary class]]) {
        return (NSMutableDictionary *)self;
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self];
    } else {
        return nil;
    }
}

- (id)fwAsClass:(Class)clazz
{
    if ([self isKindOfClass:clazz]) {
        return self;
    } else {
        return nil;
    }
}

@end

#pragma mark - NSNumber+FWSafeType

@implementation NSNumber (FWSafeType)

- (BOOL)fwIsEqualToNumber:(NSNumber *)number
{
    if (!number) return NO;
    
    return [self isEqualToNumber:number];
}

- (NSComparisonResult)fwCompare:(NSNumber *)number
{
    if (!number) return NSOrderedDescending;
    
    return [self compare:number];
}

@end

#pragma mark - NSString+FWSafeType

@implementation NSString (FWSafeType)

- (NSString *)fwTrimString
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSData *)fwUTF8Data
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)fwSubstringFromIndex:(NSInteger)from
{
    if (from < 0) {
        return nil;
    }
    
    if (from > self.length) {
        return nil;
    }
    
    return [self substringFromIndex:from];
}

- (NSString *)fwSubstringToIndex:(NSInteger)to
{
    if (to < 0) {
        return nil;
    }
    
    if (to > self.length) {
        return nil;
    }
    
    return [self substringToIndex:to];
}

- (NSString *)fwSubstringWithRange:(NSRange)range
{
    if (range.location > self.length) {
        return nil;
    }
    
    if (range.length > self.length) {
        return nil;
    }
    
    if (range.location + range.length > self.length) {
        return nil;
    }
    
    return [self substringWithRange:range];
}

@end

#pragma mark - NSData+FWSafeType

@implementation NSData (FWSafeType)

- (NSString *)fwUTF8String
{
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - NSNull+FWSafeType

@implementation NSNull (FWSafeType)

+ (void)load
{
#ifndef DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(NSNull, @selector(methodSignatureForSelector:), FWSwizzleReturn(NSMethodSignature *), FWSwizzleArgs(SEL selector), FWSwizzleCode({
            NSMethodSignature *signature = FWSwizzleOriginal(selector);
            if (!signature) {
                return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
            }
            return signature;
        }));
        FWSwizzleClass(NSNull, @selector(forwardInvocation:), FWSwizzleReturn(void), FWSwizzleArgs(NSInvocation *invocation), FWSwizzleCode({
            invocation.target = nil;
            [invocation invoke];
        }));
    });
#endif
}

@end

#pragma mark - NSURL+FWSafeType

@implementation NSURL (FWSafeType)

- (NSDictionary<NSString *,NSString *> *)fwQueryDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:self.absoluteString ?: @""];
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dict[obj.name] = [obj.value stringByRemovingPercentEncoding];
    }];
    return [dict copy];
}

+ (instancetype)fwURLWithString:(NSString *)URLString
{
    if (!URLString) return nil;
    
    NSURL *url = [self URLWithString:URLString];
    // 如果生成失败，自动URL编码再试
    if (!url && URLString.length > 0) {
        url = [self URLWithString:[URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    return url;
}

+ (instancetype)fwURLWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL
{
    if (!URLString) return nil;
    
    NSURL *url = [self URLWithString:URLString relativeToURL:baseURL];
    // 如果生成失败，自动URL编码再试
    if (!url && URLString.length > 0) {
        url = [self URLWithString:[URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] relativeToURL:baseURL];
    }
    return url;
}

@end

#pragma mark - NSArray+FWSafeType

@implementation NSArray (FWSafeType)

- (id)fwObjectAtIndex:(NSInteger)index
{
    if (index < 0) {
        return nil;
    }
    
    if (index >= self.count) {
        return nil;
    }
    
    return [self objectAtIndex:index];
}

- (NSArray *)fwSubarrayWithRange:(NSRange)range
{
    if (range.location > self.count) {
        return nil;
    }
    
    if (range.length > self.count) {
        return nil;
    }
    
    if (range.location + range.length > self.count) {
        return nil;
    }
    
    return [self subarrayWithRange:range];
}

@end

#pragma mark - NSMutableArray+FWSafeType

@implementation NSMutableArray (FWSafeType)

- (void)fwAddObject:(id)object
{
    if (object == nil) {
        return;
    }
    
    [self addObject:object];
}

- (void)fwRemoveObjectAtIndex:(NSInteger)index
{
    if (index < 0) {
        return;
    }
    
    if (index >= self.count) {
        return;
    }
    
    [self removeObjectAtIndex:index];
}

- (void)fwInsertObject:(id)object atIndex:(NSInteger)index
{
    if (object == nil) {
        return;
    }
    
    if (index < 0) {
        return;
    }
    
    if (index > self.count) {
        return;
    }
    
    [self insertObject:object atIndex:index];
}

- (void)fwReplaceObjectAtIndex:(NSInteger)index withObject:(id)object
{
    if (object == nil) {
        return;
    }
    
    if (index < 0) {
        return;
    }
    
    if (index >= self.count) {
        return;
    }
    
    [self replaceObjectAtIndex:index withObject:object];
}

- (void)fwRemoveObjectsInRange:(NSRange)range
{
    if (range.location > self.count) {
        return;
    }
    
    if (range.length > self.count) {
        return;
    }
    
    if (range.location + range.length > self.count) {
        return;
    }
    
    [self removeObjectsInRange:range];
}

- (void)fwInsertObjects:(NSArray *)objects atIndex:(NSInteger)index
{
    if (objects.count == 0) {
        return;
    }
    
    if (index < 0) {
        return;
    }
    
    if (index > self.count) {
        return;
    }
    
    for (NSInteger i = objects.count - 1; i >= 0; i--) {
        [self insertObject:objects[i] atIndex:index];
    }
}

@end

#pragma mark - NSDictionary+FWSafeType

@implementation NSDictionary (FWSafeType)

- (id)fwObjectForKey:(id)key
{
    if (!key) {
        return nil;
    }
    
    id object = [self objectForKey:key];
    if (object == nil || object == [NSNull null]) {
        return nil;
    }
    
    return object;
}

@end

#pragma mark - NSMutableDictionary+FWSafeType

@implementation NSMutableDictionary (FWSafeType)

- (void)fwRemoveObjectForKey:(id)key
{
    if (!key) {
        return;
    }
    
    [self removeObjectForKey:key];
}

- (void)fwSetObject:(id)object forKey:(id<NSCopying>)key
{
    if (!key) {
        return;
    }
    
    if (object == nil || object == [NSNull null]) {
        return;
    }
    
    [self setObject:object forKey:key];
}

@end
