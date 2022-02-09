/**
 @header     FWRelative.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIScreen+FWRelative

/// 当前屏幕宽度缩放比例
#define FWScaleWidth [UIScreen fwScaleWidth]
/// 当前屏幕高度缩放比例
#define FWScaleHeight [UIScreen fwScaleHeight]

/**
 UIScreen+FWRelative
 */
@interface UIScreen (FWRelative)

/// 指定等比例缩放参考设计图尺寸，默认{375,812}，宽度常用
@property (class, nonatomic, assign) CGSize fwReferenceSize;
/// 获取当前屏幕宽度缩放比例，宽度常用
@property (class, nonatomic, assign, readonly) CGFloat fwScaleWidth;
/// 获取当前屏幕高度缩放比例，高度不常用
@property (class, nonatomic, assign, readonly) CGFloat fwScaleHeight;

/// 获取相对设计图宽度等比例缩放值
+ (CGFloat)fwRelativeValue:(CGFloat)value;

@end

/// 获取相对设计图宽度等比例缩放值
CG_INLINE CGFloat FWRelativeValue(CGFloat value) {
    return [UIScreen fwRelativeValue:value];
}

NS_ASSUME_NONNULL_END
