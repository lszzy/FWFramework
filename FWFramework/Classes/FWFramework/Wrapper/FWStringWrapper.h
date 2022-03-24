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

/// NSString实现包装器对象协议
@interface NSString (FWStringWrapper) <FWWrapperObject>

/// 对象包装器
@property (nonatomic, strong, readonly) FWStringWrapper *fw;

@end

NS_ASSUME_NONNULL_END
