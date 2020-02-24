/*!
 @header     FWImage.h
 @indexgroup FWFramework
 @brief      FWImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/24
 */

#import <UIKit/UIKit.h>
#import "UIImage+FWGif.h"
#import "UIImageView+FWNetwork.h"
#import "FWImageDownloader.h"
#import "FWAutoPurgingImageCache.h"

NS_ASSUME_NONNULL_BEGIN

// 快速创建UIImage，支持name和file，支持普通图片和gif图片
FOUNDATION_EXPORT UIImage * _Nullable FWImageMake(NSString *string);

// 使用文件名方式加载UIImage。会被系统缓存，适用于大量复用的小资源图
FOUNDATION_EXPORT UIImage * _Nullable FWImageName(NSString *name);

// 从图片文件或应用资源路径加载UIImage。不会被系统缓存，适用于不被复用的图片，特别是大图
FOUNDATION_EXPORT UIImage * _Nullable FWImageFile(NSString *path);

@interface UIImage (FWImage)

#pragma mark - Make

// 快速创建UIImage，支持name和file，支持普通图片和gif图片
+ (nullable UIImage *)fwImageMake:(NSString *)string;

// 使用文件名方式加载UIImage。会被系统缓存，适用于大量复用的小资源图
+ (nullable UIImage *)fwImageWithName:(NSString *)name;

// 使用文件名方式从bundle加载UIImage。会被系统缓存，适用于大量复用的小资源图
+ (nullable UIImage *)fwImageWithName:(NSString *)name inBundle:(nullable NSBundle *)bundle;

// 从图片文件加载UIImage，支持绝对路径和bundle路径。不会被系统缓存，适用于不被复用的图片，特别是大图
+ (nullable UIImage *)fwImageWithFile:(NSString *)path;

// 从图片文件加载UIImage，支持绝对路径和bundle路径。不会被系统缓存，适用于不被复用的图片，特别是大图
+ (nullable UIImage *)fwImageWithFile:(NSString *)path inBundle:(nullable NSBundle *)bundle;

@end

@interface UIImageView (FWImage)

#pragma mark - Image

// 智能设置图片，如果是动画图片，自动开始播放
@property (nullable, nonatomic, strong) UIImage *fwAnimationImage;

@end

NS_ASSUME_NONNULL_END
