//
//  ObjC.h
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// ObjC桥接类，用于桥接Swift不支持的ObjC特性
NS_SWIFT_NAME(ObjCBridge)
@interface FWObjCBridge : NSObject

+ (BOOL)invokeMethod:(id)target selector:(SEL)selector arguments:(nullable NSArray *)arguments returnValue:(void *)result;

+ (id)appearanceForClass:(Class)aClass;

+ (Class)classForAppearance:(id)appearance;

+ (void)applyAppearance:(NSObject *)object;

@end

NS_ASSUME_NONNULL_END
