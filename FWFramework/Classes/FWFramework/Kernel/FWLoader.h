/**
 @header     FWLoader.h
 @indexgroup FWFramework
      FWLoader
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/15
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 通用加载器，添加处理句柄后指定输入即可加载输出结果
 */
NS_SWIFT_NAME(Loader)
@interface FWLoader<__covariant InputType, __covariant OutputType> : NSObject

/// 添加block加载器，返回标志id
- (NSString *)addBlock:(OutputType _Nullable (^)(InputType input))block;

/// 添加target和action加载器，返回标志id
- (NSString *)addTarget:(id)target action:(SEL)action;

/// 指定标志id移除加载器
- (void)remove:(NSString *)identifier;

/// 移除所有的加载器
- (void)removeAll;

/// 依次执行加载器，直到加载成功
- (nullable OutputType)load:(InputType)input;

@end

NS_ASSUME_NONNULL_END
