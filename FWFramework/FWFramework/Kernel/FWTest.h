/*!
 @header     FWTest.h
 @indexgroup FWFramework
 @brief      单元测试
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <Foundation/Foundation.h>

#pragma mark - Macro

#ifdef DEBUG

/*! @brief 定义测试宏开关，调试环境默认开启 */
#define FW_TEST 1

#else

/*! @brief 定义测试宏开关，正式环境默认关闭 */
#define FW_TEST 0

#endif

#if FW_TEST

/*!
 @brief 测试用例声明
 
 @param module 测试模块
 @param name 测试名称
 @param ... 属性声明
 */
#define FWTestCase( module, name, ... ) \
    @interface FWTestCase____##module##____##name : FWTestCase \
    __VA_ARGS__ \
    @end \
    @implementation FWTestCase____##module##____##name

/*!
 @brief 测试用例结束，自动注册
 */
#define FWTestCaseEnd( ) \
    + (void)load { [[FWUnitTest sharedInstance] addTestCase:[self class]]; } \
    @end

/*!
 @brief 测试初始化
 */
#define FWTestSetUp( ) \
    - (void)setUp

/*!
 @brief 测试收尾
 */
#define FWTestTearDown( ) \
    - (void)tearDown

/*!
 @brief 测试方法
 
 @param name 测试方法名称
 */
#define FWTest( name ) \
    - (void)test##name

/*!
 @brief 测试断言
 
 @param ... 断言表达式
 */
#define FWTestAssert( ... ) \
    [self assert:__VA_ARGS__ expr:#__VA_ARGS__ file:__FILE__ line:__LINE__];

/*!
 @brief 测试循环
 
 @param times 循环次数
 */
#define FWTestLoop( times ) \
    for ( int __i_##__LINE__ = 0; __i_##__LINE__ < times; ++__i_##__LINE__ )

#pragma mark - FWTestCase

/*!
 @brief 单元测试用例基类，所有单元测试用例必须继承
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
 @brief 断言，简洁版
 
 @param value 布尔表达式
 */
- (void)assert:(BOOL)value;

/*!
 @brief 断言，详细版
 
 @param value 布尔表达式
 @param expr 当前表达式，一般使用宏#__VA_ARGS__或__FUNCTION__
 @param file 当前文件，一般使用宏__FILE__
 @param line 当前行，一般使用宏__LINE__
 */
- (void)assert:(BOOL)value expr:(const char *)expr file:(const char *)file line:(int)line;

@end

#pragma mark - FWUnitTest

/*!
 @brief 单元测试。单例为框架测试(自动在应用启动后后台运行)
 */
@interface FWUnitTest : NSObject

/*!
 @brief 单例模式
 
 @return 单例对象
 */
+ (instancetype)sharedInstance;

/*!
 @brief 添加测试用例
 
 @param testCase 测试用例
 */
- (void)addTestCase:(Class)testCase;

/*!
 @brief 运行单元测试
 */
- (void)run;

@end

#endif
