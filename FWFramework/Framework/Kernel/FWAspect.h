/*!
 @header     FWAspect.h
 @indexgroup FWFramework
 @brief      AOP管理器
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-13
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief AOP选项，支持多个
 
 @const FWAspectPositionAfter 原始实现之后调用
 @const FWAspectPositionInstead 原始实现替换调用
 @const FWAspectPositionBefore 原始实现之前调用
 @const FWAspectAutomaticRemoval 执行一次之后自动移除
 */
typedef NS_OPTIONS(NSUInteger, FWAspectOptions) {
    FWAspectPositionAfter = 0,
    FWAspectPositionInstead = 1,
    FWAspectPositionBefore = 2,
    FWAspectAutomaticRemoval = 1 << 3,
};

/*!
 @brief 可以反注册AOP的Token
 */
@protocol FWAspectToken <NSObject>

/*!
 @brief 移除AOP注册
 
 @return 是否移除成功
 */
- (BOOL)remove;

@end

/*!
 @brief AOP信息，注册代码块的第一个参数
 */
@protocol FWAspectInfo <NSObject>

/*!
 @brief 当前AOP实例
 
 @return AOP实例
 */
- (id)instance;

/*!
 @brief 当前AOP方法原始调用
 
 @return 原始调用
 */
- (NSInvocation *)originalInvocation;

/*!
 @brief 所有方法参数数组，调用时才生成
 
 @return 方法参数数组
 */
- (NSArray *)arguments;

@end

/*!
 @brief AOP管理器，修改自Aspects
 @discussion 示例代码如下：
    [UIViewController fwHookSelector:@selector(viewWillAppear:) withBlock:^(id<FWAspectInfo> aspectInfo, BOOL animated){
        NSLog(@"viewController:%@ animated:%@", aspectInfo.instance, @(animated));
    } options:FWAspectPositionAfter error:NULL];
 
 @see https://github.com/steipete/Aspects
 */
@interface NSObject (FWAspect)

/*!
 @brief 添加指定代码到当前类方法执行之前/替换/之后
 
 @param selector 原始方法
 @param block 注册block，第一个可选参数为`id<FWAspectInfo>`，后续可选参数为原始方法的参数。不支持hook静态方法
 @param options 注册选项
 @param error 注册错误
 @return 可以反注册的AOP信息
 */
+ (nullable id<FWAspectToken>)fwHookSelector:(SEL)selector
                                   withBlock:(id)block
                                     options:(FWAspectOptions)options
                                       error:(NSError * _Nullable __autoreleasing *)error;

/*!
 @brief 添加指定代码到当前对象方法执行之前/替换/之后
 
 @param selector 原始方法
 @param block 注册block，第一个可选参数为`id<FWAspectInfo>`，后续可选参数为原始方法的参数。不支持hook静态方法
 @param options 注册选项
 @param error 注册错误
 @return 可以反注册的AOP信息
 */
- (nullable id<FWAspectToken>)fwHookSelector:(SEL)selector
                                   withBlock:(id)block
                                     options:(FWAspectOptions)options
                                       error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
