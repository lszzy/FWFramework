/*!
 @header     FWView.h
 @indexgroup FWFramework
 @brief      FWView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import <UIKit/UIKit.h>

/*!
 @brief FWViewEvent
 */
@interface FWViewEvent : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) id object;
@property (nonatomic, copy, readonly) NSDictionary *userInfo;

+ (instancetype)eventWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo;
- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo;

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
@property (nonatomic, weak) id<FWViewDelegate> fwViewDelegate;

// 调用事件代理
- (void)fwTouchEvent:(FWViewEvent *)event;

// 通用视图数据
@property (nonatomic, strong) id fwViewData;

// 渲染数据，子类重写
- (void)fwRenderData;

@end
