//
//  FWStringWrapper.h
//  FWFramework
//
//  Created by wuyong on 2022/3/24.
//

#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

/// 框架NSString对象包装器
@interface FWStringWrapper : FWWrapper<NSString *>

@end

/// NSString实现对象包装器关联协议
@interface NSString (FWStringWrapper) <FWWrapperProtocol>

/// 对象包装器属性
@property (nonatomic, strong, readonly) FWStringWrapper *fw;

@end

NS_ASSUME_NONNULL_END
