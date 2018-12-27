//
//  UIImage+FWGif.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (FWGif)

// 是否是Gif图片数据
+ (BOOL)fwIsGifImageData:(NSData *)data;

// 是否是Gif图片文件，绝对路径
+ (BOOL)fwIsGifImageFile:(NSString *)path;

// 从数据创建Gif图片对象
+ (UIImage *)fwGifImageWithData:(NSData *)data;

// 从文件路径创建Gif图片对象，绝对路径
+ (UIImage *)fwGifImageWithFile:(NSString *)path;

// 从图片名称创建Gif图片对象，内置图片，不含后缀
+ (UIImage *)fwGifImageWithName:(NSString *)name;

// 从图片数组创建Gif图片
+ (UIImage *)fwGifImageWithImages:(NSArray<UIImage *> *)images duration:(NSTimeInterval)duration;

// 缩放Gif图片到指定大小
- (UIImage *)fwGifImageWithScaleSize:(CGSize)size;

@end
