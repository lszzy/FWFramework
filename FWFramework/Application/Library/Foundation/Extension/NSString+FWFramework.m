/*!
 @header     NSString+FWFramework.m
 @indexgroup FWFramework
 @brief      NSString+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "NSString+FWFramework.h"

@implementation NSString (FWFramework)

#pragma mark - Convert

- (NSString *)fwLcfirstString
{
    if (self.length == 0) return self;
    NSMutableString *string = [NSMutableString string];
    [string appendString:[NSString stringWithFormat:@"%c", [self characterAtIndex:0]].lowercaseString];
    if (self.length >= 2) [string appendString:[self substringFromIndex:1]];
    return string;
}

- (NSString *)fwUcfirstString
{
    if (self.length == 0) return self;
    NSMutableString *string = [NSMutableString string];
    [string appendString:[NSString stringWithFormat:@"%c", [self characterAtIndex:0]].uppercaseString];
    if (self.length >= 2) [string appendString:[self substringFromIndex:1]];
    return string;
}

- (NSString *)fwUnderlineString
{
    if (self.length == 0) return self;
    NSMutableString *string = [NSMutableString string];
    for (NSUInteger i = 0; i<self.length; i++) {
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

- (NSString *)fwCamelString
{
    if (self.length == 0) return self;
    NSMutableString *string = [NSMutableString string];
    NSArray *cmps = [self componentsSeparatedByString:@"_"];
    for (NSUInteger i = 0; i<cmps.count; i++) {
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

#pragma mark - Pinyin

- (NSString *)fwPinyinString
{
    NSMutableString *mutableString = [NSMutableString stringWithString:self];
    CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
    NSString *pinyinStr = (NSMutableString *)[mutableString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                                locale:[NSLocale currentLocale]];
    return [pinyinStr lowercaseString];
}

- (NSComparisonResult)fwPinyinCompare:(NSString *)string
{
    NSString *pinyin1 = self.fwPinyinString;
    NSString *pinyin2 = string.fwPinyinString;
    
    NSUInteger count = MIN(pinyin1.length, pinyin2.length);
    for (int i = 0; i < count; i++) {
        // 获取字符
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

#pragma mark - Regex

- (NSString *)fwEmojiSubstring:(NSUInteger)index
{
    NSString *result = self;
    if (result.length > index) {
        // 获取index处的整个字符range，并截取掉整个字符，防止半个Emoji
        NSRange rangeIndex = [result rangeOfComposedCharacterSequenceAtIndex:index];
        result = [result substringToIndex:rangeIndex.location];
    }
    return result;
}

- (NSString *)fwRegexSubstring:(NSString *)regex
{
    NSRange range = [self rangeOfString:regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        return [self substringWithRange:range];
    } else {
        return nil;
    }
}

- (NSString *)fwRegexReplace:(NSString *)regex withString:(NSString *)string
{
    NSRegularExpression *regexObj = [[NSRegularExpression alloc] initWithPattern:regex options:0 error:nil];
    return [regexObj stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:string];
}

- (void)fwRegexMatches:(NSString *)regex withBlock:(void (^)(NSRange))block
{
    NSRegularExpression *regexObj = [[NSRegularExpression alloc] initWithPattern:regex options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regexObj matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    int count = (int)matches.count;
    if (count > 0) {
        // 倒序循环，避免replace等越界
        for (int i = count - 1; i >= 0; i--) {
            NSTextCheckingResult *match = [matches objectAtIndex:i];
            if (block) {
                block(match.range);
            }
        }
    }
}

#pragma mark - Html

- (NSString *)fwEscapeHtml
{
    NSUInteger len = self.length;
    if (!len) return self;
    
    unichar *buf = malloc(sizeof(unichar) * len);
    if (!buf) return self;
    [self getCharacters:buf range:NSMakeRange(0, len)];
    
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < len; i++) {
        unichar c = buf[i];
        NSString *esc = nil;
        switch (c) {
            case 34: esc = @"&quot;"; break;
            case 38: esc = @"&amp;"; break;
            case 39: esc = @"&apos;"; break;
            case 60: esc = @"&lt;"; break;
            case 62: esc = @"&gt;"; break;
            default: break;
        }
        if (esc) {
            [result appendString:esc];
        } else {
            CFStringAppendCharacters((CFMutableStringRef)result, &c, 1);
        }
    }
    free(buf);
    return result;
}

#pragma mark - Number

- (NSNumber *)fwNumberValue
{
    NSString *str = [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if (!str || str.length < 1) {
        return nil;
    }
    
    static NSDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = @{
                 @"true" :   @(YES),
                 @"yes" :    @(YES),
                 @"false" :  @(NO),
                 @"no" :     @(NO),
                 @"nil" :    [NSNull null],
                 @"null" :   [NSNull null],
                 @"<null>" : [NSNull null]
                 };
    });
    
    id num = dict[str];
    if (num) {
        return (num != [NSNull null]) ? num : nil;
    }
    
    // 十六进制
    int sign = 0;
    if ([str hasPrefix:@"0x"]) {
        sign = 1;
    } else if ([str hasPrefix:@"-0x"]) {
        sign = -1;
    }
    if (sign != 0) {
        NSScanner *scan = [NSScanner scannerWithString:str];
        unsigned num = -1;
        BOOL success = [scan scanHexInt:&num];
        if (success) {
            return [NSNumber numberWithLong:((long)num * sign)];
        } else {
            return nil;
        }
    }
    
    // 普通数字
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    return [formatter numberFromString:self];
}

#pragma mark - Static

+ (NSString *)fwUUIDString
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return (__bridge_transfer NSString *)string;
}

+ (NSString *)fwSizeString:(NSUInteger)aFileSize
{
    NSString *sizeStr;
    if (aFileSize <= 0) {
        sizeStr = @"0K";
    } else {
        double fileSize = aFileSize / 1024.f;
        if (fileSize >= 1024.f) {
            fileSize = fileSize / 1024.f;
            if (fileSize >= 1024.f) {
                fileSize = fileSize / 1024.f;
                sizeStr = [NSString stringWithFormat:@"%0.1fG", fileSize];
            } else {
                sizeStr = [NSString stringWithFormat:@"%0.1fM", fileSize];
            }
        } else {
            sizeStr = [NSString stringWithFormat:@"%dK", (int)ceil(fileSize)];
        }
    }
    return sizeStr;
}

#pragma mark - Size

- (CGSize)fwSizeWithFont:(UIFont *)font
{
    return [self fwSizeWithFont:font drawSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize
{
    return [self fwSizeWithFont:font drawSize:drawSize paragraphStyle:nil];
}

- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize paragraphStyle:(NSParagraphStyle *)paragraphStyle
{
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    attr[NSFontAttributeName] = font;
    if (paragraphStyle != nil) {
        attr[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    CGSize size = [self boundingRectWithSize:drawSize
                                     options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attr
                                     context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

@end
