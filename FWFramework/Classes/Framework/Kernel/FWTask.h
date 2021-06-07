//
//  FWTask.h
//  FWFramework
//
//  Created by wuyong on 2017/5/12.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWTask

/// 任务基类
@interface FWTask : NSOperation

/*! @brief 错误信息 */
@property (nonatomic, readonly, nullable) NSError *error;

/// 子类重写，任务执行完成，需调用finishWithError:
- (void)executeTask;

/// 标记任务完成，error为空表示任务成功
- (void)finishWithError:(nullable NSError *)error;

/// 是否需要主线程执行，会阻碍UI渲染，默认NO
- (BOOL)needMainThread;

@end

#pragma mark - FWTaskManager

/// 任务管理器，兼容NSBlockOperation和NSInvocationOperation
@interface FWTaskManager : NSObject

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWTaskManager *sharedInstance;

/*! @brief 并发操作的最大任务数 */
@property (nonatomic, assign) NSInteger maxConcurrentTaskCount;

/*! @brief 是否暂停，可恢复 */
@property (nonatomic, assign) BOOL isSuspended;

/// 添加单个任务
- (void)addTask:(NSOperation *)task;

/// 批量添加任务
- (void)addTasks:(NSArray<NSOperation *> *)tasks;

/// 从配置数组按顺序添加任务，支持className|dependency
- (void)addTaskConfig:(NSArray<NSDictionary *> *)config;

/// 取消所有任务
- (void)cancelAllTasks;

/// 等待所有任务执行完成，会阻塞线程
- (void)waitUntilFinished;

@end

NS_ASSUME_NONNULL_END
