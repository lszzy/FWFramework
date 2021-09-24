/*!
 @header     FWFoundation.h
 @indexgroup FWFramework
 @brief      FWFoundation
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSAttributedString+FWFoundation

/*!
 @brief NSAttributedString+FWFoundation
 */
@interface NSAttributedString (FWFoundation)

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
+ (nullable instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString;

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)fwHtmlString;

/// 计算所占尺寸，需设置Font等
@property (nonatomic, assign, readonly) CGSize fwSize;

/// 计算在指定绘制区域内所占尺寸，需设置Font等
- (CGSize)fwSizeWithDrawSize:(CGSize)drawSize;

@end

#pragma mark - NSDate+FWFoundation

/*!
 @brief NSDate+FWFoundation
 */
@interface NSDate (FWFoundation)

/// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (class, nonatomic, assign) NSTimeInterval fwCurrentTime;

@end

#pragma mark - NSString+FWFoundation

/*!
 @brief NSString+FWFoundation
 */
@interface NSString (FWFoundation)

/// 计算单行字符串指定字体所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font;

/// 计算多行字符串指定字体在指定绘制区域内所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize;

/// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;

@end

NS_ASSUME_NONNULL_END
