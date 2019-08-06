/*!
 @header     UILabel+FWFramework.h
 @indexgroup FWFramework
 @brief      UILabel+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/10/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UILabel+FWFramework
 */
@interface UILabel (FWFramework)

// 自定义内容边距。未设置时为系统默认
@property (nonatomic, assign) UIEdgeInsets fwContentInset;

// 纵向分布方式，默认居中
@property (nonatomic, assign) UIControlContentVerticalAlignment fwVerticalAlignment;

// 快速设置标签，不设置传nil即可
- (void)fwSetFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor text:(nullable NSString *)text;

// 快速创建标签，不初始化传nil即可
+ (instancetype)fwLabelWithFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor text:(nullable NSString *)text;

#pragma mark - Size

// 计算当前文本所占尺寸，需frame或者宽度布局完整，默认WordWrapping模式
- (CGSize)fwTextSize;

// 计算指定边界，当前文本所占尺寸，默认WordWrapping模式B
- (CGSize)fwTextSizeWithDrawSize:(CGSize)drawSize;

// 计算指定边界，当前文本所占尺寸，指定段落样式(如lineBreakMode等，默认WordWrapping)
- (CGSize)fwTextSizeWithDrawSize:(CGSize)drawSize paragraphStyle:(nullable NSParagraphStyle *)paragraphStyle;

// 计算当前属性文本所占尺寸，需frame或者宽度布局完整，attributedText需指定字体
- (CGSize)fwAttributedTextSize;

// 计算指定边界，当前属性文本所占尺寸，需frame或者宽度布局完整，attributedText需指定字体
- (CGSize)fwAttributedTextSizeWithDrawSize:(CGSize)drawSize;

@end

NS_ASSUME_NONNULL_END
