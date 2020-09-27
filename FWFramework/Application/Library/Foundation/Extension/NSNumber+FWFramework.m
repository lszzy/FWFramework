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

- (NSString *)fwDigitString:(NSInteger)digit
{
    return [self fwFormatString:digit
                    numberStyle:NSNumberFormatterNoStyle
                   roundingMode:NSNumberFormatterRoundHalfUp];
}

- (NSString *)fwDecimalString:(NSInteger)digit
{
    return [self fwFormatString:digit
                    numberStyle:NSNumberFormatterDecimalStyle
                   roundingMode:NSNumberFormatterRoundHalfUp];
}

- (NSString *)fwPercentString:(NSInteger)digit
{
    return [self fwFormatString:digit
                    numberStyle:NSNumberFormatterPercentStyle
                   roundingMode:NSNumberFormatterRoundHalfUp];
}

- (NSString *)fwFormatString:(NSInteger)digit
                 numberStyle:(NSNumberFormatterStyle)numberStyle
                roundingMode:(NSNumberFormatterRoundingMode)roundingMode
{
    NSString *result = nil;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:numberStyle];
    [formatter setRoundingMode:roundingMode];
    [formatter setMinimumIntegerDigits:1];
    [formatter setMaximumFractionDigits:digit];
    result = [formatter stringFromNumber:self];
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
    NSNumber *result = nil;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setRoundingMode:roundingMode];
    [formatter setMinimumIntegerDigits:1];
    [formatter setMaximumFractionDigits:digit];
    result = [NSNumber numberWithDouble:[[formatter stringFromNumber:self] doubleValue]];
    return result;
}

@end
