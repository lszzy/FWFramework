//
//  Task.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "Task.h"

#pragma mark - __FWTask

typedef NS_ENUM(NSInteger, __FWTaskState) {
    __FWTaskStateCreated,
    __FWTaskStateReady = 1,
    __FWTaskStateLoading,
    __FWTaskStateSuccess,
    __FWTaskStateFailure,
    __FWTaskStateCanceled,
};

@interface __FWTask ()

@property (nonatomic, assign) __FWTaskState state;
@property (nonatomic, strong, readonly) NSRecursiveLock *lock;

@end

@implementation __FWTask

@synthesize lock = _lock;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.state = __FWTaskStateReady;
    }
    return self;
}

- (NSRecursiveLock *)lock
{
    if (!_lock) {
        _lock = [[NSRecursiveLock alloc] init];
    }
    return _lock;
}

- (void)start
{
    [self.lock lock];
    if ([self isReady]) {
        self.state = __FWTaskStateLoading;
        
        // 调试日志
        NSLog(@"\n********** TASK %@ STARTED", NSStringFromClass(self.class));
        
        [self.lock unlock];
        
        if ([self needMainThread]) {
            if ([NSThread isMainThread]) {
                [self executeTask];
            } else {
                [self performSelectorOnMainThread:@selector(executeTask) withObject:nil waitUntilDone:NO];
            }
        } else {
            [self executeTask];
        }
    } else {
        [self.lock unlock];
    }
}

- (void)executeTask
{
    @throw [NSException exceptionWithName:@"FWTask"
                                   reason:[NSString stringWithFormat:@"task %@ must override executeTask", [self.class description]]
                                 userInfo:nil];
}

- (void)finishWithError:(NSError *)error
{
    [self.lock lock];
    if (![self isFinished]) {
        if (error) {
            _error = error;
            self.state = __FWTaskStateFailure;
            
            // 调试日志
            NSLog(@"\n********** TASK %@ FAILED", NSStringFromClass(self.class));
        } else {
            self.state = __FWTaskStateSuccess;
            
            // 调试日志
            NSLog(@"\n********** TASK %@ FINISHED", NSStringFromClass(self.class));
        }
    }
    [self.lock unlock];
}

- (BOOL)needMainThread
{
    return NO;
}

- (void)cancel
{
    [self.lock lock];
    
    if (![self isFinished]) {
        self.state = __FWTaskStateCanceled;
        [super cancel];
        
        // 调试日志
        NSLog(@"\n********** TASK %@ CANCELLED", NSStringFromClass(self.class));
    }
    
    [self.lock unlock];
}

- (BOOL)isAsynchronous
{
    return YES;
}

- (BOOL)isReady
{
    return self.state == __FWTaskStateReady && [super isReady];
}

- (BOOL)isFinished
{
    return self.state == __FWTaskStateSuccess || self.state == __FWTaskStateFailure || self.state == __FWTaskStateCanceled;
}

- (BOOL)isExecuting
{
    return self.state == __FWTaskStateLoading;
}

- (BOOL)isValidTransition:(__FWTaskState)fromState toState:(__FWTaskState)toState
{
    switch (fromState) {
        case __FWTaskStateReady:
        {
            switch (toState) {
                case __FWTaskStateLoading:
                case __FWTaskStateSuccess:
                case __FWTaskStateFailure:
                case __FWTaskStateCanceled:
                    return YES;
                    break;
                default:
                    return NO;
                    break;
            }
            break;
        }
        case __FWTaskStateLoading:
        {
            switch (toState) {
                case __FWTaskStateSuccess:
                case __FWTaskStateFailure:
                case __FWTaskStateCanceled:
                    return YES;
                    break;
                default:
                    return NO;
                    break;
            }
        }
        case (__FWTaskState)0:
        {
            if (toState == __FWTaskStateReady) {
                return YES;
            } else {
                return NO;
            }
        }
        default:
            return NO;
            break;
    }
}

- (void)setState:(__FWTaskState)state
{
    [self.lock lock];
    if (![self isValidTransition:_state toState:state]) {
        [self.lock unlock];
        return;
    }
    
    switch (state) {
        case __FWTaskStateCanceled:
        {
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isCancelled"];
            _state = state;
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
            [self didChangeValueForKey:@"isCancelled"];
            break;
        }
        case __FWTaskStateLoading:
        {
            [self willChangeValueForKey:@"isExecuting"];
            _state = state;
            [self didChangeValueForKey:@"isExecuting"];
            break;
        }
        case __FWTaskStateSuccess:
        case __FWTaskStateFailure:
        {
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isExecuting"];
            _state = state;
            [self didChangeValueForKey:@"isFinished"];
            [self didChangeValueForKey:@"isExecuting"];
            break;
        }
        case __FWTaskStateReady:
        {
            [self willChangeValueForKey:@"isReady"];
            _state = state;
            [self didChangeValueForKey:@"isReady"];
            break;
        }
        default:
        {
            _state = state;
            break;
        }
    }
    
    [self.lock unlock];
}

@end

#pragma mark - __FWTaskManager

@implementation __FWTaskManager
{
    NSOperationQueue *_taskQueue;
}

+ (__FWTaskManager *)sharedInstance
{
    static __FWTaskManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWTaskManager alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _taskQueue = [[NSOperationQueue alloc] init];
        _taskQueue.name = @"FWTaskManager.taskQueue";
    }
    return self;
}

- (NSInteger)maxConcurrentTaskCount
{
    return _taskQueue.maxConcurrentOperationCount;
}

- (void)setMaxConcurrentTaskCount:(NSInteger)maxConcurrentTaskCount
{
    _taskQueue.maxConcurrentOperationCount = maxConcurrentTaskCount;
}

- (BOOL)isSuspended
{
    return _taskQueue.isSuspended;
}

- (void)setIsSuspended:(BOOL)isSuspended
{
    _taskQueue.suspended = isSuspended;
}

- (void)addTask:(NSOperation *)task
{
    [_taskQueue addOperation:task];
}

- (void)addTasks:(NSArray<NSOperation *> *)tasks
{
    if (tasks.count > 0) {
        [_taskQueue addOperations:tasks waitUntilFinished:NO];
    }
}

- (void)addTaskConfig:(NSArray<NSDictionary *> *)config
{
    NSMutableDictionary *taskMap = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary *taskInfo in config) {
        // className
        NSString *className = [taskInfo objectForKey:@"className"];
        Class clazz = NSClassFromString(className);
        if ([clazz isSubclassOfClass:[NSOperation class]]) {
            NSOperation *task = [[clazz alloc] init];
            [taskMap setObject:task forKey:className];
            // dependency
            NSArray *dependencyList = [[taskInfo objectForKey:@"dependency"] componentsSeparatedByString:@","];
            if (dependencyList.count) {
                for (NSString *depedencyClass in dependencyList) {
                    NSOperation *preTask = [taskMap objectForKey:depedencyClass];
                    if (preTask) [task addDependency:preTask];
                }
            }
        }
    }
    
    [self addTasks:[taskMap allValues]];
}

- (void)cancelAllTasks
{
    [_taskQueue cancelAllOperations];
}

- (void)waitUntilFinished
{
    [_taskQueue waitUntilAllOperationsAreFinished];
}

@end
