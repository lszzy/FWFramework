/*!
 @header     FWTuple.m
 @indexgroup FWFramework
 @brief      FWTuple
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/14
 */

#import "FWTuple.h"

id FWTupleSentinel() {
    static id sentinel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sentinel = [[NSObject alloc] init];
    });
    return sentinel;
}

void** FWUnpackSentinel() {
    static id sentinel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sentinel = [[NSObject alloc] init];
    });
    return (void**)&sentinel;
}

#pragma mark - FWTuple

@implementation FWTuple
{
    NSPointerArray *storage;
}

- (id)init
{
    self = [super init];
    if (self) {
        storage = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
    }
    return self;
}

- (id)initWithArray:(NSArray *)array
{
    self = [self init];
    if (self) {
        for (id obj in array) {
            [storage addPointer:((__bridge void*)obj)];
        }
    }
    return self;
}

- (id)initWithObjects:(id)objects, ...
{
    self = [self init];
    if (self) {
        va_list ap;
        va_start(ap, objects);
        
        id obj = objects;
        id sentinel = FWTupleSentinel();
        while (obj != sentinel) {
            [storage addPointer:((__bridge void*)obj)];
            obj = va_arg(ap, id);
        }
        va_end(ap);
    }
    return self;
}

- (NSUInteger)count
{
    return storage.count;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    return [storage countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return [self objectAtIndex:index];
}

- (id)objectAtIndex:(NSInteger)index
{
    if (index < 0 || index >= [storage count]) {
        return nil;
    }
    return (__strong id)[storage pointerAtIndex:index];
}

- (id)firstObject
{
    return [self objectAtIndex:0];
}

- (id)lastObject
{
    return [self objectAtIndex:([storage count] - 1)];
}

- (void)dealloc
{
    if (storage) {
        [storage release];
        storage = nil;
    }
    [super dealloc];
}

@end

@implementation FWTuple1

@end

@implementation FWTuple2

@end

@implementation FWTuple3

@end

@implementation FWTuple4

@end

@implementation FWTuple5

@end

@implementation FWTuple6

@end

@implementation FWTuple7

@end

@implementation FWTuple8

@end

@implementation FWTupleUnpack
{
    NSMutableArray *storage;
}

- (instancetype)initWithPointers:(int)startIndex, ...
{
    self = [super init];
    if (self) {
        storage = [[NSMutableArray alloc] init];
        va_list ap;
        va_start(ap, startIndex);
        
        if (startIndex <= 0) {
            startIndex = 0;
        }
        int i = 0;
        id *sentinel = (id*)FWUnpackSentinel();
        do {
            __autoreleasing id* pp = va_arg(ap, __autoreleasing id*);
            if (pp == sentinel) {
                break;
            }
            if (i >= startIndex) {
                uintptr_t pointer = (uintptr_t)pp;
                [storage addObject:@(pointer)];
            }
            i++;
        } while (1);
        va_end(ap);
    }
    return self;
}

- (void)setTuple:(FWTuple *)tuple
{
    if (tuple == NULL || ![tuple isKindOfClass:[FWTuple class]]) {
        return;
    }
    _tuple = [tuple retain];
    int index = 0;
    for (NSNumber *number in storage) {
        if (index >= [tuple count]) {
            break;
        }
        uintptr_t p = [number unsignedLongValue];
        if (p > 0) {
            __autoreleasing id* pointer = (id*)p;
            *pointer = [[tuple objectAtIndex:index] retain];
        }
        index++;
    }
}

- (void)dealloc
{
    [storage removeAllObjects];
    storage = nil;
    if (_tuple) {
        [_tuple release];
        _tuple = nil;
    }
    [super dealloc];
}

@end
