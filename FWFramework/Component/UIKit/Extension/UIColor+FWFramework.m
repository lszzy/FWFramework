/*!
 @header     UIColor+FWFramework.m
 @indexgroup FWFramework
 @brief      UIColor+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "UIColor+FWFramework.h"
#import "UIBezierPath+FWFramework.h"

@implementation UIColor (FWFramework)

#pragma mark - Image

+ (UIColor *)fwColorWithImage:(UIImage *)image
{
    return [UIColor colorWithPatternImage:image];
}

+ (UIColor *)fwColorWithImage:(UIImage *)image point:(CGPoint)point
{
    // 检查点是否越界
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, image.size.width, image.size.height), point)) {
        return nil;
    }
    
    NSInteger pointX = trunc(point.x);
    NSInteger pointY = trunc(point.y);
    CGImageRef cgImage = image.CGImage;
    NSUInteger width = image.size.width;
    NSUInteger height = image.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 1,
                                                 1,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    // 绘制目标像素到bitmap上下文
    CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    
    // 转换颜色为float
    CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
    CGFloat green = (CGFloat)pixelData[1] / 255.0f;
    CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

#pragma mark - Color

- (UIColor *)fwAddColor:(UIColor *)color blendMode:(CGBlendMode)blendMode
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
    uint8_t pixel[4] = { 0 };
    CGContextRef context = CGBitmapContextCreate(&pixel, 1, 1, 8, 4, colorSpace, bitmapInfo);
    CGContextSetFillColorWithColor(context, self.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    CGContextSetBlendMode(context, blendMode);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return [UIColor colorWithRed:pixel[0] / 255.0f green:pixel[1] / 255.0f blue:pixel[2] / 255.0f alpha:pixel[3] / 255.0f];
}

- (UIColor *)fwInverseColor
{
    const CGFloat *componentColors = CGColorGetComponents(self.CGColor);
    UIColor *newColor = [[UIColor alloc] initWithRed:(1.0 - componentColors[0])
                                               green:(1.0 - componentColors[1])
                                                blue:(1.0 - componentColors[2])
                                               alpha:componentColors[3]];
    return newColor;
}

- (BOOL)fwIsDarkColor
{
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    
    float referenceValue = 0.411;
    float colorDelta = ((red * 0.299) + (green * 0.587) + (blue * 0.114));
    
    return 1.0 - colorDelta > referenceValue;
}

- (UIColor *)fwBrightnessColor:(CGFloat)ratio
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    return [UIColor colorWithHue:h saturation:s brightness:b * ratio alpha:a];
}

- (CGFloat)fwAlpha
{
    return CGColorGetAlpha(self.CGColor);
}

- (UIColor *)fwColorWithAlpha:(CGFloat)alpha
{
    return [self colorWithAlphaComponent:alpha];
}

#pragma mark - Gradient

+ (UIColor *)fwGradientColorWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                           direction:(UISwipeGestureRecognizerDirection)direction
{
    NSArray<NSValue *> *linePoints = [UIBezierPath fwLinePointsWithRect:CGRectMake(0, 0, size.width, size.height) direction:direction];
    CGPoint startPoint = [linePoints.firstObject CGPointValue];
    CGPoint endPoint = [linePoints.lastObject CGPointValue];
    return [self fwGradientColorWithSize:size colors:colors locations:locations startPoint:startPoint endPoint:endPoint];
}

+ (UIColor *)fwGradientColorWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorspace, (__bridge CFArrayRef)colors, locations);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);
    UIGraphicsEndImageContext();
    
    return [UIColor colorWithPatternImage:image];
}

#pragma mark - Random

+ (UIColor *)fwRandomColor
{
    NSInteger aRedValue = arc4random() % 255;
    NSInteger aGreenValue = arc4random() % 255;
    NSInteger aBlueValue = arc4random() % 255;
    UIColor *randColor = [UIColor colorWithRed:aRedValue / 255.0f green:aGreenValue / 255.0f blue:aBlueValue / 255.0f alpha:1.0f];
    return randColor;
}

@end
