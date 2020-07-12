/*!
 @header     FWTest.h
 @indexgroup FWFramework
 @brief      单元测试
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <Foundation/Foundation.h>

// 调试环境开启，正式环境关闭
#ifdef DEBUG

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 测试断言
 
 @param ... 断言表达式
 */
#define FWAssertTrue( ... ) \
    [self assertTrue:__VA_ARGS__ expression:@(#__VA_ARGS__) file:@(__FILE__) line:__LINE__];

#pragma mark - FWTestCase

/*!
 @brief 单元测试用例基类，所有单元测试用例必须继承
 @discussion 调试模式下自动执行，按模块单元测试命名格式：FWTestCase_module_name
 */
@interface FWTestCase : NSObject

/*!
 @brief 测试初始化，每次执行测试方法开始都会调用
 */
- (void)setUp;

/*!
 @brief 测试收尾，每次执行测试方法结束都会调用
 */
- (void)tearDown;

/*!
 @brief 断言方法，请勿直接调用，请调用FWAssertTrue
 
 @param value 布尔表达式
 @param expression 当前表达式，一般使用宏@(#__VA_ARGS__)或@(__FUNCTION__)
 @param file 当前文件，一般使用宏@(__FILE__)
 @param line 当前行，一般使用宏__LINE__
 */
- (void)assertTrue:(BOOL)value expression:(NSString *)expression file:(NSString *)file line:(NSInteger)line;

@end

NS_ASSUME_NONNULL_END

#endif
