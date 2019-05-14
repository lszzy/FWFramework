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

#pragma mark - FWTuple

@implementation FWTuple {
    NSPointerArray *_storage;
}

- (NSPointerArray *)storage
{
    return _storage;
}

- (void)setStorage:(NSPointerArray *)storage
{
    _storage = storage;
}

- (id)init
{
    self = [super init];
    if (self) {
        _storage = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
    }
    return self;
}

- (id)initWithArray:(NSArray *)array
{
    self = [self init];
    if (self) {
        for (id obj in array) {
            [_storage addPointer:((__bridge void*)obj)];
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
        id sentin = FWTupleSentinel();
        while (obj != sentin) {
            [_storage addPointer:((__bridge void*)obj)];
            obj = va_arg(ap, id);
        }
        va_end(ap);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copyTuple = [[[self class] alloc] init];
    [copyTuple setStorage:[[self storage] copy]];
    return copyTuple;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    return [_storage countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return [self objectAtIndex:index];
}

- (id)objectAtIndex:(NSInteger)index
{
    if (index < 0 || index >= [_storage count]) {
        return nil;
    }
    return (__strong id)[_storage pointerAtIndex:index];
}

- (id)firstObject
{
    return [self objectAtIndex:0];
}

- (id)lastObject
{
    return [self objectAtIndex:([_storage count] - 1)];
}

- (void)unpack:(id*)pointers, ...
{
    va_list ap;
    va_start(ap, pointers);
    
    __autoreleasing id* pp = pointers;
    int i = 0;
    while (pp != NULL) {
        *pp = [self objectAtIndex:i];
        pp = va_arg(ap, __autoreleasing id*);
        i++;
    }
    va_end(ap);
}

- (FWTuple *)map:(id (^)(id))block
{
    FWTuple *newTuple = [self copy];
    NSPointerArray *newStorage = [newTuple storage];
    for (NSInteger i = 0, n = [newStorage count]; i != n; i++) {
        id obj = (__strong id)[_storage pointerAtIndex:i];
        [newStorage replacePointerAtIndex:i withPointer:((__bridge void*)block(obj))];
    }
    return newTuple;
}

@end
