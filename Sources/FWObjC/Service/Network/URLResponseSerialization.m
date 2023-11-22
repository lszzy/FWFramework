// URLResponseSerialization.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "URLResponseSerialization.h"
#import "ObjC.h"
#import <TargetConditionals.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

NSString * const __FWURLResponseSerializationErrorDomain = @"site.wuyong.error.serialization.response";
NSString * const __FWNetworkingOperationFailingURLResponseErrorKey = @"site.wuyong.serialization.response.error.response";
NSString * const __FWNetworkingOperationFailingURLResponseDataErrorKey = @"site.wuyong.serialization.response.error.data";

static NSError * __FWErrorWithUnderlyingError(NSError *error, NSError *underlyingError) {
    if (!error) {
        return underlyingError;
    }

    if (!underlyingError || error.userInfo[NSUnderlyingErrorKey]) {
        return error;
    }

    NSMutableDictionary *mutableUserInfo = [error.userInfo mutableCopy];
    mutableUserInfo[NSUnderlyingErrorKey] = underlyingError;

    return [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:mutableUserInfo];
}

static BOOL __FWErrorOrUnderlyingErrorHasCodeInDomain(NSError *error, NSInteger code, NSString *domain) {
    if ([error.domain isEqualToString:domain] && error.code == code) {
        return YES;
    } else if (error.userInfo[NSUnderlyingErrorKey]) {
        return __FWErrorOrUnderlyingErrorHasCodeInDomain(error.userInfo[NSUnderlyingErrorKey], code, domain);
    }

    return NO;
}

id __FWJSONObjectByRemovingKeysWithNullValues(id JSONObject, NSJSONReadingOptions readingOptions) {
    if ([JSONObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:[(NSArray *)JSONObject count]];
        for (id value in (NSArray *)JSONObject) {
            if (![value isEqual:[NSNull null]]) {
                [mutableArray addObject:__FWJSONObjectByRemovingKeysWithNullValues(value, readingOptions)];
            }
        }

        return (readingOptions & NSJSONReadingMutableContainers) ? mutableArray : [NSArray arrayWithArray:mutableArray];
    } else if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:JSONObject];
        for (id <NSCopying> key in [(NSDictionary *)JSONObject allKeys]) {
            id value = (NSDictionary *)JSONObject[key];
            if (!value || [value isEqual:[NSNull null]]) {
                [mutableDictionary removeObjectForKey:key];
            } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
                mutableDictionary[key] = __FWJSONObjectByRemovingKeysWithNullValues(value, readingOptions);
            }
        }

        return (readingOptions & NSJSONReadingMutableContainers) ? mutableDictionary : [NSDictionary dictionaryWithDictionary:mutableDictionary];
    }

    return JSONObject;
}

@implementation __FWHTTPResponseSerializer

+ (instancetype)serializer {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    self.acceptableContentTypes = nil;

    return self;
}

#pragma mark -

- (void)setUserInfo:(NSDictionary *)userInfo forResponse:(NSURLResponse *)response {
    if (!response) return;
    objc_setAssociatedObject(response, @selector(userInfoForResponse:), userInfo, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)userInfoForResponse:(NSURLResponse *)response {
    if (!response) return nil;
    return objc_getAssociatedObject(response, @selector(userInfoForResponse:));
}

- (BOOL)validateResponse:(NSHTTPURLResponse *)response
                    data:(NSData *)data
                   error:(NSError * __autoreleasing *)error
{
    BOOL responseIsValid = YES;
    NSError *validationError = nil;

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        if (self.acceptableContentTypes && ![self.acceptableContentTypes containsObject:[response MIMEType]] &&
            !([response MIMEType] == nil && [data length] == 0)) {

            if ([data length] > 0 && [response URL]) {
                NSMutableDictionary *mutableUserInfo = [@{
                                                          NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: unacceptable content-type: %@", @"AFNetworking", nil), [response MIMEType]],
                                                          NSURLErrorFailingURLErrorKey:[response URL],
                                                          __FWNetworkingOperationFailingURLResponseErrorKey: response,
                                                        } mutableCopy];
                if (data) {
                    mutableUserInfo[__FWNetworkingOperationFailingURLResponseDataErrorKey] = data;
                }

                validationError = __FWErrorWithUnderlyingError([NSError errorWithDomain:__FWURLResponseSerializationErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:mutableUserInfo], validationError);
            }

            responseIsValid = NO;
        }

        if (self.acceptableStatusCodes && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode] && [response URL]) {
            NSMutableDictionary *mutableUserInfo = [@{
                                               NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%ld)", @"AFNetworking", nil), [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode], (long)response.statusCode],
                                               NSURLErrorFailingURLErrorKey:[response URL],
                                               __FWNetworkingOperationFailingURLResponseErrorKey: response,
                                       } mutableCopy];

            if (data) {
                mutableUserInfo[__FWNetworkingOperationFailingURLResponseDataErrorKey] = data;
            }

            validationError = __FWErrorWithUnderlyingError([NSError errorWithDomain:__FWURLResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:mutableUserInfo], validationError);

            responseIsValid = NO;
        }
    }

    if (error && !responseIsValid) {
        *error = validationError;
    }

    return responseIsValid;
}

#pragma mark - __FWURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    [self validateResponse:(NSHTTPURLResponse *)response data:data error:error];

    return data;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    if (!self) {
        return nil;
    }

    self.acceptableStatusCodes = [decoder decodeObjectOfClass:[NSIndexSet class] forKey:NSStringFromSelector(@selector(acceptableStatusCodes))];
    self.acceptableContentTypes = [decoder decodeObjectOfClass:[NSSet class] forKey:NSStringFromSelector(@selector(acceptableContentTypes))];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.acceptableStatusCodes forKey:NSStringFromSelector(@selector(acceptableStatusCodes))];
    [coder encodeObject:self.acceptableContentTypes forKey:NSStringFromSelector(@selector(acceptableContentTypes))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __FWHTTPResponseSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.acceptableStatusCodes = [self.acceptableStatusCodes copyWithZone:zone];
    serializer.acceptableContentTypes = [self.acceptableContentTypes copyWithZone:zone];

    return serializer;
}

@end

#pragma mark -

@implementation __FWJSONResponseSerializer

+ (instancetype)serializer {
    return [self serializerWithReadingOptions:(NSJSONReadingOptions)0];
}

+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions {
    __FWJSONResponseSerializer *serializer = [[self alloc] init];
    serializer.readingOptions = readingOptions;

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];

    return self;
}

#pragma mark - __FWURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (!error || __FWErrorOrUnderlyingErrorHasCodeInDomain(*error, NSURLErrorCannotDecodeContentData, __FWURLResponseSerializationErrorDomain)) {
            return nil;
        }
    }

    // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in Safari), which is not interpreted as valid input by NSJSONSerialization.
    // See https://github.com/rails/rails/issues/1742
    BOOL isSpace = [data isEqualToData:[NSData dataWithBytes:" " length:1]];
    
    if (data.length == 0 || isSpace) {
        return nil;
    }
    
    NSError *serializationError = nil;
    
    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:&serializationError];
    
    // 兼容\uD800-\uDFFF引起JSON解码报错3840问题
    if (serializationError && serializationError.code == 3840) {
        NSString *escapeString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSData *escapeData = [[self escapeJsonString:escapeString] dataUsingEncoding:NSUTF8StringEncoding];
        if (escapeData && escapeData.length != data.length) {
            serializationError = nil;
            responseObject = [NSJSONSerialization JSONObjectWithData:escapeData options:self.readingOptions error:&serializationError];
        }
    }

    if (!responseObject)
    {
        if (error) {
            *error = __FWErrorWithUnderlyingError(serializationError, *error);
        }
        return nil;
    }
    
    if (self.removesKeysWithNullValues) {
        return __FWJSONObjectByRemovingKeysWithNullValues(responseObject, self.readingOptions);
    }

    return responseObject;
}

- (NSString *)escapeJsonString:(NSString *)string {
    if (string.length < 1) return string;
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

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }

    self.readingOptions = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(readingOptions))] unsignedIntegerValue];
    self.removesKeysWithNullValues = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(removesKeysWithNullValues))] boolValue];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeObject:@(self.readingOptions) forKey:NSStringFromSelector(@selector(readingOptions))];
    [coder encodeObject:@(self.removesKeysWithNullValues) forKey:NSStringFromSelector(@selector(removesKeysWithNullValues))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __FWJSONResponseSerializer *serializer = [super copyWithZone:zone];
    serializer.readingOptions = self.readingOptions;
    serializer.removesKeysWithNullValues = self.removesKeysWithNullValues;

    return serializer;
}

@end

#pragma mark -

@implementation __FWXMLParserResponseSerializer

+ (instancetype)serializer {
    __FWXMLParserResponseSerializer *serializer = [[self alloc] init];

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];

    return self;
}

#pragma mark - __FWURLResponseSerialization

- (id)responseObjectForResponse:(NSHTTPURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (!error || __FWErrorOrUnderlyingErrorHasCodeInDomain(*error, NSURLErrorCannotDecodeContentData, __FWURLResponseSerializationErrorDomain)) {
            return nil;
        }
    }

    return [[NSXMLParser alloc] initWithData:data];
}

@end

#pragma mark -

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED

@implementation __FWXMLDocumentResponseSerializer

+ (instancetype)serializer {
    return [self serializerWithXMLDocumentOptions:0];
}

+ (instancetype)serializerWithXMLDocumentOptions:(NSUInteger)mask {
    __FWXMLDocumentResponseSerializer *serializer = [[self alloc] init];
    serializer.options = mask;

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];

    return self;
}

#pragma mark - __FWURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (!error || __FWErrorOrUnderlyingErrorHasCodeInDomain(*error, NSURLErrorCannotDecodeContentData, __FWURLResponseSerializationErrorDomain)) {
            return nil;
        }
    }

    NSError *serializationError = nil;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:self.options error:&serializationError];

    if (!document)
    {
        if (error) {
            *error = __FWErrorWithUnderlyingError(serializationError, *error);
        }
        return nil;
    }
    
    return document;
}

#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }

    self.options = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(options))] unsignedIntegerValue];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeObject:@(self.options) forKey:NSStringFromSelector(@selector(options))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __FWXMLDocumentResponseSerializer *serializer = [super copyWithZone:zone];
    serializer.options = self.options;

    return serializer;
}

@end

#endif

#pragma mark -

@implementation __FWPropertyListResponseSerializer

+ (instancetype)serializer {
    return [self serializerWithFormat:NSPropertyListXMLFormat_v1_0 readOptions:0];
}

+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                         readOptions:(NSPropertyListReadOptions)readOptions
{
    __FWPropertyListResponseSerializer *serializer = [[self alloc] init];
    serializer.format = format;
    serializer.readOptions = readOptions;

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/x-plist", nil];

    return self;
}

#pragma mark - __FWURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (!error || __FWErrorOrUnderlyingErrorHasCodeInDomain(*error, NSURLErrorCannotDecodeContentData, __FWURLResponseSerializationErrorDomain)) {
            return nil;
        }
    }

    if (!data) {
        return nil;
    }
    
    NSError *serializationError = nil;
    
    id responseObject = [NSPropertyListSerialization propertyListWithData:data options:self.readOptions format:NULL error:&serializationError];
    
    if (!responseObject)
    {
        if (error) {
            *error = __FWErrorWithUnderlyingError(serializationError, *error);
        }
        return nil;
    }

    return responseObject;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }

    self.format = (NSPropertyListFormat)[[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(format))] unsignedIntegerValue];
    self.readOptions = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(readOptions))] unsignedIntegerValue];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeObject:@(self.format) forKey:NSStringFromSelector(@selector(format))];
    [coder encodeObject:@(self.readOptions) forKey:NSStringFromSelector(@selector(readOptions))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __FWPropertyListResponseSerializer *serializer = [super copyWithZone:zone];
    serializer.format = self.format;
    serializer.readOptions = self.readOptions;

    return serializer;
}

@end

#pragma mark -

static UIImage * __FWImageWithDataAtScale(NSData *data, CGFloat scale, NSDictionary *options) {
    if (!data || [data length] == 0) {
        return nil;
    }
    
    static NSLock *imageLock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageLock = [[NSLock alloc] init];
    });
    
    UIImage *image = nil;
    [imageLock lock];
    image = [FWObjCBridge decodeImage:data scale:scale options:options];
    [imageLock unlock];
    
    return image;
}

static UIImage * __FWInflatedImageFromResponseWithDataAtScale(NSHTTPURLResponse *response, NSData *data, CGFloat scale, NSDictionary *options) {
    if (!data || [data length] == 0) {
        return nil;
    }
    
    // Fix animated png bug
    UIImage *image = __FWImageWithDataAtScale(data, scale, options);
    if (image.images || !image) {
        return image;
    }

    CGImageRef imageRef = NULL;
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    if ([response.MIMEType isEqualToString:@"image/png"]) {
        imageRef = CGImageCreateWithPNGDataProvider(dataProvider,  NULL, true, kCGRenderingIntentDefault);
    } else if ([response.MIMEType isEqualToString:@"image/jpeg"]) {
        imageRef = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, true, kCGRenderingIntentDefault);

        if (imageRef) {
            CGColorSpaceRef imageColorSpace = CGImageGetColorSpace(imageRef);
            CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(imageColorSpace);

            // CGImageCreateWithJPEGDataProvider does not properly handle CMKY, so fall back to ImageWithDataAtScale
            if (imageColorSpaceModel == kCGColorSpaceModelCMYK) {
                CGImageRelease(imageRef);
                imageRef = NULL;
            }
        }
    }

    CGDataProviderRelease(dataProvider);

    if (!imageRef) {
        imageRef = CGImageCreateCopy([image CGImage]);
        if (!imageRef) {
            return image;
        }
    }

    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);

    if (width * height > 1024 * 1024 || bitsPerComponent > 8) {
        CGImageRelease(imageRef);

        return image;
    }

    // CGImageGetBytesPerRow() calculates incorrectly in iOS 5.0, so defer to CGBitmapContextCreate
    size_t bytesPerRow = 0;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);

    if (colorSpaceModel == kCGColorSpaceModelRGB) {
        uint32_t alpha = (bitmapInfo & kCGBitmapAlphaInfoMask);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
        if (alpha == kCGImageAlphaNone) {
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaNoneSkipFirst;
        } else if (!(alpha == kCGImageAlphaNoneSkipFirst || alpha == kCGImageAlphaNoneSkipLast)) {
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaPremultipliedFirst;
        }
#pragma clang diagnostic pop
    }

    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);

    CGColorSpaceRelease(colorSpace);

    if (!context) {
        CGImageRelease(imageRef);

        return image;
    }

    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), imageRef);
    CGImageRef inflatedImageRef = CGBitmapContextCreateImage(context);

    CGContextRelease(context);

    UIImage *inflatedImage = [[UIImage alloc] initWithCGImage:inflatedImageRef scale:scale orientation:image.imageOrientation];

    CGImageRelease(inflatedImageRef);
    CGImageRelease(imageRef);

    return inflatedImage;
}

@implementation __FWImageResponseSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/octet-stream", @"application/pdf", @"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-ms-bmp", @"image/x-win-bitmap", @"image/heic", @"image/heif", @"image/webp", @"image/svg+xml", nil];

    self.imageScale = [[UIScreen mainScreen] scale];
    self.automaticallyInflatesResponseImage = YES;

    return self;
}

+ (NSData *)cachedResponseDataForImage:(UIImage *)image
{
    if (!image) return nil;
    return objc_getAssociatedObject(image, @selector(cachedResponseDataForImage:));
}

+ (void)setCachedResponseData:(NSData *)data forImage:(UIImage *)image
{
    if (!image) return;
    objc_setAssociatedObject(image, @selector(cachedResponseDataForImage:), data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)clearCachedResponseDataForImage:(UIImage *)image
{
    [self setCachedResponseData:nil forImage:image];
}

#pragma mark - FWURLResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (!error || __FWErrorOrUnderlyingErrorHasCodeInDomain(*error, NSURLErrorCannotDecodeContentData, __FWURLResponseSerializationErrorDomain)) {
            return nil;
        }
    }

    UIImage *image = nil;
    NSDictionary *options = [self userInfoForResponse:response];
    if (self.automaticallyInflatesResponseImage) {
        image = __FWInflatedImageFromResponseWithDataAtScale((NSHTTPURLResponse *)response, data, self.imageScale, options);
    } else {
        image = __FWImageWithDataAtScale(data, self.imageScale, options);
    }
    
    if (self.shouldCacheResponseData && image) {
        [__FWImageResponseSerializer setCachedResponseData:data forImage:image];
    }
    
    return image;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }

    NSNumber *imageScale = [decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(imageScale))];
#if CGFLOAT_IS_DOUBLE
    self.imageScale = [imageScale doubleValue];
#else
    self.imageScale = [imageScale floatValue];
#endif
    self.automaticallyInflatesResponseImage = [decoder decodeBoolForKey:NSStringFromSelector(@selector(automaticallyInflatesResponseImage))];
    self.shouldCacheResponseData = [decoder decodeBoolForKey:NSStringFromSelector(@selector(shouldCacheResponseData))];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeObject:@(self.imageScale) forKey:NSStringFromSelector(@selector(imageScale))];
    [coder encodeBool:self.automaticallyInflatesResponseImage forKey:NSStringFromSelector(@selector(automaticallyInflatesResponseImage))];
    [coder encodeBool:self.shouldCacheResponseData forKey:NSStringFromSelector(@selector(shouldCacheResponseData))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __FWImageResponseSerializer *serializer = [super copyWithZone:zone];
    serializer.imageScale = self.imageScale;
    serializer.automaticallyInflatesResponseImage = self.automaticallyInflatesResponseImage;
    serializer.shouldCacheResponseData = self.shouldCacheResponseData;
    
    return serializer;
}

@end

#pragma mark -

@interface __FWCompoundResponseSerializer ()
@property (readwrite, nonatomic, copy) NSArray *responseSerializers;
@end

@implementation __FWCompoundResponseSerializer

+ (instancetype)compoundSerializerWithResponseSerializers:(NSArray *)responseSerializers {
    __FWCompoundResponseSerializer *serializer = [[self alloc] init];
    serializer.responseSerializers = responseSerializers;

    return serializer;
}

#pragma mark - __FWURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    for (id <__FWURLResponseSerialization> serializer in self.responseSerializers) {
        if (![serializer isKindOfClass:[__FWHTTPResponseSerializer class]]) {
            continue;
        }

        NSError *serializerError = nil;
        id responseObject = [serializer responseObjectForResponse:response data:data error:&serializerError];
        if (responseObject) {
            if (error) {
                *error = __FWErrorWithUnderlyingError(serializerError, *error);
            }

            return responseObject;
        }
    }

    return [super responseObjectForResponse:response data:data error:error];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }

    NSSet *classes = [NSSet setWithArray:@[[NSArray class], [__FWHTTPResponseSerializer <__FWURLResponseSerialization> class]]];
    self.responseSerializers = [decoder decodeObjectOfClasses:classes forKey:NSStringFromSelector(@selector(responseSerializers))];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeObject:self.responseSerializers forKey:NSStringFromSelector(@selector(responseSerializers))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __FWCompoundResponseSerializer *serializer = [super copyWithZone:zone];
    serializer.responseSerializers = self.responseSerializers;

    return serializer;
}

@end
