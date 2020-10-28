/*!
 @header     NSNumber+FWFramework.m
 @indexgroup FWFramework
 @brief      NSNumber+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "NSNumber+FWFramework.h"

@implementation NSNumber (FWFramework)

- (CGFloat)fwCGFloatValue
{
#if CGFLOAT_IS_DOUBLE
    return [self doubleValue];
#else
    return [self floatValue];
#endif
}

- (NSString *)fwRoundString:(NSInteger)digit
{
    return [self fwFormatString:digit roundingMode:NSNumberFormatterRoundHalfUp];
}

- (NSString *)fwCeilString:(NSInteger)digit
{
    return [self fwFormatString:digit roundingMode:NSNumberFormatterRoundCeiling];
}

- (NSString *)fwFloorString:(NSInteger)digit
{
    return [self fwFormatString:digit roundingMode:NSNumberFormatterRoundFloor];
}

- (NSString *)fwFormatString:(NSInteger)digit roundingMode:(NSNumberFormatterRoundingMode)roundingMode
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterNoStyle;
    formatter.roundingMode = roundingMode;
    formatter.minimumIntegerDigits = 1;
    formatter.maximumFractionDigits = digit;
    formatter.decimalSeparator = @".";
    formatter.groupingSeparator = @"";
    formatter.usesGroupingSeparator = NO;
    formatter.currencyDecimalSeparator = @".";
    formatter.currencyGroupingSeparator = @"";
    NSString *result = [formatter stringFromNumber:self];
    return result ?: @"";
}

- (NSNumber *)fwRoundNumber:(NSUInteger)digit
{
    return [self fwFormatNumber:digit roundingMode:NSNumberFormatterRoundHalfUp];
}

- (NSNumber *)fwCeilNumber:(NSUInteger)digit
{
    return [self fwFormatNumber:digit roundingMode:NSNumberFormatterRoundCeiling];
}

- (NSNumber*)fwFloorNumber:(NSUInteger)digit
{
    return [self fwFormatNumber:digit roundingMode:NSNumberFormatterRoundFloor];
}

- (NSNumber*)fwFormatNumber:(NSUInteger)digit
               roundingMode:(NSNumberFormatterRoundingMode)roundingMode
{
    NSString *string = [self fwFormatString:digit roundingMode:roundingMode];
    return [NSNumber numberWithDouble:[string doubleValue]];
}

@end
