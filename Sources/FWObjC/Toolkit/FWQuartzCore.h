//
//  FWQuartzCore.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIView+FWQuartzCore

@interface UIView (FWQuartzCore)

#pragma mark - Drag

/// 是否启用拖动，默认NO
@property (nonatomic, assign) BOOL fw_dragEnabled NS_REFINED_FOR_SWIFT;

/// 拖动手势，延迟加载
@property (nonatomic, readonly) UIPanGestureRecognizer *fw_dragGesture NS_REFINED_FOR_SWIFT;

/// 设置拖动限制区域，默认CGRectZero，无限制
@property (nonatomic, assign) CGRect fw_dragLimit NS_REFINED_FOR_SWIFT;

/// 设置拖动动作有效区域，默认self.frame
@property (nonatomic, assign) CGRect fw_dragArea NS_REFINED_FOR_SWIFT;

/// 是否允许横向拖动(X)，默认YES
@property (nonatomic, assign) BOOL fw_dragHorizontal NS_REFINED_FOR_SWIFT;

/// 是否允许纵向拖动(Y)，默认YES
@property (nonatomic, assign) BOOL fw_dragVertical NS_REFINED_FOR_SWIFT;

/// 开始拖动回调
@property (nullable, nonatomic, copy) void (^fw_dragStartedBlock)(UIView *) NS_REFINED_FOR_SWIFT;

/// 拖动移动回调
@property (nullable, nonatomic, copy) void (^fw_dragMovedBlock)(UIView *) NS_REFINED_FOR_SWIFT;

/// 结束拖动回调
@property (nullable, nonatomic, copy) void (^fw_dragEndedBlock)(UIView *) NS_REFINED_FOR_SWIFT;

@end

#pragma mark - FWGradientView

/// 渐变View，无需设置渐变Layer的frame等，支持自动布局
NS_SWIFT_NAME(GradientView)
@interface FWGradientView : UIView

@property (nonatomic, strong, readonly) CAGradientLayer *gradientLayer;

@property (nullable, copy) NSArray *colors;

@property (nullable, copy) NSArray<NSNumber *> *locations;

@property CGPoint startPoint;

@property CGPoint endPoint;

- (instancetype)initWithColors:(nullable NSArray<UIColor *> *)colors locations:(nullable NSArray<NSNumber *> *)locations startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;

- (void)setColors:(nullable NSArray<UIColor *> *)colors locations:(nullable NSArray<NSNumber *> *)locations startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;

@end

NS_ASSUME_NONNULL_END
