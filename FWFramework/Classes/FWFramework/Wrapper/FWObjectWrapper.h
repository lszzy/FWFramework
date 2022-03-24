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

/// NSObject实现对象包装器关联协议
@interface NSObject (FWObjectWrapper) <FWWrapperProtocol>

/// 对象包装器属性
@property (nonatomic, strong, readonly) FWObjectWrapper *fw;

@end

#pragma mark - FWObjectClassWrapper

/// 框架NSObject类包装器
@interface FWObjectClassWrapper : FWClassWrapper

@end

/// NSObject实现类包装器关联协议
@interface NSObject (FWObjectClassWrapper) <FWClassWrapperProtocol>

/// 类包装器属性
@property (class, nonatomic, strong, readonly) FWObjectClassWrapper *fw;

@end

NS_ASSUME_NONNULL_END
