/*!
 @header     FWTuple.h
 @indexgroup FWFramework
 @brief      FWTuple
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/14
 */

#import <Foundation/Foundation.h>

#pragma mark - Macro

// 快速创建元组
#define FWTuple(...) \
    [[FWTuple alloc] initWithObjects:__VA_ARGS__, FWTupleSentinel()]

// 快速元组解包
#define FWUnpack(tuple, ...) \
    [tuple unpack:__VA_ARGS__, NULL]

id FWTupleSentinel(void);

#pragma mark - FWTuple

// 元组
@interface FWTuple : NSObject <NSCopying, NSFastEnumeration>

- (id)init;
- (id)initWithArray:(NSArray *)array;
- (id)initWithObjects:(id)objects, ...;

- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (id)objectAtIndex:(NSInteger)index;
- (id)firstObject;
- (id)lastObject;

- (void)unpack:(id*)pointers, ...;

- (FWTuple *)map:(id (^)(id obj))block;

@end
