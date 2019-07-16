//
//  UIImage+FWGif.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (FWGif)

#pragma mark - Judge

// 是否是Gif数据
+ (BOOL)fwIsGifData:(nullable NSData *)data;

// 是否是Gif图片
- (BOOL)fwIsGifImage;

#pragma mark - Coder

// 图片循环次数，静图永远为0，动图0表示无限循环
@property (nonatomic, assign) NSUInteger fwImageLoopCount;

// 从数据创建Gif图片对象
+ (nullable UIImage *)fwGifImageWithData:(nullable NSData *)data;

// 从图片创建Gif数据对象
+ (nullable NSData *)fwGifDataWithImage:(nullable UIImage *)image;

#pragma mark - File

// 从文件路径创建Gif图片对象，绝对路径
+ (nullable UIImage *)fwGifImageWithFile:(NSString *)path;

// 从图片名称创建Gif图片对象，内置图片，不含后缀
+ (nullable UIImage *)fwGifImageWithName:(NSString *)name;

#pragma mark - Scale

// 缩放Gif图片到指定大小
- (nullable UIImage *)fwGifImageWithScaleSize:(CGSize)size;

#pragma mark - Save

// 保存Gif图片数据到相册，保存成功时error为nil
+ (void)fwSaveGifData:(NSData *)data completion:(nullable void (^)(NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
