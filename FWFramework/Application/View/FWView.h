//
//  FWView.h
//  FWFramework
//
//  Created by wuyong on 2018/12/18.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FWViewEvent : NSObject

@property (readonly, copy) NSNotificationName name;
@property (nullable, readonly, retain) id object;
@property (nullable, readonly, copy) NSDictionary *userInfo;

- (instancetype)initWithName:(NSNotificationName)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end

@protocol FWViewDelegate <NSObject>

- (void)onTapView:(__kindof UIView *)view withEvent:(FWViewEvent *)event;

@end

/*!
 @brief 页面视图基类
 */
@interface FWView : UIView

// 单个数据赋值
- (void)assign:(NSString *)key value:(id)value;

// 批量赋值
- (void)assign:(NSDictionary *)data;

// 获取赋值数据
- (id)fetch:(NSString *)key;

// 获取全部赋值数据
- (NSDictionary *)fetchAll;

// 渲染所有数据，子类重写
- (void)render;

@end
