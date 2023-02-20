//
//  FWTask.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWTask

/// 任务基类
NS_SWIFT_NAME(TaskOperation)
@interface FWTask : NSOperation

/// 任务句柄，执行完成需调用task.finish(error:)
@property (nonatomic, copy, nullable) void (^taskBlock)(FWTask *task);

/// 是否在主线程执行，会阻碍UI渲染，默认false
@property (nonatomic, assign) BOOL onMainThread;

/** 错误信息 */
@property (nonatomic, readonly, nullable) NSError *error;

/// 子类可重写，默认调用taskBlock，任务完成需调用finish(error:)
- (void)executeTask;

/// 标记任务完成，error为空表示任务成功
- (void)finishWithError:(nullable NSError *)error;

/// 是否主线程执行，子类可重写，会阻碍UI渲染，默认返回onMainThread
- (BOOL)needMainThread;

@end

#pragma mark - FWTaskManager

/// 任务管理器，兼容NSBlockOperation和NSInvocationOperation
NS_SWIFT_NAME(TaskManager)
@interface FWTaskManager : NSObject

/** 单例模式 */
@property (class, nonatomic, readonly) FWTaskManager *sharedInstance NS_SWIFT_NAME(shared);

/** 并发操作的最大任务数 */
@property (nonatomic, assign) NSInteger maxConcurrentTaskCount;

/** 是否暂停，可恢复 */
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
