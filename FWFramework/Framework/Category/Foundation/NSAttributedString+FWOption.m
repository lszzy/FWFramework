/*!
 @header     NSAttributedString+FWOption.m
 @indexgroup FWFramework
 @brief      NSAttributedString+FWOption
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import "NSAttributedString+FWOption.h"

#pragma mark - FWAttributedOption

@interface FWAttributedOption ()

@end

@implementation FWAttributedOption

- (NSDictionary<NSAttributedStringKey,id> *)toDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    return dictionary;
}

@end

@implementation NSAttributedString (FWOption)

+ (instancetype)fwAttributedString:(NSString *)string withOption:(FWAttributedOption *)option
{
    return [[self alloc] initWithString:string attributes:[option toDictionary]];
}

@end
