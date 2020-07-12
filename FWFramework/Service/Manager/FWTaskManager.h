//
//  FWTaskManager.h
//  FWFramework
//
//  Created by wuyong on 2017/5/12.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWTask

// 任务基类
@interface FWTask : NSOperation

/**
 *  错误信息
 */
@property (nonatomic, readonly, nullable) NSError *error;

/**
 *  子类重写，任务执行完成，需调用finishWithError:
 */
- (void)executeTask;

/**
 *  标记任务完成，error为空表示任务成功
 *
 *  @param error 任务错误信息
 */
- (void)finishWithError:(nullable NSError *)error;

/**
 *  是否需要主线程执行，会阻碍UI渲染，默认NO
 */
- (BOOL)needMainThread;

@end

#pragma mark - FWTaskManager

// 任务管理器，兼容NSBlockOperation和NSInvocationOperation
@interface FWTaskManager : NSObject

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWTaskManager *sharedInstance;

/**
 *  并发操作的最大任务数
 */
@property (nonatomic, assign) NSInteger maxConcurrentTaskCount;

/**
 *  从配置数组添加任务
 *
 *  @param config 配置信息
 */
- (void)addTaskConfig:(NSArray<NSDictionary *> *)config;

/**
 *  添加单个任务
 *
 *  @param task 任务
 */
- (void)addTask:(NSOperation *)task;

/**
 *  批量添加任务
 *
 *  @param tasks 任务数组
 */
- (void)addTasks:(NSArray<NSOperation *> *)tasks;

@end

NS_ASSUME_NONNULL_END
