//
//  StatisticalManager.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "StatisticalManager.h"
#import <objc/runtime.h>

#if FWMacroSPM



#else

#import <FWFramework/FWFramework-Swift.h>

#endif

NSNotificationName const __FWStatisticalEventTriggeredNotification = @"FWStatisticalEventTriggeredNotification";

@interface __FWStatisticalManager ()

@property (nonatomic, strong) NSMutableDictionary *eventHandlers;

@end

@implementation __FWStatisticalManager

+ (instancetype)sharedInstance
{
    static __FWStatisticalManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWStatisticalManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _runLoopMode = NSDefaultRunLoopMode;
        _eventHandlers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setStatisticalEnabled:(BOOL)enabled
{
    _statisticalEnabled = enabled;
    if (enabled) [UIView fw_enableStatistical];
}

- (void)registerEvent:(NSString *)name withHandler:(__FWStatisticalBlock)handler
{
    [self.eventHandlers setObject:handler forKey:name];
}

- (void)__handleEvent:(__FWStatisticalObject *)object
{
    __FWStatisticalBlock eventHandler = [self.eventHandlers objectForKey:object.name];
    if (eventHandler) {
        eventHandler(object);
    }
    if (self.globalHandler) {
        self.globalHandler(object);
    }
    if (self.notificationEnabled) {
        [[NSNotificationCenter defaultCenter] postNotificationName:__FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }
}

@end

@interface __FWStatisticalObject ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) id object;
@property (nonatomic, copy) NSDictionary *userInfo;
@property (nonatomic, weak) __kindof UIView *view;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) NSInteger triggerCount;
@property (nonatomic, assign) NSTimeInterval triggerDuration;
@property (nonatomic, assign) NSTimeInterval totalDuration;
@property (nonatomic, assign) BOOL isExposure;
@property (nonatomic, assign) BOOL isFinished;

@end

@implementation __FWStatisticalObject

- (instancetype)initWithName:(NSString *)name
{
    return [self initWithName:name object:nil];
}

- (instancetype)initWithName:(NSString *)name object:(id)object
{
    return [self initWithName:name object:object userInfo:nil];
}

- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _object = object;
        _userInfo = [userInfo copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    __FWStatisticalObject *object = [[[self class] allocWithZone:zone] init];
    object.name = [self.name copy];
    object.object = self.object;
    object.userInfo = [self.userInfo copy];
    object.triggerOnce = self.triggerOnce;
    object.triggerIgnored = self.triggerIgnored;
    object.shieldView = self.shieldView;
    object.shieldViewBlock = self.shieldViewBlock;
    return object;
}

- (void)__triggerClick:(UIView *)view indexPath:(NSIndexPath *)indexPath triggerCount:(NSInteger)triggerCount
{
    self.view = view;
    self.indexPath = indexPath;
    self.triggerCount = triggerCount;
    self.isExposure = NO;
    self.isFinished = YES;
}

- (void)__triggerExposure:(UIView *)view indexPath:(NSIndexPath *)indexPath triggerCount:(NSInteger)triggerCount duration:(NSTimeInterval)duration totalDuration:(NSTimeInterval)totalDuration
{
    self.view = view;
    self.indexPath = indexPath;
    self.triggerCount = triggerCount;
    self.triggerDuration = duration;
    self.totalDuration = totalDuration;
    self.isExposure = YES;
    self.isFinished = duration > 0;
}

@end
