/**
 @header     FWEncode.m
 @indexgroup FWFramework
      FWEncode
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/19
 */

#import "FWEncode.h"
#import "FWSwizzle.h"
#import <CommonCrypto/CommonDigest.h>

#pragma mark - FWStringWrapper+FWEncode

@implementation FWStringWrapper (FWEncode)

#pragma mark - Json

- (id)jsonDecode
{
    NSData *data = [self.base dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    
    return [data.fw jsonDecode];
}

#pragma mark - Base64

- (NSString *)base64Encode
{
    NSData *data = [self.base dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    
    data = [data base64EncodedDataWithOptions:0];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)base64Decode
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self.base options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) return nil;
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - Unicode

- (NSUInteger)unicodeLength
{
    NSUInteger strLength = 0;

    for (int i = 0; i < self.base.length; i++) {
        if ([self.base characterAtIndex:i] > 0xff) {
            strLength += 2;
        } else {
            strLength ++;
        }
    }
    
    return ceil(strLength / 2.0);
}

- (NSString *)unicodeSubstring:(NSUInteger)length
{
    length = length * 2;
    
    int i = 0;
    int len = 0;
    while (i < self.base.length) {
        if ([self.base characterAtIndex:i] > 0xff) {
            len += 2;
        } else {
            len++;
        }
        
        i++;
        if (i >= self.base.length) {
            return self.base;
        }
        
        if (len == length) {
            return [self.base substringToIndex:i];
        } else if (len > length) {
            if (i - 1 <= 0) {
                return @"";
            }
            
            return [self.base substringToIndex:i - 1];
        }
    }
    
    return self.base;
}

- (NSString *)unicodeEncode
{
    NSUInteger length = [self.base length];
    NSMutableString *retStr = [NSMutableString stringWithCapacity:0];
    for (int i = 0; i < length; i++) {
        unichar character = [self.base characterAtIndex:i];
        // 判断是否为英文或数字
        if ((character <= '9' && character >= '0') ||
            (character >= 'a' && character <= 'z') ||
            (character >= 'A' && character <= 'Z')) {
            [retStr appendFormat:@"%@", [self.base substringWithRange:NSMakeRange(i, 1)]];
        } else {
            [retStr appendFormat:@"\\u%.4x", [self.base characterAtIndex:i]];
        }
    }
    return [NSString stringWithString:retStr];
}

- (NSString *)unicodeDecode
{
    NSString *tempStr = [self.base stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    tempStr = [tempStr stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    tempStr = [[@"\"" stringByAppendingString:tempStr] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr dataUsingEncoding:NSUTF8StringEncoding];
    
    // NSString *retStr = [NSPropertyListSerialization propertyListFromData:tempData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    NSString *retStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];
    return [retStr stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
}

#pragma mark - Url

- (NSString *)urlEncodeComponent
{
    return [self.base stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"] invertedSet]];
}

- (NSString *)urlDecodeComponent
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)self.base, CFSTR("")));
}

- (NSString *)urlEncode
{
    return [self.base stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

- (NSString *)urlDecode
{
    return [self.base stringByRemovingPercentEncoding];
}

#pragma mark - Query

- (NSDictionary<NSString *,NSString *> *)queryDecode
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSURL *url = [NSURL.fw urlWithString:self.base];
    NSString *queryString = url.scheme.length > 0 ? url.query : self.base;
    NSArray *parameters = [queryString componentsSeparatedByString:@"&"];
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

- (NSString *)md5Encode
{
    const char *cStr = [self.base UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x", digest[i]];
    }
    return [NSString stringWithString:output];
}

- (NSString *)md5EncodeFile
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:self.base];
    if (!handle) return nil;
    
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

#pragma mark - Helper

- (NSString *)trimString
{
    return [self.base stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)ucfirstString
{
    if (self.base.length == 0) return self.base;
    NSMutableString *string = [NSMutableString string];
    [string appendString:[NSString stringWithFormat:@"%c", [self.base characterAtIndex:0]].uppercaseString];
    if (self.base.length >= 2) [string appendString:[self.base substringFromIndex:1]];
    return string;
}

- (NSString *)lcfirstString
{
    if (self.base.length == 0) return self.base;
    NSMutableString *string = [NSMutableString string];
    [string appendString:[NSString stringWithFormat:@"%c", [self.base characterAtIndex:0]].lowercaseString];
    if (self.base.length >= 2) [string appendString:[self.base substringFromIndex:1]];
    return string;
}

- (NSString *)underlineString
{
    if (self.base.length == 0) return self.base;
    NSMutableString *string = [NSMutableString string];
    for (NSUInteger i = 0; i < self.base.length; i++) {
        unichar c = [self.base characterAtIndex:i];
        NSString *cString = [NSString stringWithFormat:@"%c", c];
        NSString *cStringLower = [cString lowercaseString];
        if ([cString isEqualToString:cStringLower]) {
            [string appendString:cStringLower];
        } else {
            [string appendString:@"_"];
            [string appendString:cStringLower];
        }
    }
    return string;
}

- (NSString *)camelString
{
    if (self.base.length == 0) return self.base;
    NSMutableString *string = [NSMutableString string];
    NSArray *cmps = [self.base componentsSeparatedByString:@"_"];
    for (NSUInteger i = 0; i < cmps.count; i++) {
        NSString *cmp = cmps[i];
        if (i && cmp.length) {
            [string appendString:[NSString stringWithFormat:@"%c", [cmp characterAtIndex:0]].uppercaseString];
            if (cmp.length >= 2) [string appendString:[cmp substringFromIndex:1]];
        } else {
            [string appendString:cmp];
        }
    }
    return string;
}

- (NSData *)utf8Data
{
    return [self.base dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSURL *)url
{
    return [NSURL.fw urlWithString:self.base];
}

- (NSNumber *)number
{
    static NSCharacterSet *dot;
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dic = @{@"TRUE"   : @(YES),
                @"True"   : @(YES),
                @"true"   : @(YES),
                @"FALSE"  : @(NO),
                @"False"  : @(NO),
                @"false"  : @(NO),
                @"YES"    : @(YES),
                @"Yes"    : @(YES),
                @"yes"    : @(YES),
                @"NO"     : @(NO),
                @"No"     : @(NO),
                @"no"     : @(NO),
                @"NIL"    : (id)kCFNull,
                @"Nil"    : (id)kCFNull,
                @"nil"    : (id)kCFNull,
                @"NULL"   : (id)kCFNull,
                @"Null"   : (id)kCFNull,
                @"null"   : (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull};
    });
    
    NSNumber *num = dic[self.base];
    if (num != nil) {
        if (num == (id)kCFNull) return nil;
        return num;
    }
    if ([self.base rangeOfCharacterFromSet:dot].location != NSNotFound) {
        const char *cstring = self.base.UTF8String;
        if (!cstring) return nil;
        double cnum = atof(cstring);
        if (isnan(cnum) || isinf(cnum)) return nil;
        return @(cnum);
    } else {
        const char *cstring = self.base.UTF8String;
        if (!cstring) return nil;
        return @(atoll(cstring));
    }
}

- (NSString *)escapeJson
{
    NSString *string = self.base;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"(\\\\UD[8-F][0-F][0-F])(\\\\UD[8-F][0-F][0-F])?" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    int count = (int)matches.count;
    if (count < 1) return string;
    
    // 倒序循环，避免replace越界
    for (int i = count - 1; i >= 0; i--) {
        NSRange range = [matches objectAtIndex:i].range;
        NSString *substr = [[string substringWithRange:range] uppercaseString];
        if (range.length == 12 && [substr characterAtIndex:3] <= 'B' && [substr characterAtIndex:9] > 'B') continue;
        string = [string stringByReplacingCharactersInRange:range withString:@""];
    }
    return string;
}

@end

#pragma mark - FWStringClassWrapper+FWEncode

@implementation FWStringClassWrapper (FWEncode)

#pragma mark - Json

- (NSString *)jsonEncode:(id)object
{
    NSData *data = [NSData.fw jsonEncode:object];
    if (!data) return nil;
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - Query

- (NSString *)queryEncode:(NSDictionary<NSString *,id> *)dictionary
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
    return [NSString stringWithString:string];
}

@end

#pragma mark - FWDataWrapper+FWEncode

@implementation FWDataWrapper (FWEncode)

#pragma mark - Json

- (id)jsonDecode
{
    NSError *error = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:self.base options:NSJSONReadingAllowFragments error:&error];
    if (!error || error.code != 3840) return obj;
    
    NSString *string = [[NSString alloc] initWithData:self.base encoding:NSUTF8StringEncoding];
    NSData *data = [[string.fw escapeJson] dataUsingEncoding:NSUTF8StringEncoding];
    if (!data || data.length == self.base.length) return nil;
    
    obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
    return obj;
}

#pragma mark - Base64

- (NSData *)base64Encode
{
    return [self.base base64EncodedDataWithOptions:0];
}

- (NSData *)base64Decode
{
    return [[NSData alloc] initWithBase64EncodedData:self.base options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

#pragma mark - Helper

- (NSString *)utf8String
{
    return [[NSString alloc] initWithData:self.base encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - FWDataClassWrapper+FWEncode

@implementation FWDataClassWrapper (FWEncode)

#pragma mark - Json

- (NSData *)jsonEncode:(id)object
{
    if (!object || ![NSJSONSerialization isValidJSONObject:object]) return nil;
    return [NSJSONSerialization dataWithJSONObject:object options:0 error:NULL];
}

@end

#pragma mark - FWURLWrapper+FWEncode

@implementation FWURLWrapper (FWEncode)

- (NSDictionary<NSString *,NSString *> *)queryDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSString *urlString = self.base.absoluteString ?: @"";
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:urlString];
    if (!urlComponents) {
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        urlComponents = [[NSURLComponents alloc] initWithString:urlString];
    }
    // queryItems.value会自动进行URL参数解码
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem *obj, NSUInteger idx, BOOL *stop) {
        dict[obj.name] = obj.value;
    }];
    return [dict copy];
}

- (NSString *)pathURI
{
    NSString *URLString = self.base.absoluteString ?: @"";
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:URLString];
    if (urlComponents && urlComponents.rangeOfPath.location != NSNotFound) {
        return [URLString substringFromIndex:urlComponents.rangeOfPath.location];
    }
    return nil;
}

@end

#pragma mark - FWURLClassWrapper+FWEncode

@implementation FWURLClassWrapper (FWEncode)

- (NSURL *)urlWithString:(NSString *)string
{
    if (!string) return nil;
    
    NSURL *url = [NSURL URLWithString:string];
    // 如果生成失败，自动URL编码再试
    if (!url && string.length > 0) {
        // url = [NSURL URLWithString:(NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]", NULL, kCFStringEncodingUTF8))];
        url = [NSURL URLWithString:[string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    return url;
}

- (NSURL *)urlWithString:(NSString *)string relativeTo:(NSURL *)baseURL
{
    if (!string) return nil;
    
    NSURL *url = [NSURL URLWithString:string relativeToURL:baseURL];
    // 如果生成失败，自动URL编码再试
    if (!url && string.length > 0) {
        url = [NSURL URLWithString:[string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] relativeToURL:baseURL];
    }
    return url;
}

@end

#pragma mark - FWSafeValue

NSNumber * FWSafeNumber(id value) {
    if (!value) return @(0);
    if ([value isKindOfClass:[NSNumber class]]) return value;
    NSNumber *num = FWSafeString(value).fw.number;
    return num ?: @(0);
}

NSString * FWSafeString(id value) {
    if (!value || [value isKindOfClass:[NSNull class]]) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSData class]]) return [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding] ?: @"";
    return [NSString stringWithFormat:@"%@", value];
}

NSURL * FWSafeURL(id value) {
    if (!value) return [NSURL new];
    if ([value isKindOfClass:[NSURL class]]) return value;
    return [NSURL.fw urlWithString:FWSafeString(value)] ?: [NSURL new];
}

#pragma mark - FWObjectWrapper+FWSafeType

@implementation FWObjectWrapper (FWSafeType)

- (BOOL)isNotNull
{
    return !(self.base == nil ||
             [self.base isKindOfClass:[NSNull class]]);
}

- (BOOL)isNotEmpty
{
    return !(self.base == nil ||
             [self.base isKindOfClass:[NSNull class]] ||
             ([self.base respondsToSelector:@selector(length)] && [(NSData *)self.base length] == 0) ||
             ([self.base respondsToSelector:@selector(count)] && [(NSArray *)self.base count] == 0));
}

- (NSInteger)safeInteger
{
    return [[self safeNumber] integerValue];
}

- (float)safeFloat
{
    return [[self safeNumber] floatValue];
}

- (double)safeDouble
{
    return [[self safeNumber] doubleValue];
}

- (BOOL)safeBool
{
    return [[self safeNumber] boolValue];
}

- (NSNumber *)safeNumber
{
    if ([self.base isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)self.base;
    } else if ([self.base isKindOfClass:[NSString class]]) {
        return [((NSString *)self.base).fw number] ?: @(0);
    } else if ([self.base isKindOfClass:[NSDate class]]) {
        return [NSNumber numberWithDouble:[(NSDate *)self.base timeIntervalSince1970]];
    } else {
        return @(0);
    }
}

- (NSString *)safeString
{
    if ([self.base isKindOfClass:[NSNull class]]) {
        return @"";
    } else if ([self.base isKindOfClass:[NSString class]]) {
        return (NSString *)self.base;
    } else if ([self.base isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter stringFromDate:(NSDate *)self.base];
    } else if ([self.base isKindOfClass:[NSData class]]) {
        return [[NSString alloc] initWithData:(NSData *)self.base encoding:NSUTF8StringEncoding] ?: @"";
    } else {
        return [NSString stringWithFormat:@"%@", self.base];
    }
}

- (NSDate *)safeDate
{
    if ([self.base isKindOfClass:[NSDate class]]) {
        return (NSDate *)self.base;
    } else if ([self.base isKindOfClass:[NSString class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter dateFromString:(NSString *)self.base] ?: [NSDate date];
    } else if ([self.base isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)self.base doubleValue]];
    } else {
        return [NSDate date];
    }
}

- (NSData *)safeData
{
    if ([self.base isKindOfClass:[NSString class]]) {
        return [(NSString *)self.base dataUsingEncoding:NSUTF8StringEncoding] ?: [NSData new];
    } else if ([self.base isKindOfClass:[NSData class]]) {
        return (NSData *)self.base;
    } else {
        return [NSData new];
    }
}

- (NSArray *)safeArray
{
    if ([self.base isKindOfClass:[NSArray class]]) {
        return (NSArray *)self.base;
    } else {
        return @[];
    }
}

- (NSMutableArray *)safeMutableArray
{
    if ([self.base isKindOfClass:[NSMutableArray class]]) {
        return (NSMutableArray *)self.base;
    } else if ([self.base isKindOfClass:[NSArray class]]) {
        return [NSMutableArray arrayWithArray:(NSArray *)self.base];
    } else {
        return [NSMutableArray array];
    }
}

- (NSDictionary *)safeDictionary
{
    if ([self.base isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)self.base;
    } else {
        return @{};
    }
}

- (NSMutableDictionary *)safeMutableDictionary
{
    if ([self.base isKindOfClass:[NSMutableDictionary class]]) {
        return (NSMutableDictionary *)self.base;
    } else if ([self.base isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self.base];
    } else {
        return [NSMutableDictionary dictionary];
    }
}

@end

#pragma mark - FWStringWrapper+FWSafeType

@implementation FWStringWrapper (FWSafeType)

- (NSString *)substringFromIndex:(NSInteger)from
{
    if (from < 0) return nil;
    if (from > self.base.length) return nil;
    return [self.base substringFromIndex:from];
}

- (NSString *)substringToIndex:(NSInteger)to
{
    if (to < 0) return nil;
    if (to > self.base.length) return nil;
    return [self.base substringToIndex:to];
}

- (NSString *)substringWithRange:(NSRange)range
{
    if (range.location > self.base.length) return nil;
    if (range.length > self.base.length) return nil;
    if (range.location + range.length > self.base.length) return nil;
    return [self.base substringWithRange:range];
}

@end

#pragma mark - FWArrayWrapper+FWSafeType

@implementation FWArrayWrapper (FWSafeType)

- (id)objectAtIndex:(NSInteger)index
{
    if (index < 0) return nil;
    if (index >= self.base.count) return nil;
    return [self.base objectAtIndex:index];
}

- (NSArray *)subarrayWithRange:(NSRange)range
{
    if (range.location > self.base.count) return nil;
    if (range.length > self.base.count) return nil;
    if (range.location + range.length > self.base.count) return nil;
    return [self.base subarrayWithRange:range];
}

@end

#pragma mark - FWMutableArrayWrapper+FWSafeType

@implementation FWMutableArrayWrapper (FWSafeType)

- (void)addObject:(id)object
{
    if (object == nil) return;
    [self.base addObject:object];
}

- (void)removeObjectAtIndex:(NSInteger)index
{
    if (index < 0) return;
    if (index >= self.base.count) return;
    [self.base removeObjectAtIndex:index];
}

- (void)insertObject:(id)object atIndex:(NSInteger)index
{
    if (object == nil) return;
    if (index < 0) return;
    if (index > self.base.count) return;
    [self.base insertObject:object atIndex:index];
}

- (void)replaceObjectAtIndex:(NSInteger)index withObject:(id)object
{
    if (object == nil) return;
    if (index < 0) return;
    if (index >= self.base.count) return;
    [self.base replaceObjectAtIndex:index withObject:object];
}

- (void)removeObjectsInRange:(NSRange)range
{
    if (range.location > self.base.count) return;
    if (range.length > self.base.count) return;
    if (range.location + range.length > self.base.count) return;
    [self.base removeObjectsInRange:range];
}

- (void)insertObjects:(NSArray *)objects atIndex:(NSInteger)index
{
    if (objects.count == 0) return;
    if (index < 0) return;
    if (index > self.base.count) return;
    
    for (NSInteger i = objects.count - 1; i >= 0; i--) {
        [self.base insertObject:objects[i] atIndex:index];
    }
}

@end

#pragma mark - FWMutableSetWrapper+FWSafeType

@implementation FWMutableSetWrapper (FWSafeType)

- (void)addObject:(id)object
{
    if (object == nil) return;
    [self.base addObject:object];
}

- (void)removeObject:(id)object
{
    if (object == nil) return;
    [self.base removeObject:object];
}

@end

#pragma mark - FWDictionaryWrapper+FWSafeType

@implementation FWDictionaryWrapper (FWSafeType)

- (id)objectForKey:(id)key
{
    if (!key) return nil;
    id object = [self.base objectForKey:key];
    if (object == nil || object == [NSNull null]) return nil;
    return object;
}

@end

#pragma mark - FWMutableDictionaryWrapper+FWSafeType

@implementation FWMutableDictionaryWrapper (FWSafeType)

- (void)removeObjectForKey:(id)key
{
    if (!key) return;
    [self.base removeObjectForKey:key];
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key
{
    if (!key) return;
    if (object == nil || object == [NSNull null]) return;
    [self.base setObject:object forKey:key];
}

@end
