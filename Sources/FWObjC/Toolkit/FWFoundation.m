//
//  FWFoundation.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWFoundation.h"
#import "FWEncode.h"
#import "FWTheme.h"
#import <sys/sysctl.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>
#if FWMacroSPM
@import FWFramework;
#else
#import <FWFramework/FWFramework-Swift.h>
#endif

#pragma mark - NSArray+FWFoundation

@implementation NSArray (FWFoundation)

- (NSArray *)fw_filterWithBlock:(BOOL (^)(id))block
{
    NSParameterAssert(block != nil);
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj)) {
            [result addObject:obj];
        }
    }];
    return result;
}

- (NSArray *)fw_mapWithBlock:(id (^)(id))block
{
    NSParameterAssert(block != nil);
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if (value) {
            [result addObject:value];
        }
    }];
    return result;
}

- (id)fw_matchWithBlock:(BOOL (^)(id))block
{
    NSParameterAssert(block != nil);
    
    __block id result = nil;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj)) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

- (id)fw_randomObject
{
    if (self.count < 1) return nil;
    
    return self[arc4random_uniform((u_int32_t)self.count)];
}

- (id)fw_randomObject:(NSArray *)weights
{
    NSInteger count = self.count;
    if (count < 1) return nil;
    
    __block NSInteger sum = 0;
    [weights enumerateObjectsUsingBlock:^(NSObject *obj, NSUInteger idx, BOOL *stop) {
        NSInteger val = [obj fw_safeInteger];
        if (val > 0 && idx < count) {
            sum += val;
        }
    }];
    if (sum < 1) return self.fw_randomObject;
    
    __block NSInteger index = -1;
    __block NSInteger weight = 0;
    NSInteger random = arc4random_uniform((u_int32_t)sum);
    [weights enumerateObjectsUsingBlock:^(NSObject *obj, NSUInteger idx, BOOL *stop) {
        NSInteger val = [obj fw_safeInteger];
        if (val > 0 && idx < count) {
            weight += val;
            if (weight > random) {
                index = idx;
                *stop = YES;
            }
        }
    }];
    return index >= 0 && index < count ? [self objectAtIndex:index] : self.fw_randomObject;
}

@end

#pragma mark - NSData+FWFoundation

@implementation NSData (FWFoundation)

- (id)fw_unarchiveObject:(Class)clazz
{
    id object = nil;
    @try {
        object = [NSKeyedUnarchiver unarchivedObjectOfClass:clazz fromData:self error:NULL];
    } @catch (NSException *exception) { }
    return object;
}

+ (NSData *)fw_archiveObject:(id)object
{
    NSData *data = nil;
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:NULL];
    } @catch (NSException *exception) { }
    return data;
}

+ (BOOL)fw_archiveObject:(id)object toFile:(NSString *)path
{
    NSData *data = [self fw_archiveObject:object];
    if (!data) return NO;
    return [data writeToFile:path atomically:YES];
}

+ (id)fw_unarchiveObject:(Class)clazz withFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return nil;
    return [data fw_unarchiveObject:clazz];
}

#pragma mark - Encrypt

- (NSData *)fw_AESEncryptWithKey:(NSString *)key andIV:(NSData *)iv
{
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *encryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSizeAES128];
    
    CCCryptorStatus status = CCCrypt(kCCEncrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     encryptedData.mutableBytes,    // encrypted data out
                                     encryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (status == kCCSuccess) {
        encryptedData.length = dataMoved;
        return encryptedData;
    }
    
    return nil;
}

- (NSData *)fw_AESDecryptWithKey:(NSString *)key andIV:(NSData *)iv
{
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *decryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSizeAES128];
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     decryptedData.mutableBytes,    // encrypted data out
                                     decryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (result == kCCSuccess) {
        decryptedData.length = dataMoved;
        return decryptedData;
    }
    
    return nil;
}

- (NSData *)fw_DES3EncryptWithKey:(NSString *)key andIV:(NSData *)iv
{
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *encryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSize3DES];
    
    CCCryptorStatus result = CCCrypt(kCCEncrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithm3DES,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     encryptedData.mutableBytes,    // encrypted data out
                                     encryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (result == kCCSuccess) {
        encryptedData.length = dataMoved;
        return encryptedData;
    }
    
    return nil;
}

- (NSData *)fw_DES3DecryptWithKey:(NSString *)key andIV:(NSData *)iv
{
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *decryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSize3DES];
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithm3DES,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     decryptedData.mutableBytes,    // encrypted data out
                                     decryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (result == kCCSuccess) {
        decryptedData.length = dataMoved;
        return decryptedData;
    }
    
    return nil;
}

#pragma mark - RSA

- (NSData *)fw_RSAEncryptWithPublicKey:(NSString *)publicKey
{
    return [self fw_RSAEncryptWithPublicKey:publicKey andTag:@"FWRSA_PublicKey" base64Encode:YES];
}

- (NSData *)fw_RSAEncryptWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode
{
    if (!publicKey) return nil;
    
    SecKeyRef keyRef = [NSData fw_RSAAddPublicKey:publicKey andTag:tagName];
    if (!keyRef) return nil;
    
    NSData *data = [NSData fw_RSAEncryptData:self withKeyRef:keyRef isSign:NO];
    if (data && base64Encode) {
        data = [data base64EncodedDataWithOptions:0];
    }
    return data;
}

- (NSData *)fw_RSADecryptWithPrivateKey:(NSString *)privateKey
{
    return [self fw_RSADecryptWithPrivateKey:privateKey andTag:@"FWRSA_PrivateKey" base64Decode:YES];
}

- (NSData *)fw_RSADecryptWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode
{
    NSData *data = self;
    if (base64Decode) {
        data = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data || !privateKey) return nil;
    
    SecKeyRef keyRef = [NSData fw_RSAAddPrivateKey:privateKey andTag:tagName];
    if (!keyRef) return nil;
    
    return [NSData fw_RSADecryptData:data withKeyRef:keyRef];
}

- (NSData *)fw_RSASignWithPrivateKey:(NSString *)privateKey
{
    return [self fw_RSASignWithPrivateKey:privateKey andTag:@"FWRSA_PrivateKey" base64Encode:YES];
}

- (NSData *)fw_RSASignWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode
{
    if (!privateKey) return nil;
    
    SecKeyRef keyRef = [NSData fw_RSAAddPrivateKey:privateKey andTag:tagName];
    if (!keyRef) return nil;
    
    NSData *data = [NSData fw_RSAEncryptData:self withKeyRef:keyRef isSign:YES];
    if (data && base64Encode) {
        data = [data base64EncodedDataWithOptions:0];
    }
    return data;
}

- (NSData *)fw_RSAVerifyWithPublicKey:(NSString *)publicKey
{
    return [self fw_RSAVerifyWithPublicKey:publicKey andTag:@"FWRSA_PublicKey" base64Decode:YES];
}

- (NSData *)fw_RSAVerifyWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode
{
    NSData *data = self;
    if (base64Decode) {
        data = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data || !publicKey) return nil;
    
    SecKeyRef keyRef = [NSData fw_RSAAddPublicKey:publicKey andTag:tagName];
    if (!keyRef) return nil;
    
    return [NSData fw_RSADecryptData:data withKeyRef:keyRef];
}

+ (NSData *)fw_RSAEncryptData:(NSData *)data withKeyRef:(SecKeyRef) keyRef isSign:(BOOL)isSign
{
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    void *outbuf = malloc(block_size);
    size_t src_block_size = block_size - 11;
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    for (int idx = 0; idx < srclen; idx += src_block_size) {
        size_t data_len = srclen - idx;
        if (data_len > src_block_size) {
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        
        if (isSign) {
            status = SecKeyRawSign(keyRef,
                                   kSecPaddingPKCS1,
                                   srcbuf + idx,
                                   data_len,
                                   outbuf,
                                   &outlen
                                   );
        } else {
            status = SecKeyEncrypt(keyRef,
                                   kSecPaddingPKCS1,
                                   srcbuf + idx,
                                   data_len,
                                   outbuf,
                                   &outlen
                                   );
        }
        if (status != 0) {
            ret = nil;
            break;
        } else {
            [ret appendBytes:outbuf length:outlen];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}

+ (NSData *)fw_RSADecryptData:(NSData *)data withKeyRef:(SecKeyRef)keyRef
{
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    UInt8 *outbuf = malloc(block_size);
    size_t src_block_size = block_size;
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    for (int idx = 0; idx < srclen; idx += src_block_size) {
        size_t data_len = srclen - idx;
        if (data_len > src_block_size) {
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        status = SecKeyDecrypt(keyRef,
                               kSecPaddingNone,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0) {
            ret = nil;
            break;
        } else {
            int idxFirstZero = -1;
            int idxNextZero = (int)outlen;
            for (int i = 0; i < outlen; i++) {
                if (outbuf[i] == 0) {
                    if (idxFirstZero < 0) {
                        idxFirstZero = i;
                    } else {
                        idxNextZero = i;
                        break;
                    }
                }
            }
            [ret appendBytes:&outbuf[idxFirstZero + 1] length:idxNextZero - idxFirstZero - 1];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}

+ (SecKeyRef)fw_RSAAddPublicKey:(NSString *)key andTag:(NSString *)tagName
{
    NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];
    if (spos.location != NSNotFound && epos.location != NSNotFound) {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:key options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self fw_RSAStripPublicKeyHeader:data];
    if (!data) {
        return nil;
    }

    NSData *tagData = [NSData dataWithBytes:[tagName UTF8String] length:[tagName length]];
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:tagData forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil) {
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }

    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if (status != noErr) {
        return nil;
    }
    return keyRef;
}

+ (SecKeyRef)fw_RSAAddPrivateKey:(NSString *)key andTag:(NSString *)tagName
{
    NSRange spos;
    NSRange epos;
    spos = [key rangeOfString:@"-----BEGIN RSA PRIVATE KEY-----"];
    if (spos.length > 0) {
        epos = [key rangeOfString:@"-----END RSA PRIVATE KEY-----"];
    } else {
        spos = [key rangeOfString:@"-----BEGIN PRIVATE KEY-----"];
        epos = [key rangeOfString:@"-----END PRIVATE KEY-----"];
    }
    if (spos.location != NSNotFound && epos.location != NSNotFound) {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];

    NSData *data = [[NSData alloc] initWithBase64EncodedString:key options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self fw_RSAStripPrivateKeyHeader:data];
    if (!data) {
        return nil;
    }

    NSData *tagData = [NSData dataWithBytes:[tagName UTF8String] length:[tagName length]];
    NSMutableDictionary *privateKey = [[NSMutableDictionary alloc] init];
    [privateKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [privateKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [privateKey setObject:tagData forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)privateKey);

    [privateKey setObject:data forKey:(__bridge id)kSecValueData];
    [privateKey setObject:(__bridge id) kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];

    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)privateKey, &persistKey);
    if (persistKey != nil) {
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }

    [privateKey removeObjectForKey:(__bridge id)kSecValueData];
    [privateKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [privateKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)privateKey, (CFTypeRef *)&keyRef);
    if (status != noErr) {
        return nil;
    }
    return keyRef;
}

+ (NSData *)fw_RSAStripPublicKeyHeader:(NSData *)d_key
{
    if (d_key == nil) return nil;
    unsigned long len = [d_key length];
    if (!len) return nil;
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    if (c_key[idx++] != 0x30) return nil;
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;

    static unsigned char seqiod[] = { 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return nil;
    
    idx += 15;
    if (c_key[idx++] != 0x03) return nil;
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    if (c_key[idx++] != '\0') return nil;
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

+ (NSData *)fw_RSAStripPrivateKeyHeader:(NSData *)d_key
{
    if (d_key == nil) return nil;
    unsigned long len = [d_key length];
    if (!len) return nil;

    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx     = 22;
    if (0x04 != c_key[idx++]) return d_key;

    unsigned int c_len = c_key[idx++];
    int det = c_len & 0x80;
    if (!det) {
        c_len = c_len & 0x7f;
    } else {
        int byteCount = c_len & 0x7f;
        if (byteCount + idx > len) {
            return nil;
        }
        unsigned int accum = 0;
        unsigned char *ptr = &c_key[idx];
        idx += byteCount;
        while (byteCount) {
            accum = (accum << 8) + *ptr;
            ptr++;
            byteCount--;
        }
        c_len = accum;
    }
    return [d_key subdataWithRange:NSMakeRange(idx, c_len)];
}

@end

#pragma mark - NSDate+FWFoundation

// 当前基准时间值
static NSTimeInterval fwStaticCurrentBaseTime = 0;
// 本地基准时间值
static NSTimeInterval fwStaticLocalBaseTime = 0;

@implementation NSDate (FWFoundation)

- (NSString *)fw_stringValue
{
    return [self fw_stringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
}

- (NSString *)fw_stringWithFormat:(NSString *)format
{
    return [self fw_stringWithFormat:format timeZone:nil];
}

- (NSString *)fw_stringWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    if (timeZone) formatter.timeZone = timeZone;
    NSString *string = [formatter stringFromDate:self];
    return string;
}

+ (NSTimeInterval)fw_currentTime
{
    // 没有同步过返回本地时间
    if (fwStaticCurrentBaseTime == 0) {
        // 是否本地有服务器时间
        NSNumber *preCurrentTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWCurrentTime"];
        NSNumber *preLocalTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalTime"];
        if (preCurrentTime && preLocalTime) {
            // 计算当前服务器时间
            NSTimeInterval offsetTime = [[NSDate date] timeIntervalSince1970] - preLocalTime.doubleValue;
            return preCurrentTime.doubleValue + offsetTime;
        } else {
            return [[NSDate date] timeIntervalSince1970];
        }
    // 同步过计算当前服务器时间
    } else {
        NSTimeInterval offsetTime = [self fw_currentSystemUptime] - fwStaticLocalBaseTime;
        return fwStaticCurrentBaseTime + offsetTime;
    }
}

+ (void)setFw_currentTime:(NSTimeInterval)currentTime
{
    fwStaticCurrentBaseTime = currentTime;
    // 取运行时间，调整系统时间不会影响
    fwStaticLocalBaseTime = [self fw_currentSystemUptime];
    
    // 保存当前服务器时间到本地
    [[NSUserDefaults standardUserDefaults] setObject:@(currentTime) forKey:@"FWCurrentTime"];
    [[NSUserDefaults standardUserDefaults] setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"FWLocalTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSTimeInterval)fw_currentSystemUptime
{
    struct timeval bootTime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(bootTime);
    int resctl = sysctl(mib, 2, &bootTime, &size, NULL, 0);

    struct timeval now;
    struct timezone tz;
    gettimeofday(&now, &tz);
    
    NSTimeInterval uptime = 0;
    if (resctl != -1 && bootTime.tv_sec != 0) {
        uptime = now.tv_sec - bootTime.tv_sec;
        uptime += (now.tv_usec - bootTime.tv_usec) / 1.e6;
    }
    return uptime;
}

+ (NSDate *)fw_dateWithString:(NSString *)string
{
    return [self fw_dateWithString:string format:@"yyyy-MM-dd HH:mm:ss"];
}

+ (NSDate *)fw_dateWithString:(NSString *)string format:(NSString *)format
{
    return [self fw_dateWithString:string format:format timeZone:nil];
}

+ (NSDate *)fw_dateWithString:(NSString *)string format:(NSString *)format timeZone:(NSTimeZone *)timeZone
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    if (timeZone) formatter.timeZone = timeZone;
    NSDate *date = [formatter dateFromString:string];
    return date;
}

+ (NSString *)fw_formatDuration:(NSTimeInterval)duration hasHour:(BOOL)hasHour
{
    long long seconds = (long long)duration;
    if (hasHour) {
        long long minute = seconds / 60;
        long long hour   = minute / 60;
        seconds -= minute * 60;
        minute -= hour * 60;
        return [NSString stringWithFormat:@"%02d:%02d:%02d", (int)hour, (int)minute, (int)seconds];
    } else {
        long long minute = seconds / 60;
        long long second = seconds % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)second];
    }
}

+ (NSTimeInterval)fw_formatTimestamp:(NSTimeInterval)timestamp
{
    NSString *string = [NSString stringWithFormat:@"%ld", (long)timestamp];
    if (string.length == 16) {
        return timestamp / 1000.0 / 1000.0;
    } else if (string.length == 13) {
        return timestamp / 1000.0;
    } else {
        return timestamp;
    }
}

- (BOOL)fw_isLeapYear
{
    NSInteger year = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:self];
    if (year % 400 == 0) {
        return YES;
    } else if (year % 100 == 0) {
        return NO;
    } else if (year % 4 == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)fw_isSameDay:(NSDate *)date
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:date];
    NSDate *dateOne = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    components = [[NSCalendar currentCalendar] components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:self];
    NSDate *dateTwo = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    return [dateOne isEqualToDate:dateTwo];
}

- (NSDate *)fw_dateByAdding:(NSDateComponents *)components
{
    return [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:self options:0];
}

- (NSInteger)fw_daysFrom:(NSDate *)date
{
    NSDate *earliest = [self earlierDate:date];
    NSDate *latest = (earliest == self) ? date : self;
    NSInteger multipier = (earliest == self) ? -1 : 1;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:earliest toDate:latest options:0];
    return multipier * components.day;
}

@end

#pragma mark - NSDictionary+FWFoundation

@implementation NSDictionary (FWFoundation)

- (NSDictionary *)fw_filterWithBlock:(BOOL (^)(id, id))block
{
    NSParameterAssert(block != nil);

    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (block(key, obj)) {
            result[key] = obj;
        }
    }];
    return result;
}

- (NSDictionary *)fw_mapWithBlock:(id (^)(id, id))block
{
    NSParameterAssert(block != nil);
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = block(key, obj);
        if (value) {
            result[key] = value;
        }
    }];
    return result;
}

- (id)fw_matchWithBlock:(BOOL (^)(id, id))block
{
    NSParameterAssert(block != nil);
    
    __block id result = nil;
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (block(key, obj)) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

@end

#pragma mark - NSString+FWFoundation

@implementation NSString (FWFoundation)

- (CGSize)fw_sizeWithFont:(UIFont *)font
{
    return [self fw_sizeWithFont:font drawSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)fw_sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize
{
    return [self fw_sizeWithFont:font drawSize:drawSize attributes:nil];
}

- (CGSize)fw_sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize attributes:(NSDictionary<NSAttributedStringKey,id> *)attributes
{
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    attr[NSFontAttributeName] = font;
    if (attributes != nil) {
        [attr addEntriesFromDictionary:attributes];
    }
    CGSize size = [self boundingRectWithSize:drawSize
                                          options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attr
                                          context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

- (BOOL)fw_matchesRegex:(NSString *)regex
{
    NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [regexPredicate evaluateWithObject:self] == YES;
}

+ (NSString *)fw_sizeString:(NSUInteger)aFileSize
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

- (NSString *)fw_emojiSubstring:(NSUInteger)index
{
    NSString *result = self;
    if (result.length > index) {
        // 获取index处的整个字符range，并截取掉整个字符，防止半个Emoji
        NSRange rangeIndex = [result rangeOfComposedCharacterSequenceAtIndex:index];
        result = [result substringToIndex:rangeIndex.location];
    }
    return result;
}

- (NSString *)fw_regexSubstring:(NSString *)regex
{
    NSRange range = [self rangeOfString:regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        return [self substringWithRange:range];
    } else {
        return nil;
    }
}

- (NSString *)fw_regexReplace:(NSString *)regex withString:(NSString *)string
{
    NSRegularExpression *regexObj = [[NSRegularExpression alloc] initWithPattern:regex options:0 error:nil];
    return [regexObj stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:string];
}

- (void)fw_regexMatches:(NSString *)regex withBlock:(void (^)(NSRange))block
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

- (NSString *)fw_escapeHtml
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

- (BOOL)fw_isFormatRegex:(NSString *)regex
{
    NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [regexPredicate evaluateWithObject:self] == YES;
}

- (BOOL)fw_isFormatMobile
{
    return [self fw_isFormatRegex:@"^1\\d{10}$"];
}

- (BOOL)fw_isFormatTelephone
{
    return [self fw_isFormatRegex:@"^(\\d{3}\\-)?\\d{8}|(\\d{4}\\-)?\\d{7}$"];
}

- (BOOL)fw_isFormatInteger
{
    return [self fw_isFormatRegex:@"^\\-?\\d+$"];
}

- (BOOL)fw_isFormatNumber
{
    return [self fw_isFormatRegex:@"^\\-?\\d+\\.?\\d*$"];
}

- (BOOL)fw_isFormatMoney
{
    return [self fw_isFormatRegex:@"^\\d+\\.?\\d{0,2}$"];
}

- (BOOL)fw_isFormatIdcard
{
    // 简单版本
    // return [self isFormatRegex:@"^[1-9]\\d{5}[1-9]\\d{3}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}(\\d|x|X)$"];
    
    // 复杂版本
    NSString *sPaperId = self;
    // 判断位数
    if ([sPaperId length] != 15 && [sPaperId length] != 18) {
        return NO;
    }
    
    NSString *carid = sPaperId;
    long lSumQT = 0;
    // 加权因子
    int R[] = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2};
    // 校验码
    unsigned char sChecker[11] = {'1','0','X', '9', '8', '7', '6', '5', '4', '3', '2'};
    // 将15位身份证号转换成18位
    NSMutableString *mString = [NSMutableString stringWithString:sPaperId];
    if ([sPaperId length] == 15) {
        [mString insertString:@"19" atIndex:6];
        long p = 0;
        const char *pid = [mString UTF8String];
        for (int i = 0; i <= 16; i++) {
            p += (pid[i] - 48) * R[i];
        }
        int o = p % 11;
        NSString *string_content = [NSString stringWithFormat:@"%c", sChecker[o]];
        [mString insertString:string_content atIndex:[mString length]];
        carid = mString;
    }
    
    // 判断是否在地区码内
    NSString *sProvince = [carid substringToIndex:2];
    NSDictionary *dic = @{
                          @"11" : @"北京",
                          @"12" : @"天津",
                          @"13" : @"河北",
                          @"14" : @"山西",
                          @"15" : @"内蒙古",
                          @"21" : @"辽宁",
                          @"22" : @"吉林",
                          @"23" : @"黑龙江",
                          @"31" : @"上海",
                          @"32" : @"江苏",
                          @"33" : @"浙江",
                          @"34" : @"安徽",
                          @"35" : @"福建",
                          @"36" : @"江西",
                          @"37" : @"山东",
                          @"41" : @"河南",
                          @"42" : @"湖北",
                          @"43" : @"湖南",
                          @"44" : @"广东",
                          @"45" : @"广西",
                          @"46" : @"海南",
                          @"50" : @"重庆",
                          @"51" : @"四川",
                          @"52" : @"贵州",
                          @"53" : @"云南",
                          @"54" : @"西藏",
                          @"61" : @"陕西",
                          @"62" : @"甘肃",
                          @"63" : @"青海",
                          @"64" : @"宁夏",
                          @"65" : @"新疆",
                          @"71" : @"台湾",
                          @"81" : @"香港",
                          @"82" : @"澳门",
                          @"91" : @"国外",
                          };
    if ([dic objectForKey:sProvince] == nil) {
        return NO;
    }
    
    // 判断年月日是否有效
    int strYear = [[carid substringWithRange:NSMakeRange(6, 4)] intValue];
    int strMonth = [[carid substringWithRange:NSMakeRange(10, 2)] intValue];
    int strDay = [[carid substringWithRange:NSMakeRange(12, 2)] intValue];
    NSTimeZone *localZone = [NSTimeZone localTimeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeZone:localZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%d-%d-%d 12:01:01", strYear, strMonth, strDay]];
    if (date == nil) {
        return NO;
    }
    
    // 检验长度
    const char *PaperId  = [carid UTF8String];
    if( 18 != strlen(PaperId)) return NO;
    // 校验数字
    for (int i = 0; i < 18; i++) {
        if (!isdigit(PaperId[i]) && !(('X' == PaperId[i] || 'x' == PaperId[i]) && 17 == i)) {
            return NO;
        }
    }
    
    // 验证最末的校验码
    for (int i = 0; i <= 16; i++) {
        lSumQT += (PaperId[i] - 48) * R[i];
    }
    if (sChecker[lSumQT % 11] != PaperId[17]) {
        return NO;
    }
    
    // 校验通过
    return YES;
}

/**
 *  银行卡号有效性问题Luhn算法
 *  现行 16 位银联卡现行卡号开头 6 位是 622126～622925 之间的，7 到 15 位是银行自定义的，
 *  可能是发卡分行，发卡网点，发卡序号，第 16 位是校验码。
 *  16 位卡号校验位采用 Luhm 校验方法计算：
 *  1，将未带校验位的 15 位卡号从右依次编号 1 到 15，位于奇数位号上的数字乘以 2
 *  2，将奇位乘积的个十位全部相加，再加上所有偶数位上的数字
 *  3，将加法和加上校验位能被 10 整除。
 */
- (BOOL)fw_isFormatBankcard
{
    // 取出最后一位
    NSString *lastNum = [[self substringFromIndex:(self.length - 1)] copy];
    // 前15或18位
    NSString *forwardNum = [[self substringToIndex:(self.length - 1)] copy];
    
    NSMutableArray *forwardArr = [[NSMutableArray alloc] initWithCapacity:0];
    for (int i = 0; i < forwardNum.length; i++) {
        NSString *subStr = [forwardNum substringWithRange:NSMakeRange(i, 1)];
        [forwardArr addObject:subStr];
    }
    
    NSMutableArray *forwardDescArr = [[NSMutableArray alloc] initWithCapacity:0];
    // 前15位或者前18位倒序存进数组
    for (int i = (int)(forwardArr.count - 1); i > -1; i--) {
        [forwardDescArr addObject:forwardArr[i]];
    }
    
    // 奇数位*2的积 < 9
    NSMutableArray *arrOddNum = [[NSMutableArray alloc] initWithCapacity:0];
    // 奇数位*2的积 > 9
    NSMutableArray *arrOddNum2 = [[NSMutableArray alloc] initWithCapacity:0];
    // 偶数位数组
    NSMutableArray *arrEvenNum = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (int i = 0; i < forwardDescArr.count; i++) {
        NSInteger num = [forwardDescArr[i] intValue];
        // 偶数位
        if (i % 2) {
            [arrEvenNum addObject:[NSNumber numberWithInteger:num]];
            // 奇数位
        } else {
            if (num * 2 < 9) {
                [arrOddNum addObject:[NSNumber numberWithInteger:num * 2]];
            } else {
                NSInteger decadeNum = (num * 2) / 10;
                NSInteger unitNum = (num * 2) % 10;
                [arrOddNum2 addObject:[NSNumber numberWithInteger:unitNum]];
                [arrOddNum2 addObject:[NSNumber numberWithInteger:decadeNum]];
            }
        }
    }
    
    __block NSInteger sumOddNumTotal = 0;
    [arrOddNum enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        sumOddNumTotal += [obj integerValue];
    }];
    
    __block NSInteger sumOddNum2Total = 0;
    [arrOddNum2 enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        sumOddNum2Total += [obj integerValue];
    }];
    
    __block NSInteger sumEvenNumTotal =0 ;
    [arrEvenNum enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        sumEvenNumTotal += [obj integerValue];
    }];
    
    NSInteger lastNumber = [lastNum integerValue];
    NSInteger luhmTotal = lastNumber + sumEvenNumTotal + sumOddNum2Total + sumOddNumTotal;
    return (luhmTotal % 10 == 0) ? YES : NO;
}

- (BOOL)fw_isFormatCarno
{
    // 车牌号:湘K-DE829 香港车牌号码:粤Z-J499港。\u4e00-\u9fa5表示unicode编码中汉字已编码部分，\u9fa5-\u9fff是保留部分
    NSString *regex = @"^[\u4e00-\u9fff]{1}[a-zA-Z]{1}[-][a-zA-Z_0-9]{4}[a-zA-Z_0-9_\u4e00-\u9fff]$";
    return [self fw_isFormatRegex:regex];
}

- (BOOL)fw_isFormatPostcode
{
    return [self fw_isFormatRegex:@"^[0-8]\\d{5}(?!\\d)$"];
}

- (BOOL)fw_isFormatIp
{
    // 简单版本
    // return [self fw_isFormatRegex:@"^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$"];
    
    // 复杂版本
    NSArray *components = [self componentsSeparatedByString:@"."];
    NSCharacterSet *invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet];
    
    if ([components count] == 4) {
        NSString *part1 = [components objectAtIndex:0];
        NSString *part2 = [components objectAtIndex:1];
        NSString *part3 = [components objectAtIndex:2];
        NSString *part4 = [components objectAtIndex:3];
        
        if ([part1 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound &&
            [part2 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound &&
            [part3 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound &&
            [part4 rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound) {
            if ([part1 intValue] < 255 &&
                [part2 intValue] < 255 &&
                [part3 intValue] < 255 &&
                [part4 intValue] < 255) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)fw_isFormatUrl
{
    return [self.lowercaseString hasPrefix:@"http://"] || [self.lowercaseString hasPrefix:@"https://"];
}

- (BOOL)fw_isFormatHtml
{
    return [self rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch].location != NSNotFound;
}

- (BOOL)fw_isFormatEmail
{
    return [self fw_isFormatRegex:@"^[A-Z0-9a-z._\%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"];
}

- (BOOL)fw_isFormatChinese
{
    return [self fw_isFormatRegex:@"^[\\x{4e00}-\\x{9fa5}]+$"];
}

- (BOOL)fw_isFormatDatetime
{
    return [self fw_isFormatRegex:@"^\\d{4}\\-\\d{2}\\-\\d{2}\\s\\d{2}\\:\\d{2}\\:\\d{2}$"];
}

- (BOOL)fw_isFormatTimestamp
{
    return [self fw_isFormatRegex:@"^\\d{10}$"];
}

- (BOOL)fw_isFormatCoordinate
{
    return [self fw_isFormatRegex:@"^\\-?\\d+\\.?\\d*,\\-?\\d+\\.?\\d*$"];
}

@end

#pragma mark - NSURL+FWFoundation

@implementation NSURL (FWFoundation)

+ (NSURL *)fw_mapsURLWithString:(NSString *)string params:(NSDictionary *)params
{
    NSMutableString *urlString = [[NSMutableString alloc] initWithString:string];
    [urlString appendString:@"?"];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *valueStr = [[[NSString stringWithFormat:@"%@", value] stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendFormat:@"%@=%@&", key, valueStr];
    }];
    return [NSURL URLWithString:[urlString substringToIndex:urlString.length - 1]];
}

+ (NSURL *)fw_appleMapsURLWithAddr:(NSString *)addr options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (addr.length > 0) {
        [params setObject:addr forKey:@"q"];
    }
    return [self fw_mapsURLWithString:@"http://maps.apple.com/" params:params];
}

+ (NSURL *)fw_appleMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (saddr.length > 0) {
        [params setObject:saddr forKey:@"saddr"];
    }
    if (daddr.length > 0) {
        [params setObject:daddr forKey:@"daddr"];
    }
    return [self fw_mapsURLWithString:@"http://maps.apple.com/" params:params];
}

+ (NSURL *)fw_googleMapsURLWithAddr:(NSString *)addr options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (addr.length > 0) {
        [params setObject:addr forKey:@"q"];
    }
    return [self fw_mapsURLWithString:@"comgooglemaps://" params:params];
}

+ (NSURL *)fw_googleMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr mode:(NSString *)mode options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (saddr.length > 0) {
        [params setObject:saddr forKey:@"saddr"];
    }
    if (daddr.length > 0) {
        [params setObject:daddr forKey:@"daddr"];
    }
    [params setObject:(mode.length > 0 ? mode : @"driving") forKey:@"directionsmode"];
    return [self fw_mapsURLWithString:@"comgooglemaps://" params:params];
}

+ (NSURL *)fw_baiduMapsURLWithAddr:(NSString *)addr options:(NSDictionary *)options
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:options];
    if (addr.length > 0) {
        if ([addr fw_isFormatCoordinate]) {
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
    return [self fw_mapsURLWithString:@"baidumap://map/geocoder" params:params];
}

+ (NSURL *)fw_baiduMapsURLWithSaddr:(NSString *)saddr daddr:(NSString *)daddr mode:(NSString *)mode options:(NSDictionary *)options
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
    return [self fw_mapsURLWithString:@"baidumap://map/direction" params:params];
}

@end
