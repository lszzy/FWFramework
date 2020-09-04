/*!
 @header     UIImage+FWAnimated.m
 @indexgroup FWFramework
 @brief      UIImage+FWAnimated
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import "UIImage+FWAnimated.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>

UIImage * FWImageName(NSString *name) {
    return [UIImage imageNamed:name];
}

UIImage * FWImageFile(NSString *path) {
    return [UIImage fwImageWithFile:path];
}

#pragma mark - UIImage+FWAnimated

@implementation UIImage (FWAnimated)

+ (UIImage *)fwImageWithName:(NSString *)name
{
    return [UIImage imageNamed:name];
}

+ (UIImage *)fwImageWithFile:(NSString *)path
{
    if (path.length < 1) return nil;
    
    NSString *file = path.isAbsolutePath ? path : [[NSBundle mainBundle] pathForResource:path ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:file];
    return [self fwImageWithData:data scale:[UIScreen mainScreen].scale];
}

+ (UIImage *)fwImageWithData:(NSData *)data
{
    return [self fwImageWithData:data scale:1];
}

+ (UIImage *)fwImageWithData:(NSData *)data scale:(CGFloat)scale
{
    if (!data) return nil;
    
    // TODO
    return [UIImage imageWithData:data scale:scale];
}

- (NSUInteger)fwImageLoopCount
{
    return [objc_getAssociatedObject(self, @selector(fwImageLoopCount)) unsignedIntegerValue];
}

- (void)setFwImageLoopCount:(NSUInteger)fwImageLoopCount
{
    objc_setAssociatedObject(self, @selector(fwImageLoopCount), @(fwImageLoopCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwIsAnimated
{
    return self.images != nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (BOOL)fwIsVector
{
    if (@available(iOS 13.0, *)) {
        // Xcode 11 supports symbol image, keep Xcode 10 compatible currently
        SEL SymbolSelector = NSSelectorFromString(@"isSymbolImage");
        if ([self respondsToSelector:SymbolSelector] && [self performSelector:SymbolSelector]) {
            return YES;
        }
        // SVG
        SEL SVGSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@", @"CGSVGDocument"]);
        if ([self respondsToSelector:SVGSelector] && [self performSelector:SVGSelector]) {
            return YES;
        }
    }
    if (@available(iOS 11.0, *)) {
        // PDF
        SEL PDFSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@", @"CGPDFPage"]);
        if ([self respondsToSelector:PDFSelector] && [self performSelector:PDFSelector]) {
            return YES;
        }
    }
    return NO;
}
#pragma clang diagnostic pop

- (FWImageFormat)fwImageFormat
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fwImageFormat));
    if (value) {
        return [value integerValue];
    }
    if (@available(iOS 9.0, *)) {
        CFStringRef uttype = CGImageGetUTType(self.CGImage);
        return [NSData fwImageFormatFromUTType:uttype];
    }
    return FWImageFormatUndefined;
}

- (void)setFwImageFormat:(FWImageFormat)fwImageFormat
{
    objc_setAssociatedObject(self, @selector(fwImageFormat), @(fwImageFormat), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UIImage+FWAnimated

#define kSVGTagEnd @"</svg>"

@implementation NSData (FWAnimated)

+ (FWImageFormat)fwImageFormatForImageData:(NSData *)data
{
    if (!data) {
        return FWImageFormatUndefined;
    }
    
    // File signatures table: http://www.garykessler.net/library/file_sigs.html
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return FWImageFormatJPEG;
        case 0x89:
            return FWImageFormatPNG;
        case 0x47:
            return FWImageFormatGIF;
        case 0x49:
        case 0x4D:
            return FWImageFormatTIFF;
        case 0x52: {
            if (data.length >= 12) {
                //RIFF....WEBP
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    return FWImageFormatWebP;
                }
            }
            break;
        }
        case 0x00: {
            if (data.length >= 12) {
                //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(4, 8)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"ftypheic"]
                    || [testString isEqualToString:@"ftypheix"]
                    || [testString isEqualToString:@"ftyphevc"]
                    || [testString isEqualToString:@"ftyphevx"]) {
                    return FWImageFormatHEIC;
                }
                //....ftypmif1 ....ftypmsf1
                if ([testString isEqualToString:@"ftypmif1"] || [testString isEqualToString:@"ftypmsf1"]) {
                    return FWImageFormatHEIF;
                }
            }
            break;
        }
        case 0x25: {
            if (data.length >= 4) {
                //%PDF
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, 3)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"PDF"]) {
                    return FWImageFormatPDF;
                }
            }
        }
        case 0x3C: {
            // Check end with SVG tag
            if ([data rangeOfData:[kSVGTagEnd dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchBackwards range: NSMakeRange(data.length - MIN(100, data.length), MIN(100, data.length))].location != NSNotFound) {
                return FWImageFormatSVG;
            }
        }
    }
    return FWImageFormatUndefined;
}

+ (nonnull CFStringRef)fwUTTypeFromImageFormat:(FWImageFormat)format
{
    CFStringRef UTType;
    switch (format) {
        case FWImageFormatJPEG:
            UTType = kUTTypeJPEG;
            break;
        case FWImageFormatPNG:
            UTType = kUTTypePNG;
            break;
        case FWImageFormatGIF:
            UTType = kUTTypeGIF;
            break;
        case FWImageFormatTIFF:
            UTType = kUTTypeTIFF;
            break;
        case FWImageFormatWebP:
            UTType = kFWUTTypeWebP;
            break;
        case FWImageFormatHEIC:
            UTType = kFWUTTypeHEIC;
            break;
        case FWImageFormatHEIF:
            UTType = kFWUTTypeHEIF;
            break;
        case FWImageFormatPDF:
            UTType = kUTTypePDF;
            break;
        case FWImageFormatSVG:
            UTType = kUTTypeScalableVectorGraphics;
            break;
        default:
            // default is kUTTypeImage abstract type
            UTType = kUTTypeImage;
            break;
    }
    return UTType;
}

+ (FWImageFormat)fwImageFormatFromUTType:(CFStringRef)uttype
{
    if (!uttype) {
        return FWImageFormatUndefined;
    }
    FWImageFormat imageFormat;
    if (CFStringCompare(uttype, kUTTypeJPEG, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatJPEG;
    } else if (CFStringCompare(uttype, kUTTypePNG, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatPNG;
    } else if (CFStringCompare(uttype, kUTTypeGIF, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatGIF;
    } else if (CFStringCompare(uttype, kUTTypeTIFF, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatTIFF;
    } else if (CFStringCompare(uttype, kFWUTTypeWebP, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatWebP;
    } else if (CFStringCompare(uttype, kFWUTTypeHEIC, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatHEIC;
    } else if (CFStringCompare(uttype, kFWUTTypeHEIF, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatHEIF;
    } else if (CFStringCompare(uttype, kUTTypePDF, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatPDF;
    } else if (CFStringCompare(uttype, kUTTypeScalableVectorGraphics, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatSVG;
    } else {
        imageFormat = FWImageFormatUndefined;
    }
    return imageFormat;
}

@end
