/*!
 @header     UIImage+FWAnimated.h
 @indexgroup FWFramework
 @brief      UIImage+FWAnimated
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 使用文件名方式加载UIImage，不支持动图。会被系统缓存，适用于大量复用的小资源图
FOUNDATION_EXPORT UIImage * _Nullable FWImageName(NSString *name);

// 从图片文件或应用资源路径加载UIImage，支持动图。不会被系统缓存，适用于不被复用的图片，特别是大图
FOUNDATION_EXPORT UIImage * _Nullable FWImageFile(NSString *path);

/*!
 @brief UIImage+FWAnimated
 */
@interface UIImage (FWAnimated)

// 使用文件名方式加载UIImage，不支持动图。会被系统缓存，适用于大量复用的小资源图
+ (nullable UIImage *)fwImageWithName:(NSString *)name;

// 从图片文件加载UIImage，支持动图，支持绝对路径和bundle路径。不会被系统缓存，适用于不被复用的图片，特别是大图
+ (nullable UIImage *)fwImageWithFile:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
