/*!
 @header     FWView.h
 @indexgroup FWFramework
 @brief      FWView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief FWViewEvent
 */
@interface FWViewEvent : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly, nullable) id object;
@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;

+ (instancetype)eventWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;
- (instancetype)initWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end

/*!
 @brief FWViewDelegate
 */
@protocol FWViewDelegate <NSObject>

- (void)onTouchView:(__kindof UIView *)view withEvent:(FWViewEvent *)event;

@end

/*!
 @brief UIView+FWEvent
 */
@interface UIView (FWEvent)

// 通用事件代理
@property (nonatomic, weak, nullable) id<FWViewDelegate> fwViewDelegate;

// 调用事件代理
- (void)fwTouchEvent:(FWViewEvent *)event;

// 通用视图数据
@property (nonatomic, strong, nullable) id fwViewData;

// 渲染数据，子类重写
- (void)fwRenderData;

@end

NS_ASSUME_NONNULL_END
