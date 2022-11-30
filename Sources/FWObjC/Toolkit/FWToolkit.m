//
//  FWToolkit.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWToolkit.h"
#import "FWUIKit.h"
#import "FWNavigator.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import <Accelerate/Accelerate.h>
#import <objc/runtime.h>
#if FWMacroSPM
@import FWFramework;
#else
#import <FWFramework/FWFramework-Swift.h>
#endif

UIFont * FWFontThin(CGFloat size) { return [UIFont fw_thinFontOfSize:size]; }
UIFont * FWFontLight(CGFloat size) { return [UIFont fw_lightFontOfSize:size]; }
UIFont * FWFontRegular(CGFloat size) { return [UIFont fw_fontOfSize:size]; }
UIFont * FWFontMedium(CGFloat size) { return [UIFont fw_mediumFontOfSize:size]; }
UIFont * FWFontSemibold(CGFloat size) { return [UIFont fw_semiboldFontOfSize:size]; }
UIFont * FWFontBold(CGFloat size) { return [UIFont fw_boldFontOfSize:size]; }

#pragma mark - UIImage+FWToolkit

@implementation UIImage (FWToolkit)

- (void)fw_saveImageWithCompletion:(void (^)(NSError * _Nullable))completion
{
    objc_setAssociatedObject(self, @selector(fw_saveImageWithCompletion:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    UIImageWriteToSavedPhotosAlbum(self, self, @selector(fw_innerImage:didFinishSavingWithError:contextInfo:), NULL);
}

+ (void)fw_saveVideo:(NSString *)videoPath withCompletion:(nullable void (^)(NSError * _Nullable))completion
{
    objc_setAssociatedObject(self, @selector(fw_saveVideo:withCompletion:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(fw_innerVideo:didFinishSavingWithError:contextInfo:), NULL);
    }
}

- (void)fw_innerImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    void (^block)(NSError *error) = objc_getAssociatedObject(self, @selector(fw_saveImageWithCompletion:));
    objc_setAssociatedObject(self, @selector(fw_saveImageWithCompletion:), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (block) {
        block(error);
    }
}

+ (void)fw_innerVideo:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    void (^block)(NSError *error) = objc_getAssociatedObject(self, @selector(fw_saveVideo:withCompletion:));
    objc_setAssociatedObject(self, @selector(fw_saveVideo:withCompletion:), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (block) {
        block(error);
    }
}

- (UIImage *)fw_grayImage
{
    int width = self.size.width;
    int height = self.size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    if (context == NULL) {
        return nil;
    }
    
    CGContextDrawImage(context,CGRectMake(0, 0, width, height), self.CGImage);
    CGImageRef contextRef = CGBitmapContextCreateImage(context);
    UIImage *grayImage = [UIImage imageWithCGImage:contextRef];
    CGContextRelease(context);
    CGImageRelease(contextRef);
    
    return grayImage;
}

- (UIColor *)fw_averageColor
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char rgba[4];
    CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), self.CGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    if (rgba[3] > 0) {
        CGFloat alpha = ((CGFloat)rgba[3]) / 255.0;
        CGFloat multiplier = alpha / 255.0;
        return [UIColor colorWithRed:((CGFloat)rgba[0]) * multiplier
                               green:((CGFloat)rgba[1]) * multiplier
                                blue:((CGFloat)rgba[2]) * multiplier
                               alpha:alpha];
    } else {
        return [UIColor colorWithRed:((CGFloat)rgba[0]) / 255.0
                               green:((CGFloat)rgba[1]) / 255.0
                                blue:((CGFloat)rgba[2]) / 255.0
                               alpha:((CGFloat)rgba[3]) / 255.0];
    }
}

- (UIImage *)fw_imageWithReflectScale:(CGFloat)scale
{
    static CGImageRef sharedMask = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 256), YES, 0.0);
        CGContextRef gradientContext = UIGraphicsGetCurrentContext();
        CGFloat colors[] = {0.0, 1.0, 1.0, 1.0};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
        CGPoint gradientStartPoint = CGPointMake(0, 0);
        CGPoint gradientEndPoint = CGPointMake(0, 256);
        CGContextDrawLinearGradient(gradientContext, gradient, gradientStartPoint,
                                    gradientEndPoint, kCGGradientDrawsAfterEndLocation);
        sharedMask = CGBitmapContextCreateImage(gradientContext);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
        UIGraphicsEndImageContext();
    });
    
    CGFloat height = ceil(self.size.height * scale);
    CGSize size = CGSizeMake(self.size.width, height);
    CGRect bounds = CGRectMake(0.0f, 0.0f, size.width, size.height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClipToMask(context, bounds, sharedMask);
    
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGContextTranslateCTM(context, 0.0f, -self.size.height);
    [self drawInRect:CGRectMake(0.0f, 0.0f, self.size.width, self.size.height)];
    
    UIImage *reflection = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reflection;
}

- (UIImage *)fw_imageWithReflectScale:(CGFloat)scale gap:(CGFloat)gap alpha:(CGFloat)alpha
{
    UIImage *reflection = [self fw_imageWithReflectScale:scale];
    CGFloat reflectionOffset = reflection.size.height + gap;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.size.width, self.size.height + reflectionOffset * 2.0f), NO, 0.0f);
    
    [reflection drawAtPoint:CGPointMake(0.0f, reflectionOffset + self.size.height + gap) blendMode:kCGBlendModeNormal alpha:alpha];
    
    [self drawAtPoint:CGPointMake(0.0f, reflectionOffset)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithShadowColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur
{
    CGSize border = CGSizeMake(fabs(offset.width) + blur, fabs(offset.height) + blur);
    CGSize size = CGSizeMake(self.size.width + border.width * 2.0f, self.size.height + border.height * 2.0f);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetShadowWithColor(context, offset, blur, color.CGColor);
    [self drawAtPoint:CGPointMake(border.width, border.height)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_maskImage
{
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

- (UIImage *)fw_imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(UIColor *)tintColor maskImage:(UIImage *)maskImage
{
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

- (UIImage *)fw_alphaImage
{
    if ([self fw_hasAlpha]) {
        return self;
    }
    
    CGImageRef imageRef = self.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    CGContextRef offscreenContext = CGBitmapContextCreate(NULL,
                                                          width,
                                                          height,
                                                          8,
                                                          0,
                                                          CGImageGetColorSpace(imageRef),
                                                          kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(offscreenContext, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(offscreenContext);
    UIImage *imageWithAlpha = [UIImage imageWithCGImage:imageRefWithAlpha];
    
    CGContextRelease(offscreenContext);
    CGImageRelease(imageRefWithAlpha);
    return imageWithAlpha;
}

+ (UIImage *)fw_imageWithView:(UIView *)view limitWidth:(CGFloat)limitWidth
{
    if (!view) return nil;
    
    CGAffineTransform oldTransform = view.transform;
    CGAffineTransform scaleTransform = CGAffineTransformIdentity;
    if (!isnan(limitWidth) && limitWidth > 0 && CGRectGetWidth(view.frame) > 0) {
        CGFloat maxScale = limitWidth / CGRectGetWidth(view.frame);
        CGAffineTransform transformScale = CGAffineTransformMakeScale(maxScale, maxScale);
        scaleTransform = CGAffineTransformConcat(oldTransform, transformScale);
    }
    if(!CGAffineTransformEqualToTransform(scaleTransform, CGAffineTransformIdentity)){
        view.transform = scaleTransform;
    }
    
    CGRect actureFrame = view.frame;
    // CGRectApplyAffineTransform();
    CGRect actureBounds= view.bounds;
    
    UIGraphicsBeginImageContextWithOptions(actureFrame.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    // CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1, -1);
    CGContextTranslateCTM(context, actureFrame.size.width / 2, actureFrame.size.height / 2);
    CGContextConcatCTM(context, view.transform);
    CGPoint anchorPoint = view.layer.anchorPoint;
    CGContextTranslateCTM(context, -actureBounds.size.width * anchorPoint.x, -actureBounds.size.height * anchorPoint.y);
    if (view.window) {
        // iOS7+：更新屏幕后再截图，防止刚添加还未显示时截图失败，效率高
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    } else {
        // iOS6+：截取当前状态，未添加到界面时也可截图，效率偏低
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    view.transform = oldTransform;
    
    return screenshot;
}

+ (UIImage *)fw_appIconImage
{
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSString *iconName = [[infoPlist valueForKeyPath:@"CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles"] lastObject];
    return [UIImage imageNamed:iconName];
}

+ (UIImage *)fw_appIconImage:(CGSize)size
{
    NSString *iconName = [NSString stringWithFormat:@"AppIcon%.0fx%.0f", size.width, size.height];
    return [UIImage imageNamed:iconName];
}

+ (UIImage *)fw_imageWithPdf:(id)path
{
    return [self fw_imageWithPdf:path size:CGSizeZero];
}

+ (UIImage *)fw_imageWithPdf:(id)path size:(CGSize)size
{
    CGPDFDocumentRef pdf = NULL;
    if ([path isKindOfClass:[NSData class]]) {
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)path);
        pdf = CGPDFDocumentCreateWithProvider(provider);
        CGDataProviderRelease(provider);
    } else if ([path isKindOfClass:[NSString class]]) {
        pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path]);
    }
    if (!pdf) return nil;
    
    CGPDFPageRef page = CGPDFDocumentGetPage(pdf, 1);
    if (!page) {
        CGPDFDocumentRelease(pdf);
        return nil;
    }
    
    CGRect pdfRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGSize pdfSize = CGSizeEqualToSize(size, CGSizeZero) ? pdfRect.size : size;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, pdfSize.width * scale, pdfSize.height * scale, 8, 0, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    if (!ctx) {
        CGColorSpaceRelease(colorSpace);
        CGPDFDocumentRelease(pdf);
        return nil;
    }
    
    CGContextScaleCTM(ctx, scale, scale);
    CGContextTranslateCTM(ctx, -pdfRect.origin.x, -pdfRect.origin.y);
    CGContextDrawPDFPage(ctx, page);
    CGPDFDocumentRelease(pdf);
    
    CGImageRef image = CGBitmapContextCreateImage(ctx);
    UIImage *pdfImage = [[UIImage alloc] initWithCGImage:image scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(image);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    return pdfImage;
}

+ (UIImage *)fw_gradientImageWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                           direction:(UISwipeGestureRecognizerDirection)direction
{
    NSArray<NSValue *> *linePoints = [UIBezierPath fw_linePointsWithRect:CGRectMake(0, 0, size.width, size.height) direction:direction];
    CGPoint startPoint = [linePoints.firstObject CGPointValue];
    CGPoint endPoint = [linePoints.lastObject CGPointValue];
    return [self fw_gradientImageWithSize:size colors:colors locations:locations startPoint:startPoint endPoint:endPoint];
}

+ (UIImage *)fw_gradientImageWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return nil;
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGContextAddRect(ctx, rect);
    CGContextClip(ctx);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

#pragma mark - UIView+FWToolkit

@implementation UIView (FWToolkit)

- (CGFloat)fw_top
{
    return self.frame.origin.y;
}

- (void)setFw_top:(CGFloat)top
{
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
}

- (CGFloat)fw_bottom
{
    return self.fw_top + self.fw_height;
}

- (void)setFw_bottom:(CGFloat)bottom
{
    self.fw_top = bottom - self.fw_height;
}

- (CGFloat)fw_left
{
    return self.frame.origin.x;
}

- (void)setFw_left:(CGFloat)left
{
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
}

- (CGFloat)fw_right
{
    return self.fw_left + self.fw_width;
}

- (void)setFw_right:(CGFloat)right
{
    self.fw_left = right - self.fw_width;
}

- (CGFloat)fw_width
{
    return self.frame.size.width;
}

- (void)setFw_width:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)fw_height
{
    return self.frame.size.height;
}

- (void)setFw_height:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)fw_centerX
{
    return self.center.x;
}

- (void)setFw_centerX:(CGFloat)centerX
{
    self.center = CGPointMake(centerX, self.fw_centerY);
}

- (CGFloat)fw_centerY
{
    return self.center.y;
}

- (void)setFw_centerY:(CGFloat)centerY
{
    self.center = CGPointMake(self.fw_centerX, centerY);
}

- (CGFloat)fw_x
{
    return self.frame.origin.x;
}

- (void)setFw_x:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)fw_y
{
    return self.frame.origin.y;
}

- (void)setFw_y:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGPoint)fw_origin
{
    return self.frame.origin;
}

- (void)setFw_origin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)fw_size
{
    return self.frame.size;
}

- (void)setFw_size:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

@end

#pragma mark - UIViewController+FWToolkit

@implementation UIViewController (FWToolkit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            selfObject.fw_visibleState = FWViewControllerVisibleStateDidLoad;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateWillAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateDidAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateWillDisappear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateDidDisappear;
        }));
        
        FWSwizzleClass(UIViewController, NSSelectorFromString(@"dealloc"), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            // dealloc时不调用fw，防止释放时动态创建包装器对象
            void (^completionHandler)(id) = objc_getAssociatedObject(selfObject, @selector(fw_completionHandler));
            if (completionHandler != nil) {
                id completionResult = objc_getAssociatedObject(selfObject, @selector(fw_completionResult));
                completionHandler(completionResult);
            }
            
            FWSwizzleOriginal();
        }));
    });
}

- (FWViewControllerVisibleState)fw_visibleState
{
    return [objc_getAssociatedObject(self, @selector(fw_visibleState)) unsignedIntegerValue];
}

- (void)setFw_visibleState:(FWViewControllerVisibleState)visibleState
{
    BOOL valueChanged = self.fw_visibleState != visibleState;
    objc_setAssociatedObject(self, @selector(fw_visibleState), @(visibleState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (valueChanged && self.fw_visibleStateChanged) {
        self.fw_visibleStateChanged(self, visibleState);
    }
}

- (void (^)(__kindof UIViewController *, FWViewControllerVisibleState))fw_visibleStateChanged
{
    return objc_getAssociatedObject(self, @selector(fw_visibleStateChanged));
}

- (void)setFw_visibleStateChanged:(void (^)(__kindof UIViewController *, FWViewControllerVisibleState))visibleStateChanged
{
    objc_setAssociatedObject(self, @selector(fw_visibleStateChanged), visibleStateChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (id)fw_completionResult
{
    return objc_getAssociatedObject(self, @selector(fw_completionResult));
}

- (void)setFw_completionResult:(id)completionResult
{
    objc_setAssociatedObject(self, @selector(fw_completionResult), completionResult, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(id _Nullable))fw_completionHandler
{
    return objc_getAssociatedObject(self, @selector(fw_completionHandler));
}

- (void)setFw_completionHandler:(void (^)(id _Nullable))completionHandler
{
    objc_setAssociatedObject(self, @selector(fw_completionHandler), completionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(void))fw_allowsPopGesture
{
    return objc_getAssociatedObject(self, @selector(fw_allowsPopGesture));
}

- (void)setFw_allowsPopGesture:(BOOL (^)(void))allowsPopGesture
{
    objc_setAssociatedObject(self, @selector(fw_allowsPopGesture), allowsPopGesture, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(void))fw_shouldPopController
{
    return objc_getAssociatedObject(self, @selector(fw_shouldPopController));
}

- (void)setFw_shouldPopController:(BOOL (^)(void))shouldPopController
{
    objc_setAssociatedObject(self, @selector(fw_shouldPopController), shouldPopController, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)allowsPopGesture
{
    BOOL (^block)(void) = objc_getAssociatedObject(self, @selector(fw_allowsPopGesture));
    if (block) return block();
    return YES;
}

- (BOOL)shouldPopController
{
    BOOL (^block)(void) = objc_getAssociatedObject(self, @selector(fw_shouldPopController));
    if (block) return block();
    return YES;
}

@end
