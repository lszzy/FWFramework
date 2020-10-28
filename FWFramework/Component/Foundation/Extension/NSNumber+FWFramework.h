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

/// 四舍五入，去掉末尾0，最多digit位，小数分隔符为.，分组分隔符为空，示例：12345.6789 => 12345.68
- (NSString *)fwRoundString:(NSInteger)digit;

/// 取上整，去掉末尾0，最多digit位，小数分隔符为.，分组分隔符为空，示例：12345.6789 => 12345.68
- (NSString *)fwCeilString:(NSInteger)digit;

/// 取下整，去掉末尾0，最多digit位，小数分隔符为.，分组分隔符为空，示例：12345.6789 => 12345.67
- (NSString *)fwFloorString:(NSInteger)digit;

/// 四舍五入，去掉末尾0，最多digit位，示例：12345.6789 => 12345.68
- (NSNumber *)fwRoundNumber:(NSUInteger)digit;

/// 取上整，去掉末尾0，最多digit位，示例：12345.6789 => 12345.68
- (NSNumber *)fwCeilNumber:(NSUInteger)digit;

/// 取下整，去掉末尾0，最多digit位，示例：12345.6789 => 12345.67
- (NSNumber *)fwFloorNumber:(NSUInteger)digit;

@end

NS_ASSUME_NONNULL_END
