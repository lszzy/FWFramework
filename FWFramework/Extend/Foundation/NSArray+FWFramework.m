/*!
 @header     NSArray+FWFramework.m
 @indexgroup FWFramework
 @brief      NSArray分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import "NSArray+FWFramework.h"

@implementation NSArray (FWFramework)

- (id)fwRandomObject
{
    if (self.count > 0) {
        return self[arc4random_uniform((u_int32_t)self.count)];
    }
    return nil;
}

- (NSArray *)fwReverseArray
{
    NSMutableArray *reverseArray = [NSMutableArray arrayWithArray:self];
    [reverseArray fwReverse];
    return [reverseArray copy];
}

- (NSArray *)fwShuffleArray
{
    NSMutableArray *shuffleArray = [NSMutableArray arrayWithArray:self];
    [shuffleArray fwShuffle];
    return [shuffleArray copy];
}

- (BOOL)fwIncludeNull
{
    __block BOOL includeNull = NO;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSNull class]]) {
            includeNull = YES;
            *stop = YES;
        }
    }];
    return includeNull;
}

@end

#pragma mark - NSMutableArray+FWFramework

@implementation NSMutableArray (FWFramework)

- (void)fwReverse
{
    NSUInteger count = self.count;
    int mid = floor(count / 2.0);
    for (NSUInteger i = 0; i < mid; i++) {
        [self exchangeObjectAtIndex:i withObjectAtIndex:(count - (i + 1))];
    }
}

- (void)fwShuffle
{
    for (NSUInteger i = self.count; i > 1; i--) {
        [self exchangeObjectAtIndex:(i - 1)
                  withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
    }
}

@end
