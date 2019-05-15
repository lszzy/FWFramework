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
#define FWUnpack(...) \
    [[FWTupleUnpack alloc] initWithPointers:0, __VA_ARGS__, FWUnpackSentinel()].tuple

id FWTupleSentinel(void);

void** FWUnpackSentinel(void);

#pragma mark - FWTuple

/*!
 @brief 元组，参考自coobjc
 
 @see https://github.com/alibaba/coobjc
 */
@interface FWTuple<Value1, Value2> : NSObject <NSFastEnumeration>

- (id)init;
- (id)initWithArray:(NSArray *)array;
- (id)initWithObjects:(id)objects, ...;

- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (id)objectAtIndex:(NSInteger)index;

- (id)firstObject;
- (id)lastObject;

@end

@interface FWTupleUnpack : NSObject

@property(nonatomic, strong) FWTuple *tuple;

- (instancetype)initWithPointers:(int)startIndex, ...;

@end
