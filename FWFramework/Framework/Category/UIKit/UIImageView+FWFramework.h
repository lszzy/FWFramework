//
//  UIImageView+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2017/5/27.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+FWNetwork.h"

/**
 *  图片视图分类
 */
@interface UIImageView (FWFramework)

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
