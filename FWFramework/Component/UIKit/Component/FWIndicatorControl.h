//
//  FWIndicatorControl.h
//  FWFramework
//
//  Created by wuyong on 17/3/24.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 指示器控件类型
typedef NS_ENUM(NSInteger, FWIndicatorControlType) {
    // 自定义指示器控件
    FWIndicatorControlTypeCustom = 0,
    // 文本指示器控件
    FWIndicatorControlTypeText,
    // 图片指示器控件
    FWIndicatorControlTypeImage,
    // 活动指示器控件
    FWIndicatorControlTypeActivity,
    // 进度指示器控件
    FWIndicatorControlTypeProgress,
};

/**
 *  指示器控件
 */
@interface FWIndicatorControl : UIControl

// 当前控件类型，只读
@property (nonatomic, readonly) FWIndicatorControlType type;

// 指示器容器视图，可设置背景色、圆角、添加自定义视图，只读
@property (nonatomic, readonly) UIView *contentView;

// 指示器容器左右最小内间距，默认10，show之前生效
@property (nonatomic, assign) CGFloat paddingWidth;

// 指示器容器内边距，非自定义时生效，show之前生效
@property (nonatomic, assign) UIEdgeInsets contentInsets;

// 指示器容器内容间距，默认5.0，show之前生效
@property (nonatomic, assign) CGFloat contentSpacing;

// 是否水平对齐，默认垂直对齐，show之前生效
@property (nonatomic, assign) BOOL horizontalAlignment;

// 指示器大小，仅Image、Progress生效，show之前生效
@property (nonatomic, assign) CGSize indicatorSize;

// 主指示器颜色，根据类型处理，show之前生效
@property (nonatomic, strong, nullable) UIColor *indicatorColor;

// 指示器图片，支持动画图片，自适应大小，仅Image生效，show之前生效
@property (nonatomic, strong, nullable) UIImage *indicatorImage;

// 活动指示器样式，默认WhiteLarge，仅Activity生效，show之前生效
@property (nonatomic, assign) UIActivityIndicatorViewStyle indicatorStyle;

// 带属性标题文本，非Text类型show之前如果为nil则不显示文本，一直生效
@property (nonatomic, copy, nullable) NSAttributedString *attributedTitle;

// 当前指示器进度值，范围0~1，仅Progress生效，一直生效
@property (nonatomic, assign) CGFloat progress;

// 完成回调句柄
@property (nonatomic, copy, nullable) void (^completionBlock)(void);

// 初始化指定类型指示器
- (instancetype)initWithType:(FWIndicatorControlType)type;

// 显示指示器
- (void)show:(BOOL)animated;

// 移除指示器，延迟指定时间后执行
- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay;

// 移除指示器
- (void)hide:(BOOL)animated;

@end

/**
 *  视图指示器控件分类
 */
@interface UIView (FWIndicatorControl)

/**
 *  视图指示器控件，不可点击，同一视图最多显示一个指示器
 */
@property (nonatomic, strong, nullable) FWIndicatorControl *fwIndicatorControl;

@end

NS_ASSUME_NONNULL_END
