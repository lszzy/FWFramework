//
//  Bridge.m
//  FWFramework
//
//  Created by wuyong on 2022/11/11.
//

#import "Bridge.h"
#import <sys/sysctl.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Accelerate/Accelerate.h>
#import <dlfcn.h>

#pragma mark - __FWBridge

typedef struct CF_BRIDGED_TYPE(id) CGSVGDocument *CGSVGDocumentRef;
static void (*__FWCGSVGDocumentRelease)(CGSVGDocumentRef);
static CGSVGDocumentRef (*__FWCGSVGDocumentCreateFromData)(CFDataRef data, CFDictionaryRef options);
static void (*__FWCGSVGDocumentWriteToData)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options);
static void (*__FWCGContextDrawSVGDocument)(CGContextRef context, CGSVGDocumentRef document);
static CGSize (*__FWCGSVGDocumentGetCanvasSize)(CGSVGDocumentRef document);
static SEL __FWImageWithCGSVGDocumentSEL = NULL;
static SEL __FWCGSVGDocumentSEL = NULL;

@implementation __FWBridge

+ (NSString *)base64Decode:(NSString *)base64String {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (BOOL)svgSupported {
    static BOOL isSupported = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __FWCGSVGDocumentRelease = dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudFJlbGVhc2U="].UTF8String);
        __FWCGSVGDocumentCreateFromData = dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudENyZWF0ZUZyb21EYXRh"].UTF8String);
        __FWCGSVGDocumentWriteToData = dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudFdyaXRlVG9EYXRh"].UTF8String);
        __FWCGContextDrawSVGDocument = (void (*)(CGContextRef context, CGSVGDocumentRef document))dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dDb250ZXh0RHJhd1NWR0RvY3VtZW50"].UTF8String);
        __FWCGSVGDocumentGetCanvasSize = (CGSize (*)(CGSVGDocumentRef document))dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudEdldENhbnZhc1NpemU="].UTF8String);
        __FWImageWithCGSVGDocumentSEL = NSSelectorFromString([self base64Decode:@"X2ltYWdlV2l0aENHU1ZHRG9jdW1lbnQ6"]);
        __FWCGSVGDocumentSEL = NSSelectorFromString([self base64Decode:@"X0NHU1ZHRG9jdW1lbnQ="]);
        
        isSupported = [UIImage respondsToSelector:__FWImageWithCGSVGDocumentSEL];
    });
    return isSupported;
}

+ (UIImage *)svgDecode:(NSData *)data thumbnailSize:(CGSize)thumbnailSize {
    if (![self svgSupported]) return nil;
    
    BOOL prefersBitmap = NO;
    CGSize imageSize = CGSizeZero;
    if (!CGSizeEqualToSize(thumbnailSize, CGSizeZero)) {
        prefersBitmap = YES;
        imageSize = thumbnailSize;
    }
    
    if (!prefersBitmap) {
        CGSVGDocumentRef document = __FWCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
        if (!document) return nil;
        UIImage *image = ((UIImage *(*)(id,SEL,CGSVGDocumentRef))[UIImage.class methodForSelector:__FWImageWithCGSVGDocumentSEL])(UIImage.class, __FWImageWithCGSVGDocumentSEL, document);
        __FWCGSVGDocumentRelease(document);
        
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)];
        @try {
            __unused UIImage *dummyImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
                [image drawInRect:CGRectMake(0, 0, 1, 1)];
            }];
        } @catch (...) {
            return nil;
        }
        return image;
    } else {
        CGSVGDocumentRef document = __FWCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
        if (!document) {
            return nil;
        }
        CGSize size = __FWCGSVGDocumentGetCanvasSize(document);
        if (size.width == 0 || size.height == 0) {
            return nil;
        }
        
        CGFloat xScale;
        CGFloat yScale;
        if (thumbnailSize.width <= 0 && thumbnailSize.height <= 0) {
            thumbnailSize.width = size.width;
            thumbnailSize.height = size.height;
            xScale = 1;
            yScale = 1;
        } else {
            CGFloat xRatio = thumbnailSize.width / size.width;
            CGFloat yRatio = thumbnailSize.height / size.height;
            if (thumbnailSize.width <= 0) {
                yScale = yRatio;
                xScale = yRatio;
                thumbnailSize.width = size.width * xScale;
            } else if (thumbnailSize.height <= 0) {
                xScale = xRatio;
                yScale = xRatio;
                thumbnailSize.height = size.height * yScale;
            } else {
                xScale = MIN(xRatio, yRatio);
                yScale = MIN(xRatio, yRatio);
                thumbnailSize.width = size.width * xScale;
                thumbnailSize.height = size.height * yScale;
            }
        }
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        CGRect targetRect = CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height);
        
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(xScale, yScale);
        CGAffineTransform transform = CGAffineTransformMakeTranslation((targetRect.size.width / xScale - rect.size.width) / 2, (targetRect.size.height / yScale - rect.size.height) / 2);
        
        UIGraphicsBeginImageContextWithOptions(targetRect.size, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, targetRect.size.height);
        CGContextScaleCTM(context, 1, -1);
        CGContextConcatCTM(context, scaleTransform);
        CGContextConcatCTM(context, transform);
        
        __FWCGContextDrawSVGDocument(context, document);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        __FWCGSVGDocumentRelease(document);
        return image;
    }
}

+ (NSData *)svgEncode:(UIImage *)image {
    if (![self svgSupported]) return nil;
    
    NSMutableData *data = [NSMutableData data];
    CGSVGDocumentRef document = ((CGSVGDocumentRef (*)(id,SEL))[image methodForSelector:__FWCGSVGDocumentSEL])(image, __FWCGSVGDocumentSEL);
    if (!document) return nil;
    __FWCGSVGDocumentWriteToData(document, (__bridge CFDataRef)data, NULL);
    return [data copy];
}

@end

#pragma mark - __FWEncrypt

@implementation NSData (__FWEncrypt)

- (NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey {
    return [self __fw_RSAEncryptWithPublicKey:publicKey andTag:@"FWRSA_PublicKey" base64Encode:YES];
}

- (NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode {
    if (!publicKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPublicKey:publicKey andTag:tagName];
    if (!keyRef) return nil;
    
    NSData *data = [NSData __fw_RSAEncryptData:self withKeyRef:keyRef isSign:NO];
    if (data && base64Encode) {
        data = [data base64EncodedDataWithOptions:0];
    }
    return data;
}

- (NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey {
    return [self __fw_RSADecryptWithPrivateKey:privateKey andTag:@"FWRSA_PrivateKey" base64Decode:YES];
}

- (NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode {
    NSData *data = self;
    if (base64Decode) {
        data = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data || !privateKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPrivateKey:privateKey andTag:tagName];
    if (!keyRef) return nil;
    
    return [NSData __fw_RSADecryptData:data withKeyRef:keyRef];
}

- (NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey {
    return [self __fw_RSASignWithPrivateKey:privateKey andTag:@"FWRSA_PrivateKey" base64Encode:YES];
}

- (NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode {
    if (!privateKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPrivateKey:privateKey andTag:tagName];
    if (!keyRef) return nil;
    
    NSData *data = [NSData __fw_RSAEncryptData:self withKeyRef:keyRef isSign:YES];
    if (data && base64Encode) {
        data = [data base64EncodedDataWithOptions:0];
    }
    return data;
}

- (NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey {
    return [self __fw_RSAVerifyWithPublicKey:publicKey andTag:@"FWRSA_PublicKey" base64Decode:YES];
}

- (NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode {
    NSData *data = self;
    if (base64Decode) {
        data = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data || !publicKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPublicKey:publicKey andTag:tagName];
    if (!keyRef) return nil;
    
    return [NSData __fw_RSADecryptData:data withKeyRef:keyRef];
}

+ (NSData *)__fw_RSAEncryptData:(NSData *)data withKeyRef:(SecKeyRef) keyRef isSign:(BOOL)isSign {
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

+ (NSData *)__fw_RSADecryptData:(NSData *)data withKeyRef:(SecKeyRef)keyRef {
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

+ (SecKeyRef)__fw_RSAAddPublicKey:(NSString *)key andTag:(NSString *)tagName {
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
    data = [self __fw_RSAStripPublicKeyHeader:data];
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

+ (SecKeyRef)__fw_RSAAddPrivateKey:(NSString *)key andTag:(NSString *)tagName {
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
    data = [self __fw_RSAStripPrivateKeyHeader:data];
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

+ (NSData *)__fw_RSAStripPublicKeyHeader:(NSData *)d_key {
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

+ (NSData *)__fw_RSAStripPrivateKeyHeader:(NSData *)d_key {
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

#pragma mark - UIImage+__FWBridge

@implementation UIImage (__FWBridge)

- (UIImage *)__fw_maskImage {
    NSInteger width = CGImageGetWidth(self.CGImage);
    NSInteger height = CGImageGetHeight(self.CGImage);
    
    NSInteger bytesPerRow = ((width + 3) / 4) * 4;
    void *data = calloc(bytesPerRow * height, sizeof(unsigned char *));
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, bytesPerRow, NULL, kCGImageAlphaOnly);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), self.CGImage);
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            NSInteger index = y * bytesPerRow + x;
            ((unsigned char *)data)[index] = 255 - ((unsigned char *)data)[index];
        }
    }
    
    CGImageRef maskRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *mask = [UIImage imageWithCGImage:maskRef];
    CGImageRelease(maskRef);
    free(data);
    
    return mask;
}

- (UIImage *)__fw_imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(UIColor *)tintColor maskImage:(UIImage *)maskImage {
    if (self.size.width < 1 || self.size.height < 1) {
        return nil;
    }
    if (!self.CGImage) {
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDelta - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            uint32_t radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1;
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDelta;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

@end
