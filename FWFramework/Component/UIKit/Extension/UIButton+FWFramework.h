/*!
 @header     UIButton+FWFramework.h
 @indexgroup FWFramework
 @brief      UIButton+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIButton+FWFramework
 */
@interface UIButton (FWFramework)

// 设置图片的居中边位置。需要在setImage和setTitle之后调用才生效，且button大小大于图片+文字+间距。利用titleEdgeInsets和imageEdgeInsets实现
- (void)fwSetImageEdge:(UIRectEdge)edge spacing:(CGFloat)spacing;

// 设置背景色
- (void)fwSetBackgroundColor:(nullable UIColor *)backgroundColor forState:(UIControlState)state;

// 设置按钮倒计时。等待时按钮disabled，非等待时enabled。时间支持格式化，示例：重新获取(%lds)
- (void)fwCountDown:(NSInteger)timeout title:(NSString *)title waitTitle:(NSString *)waitTitle;

// 快速设置按钮，不设置传nil即可
- (void)fwSetFont:(nullable UIFont *)font titleColor:(nullable UIColor *)titleColor title:(nullable NSString *)title;

// 快速设置居中图片
- (void)fwSetImage:(nullable UIImage *)image;

// 快速创建按钮，不初始化传nil即可
+ (instancetype)fwButtonWithFont:(nullable UIFont *)font titleColor:(nullable UIColor *)titleColor title:(nullable NSString *)title;

// 快速创建居中图片按钮
+ (instancetype)fwButtonWithImage:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
