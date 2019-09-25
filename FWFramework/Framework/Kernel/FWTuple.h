/*!
 @header     FWTuple.h
 @indexgroup FWFramework
 @brief      FWTuple
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/9/25
 */

#import <Foundation/Foundation.h>

/*!
 @brief 元组，参考自coobjc
 
 @see https://github.com/alibaba/coobjc
 */
@interface FWTuple : NSObject <NSFastEnumeration>

- (id)init;
- (id)initWithArray:(NSArray *)array;
- (id)initWithObjects:(id)objects, ...;

- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (id)objectAtIndex:(NSInteger)index;

- (id)firstObject;
- (id)lastObject;

@end

@interface FWTuple1<Value1>: FWTuple

@end

@interface FWTuple2<Value1, Value2>: FWTuple

@end

@interface FWTuple3<Value1, Value2, Value3>: FWTuple

@end

@interface FWTuple4<Value1, Value2, Value3, Value4>: FWTuple

@end

@interface FWTuple5<Value1, Value2, Value3, Value4, Value5>: FWTuple

@end

@interface FWTuple6<Value1, Value2, Value3, Value4, Value5, Value6>: FWTuple

@end

@interface FWTuple7<Value1, Value2, Value3, Value4, Value5, Value6, Value7>: FWTuple

@end

@interface FWTuple8<Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8>: FWTuple

@end

@interface FWTupleUnpack : NSObject

@property(nonatomic, strong) FWTuple *tuple;

- (instancetype)initWithPointers:(int)startIndex, ...;

@end

id FWTupleSentinel(void);

void** FWUnpackSentinel(void);

// 快速创建元组
#define FWTuple(...) \
    [[FWTuple alloc] initWithObjects:__VA_ARGS__, FWTupleSentinel()]

// 快速元组解包
#define FWUnpack(...) \
    [[FWTupleUnpack alloc] initWithPointers:0, __VA_ARGS__, FWUnpackSentinel()].tuple
