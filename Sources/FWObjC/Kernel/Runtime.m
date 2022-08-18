//
//  Runtime.m
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import "Runtime.h"
#import <objc/runtime.h>

@interface __WeakObject : NSObject

@property (nonatomic, weak, readonly, nullable) id object;

@end

@implementation __WeakObject

- (instancetype)initWithObject:(id)object {
    self = [super init];
    if (self) {
        _object = object;
    }
    return self;
}

@end

@implementation NSObject (FWRuntime)

- (id)__propertyForName:(NSString *)name {
    id object = objc_getAssociatedObject(self, NSSelectorFromString(name));
    if ([object isKindOfClass:[__WeakObject class]]) {
        object = [(__WeakObject *)object object];
    }
    return object;
}

- (void)__setProperty:(id)object forName:(NSString *)name {
    if (object != [self __propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)__setPropertyAssign:(id)object forName:(NSString *)name {
    if (object != [self __propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_ASSIGN);
    }
}

- (void)__setPropertyCopy:(id)object forName:(NSString *)name {
    if (object != [self __propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

- (void)__setPropertyWeak:(id)object forName:(NSString *)name {
    if (object != [self __propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), [[__WeakObject alloc] initWithObject:object], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
