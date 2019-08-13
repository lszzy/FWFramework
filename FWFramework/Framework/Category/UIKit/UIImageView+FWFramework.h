//
//  UIImageView+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2017/5/27.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+FWNetwork.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  图片视图分类
 */
@interface UIImageView (FWFramework)

#pragma mark - Image

// 设置图片，如果是gif图片，自动开始播放
@property (nullable, nonatomic, strong) UIImage *fwImage;

#pragma mark - Mode

// 设置图片模式为ScaleAspectFill，自动拉伸不变形，超过区域隐藏。可通过appearance统一设置
- (void)fwSetContentModeAspectFill UI_APPEARANCE_SELECTOR;

// 设置指定图片模式，超过区域隐藏。可通过appearance统一设置
- (void)fwSetContentMode:(UIViewContentMode)contentMode UI_APPEARANCE_SELECTOR;

#pragma mark - Face

// 优化图片人脸显示，参考：https://github.com/croath/UIImageView-BetterFace
- (void)fwFaceAware;

#pragma mark - Reflect

// 倒影效果
- (void)fwReflect;

#pragma mark - Watermark

// 图片水印
- (void)fwSetImage:(UIImage *)image watermarkImage:(UIImage *)watermarkImage inRect:(CGRect)rect;

// 文字水印，指定区域
- (void)fwSetImage:(UIImage *)image watermarkString:(NSAttributedString *)watermarkString inRect:(CGRect)rect;

// 文字水印，指定坐标
- (void)fwSetImage:(UIImage *)image watermarkString:(NSAttributedString *)watermarkString atPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
