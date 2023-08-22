//
//  FWAlertControllerImpl.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWAlertController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAlertControllerImpl

NS_SWIFT_NAME(AlertControllerImpl)
@interface FWAlertControllerImpl : NSObject <FWAlertPlugin>

/** 单例模式 */
@property (class, nonatomic, readonly) FWAlertControllerImpl *sharedInstance NS_SWIFT_NAME(shared);

/// 自定义Alert弹窗样式，nil时使用单例
@property (nonatomic, strong, nullable) FWAlertControllerAppearance *customAlertAppearance;

/// 自定义ActionSheet弹窗样式，nil时使用单例
@property (nonatomic, strong, nullable) FWAlertControllerAppearance *customSheetAppearance;

/// 点击暗色背景关闭时是否触发cancelBlock，默认NO
@property (nonatomic, assign) BOOL dimmingTriggerCancel;

/// 是否隐藏ActionSheet取消按钮，取消后可点击背景关闭并触发cancelBlock
@property (nonatomic, assign) BOOL hidesSheetCancel;

/// 弹窗自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(FWAlertController *alertController);

/// 显示自定义视图弹窗，无默认按钮
- (void)viewController:(UIViewController *)viewController
    showAlertWithStyle:(UIAlertControllerStyle)style
            headerView:(UIView *)headerView
                cancel:(nullable id)cancel
               actions:(nullable NSArray *)actions
           actionBlock:(nullable void (^)(NSInteger index))actionBlock
           cancelBlock:(nullable void (^)(void))cancelBlock
           customBlock:(nullable void (^)(id alertController))customBlock;

@end

NS_ASSUME_NONNULL_END
