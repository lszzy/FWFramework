//
//  FWObjectWrapper.h
//  FWFramework
//
//  Created by wuyong on 2022/3/24.
//

#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWObjectWrapper

/// 框架NSObject对象包装器
@interface FWObjectWrapper : FWWrapper<NSObject *>

@end

/// NSObject实现包装器对象协议
@interface NSObject (FWObjectWrapper) <FWWrapperObject>

/// 对象包装器
@property (nonatomic, strong, readonly) FWObjectWrapper *fw;

@end

#pragma mark - FWObjectClassWrapper

/// 框架NSObject类包装器
@interface FWObjectClassWrapper : FWWrapper<Class>

@end

/// NSObject实现包装器类协议
@interface NSObject (FWObjectClassWrapper) <FWWrapperClass>

/// 类包装器
@property (class, nonatomic, strong, readonly) FWObjectClassWrapper *fw;

@end

NS_ASSUME_NONNULL_END
