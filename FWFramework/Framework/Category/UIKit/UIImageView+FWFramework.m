//
//  UIImageView+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 2017/5/27.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIImageView+FWFramework.h"
#import "UIImage+FWGif.h"
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>

@implementation UIImageView (FWFramework)

#pragma mark - Image

- (UIImage *)fwImage
{
    if (!self.image && self.animationImages != nil) {
        // 兼容直接设置animationImages而未设置image的情况
        UIImage *image = [UIImage animatedImageWithImages:self.animationImages duration:self.animationDuration];
        image.fwImageLoopCount = self.animationRepeatCount;
        return image;
    }
    return self.image;
}

- (void)setFwImage:(UIImage *)image
{
    // 同时设置image属性，防止通过image属性读取不到图片
    self.image = image;
    if (image && image.images != nil) {
        self.animationImages = image.images;
        self.animationDuration = image.duration;
        self.animationRepeatCount = image.fwImageLoopCount;
        [self startAnimating];
    }
}

#pragma mark - Mode

- (void)fwSetContentModeAspectFill
{
    [self fwSetContentMode:UIViewContentModeScaleAspectFill];
}

- (void)fwSetContentMode:(UIViewContentMode)contentMode
{
    self.contentMode = contentMode;
    self.layer.masksToBounds = YES;
}

#pragma mark - Face

- (void)fwFaceAware
{
    if (self.image == nil) {
        return;
    }
    
    [self fwFaceDetect:self.image];
}

- (void)fwFaceDetect:(UIImage *)aImage
{
    // 初始化人脸检测
    static CIDetector *_faceDetector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                           context:nil
                                           options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    });
    
    dispatch_queue_t queue = dispatch_queue_create("site.wuyong.FWFramework.FWFaceQueue", NULL);
    dispatch_async(queue, ^{
        CIImage *image = aImage.CIImage;
        if (image == nil) {
            image = [CIImage imageWithCGImage:aImage.CGImage];
        }
        
        NSArray *features = [_faceDetector featuresInImage:image];
        if (features.count == 0) {
            NSLog(@"detect no faces");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self fwFaceLayer:NO] removeFromSuperlayer];
            });
        } else {
            NSLog(@"detect %lu faces", (unsigned long)features.count);
            [self fwFaceMark:features size:CGSizeMake(CGImageGetWidth(aImage.CGImage), CGImageGetHeight(aImage.CGImage))];
        }
    });
}

- (void)fwFaceMark:(NSArray *)features size:(CGSize)size
{
    CGRect fixedRect = CGRectMake(MAXFLOAT, MAXFLOAT, 0, 0);
    CGFloat rightBorder = 0, bottomBorder = 0;
    for (CIFaceFeature *f in features){
        CGRect oneRect = f.bounds;
        oneRect.origin.y = size.height - oneRect.origin.y - oneRect.size.height;
        
        fixedRect.origin.x = MIN(oneRect.origin.x, fixedRect.origin.x);
        fixedRect.origin.y = MIN(oneRect.origin.y, fixedRect.origin.y);
        
        rightBorder = MAX(oneRect.origin.x + oneRect.size.width, rightBorder);
        bottomBorder = MAX(oneRect.origin.y + oneRect.size.height, bottomBorder);
    }
    
    fixedRect.size.width = rightBorder - fixedRect.origin.x;
    fixedRect.size.height = bottomBorder - fixedRect.origin.y;
    
    CGPoint fixedCenter = CGPointMake(fixedRect.origin.x + fixedRect.size.width / 2.0,
                                      fixedRect.origin.y + fixedRect.size.height / 2.0);
    CGPoint offset = CGPointZero;
    CGSize finalSize = size;
    if (size.width / size.height > self.bounds.size.width / self.bounds.size.height) {
        // 水平移动
        finalSize.height = self.bounds.size.height;
        finalSize.width = size.width/size.height * finalSize.height;
        fixedCenter.x = finalSize.width / size.width * fixedCenter.x;
        fixedCenter.y = finalSize.width / size.width * fixedCenter.y;
        
        offset.x = fixedCenter.x - self.bounds.size.width * 0.5;
        if (offset.x < 0) {
            offset.x = 0;
        } else if (offset.x + self.bounds.size.width > finalSize.width) {
            offset.x = finalSize.width - self.bounds.size.width;
        }
        offset.x = - offset.x;
    } else {
        // 垂直移动
        finalSize.width = self.bounds.size.width;
        finalSize.height = size.height/size.width * finalSize.width;
        fixedCenter.x = finalSize.width / size.width * fixedCenter.x;
        fixedCenter.y = finalSize.width / size.width * fixedCenter.y;
        
        offset.y = fixedCenter.y - self.bounds.size.height * (1 - 0.618);
        if (offset.y < 0) {
            offset.y = 0;
        } else if (offset.y + self.bounds.size.height > finalSize.height){
            offset.y = finalSize.height - self.bounds.size.height;
        }
        offset.y = - offset.y;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CALayer *layer = [self fwFaceLayer:YES];
        layer.frame = CGRectMake(offset.x, offset.y, finalSize.width, finalSize.height);
        layer.contents = (id)self.image.CGImage;
    });
}

- (CALayer *)fwFaceLayer:(BOOL)lazyload
{
    for (CALayer *layer in self.layer.sublayers) {
        if ([@"FWFaceLayer" isEqualToString:layer.name]) {
            return layer;
        }
    }
    
    if (lazyload) {
        CALayer *layer = [CALayer layer];
        layer.name = @"FWFaceLayer";
        layer.actions = @{
                          @"contents": [NSNull null],
                          @"bounds": [NSNull null],
                          @"position": [NSNull null],
                          };
        [self.layer addSublayer:layer];
        return layer;
    }
    
    return nil;
}

#pragma mark - Reflect

- (void)fwReflect
{
    CGRect frame = self.frame;
    frame.origin.y += (frame.size.height + 1);
    
    UIImageView *reflectionImageView = [[UIImageView alloc] initWithFrame:frame];
    self.clipsToBounds = TRUE;
    reflectionImageView.contentMode = self.contentMode;
    [reflectionImageView setImage:self.image];
    reflectionImageView.transform = CGAffineTransformMakeScale(1.0, -1.0);
    
    CALayer *reflectionLayer = [reflectionImageView layer];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.bounds = reflectionLayer.bounds;
    gradientLayer.position = CGPointMake(reflectionLayer.bounds.size.width / 2, reflectionLayer.bounds.size.height * 0.5);
    gradientLayer.colors = [NSArray arrayWithObjects:
                            (id)[[UIColor clearColor] CGColor],
                            (id)[[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3] CGColor], nil];
    
    gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    reflectionLayer.mask = gradientLayer;
    
    [self.superview addSubview:reflectionImageView];
}

#pragma mark - Watermark

- (void)fwSetImage:(UIImage *)image watermarkImage:(UIImage *)watermarkImage inRect:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    // 原图和水印图
    [image drawInRect:self.bounds];
    [watermarkImage drawInRect:rect];
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = newPic;
}

- (void)fwSetImage:(UIImage *)image watermarkString:(NSAttributedString *)watermarkString inRect:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    // 原图和水印文字
    [image drawInRect:self.bounds];
    [watermarkString drawInRect:rect];
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = newPic;
}

- (void)fwSetImage:(UIImage *)image watermarkString:(NSAttributedString *)watermarkString atPoint:(CGPoint)point
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    // 原图和水印文字
    [image drawInRect:self.bounds];
    [watermarkString drawAtPoint:point];
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = newPic;
}

@end
