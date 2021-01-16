//
//  AppConfig.h
//  Example
//
//  Created by wuyong on 16/11/8.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ENV

// 开发环境
#define APP_ENV_DEV  1
// 测试环境
#define APP_ENV_TEST 2
// 正式环境
#define APP_ENV_PROD 3

// 定义当前环境
#define APP_ENV APP_ENV_DEV

#pragma mark - API

// 开发配置
#if (APP_ENV == APP_ENV_DEV)

// 接口地址
#define APP_API_URL @""
// 接口签名
#define APP_API_KEY @""

// 测试配置
#elif (APP_ENV == APP_ENV_TEST)

// 接口地址
#define APP_API_URL @""
// 接口签名
#define APP_API_KEY @""

// 生产配置
#elif (APP_ENV == APP_ENV_PROD)

// 接口地址
#define APP_API_URL @""
// 接口签名
#define APP_API_KEY @""

#endif

NS_ASSUME_NONNULL_END
