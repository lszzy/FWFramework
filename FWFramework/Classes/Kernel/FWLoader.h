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
 加载器，处理swift不支持load方法问题
 @note 本方案采用objc扩展方法实现，相对于全局扫描类方案性能高(1/200)，使用简单
    使用方法：新增FWLoader扩展objc类方法，以load开头即会自动调用，注意方法名不要重复，建议load+类名+扩展名
 */
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
