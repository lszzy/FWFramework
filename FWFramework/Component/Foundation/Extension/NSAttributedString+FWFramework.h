/*!
 @header     NSAttributedString+FWFramework.h
 @indexgroup FWFramework
 @brief      NSAttributedString+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/25
 */

#import <UIKit/UIKit.h>
#import "NSAttributedString+FWOption.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSAttributedString+FWFramework
 @discussion 注意iOS在后台运行时，如果调用NSAttributedString解析html会导致崩溃(如动态切换深色模式时在后台解析html)。解决方法是提前在前台解析好或者后台异步到下一个主线程RunLoop
 */
@interface NSAttributedString (FWFramework)

#pragma mark - Convert

/// 快速创建NSAttributedString，自定义字体
+ (instancetype)fwAttributedString:(NSString *)string withFont:(nullable UIFont *)font;

/// 快速创建NSAttributedString，自定义字体和颜色
+ (instancetype)fwAttributedString:(NSString *)string withFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor;

#pragma mark - Html

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
+ (nullable instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString;

/// html字符串转换为NSAttributedString对象，可设置默认字体颜色和字号(附加CSS方式)
+ (nullable instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString defaultAttributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)fwHtmlString;

#pragma mark - Size

/// 计算所占尺寸，需设置Font等
- (CGSize)fwSize;

/// 计算在指定绘制区域内所占尺寸，需设置Font等
- (CGSize)fwSizeWithDrawSize:(CGSize)drawSize;

@end

NS_ASSUME_NONNULL_END
