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

/// 视图实现对象包装器关联协议
@interface UIView (FWViewWrapper) <FWWrapperProtocol>

/// 对象包装器属性
@property (nonatomic, strong, readonly) FWViewWrapper *fw;

@end

NS_ASSUME_NONNULL_END
