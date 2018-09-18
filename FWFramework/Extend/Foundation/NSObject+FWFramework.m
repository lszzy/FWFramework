/*!
 @header     NSObject+FWFramework.h
 @indexgroup FWFramework
 @brief      NSObject分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-15
 */

#import "NSObject+FWFramework.h"
#import <objc/runtime.h>

@implementation NSObject (FWFramework)

@dynamic fwTempObject;

- (id)fwTempObject
{
    return objc_getAssociatedObject(self, @selector(fwTempObject));
}

- (void)setFwTempObject:(id)fwTempObject
{
    if (fwTempObject != self.fwTempObject) {
        [self willChangeValueForKey:@"fwTempObject"];
        objc_setAssociatedObject(self, @selector(fwTempObject), fwTempObject, fwTempObject ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:@"fwTempObject"];
    }
}

- (id)fwArchiveCopy
{
    id obj = nil;
    @try {
        obj = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    return obj;
}

@end
