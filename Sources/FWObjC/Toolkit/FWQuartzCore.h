//
//  FWQuartzCore.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

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
