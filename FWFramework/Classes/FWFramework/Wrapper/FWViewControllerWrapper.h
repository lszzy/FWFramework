//
//  FWViewControllerWrapper.h
//  FWFramework
//
//  Created by wuyong on 2022/3/24.
//

#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

/// 框架视图控制器对象包装器
@interface FWViewControllerWrapper : FWWrapper<UIViewController *>

@end

/// 视图控制器实现包装器对象协议
@interface UIViewController (FWViewControllerWrapper) <FWWrapperObject>

/// 对象包装器
@property (nonatomic, strong, readonly) FWViewControllerWrapper *fw;

@end

NS_ASSUME_NONNULL_END
