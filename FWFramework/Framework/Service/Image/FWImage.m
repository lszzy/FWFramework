/*!
 @header     FWImage.m
 @indexgroup FWFramework
 @brief      FWImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/24
 */

#import "FWImage.h"

UIImage * FWImageMake(NSString *string) {
    return [UIImage fwImageMake:string];
}

UIImage * FWImageName(NSString *name) {
    return [UIImage imageNamed:name];
}

UIImage * FWImageFile(NSString *path) {
    return [UIImage imageWithContentsOfFile:(path.isAbsolutePath ? path : [NSBundle.mainBundle pathForResource:path ofType:nil])];
}

@implementation UIImage (FWImage)

#pragma mark - Make

+ (UIImage *)fwImageMake:(NSString *)string
{
    UIImage *image = nil;
    if ([string hasSuffix:@".gif"]) {
        image = [UIImage fwGifImageWithFile:string];
        if (!image) image = [UIImage fwGifImageWithName:[string substringToIndex:string.length - 4]];
    } else {
        image = [UIImage imageNamed:string];
        if (!image) image = [UIImage fwImageWithFile:string];
    }
    return image;
}

+ (UIImage *)fwImageWithName:(NSString *)name
{
    return [self fwImageWithName:name inBundle:nil];
}

+ (UIImage *)fwImageWithName:(NSString *)name inBundle:(NSBundle *)bundle
{
    return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

+ (UIImage *)fwImageWithFile:(NSString *)path
{
    return [self fwImageWithFile:path inBundle:nil];
}

+ (UIImage *)fwImageWithFile:(NSString *)path inBundle:(NSBundle *)bundle
{
    NSString *file = path;
    if (![file isAbsolutePath]) {
        NSBundle *resourceBundle = bundle ? bundle : [NSBundle mainBundle];
        file = [resourceBundle pathForResource:file ofType:nil];
    }
    return [UIImage imageWithContentsOfFile:file];
}

@end

@implementation UIImageView (FWImage)

#pragma mark - Image

- (UIImage *)fwAnimationImage
{
    if (!self.image && self.animationImages != nil) {
        // 兼容直接设置animationImages而未设置image的情况
        UIImage *image = [UIImage animatedImageWithImages:self.animationImages duration:self.animationDuration];
        image.fwImageLoopCount = self.animationRepeatCount;
        return image;
    }
    return self.image;
}

- (void)setFwAnimationImage:(UIImage *)image
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

@end
