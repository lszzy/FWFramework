//
//  Autoloader.h
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 内部自动加载器，处理Swift不支持load方法问题
@interface __Autoloader : NSObject

@end

NS_ASSUME_NONNULL_END
