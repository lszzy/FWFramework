//
//  Runtime.h
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (FWRuntime)

/// 读取关联属性
- (nullable id)__propertyForName:(NSString *)name;

/// 设置强关联属性，支持KVO
- (void)__setProperty:(nullable id)object forName:(NSString *)name;

/// 设置赋值关联属性，支持KVO，注意可能会产生野指针
- (void)__setPropertyAssign:(nullable id)object forName:(NSString *)name;

/// 设置拷贝关联属性，支持KVO
- (void)__setPropertyCopy:(nullable id)object forName:(NSString *)name;

/// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
- (void)__setPropertyWeak:(nullable id)object forName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
