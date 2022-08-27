//
//  FWEncode.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWEncode.h"
#import <CommonCrypto/CommonDigest.h>

#pragma mark - NSString+FWEncode

@implementation NSString (FWEncode)

#pragma mark - Json

+ (NSString *)fw_jsonEncode:(id)object
{
    NSData *data = [NSData fw_jsonEncode:object];
    if (!data) return nil;
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (id)fw_jsonDecode
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    
    return [data fw_jsonDecode];
}

#pragma mark - Base64

- (NSString *)fw_base64Encode
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    
    data = [data base64EncodedDataWithOptions:0];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)fw_base64Decode
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) return nil;
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - Unicode

- (NSUInteger)fw_unicodeLength
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

- (NSString *)fw_unicodeSubstring:(NSUInteger)length
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

- (NSString *)fw_unicodeEncode
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
    return [NSString stringWithString:retStr];
}

- (NSString *)fw_unicodeDecode
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

- (NSString *)fw_urlEncodeComponent
{
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"] invertedSet]];
}

- (NSString *)fw_urlDecodeComponent
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)self, CFSTR("")));
}

- (NSString *)fw_urlEncode
{
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

- (NSString *)fw_urlDecode
{
    return [self stringByRemovingPercentEncoding];
}

#pragma mark - Query

+ (NSString *)fw_queryEncode:(NSDictionary<NSString *,id> *)dictionary
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

- (NSDictionary<NSString *,NSString *> *)fw_queryDecode
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSURL *url = [NSURL fw_urlWithString:self];
    NSString *queryString = url.scheme.length > 0 ? url.query : self;
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

- (NSString *)fw_md5Encode
{
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x", digest[i]];
    }
    return [NSString stringWithString:output];
}

- (NSString *)fw_md5EncodeFile
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:self];
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

- (NSString *)fw_trimString
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)fw_ucfirstString
{
    if (self.length == 0) return self;
    NSMutableString *string = [NSMutableString string];
    [string appendString:[NSString stringWithFormat:@"%c", [self characterAtIndex:0]].uppercaseString];
    if (self.length >= 2) [string appendString:[self substringFromIndex:1]];
    return string;
}

- (NSString *)fw_lcfirstString
{
    if (self.length == 0) return self;
    NSMutableString *string = [NSMutableString string];
    [string appendString:[NSString stringWithFormat:@"%c", [self characterAtIndex:0]].lowercaseString];
    if (self.length >= 2) [string appendString:[self substringFromIndex:1]];
    return string;
}

- (NSString *)fw_underlineString
{
    if (self.length == 0) return self;
    NSMutableString *string = [NSMutableString string];
    for (NSUInteger i = 0; i < self.length; i++) {
        unichar c = [self characterAtIndex:i];
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

- (NSString *)fw_camelString
{
    if (self.length == 0) return self;
    NSMutableString *string = [NSMutableString string];
    NSArray *cmps = [self componentsSeparatedByString:@"_"];
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

- (NSString *)fw_pinyinString
{
    if (self.length == 0) return self;
    NSMutableString *mutableString = [NSMutableString stringWithString:self];
    CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
    NSString *pinyinStr = (NSMutableString *)[mutableString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
    return [pinyinStr lowercaseString];
}

- (NSComparisonResult)fw_pinyinCompare:(NSString *)string
{
    NSString *pinyin1 = self.fw_pinyinString;
    NSString *pinyin2 = string.fw_pinyinString;
    
    NSUInteger count = MIN(pinyin1.length, pinyin2.length);
    for (int i = 0; i < count; i++) {
        UniChar char1 = [pinyin1 characterAtIndex:i];
        UniChar char2 = [pinyin2 characterAtIndex:i];
        if (char1 == char2) continue;
        
        NSUInteger charType1 = (char1 >= '0' && char1 <= '9') ? 1 : ((char1 >= 'a' && char1 <= 'z') ? 0 : 2);
        NSUInteger charType2 = (char2 >= '0' && char2 <= '9') ? 1 : ((char2 >= 'a' && char2 <= 'z') ? 0 : 2);
        
        NSComparisonResult typeResult = (charType1 < charType2) ? NSOrderedAscending : ((charType1 > charType2) ? NSOrderedDescending : NSOrderedSame);
        if (typeResult == NSOrderedSame) {
            return (char1 < char2) ? NSOrderedAscending : ((char1 > char2) ? NSOrderedDescending : NSOrderedSame);
        } else {
            return typeResult;
        }
    }
    
    return (pinyin1.length < pinyin2.length) ? NSOrderedAscending : ((pinyin1.length > pinyin2.length) ? NSOrderedDescending : NSOrderedSame);
}

- (NSData *)fw_utf8Data
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSURL *)fw_url
{
    return [NSURL fw_urlWithString:self];
}

- (NSNumber *)fw_number
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
    
    NSNumber *num = dic[self];
    if (num != nil) {
        if (num == (id)kCFNull) return nil;
        return num;
    }
    if ([self rangeOfCharacterFromSet:dot].location != NSNotFound) {
        const char *cstring = self.UTF8String;
        if (!cstring) return nil;
        double cnum = atof(cstring);
        if (isnan(cnum) || isinf(cnum)) return nil;
        return @(cnum);
    } else {
        const char *cstring = self.UTF8String;
        if (!cstring) return nil;
        return @(atoll(cstring));
    }
}

- (NSString *)fw_escapeJson
{
    NSString *string = self;
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

#pragma mark - NSData+FWEncode

@implementation NSData (FWEncode)

#pragma mark - Json

+ (NSData *)fw_jsonEncode:(id)object
{
    if (!object || ![NSJSONSerialization isValidJSONObject:object]) return nil;
    return [NSJSONSerialization dataWithJSONObject:object options:0 error:NULL];
}

- (id)fw_jsonDecode
{
    NSError *error = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:&error];
    if (!error || error.code != 3840) return obj;
    
    NSString *string = [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
    NSData *data = [[string fw_escapeJson] dataUsingEncoding:NSUTF8StringEncoding];
    if (!data || data.length == self.length) return nil;
    
    obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
    return obj;
}

#pragma mark - Base64

- (NSData *)fw_base64Encode
{
    return [self base64EncodedDataWithOptions:0];
}

- (NSData *)fw_base64Decode
{
    return [[NSData alloc] initWithBase64EncodedData:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

#pragma mark - Helper

- (NSString *)fw_utf8String
{
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - NSURL+FWEncode

@implementation NSURL (FWEncode)

- (NSDictionary<NSString *,NSString *> *)fw_queryDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSString *urlString = self.absoluteString ?: @"";
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

- (NSString *)fw_baseURI
{
    NSString *URLString = self.absoluteString ?: @"";
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:URLString];
    if (urlComponents && urlComponents.rangeOfPath.location != NSNotFound) {
        return [URLString substringToIndex:urlComponents.rangeOfPath.location];
    }
    return nil;
}

- (NSString *)fw_pathURI
{
    NSString *URLString = self.absoluteString ?: @"";
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:URLString];
    if (urlComponents && urlComponents.rangeOfPath.location != NSNotFound) {
        return [URLString substringFromIndex:urlComponents.rangeOfPath.location];
    }
    return nil;
}

+ (NSURL *)fw_urlWithString:(NSString *)string
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

+ (NSURL *)fw_urlWithString:(NSString *)string relativeTo:(NSURL *)baseURL
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
    NSNumber *num = FWSafeString(value).fw_number;
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
    return [NSURL fw_urlWithString:FWSafeString(value)] ?: [NSURL new];
}

#pragma mark - NSObject+FWSafeType

@implementation NSObject (FWSafeType)

- (BOOL)fw_isNotNull
{
    return !(self == nil ||
             [self isKindOfClass:[NSNull class]]);
}

- (BOOL)fw_isNotEmpty
{
    return !(self == nil ||
             [self isKindOfClass:[NSNull class]] ||
             ([self respondsToSelector:@selector(length)] && [(NSData *)self length] == 0) ||
             ([self respondsToSelector:@selector(count)] && [(NSArray *)self count] == 0));
}

- (NSInteger)fw_safeInteger
{
    return [[self fw_safeNumber] integerValue];
}

- (float)fw_safeFloat
{
    return [[self fw_safeNumber] floatValue];
}

- (double)fw_safeDouble
{
    return [[self fw_safeNumber] doubleValue];
}

- (BOOL)fw_safeBool
{
    return [[self fw_safeNumber] boolValue];
}

- (NSNumber *)fw_safeNumber
{
    if ([self isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)self;
    } else if ([self isKindOfClass:[NSString class]]) {
        return [((NSString *)self) fw_number] ?: @(0);
    } else if ([self isKindOfClass:[NSDate class]]) {
        return [NSNumber numberWithDouble:[(NSDate *)self timeIntervalSince1970]];
    } else {
        return @(0);
    }
}

- (NSString *)fw_safeString
{
    if ([self isKindOfClass:[NSNull class]]) {
        return @"";
    } else if ([self isKindOfClass:[NSString class]]) {
        return (NSString *)self;
    } else if ([self isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter stringFromDate:(NSDate *)self];
    } else if ([self isKindOfClass:[NSData class]]) {
        return [[NSString alloc] initWithData:(NSData *)self encoding:NSUTF8StringEncoding] ?: @"";
    } else {
        return [NSString stringWithFormat:@"%@", self];
    }
}

- (NSDate *)fw_safeDate
{
    if ([self isKindOfClass:[NSDate class]]) {
        return (NSDate *)self;
    } else if ([self isKindOfClass:[NSString class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter dateFromString:(NSString *)self] ?: [NSDate date];
    } else if ([self isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)self doubleValue]];
    } else {
        return [NSDate date];
    }
}

- (NSData *)fw_safeData
{
    if ([self isKindOfClass:[NSString class]]) {
        return [(NSString *)self dataUsingEncoding:NSUTF8StringEncoding] ?: [NSData new];
    } else if ([self isKindOfClass:[NSData class]]) {
        return (NSData *)self;
    } else {
        return [NSData new];
    }
}

- (NSArray *)fw_safeArray
{
    if ([self isKindOfClass:[NSArray class]]) {
        return (NSArray *)self;
    } else {
        return @[];
    }
}

- (NSMutableArray *)fw_safeMutableArray
{
    if ([self isKindOfClass:[NSMutableArray class]]) {
        return (NSMutableArray *)self;
    } else if ([self isKindOfClass:[NSArray class]]) {
        return [NSMutableArray arrayWithArray:(NSArray *)self];
    } else {
        return [NSMutableArray array];
    }
}

- (NSDictionary *)fw_safeDictionary
{
    if ([self isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)self;
    } else {
        return @{};
    }
}

- (NSMutableDictionary *)fw_safeMutableDictionary
{
    if ([self isKindOfClass:[NSMutableDictionary class]]) {
        return (NSMutableDictionary *)self;
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self];
    } else {
        return [NSMutableDictionary dictionary];
    }
}

@end

#pragma mark - NSString+FWSafeType

@implementation NSString (FWSafeType)

- (NSString *)fw_substringFromIndex:(NSInteger)from
{
    if (from < 0) return nil;
    if (from > self.length) return nil;
    return [self substringFromIndex:from];
}

- (NSString *)fw_substringToIndex:(NSInteger)to
{
    if (to < 0) return nil;
    if (to > self.length) return nil;
    return [self substringToIndex:to];
}

- (NSString *)fw_substringWithRange:(NSRange)range
{
    if (range.location > self.length) return nil;
    if (range.length > self.length) return nil;
    if (range.location + range.length > self.length) return nil;
    return [self substringWithRange:range];
}

@end

#pragma mark - NSArray+FWSafeType

@implementation NSArray (FWSafeType)

- (id)fw_objectAtIndex:(NSInteger)index
{
    if (index < 0) return nil;
    if (index >= self.count) return nil;
    return [self objectAtIndex:index];
}

- (NSArray *)fw_subarrayWithRange:(NSRange)range
{
    if (range.location > self.count) return nil;
    if (range.length > self.count) return nil;
    if (range.location + range.length > self.count) return nil;
    return [self subarrayWithRange:range];
}

@end

#pragma mark - NSMutableArray+FWSafeType

@implementation NSMutableArray (FWSafeType)

- (void)fw_addObject:(id)object
{
    if (object == nil) return;
    [self addObject:object];
}

- (void)fw_removeObjectAtIndex:(NSInteger)index
{
    if (index < 0) return;
    if (index >= self.count) return;
    [self removeObjectAtIndex:index];
}

- (void)fw_insertObject:(id)object atIndex:(NSInteger)index
{
    if (object == nil) return;
    if (index < 0) return;
    if (index > self.count) return;
    [self insertObject:object atIndex:index];
}

- (void)fw_replaceObjectAtIndex:(NSInteger)index withObject:(id)object
{
    if (object == nil) return;
    if (index < 0) return;
    if (index >= self.count) return;
    [self replaceObjectAtIndex:index withObject:object];
}

- (void)fw_removeObjectsInRange:(NSRange)range
{
    if (range.location > self.count) return;
    if (range.length > self.count) return;
    if (range.location + range.length > self.count) return;
    [self removeObjectsInRange:range];
}

- (void)fw_insertObjects:(NSArray *)objects atIndex:(NSInteger)index
{
    if (objects.count == 0) return;
    if (index < 0) return;
    if (index > self.count) return;
    
    for (NSInteger i = objects.count - 1; i >= 0; i--) {
        [self insertObject:objects[i] atIndex:index];
    }
}

@end

#pragma mark - NSMutableSet+FWSafeType

@implementation NSMutableSet (FWSafeType)

- (void)fw_addObject:(id)object
{
    if (object == nil) return;
    [self addObject:object];
}

- (void)fw_removeObject:(id)object
{
    if (object == nil) return;
    [self removeObject:object];
}

@end

#pragma mark - NSDictionary+FWSafeType

@implementation NSDictionary (FWSafeType)

- (id)fw_objectForKey:(id)key
{
    if (!key) return nil;
    id object = [self objectForKey:key];
    if (object == nil || object == [NSNull null]) return nil;
    return object;
}

@end

#pragma mark - NSMutableDictionary+FWSafeType

@implementation NSMutableDictionary (FWSafeType)

- (void)fw_removeObjectForKey:(id)key
{
    if (!key) return;
    [self removeObjectForKey:key];
}

- (void)fw_setObject:(id)object forKey:(id<NSCopying>)key
{
    if (!key) return;
    if (object == nil || object == [NSNull null]) return;
    [self setObject:object forKey:key];
}

@end
