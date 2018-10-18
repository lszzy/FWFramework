//
//  FWProgressView.h
//  FWFramework
//
//  Created by wuyong on 17/3/24.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  框架进度视图，UIProgressView为横条样式
 */
@interface FWProgressView : UIView

// 进度值，0.0到1.0
@property (nonatomic, assign) float progress;

// 进度值颜色，默认白色
@property (nonatomic, strong) UIColor *progressTintColor;

// 进度背景色，默认白色，annular为NO时生效
@property (nonatomic, strong) UIColor *progressBackgroundColor;

// 进度条背景色，无进度时颜色，默认白色，透明度0.1
@property (nonatomic, strong) UIColor *backgroundTintColor;

// 是否显示百分比文本，默认NO
@property (nonatomic, assign) BOOL percentShow;

// 文本颜色，默认白色
@property (nonatomic, strong) UIColor *percentTextColor;

// 文本字体，默认12号粗体
@property (nonatomic, strong) UIFont *percentFont;

// 是否显示环形线条样式，默认YES，NO为圆形
@property (nonatomic, assign) BOOL annular;

// 环形进度样式，默认kCGLineCapButt
@property (nonatomic, assign) CGLineCap annularLineCapStyle;

// 环形线条宽度，默认2.0f
@property (nonatomic, assign) CGFloat annularLineWidth;

@end
