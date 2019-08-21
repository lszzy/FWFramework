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

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance
{
    // 设置统一默认样式
    // WAttributedOption *appearance = [FWAttributedOption appearance];
}

+ (instancetype)appearance
{
    static FWAttributedOption *appearance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appearance = [[self alloc] init];
    });
    return appearance;
}

- (NSDictionary<NSAttributedStringKey,id> *)toDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    return dictionary;
}

@end

#pragma mark - NSAttributedString+FWOption

@implementation NSAttributedString (FWOption)

+ (instancetype)fwAttributedString:(NSString *)string withOption:(FWAttributedOption *)option
{
    return [[self alloc] initWithString:string attributes:[option toDictionary]];
}

@end
