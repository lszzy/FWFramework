//
//  UIView+FWBadge.h
//  FWFramework
//
//  Created by wuyong on 2017/4/10.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - FWBadgeView

// 提醒灯样式
typedef NS_ENUM(NSInteger, FWBadgeStyle) {
    // 小红点
    FWBadgeStyleDot = 0,
    // 小提醒灯，同系统标签，(18+)*(18)，12号字体
    FWBadgeStyleSmall,
    // 大提醒灯，同系统桌面，(24+)*(24)，14号字体
    FWBadgeStyleBig,
};

// 提醒灯视图
@interface FWBadgeView : UIView

// 提醒灯文本标签。可自定义样式
@property (nonatomic, readonly) UILabel *badgeLabel;

// 初始化指定样式提醒灯。宽高自动布局，其它手工布局
- (instancetype)initWithStyle:(FWBadgeStyle)style;

@end

#pragma mark - UIView+FWBadge

// 视图提醒灯分类
@interface UIView (FWBadge)

// 显示右上角提醒灯
- (void)fwShowBadgeWithStyle:(FWBadgeStyle)style badgeValue:(NSString *)badgeValue;

// 隐藏提醒灯
- (void)fwHideBadge;

@end

#pragma mark - UIBarButtonItem+FWBadge

// 导航栏项提醒灯分类
@interface UIBarButtonItem (FWBadge)

// 显示右上角提醒灯
- (void)fwShowBadgeWithStyle:(FWBadgeStyle)style badgeValue:(NSString *)badgeValue;

// 隐藏提醒灯
- (void)fwHideBadge;

@end

#pragma mark - UITabBarItem+FWBadge

// 标签栏项提醒灯分类
@interface UITabBarItem (FWBadge)

// 显示右上角提醒灯
- (void)fwShowBadgeWithStyle:(FWBadgeStyle)style badgeValue:(NSString *)badgeValue;

// 隐藏提醒灯
- (void)fwHideBadge;

@end
