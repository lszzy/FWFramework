/*!
 @header     UIView+FWStatistical.h
 @indexgroup FWFramework
 @brief      UIView+FWStatistical
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/1/16
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWStatistical

// 统计事件触发通知，可统一处理。通知object为FWStatisticalObject统计对象，userInfo为附加信息
extern NSString *const FWStatisticalEventTriggeredNotification;

/*!
 @brief 事件统计对象
 */
@interface FWStatisticalObject : NSObject

// 事件绑定信息，未绑定时为空
@property (nonatomic, copy, readonly, nullable) NSString *name;
@property (nonatomic, strong, readonly, nullable) id object;
@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;

// 事件来源信息，触发时自动赋值
@property (nonatomic, weak, readonly, nullable) __kindof UIView *view;
@property (nonatomic, strong, readonly, nullable) NSIndexPath *indexPath;

// 创建事件绑定信息
- (instancetype)initWithName:(nullable NSString *)name;
- (instancetype)initWithName:(nullable NSString *)name object:(nullable id)object;
- (instancetype)initWithName:(nullable NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end

/*!
@brief 统计通用block
*/
typedef void (^FWStatisticalBlock)(FWStatisticalObject *object);

#pragma mark - UIView+FWStatistical

/*!
 @brief Click点击统计
 */
@interface UIView (FWStatistical)

#pragma mark - Click

// 绑定统计点击事件，发送通知。view为添加的Tap手势(需先添加手势)，control为TouchUpInside，tableView|collectionView为Select(需先设置delegate)
@property (nullable, nonatomic, strong) FWStatisticalObject *fwStatisticalClick;

// 绑定统计点击事件，触发回调。view为添加的Tap手势(需先添加手势)，control为TouchUpInside，tableView|collectionView为Select(需先设置delegate)
@property (nullable, nonatomic, copy) FWStatisticalBlock fwStatisticalClickBlock;

@end

@interface UIControl (FWStatistical)

#pragma mark - Changed

// 绑定统计值Changed事件，发送通知
@property (nullable, nonatomic, strong) FWStatisticalObject *fwStatisticalChanged;

// 绑定统计值Changed事件，触发回调
@property (nullable, nonatomic, copy) FWStatisticalBlock fwStatisticalChangedBlock;

@end

#pragma mark - UIView+FWExposure

// 曝光状态，未曝光、部分曝光、全曝光
typedef NS_ENUM(NSInteger, FWStatisticalExposureState) {
    FWStatisticalExposureStateNone,
    FWStatisticalExposureStatePartly,
    FWStatisticalExposureStateFully,
};

/*!
 @brief Exposure曝光统计
 */
@interface UIView (FWExposure)

#pragma mark - Exposure

// 当前视图在指定父视图的曝光状态
- (FWStatisticalExposureState)fwExposureStateInSuperview:(UIView *)superview;

// 当前视图在父控制器的曝光状态
- (FWStatisticalExposureState)fwExposureStateInViewController;

// 绑定统计曝光事件，发送通知
@property (nullable, nonatomic, strong) FWStatisticalObject *fwStatisticalExposure;

// 绑定统计曝光事件，触发回调
@property (nullable, nonatomic, copy) FWStatisticalBlock fwStatisticalExposureBlock;

@end

NS_ASSUME_NONNULL_END
