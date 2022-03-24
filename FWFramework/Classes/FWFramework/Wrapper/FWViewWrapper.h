//
//  FWViewWrapper.h
//  FWFramework
//
//  Created by wuyong on 2022/3/24.
//

#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

/// 框架视图对象包装器
@interface FWViewWrapper : FWWrapper<UIView *>

@end

/// 视图实现包装器对象协议
@interface UIView (FWViewWrapper) <FWWrapperObject>

/// 对象包装器
@property (nonatomic, strong, readonly) FWViewWrapper *fw;

@end

NS_ASSUME_NONNULL_END
