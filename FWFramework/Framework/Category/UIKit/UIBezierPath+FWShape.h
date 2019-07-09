/*!
 @header     UIBezierPath+FWShape.h
 @indexgroup FWFramework
 @brief      UIBezierPath+FWShape
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/7/9
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIBezierPath+FWShape
 */
@interface UIBezierPath (FWShape)

// 圆的形状，0~1，degree为起始角度，如-90度
+ (UIBezierPath *)fwShapeCircle:(CGRect)frame percent:(float)percent degree:(CGFloat)degree;

// 心的形状
+ (UIBezierPath *)fwShapeHeart:(CGRect)frame;

// 头像的形状
+ (UIBezierPath *)fwShapeAvatar:(CGRect)frame;

// 星星的形状
+ (UIBezierPath *)fwShapeStar:(CGRect)frame;

// 几颗星星的形状
+ (UIBezierPath *)fwShapeStars:(NSUInteger)count frame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
