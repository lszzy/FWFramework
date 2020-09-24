/*!
 @header     NSNumber+FWFramework.h
 @indexgroup FWFramework
 @brief      NSNumber+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

// 确保值在固定范围之内
#define FWClamp( min, x, max ) \
    (x < min ? min : (x > max ? max : x))

/*!
 @brief NSNumber+FWFramework
 */
@interface NSNumber (FWFramework)

/// 转换为CGFloat
- (CGFloat)fwCGFloatValue;

/// 小数展示，四舍五入，去掉末尾0，最多digit位，示例：12345.6789 => 12345.68
- (NSString *)fwDigitString:(NSInteger)digit;

/// 逗号展示，四舍五入，去掉末尾0，最多digit位，示例：12345.6789 => 12,345.68
- (NSString *)fwDecimalString:(NSInteger)digit;

/// 百分比展示，逗号格式，四舍五入，去掉末尾0，最多digit位，示例：12345.6789 => 1,234,567.89%
- (NSString *)fwPercentString:(NSInteger)digit;

/// 格式化为字符串，去掉末尾0，最多digit位，指定格式样式和取舍模式
- (NSString *)fwFormatString:(NSInteger)digit
                 numberStyle:(NSNumberFormatterStyle)numberStyle
                roundingMode:(NSNumberFormatterRoundingMode)roundingMode;

/// 四舍五入，去掉末尾0，最多digit位，示例：12345.6789 => 12345.68
- (NSNumber *)fwRoundNumber:(NSUInteger)digit;

/// 取上整，去掉末尾0，最多digit位，示例：12345.6789 => 12345.68
- (NSNumber *)fwCeilNumber:(NSUInteger)digit;

/// 取下整，去掉末尾0，最多digit位，示例：12345.6789 => 12345.67
- (NSNumber *)fwFloorNumber:(NSUInteger)digit;

/// 格式化数字，去掉末尾0，最多digit位，指定取舍模式
- (NSNumber*)fwFormatNumber:(NSUInteger)digit
               roundingMode:(NSNumberFormatterRoundingMode)roundingMode;

@end

NS_ASSUME_NONNULL_END
