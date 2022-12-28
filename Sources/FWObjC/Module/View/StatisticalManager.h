//
//  StatisticalManager.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWStatistical

@class __FWStatisticalObject;

/// 统计事件触发通知，可统一处理。通知object为__FWStatisticalObject统计对象，userInfo为附加信息
extern NSNotificationName const __FWStatisticalEventTriggeredNotification NS_SWIFT_NAME(StatisticalEventTriggered);

/// 统计通用block，参数object为__FWStatisticalObject统计对象
typedef void (^__FWStatisticalBlock)(__FWStatisticalObject *object) NS_SWIFT_NAME(StatisticalBlock);

/// 统计点击回调block，参数cell为表格子cell，indexPath为表格子cell所在位置
typedef void (^__FWStatisticalClickCallback)(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath) NS_SWIFT_NAME(StatisticalClickCallback);

/// 统计曝光回调block，参数cell为表格子cell，indexPath为表格子cell所在位置，duration为曝光时长(0表示开始)
typedef void (^__FWStatisticalExposureCallback)(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath, NSTimeInterval duration) NS_SWIFT_NAME(StatisticalExposureCallback);

/**
 事件统计管理器
 @note 视图从不可见变为可见时曝光开始，触发曝光开始事件(triggerDuration为0)；
 视图从可见到不可见时曝光结束，视为一次曝光，触发曝光结束事件(triggerDuration大于0)并统计曝光时长。
 目前暂未实现曝光时长统计，仅触发开始事件用于统计次数，可自行处理时长统计，注意应用退后台时不计曝光时间。
 默认运行模式时，视图快速滚动不计算曝光，可配置runLoopMode快速滚动时也计算曝光
 */
NS_SWIFT_NAME(StatisticalManager)
@interface __FWStatisticalManager : NSObject

/// 单例模式
@property (class, nonatomic, readonly) __FWStatisticalManager *sharedInstance NS_SWIFT_NAME(shared);

/// 是否启用事件统计，为提高性能，默认NO未开启，需手动开启
@property (nonatomic, assign) BOOL statisticalEnabled;

/// 是否启用通知，默认NO
@property (nonatomic, assign) BOOL notificationEnabled;

/// 设置运行模式，默认Default快速滚动时不计算曝光
@property (nonatomic, copy) NSRunLoopMode runLoopMode;

/// 是否部分可见时触发曝光，默认NO，仅视图完全可见时才触发曝光
@property (nonatomic, assign) BOOL exposurePartly;

/// 设置全局事件处理器
@property (nonatomic, copy, nullable) __FWStatisticalBlock globalHandler;

/// 注册单个事件处理器
- (void)registerEvent:(NSString *)name withHandler:(__FWStatisticalBlock)handler;

@end

/**
 事件统计对象
 */
NS_SWIFT_NAME(StatisticalObject)
@interface __FWStatisticalObject : NSObject <NSCopying>

/// 事件绑定名称，未绑定时为空
@property (nonatomic, copy, readonly, nullable) NSString *name;
/// 事件绑定对象，未绑定时为空
@property (nonatomic, strong, readonly, nullable) id object;
/// 事件绑定信息，未绑定时为空
@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;

/// 事件来源视图，触发时自动赋值
@property (nonatomic, weak, readonly, nullable) __kindof UIView *view;
/// 事件来源位置，触发时自动赋值
@property (nonatomic, strong, readonly, nullable) NSIndexPath *indexPath;
/// 事件触发次数，触发时自动赋值
@property (nonatomic, assign, readonly) NSInteger triggerCount;
/// 事件触发单次时长，0表示曝光开始，仅曝光支持，触发时自动赋值
@property (nonatomic, assign, readonly) NSTimeInterval triggerDuration;
/// 事件触发总时长，仅曝光支持，触发时自动赋值
@property (nonatomic, assign, readonly) NSTimeInterval totalDuration;
/// 是否是曝光事件，默认NO为点击事件
@property (nonatomic, assign, readonly) BOOL isExposure;
/// 事件是否完成，注意曝光会触发两次，第一次为NO曝光开始，第二次为YES曝光结束
@property (nonatomic, assign, readonly) BOOL isFinished;

/// 是否事件仅触发一次，默认NO
@property (nonatomic, assign) BOOL triggerOnce;
/// 是否忽略事件触发，默认NO
@property (nonatomic, assign) BOOL triggerIgnored;
/// 曝光遮挡视图，被遮挡时不计曝光
@property (nonatomic, weak, nullable) UIView *shieldView;
/// 曝光遮挡视图句柄，被遮挡时不计曝光
@property (nonatomic, copy, nullable) UIView * _Nullable (^shieldViewBlock)(void);

/// 创建事件绑定信息，指定名称
- (instancetype)initWithName:(NSString *)name;
/// 创建事件绑定信息，指定名称和对象
- (instancetype)initWithName:(NSString *)name object:(nullable id)object;
/// 创建事件绑定信息，指定名称、对象和信息
- (instancetype)initWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end

/**
 自定义统计实现代理
 */
NS_SWIFT_NAME(StatisticalDelegate)
@protocol __FWStatisticalDelegate <NSObject>

@optional

/// 自定义点击事件统计方式(单次)，仅注册时调用一次，点击触发时必须调用callback。参数cell为表格子cell，indexPath为表格子cell所在位置
- (void)statisticalClickWithCallback:(__FWStatisticalClickCallback)callback;

/// 自定义曝光事件统计方式(多次)，当视图绑定曝光、完全曝光时会调用，曝光触发时必须调用callback。参数cell为表格子cell，indexPath为表格子cell所在位置，duration为曝光时长(0表示开始)
- (void)statisticalExposureWithCallback:(__FWStatisticalExposureCallback)callback;

/// 自定义cell事件代理视图，仅cell生效。默认为所在tableView|collectionView，如果不同，实现此方法即可
- (nullable UIView *)statisticalCellProxyView;

@end

#pragma mark - UIView+__FWStatistical

/**
 Click点击统计
 */
@interface UIView (__FWStatistical)

/// 绑定统计点击事件，触发管理器。view为添加的Tap手势(需先添加手势)，control为TouchUpInside|ValueChanged，tableView|collectionView为Select(需先设置delegate)
@property (nullable, nonatomic, strong) __FWStatisticalObject *fw_statisticalClick NS_REFINED_FOR_SWIFT;

/// 绑定统计点击事件，仅触发回调。view为添加的Tap手势(需先添加手势)，control为TouchUpInside|ValueChanged，tableView|collectionView为Select(需先设置delegate)
@property (nullable, nonatomic, copy) __FWStatisticalBlock fw_statisticalClickBlock NS_REFINED_FOR_SWIFT;

/// 手工触发统计点击事件，更新点击次数，列表可指定cell和位置，可重复触发
- (void)fw_statisticalTriggerClick:(nullable UIView *)cell indexPath:(nullable NSIndexPath *)indexPath NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIView+__FWExposure

/**
 Exposure曝光统计
 */
@interface UIView (__FWExposure)

/// 绑定统计曝光事件，触发管理器。如果对象发生变化(indexPath|name|object)，也会触发
@property (nullable, nonatomic, strong) __FWStatisticalObject *fw_statisticalExposure NS_REFINED_FOR_SWIFT;

/// 绑定统计曝光事件，仅触发回调
@property (nullable, nonatomic, copy) __FWStatisticalBlock fw_statisticalExposureBlock NS_REFINED_FOR_SWIFT;

/// 手工触发统计曝光事件，更新曝光次数和时长，列表可指定cell和位置，duration为单次曝光时长(0表示开始)，可重复触发
- (void)fw_statisticalTriggerExposure:(nullable UIView *)cell indexPath:(nullable NSIndexPath *)indexPath duration:(NSTimeInterval)duration NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
