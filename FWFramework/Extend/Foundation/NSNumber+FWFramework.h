/*!
 @header     NSNumber+FWFramework.h
 @indexgroup FWFramework
 @brief      NSNumber+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <Foundation/Foundation.h>

#pragma mark - Macro

// 确保值在固定范围之内
#define FWClamp( min, x, max ) \
    (x < min ? min : (x > max ? max : x))

/*!
 @brief NSNumber+FWFramework
 */
@interface NSNumber (FWFramework)

// 小数展示，去掉末尾0，最多digit位
- (NSString *)fwDigitString:(NSInteger)digit;

// 百分比展示，最多digit位
- (NSString *)fwPercentString:(NSInteger)digit;

// 四舍五入，最多digit位
- (NSNumber *)fwRoundNumber:(NSUInteger)digit;

// 取上整，最多digit位
- (NSNumber *)fwCeilNumber:(NSUInteger)digit;

// 取下整，最多digit位
- (NSNumber *)fwFloorNumber:(NSUInteger)digit;

@end
